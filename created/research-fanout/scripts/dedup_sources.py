"""List finished research lanes and write one deduplicated source list."""

import argparse
import contextlib
import io
import re
import sys
import tempfile
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit


LANE_PATTERN = re.compile(r"^([A-Z])\. ", re.MULTILINE)
URL_PATTERN = re.compile(r"https?://[^\s)\]>\"'<`]+")
LOCAL_HOSTS = ("localhost", "127.0.0.1", "0.0.0.0")
TRACKING_PARAMS = frozenset({"fbclid", "gclid", "ref"})
DONE_LINE = "STATUS: DONE"


def read_text(path):
    return path.read_text(encoding="utf-8", errors="replace")


def lane_letters(run_dir):
    """Expected lane letters, from the 'A. text' lines of plan.md, in order."""
    plan = run_dir / "plan.md"
    if not plan.is_file():
        return []
    return LANE_PATTERN.findall(read_text(plan))


def last_nonempty_line(path):
    if not path.is_file():
        return None
    for line in reversed(read_text(path).splitlines()):
        if line.strip():
            return line.rstrip()
    return None


def split_lanes(run_dir):
    """Return (done letters, unfinished letters) in plan order."""
    done, unfinished = [], []
    for letter in lane_letters(run_dir):
        path = run_dir / f"agent_{letter}.md"
        if last_nonempty_line(path) == DONE_LINE:
            done.append(letter)
        else:
            unfinished.append(letter)
    return done, unfinished


def normalize(url):
    """Key for one URL, so the same page collapses under tracking noise."""
    parts = urlsplit(url)
    host = parts.netloc.lower()
    if host.startswith("www."):
        host = host[4:]
    params = sorted(
        (name, value) for name, value in parse_qsl(parts.query, True)
        if not name.startswith("utm_") and name not in TRACKING_PARAMS
    )
    return urlunsplit(("https", host, parts.path.rstrip("/"), urlencode(params), ""))


def collect(run_dir, lanes):
    """Map each normalized key to [first original URL, citing lanes in order]."""
    found = {}
    for letter in lanes:
        text = read_text(run_dir / f"agent_{letter}.md")
        for match in URL_PATTERN.finditer(text):
            url = match.group(0).rstrip(".,;:")
            if urlsplit(url).hostname in LOCAL_HOSTS:
                continue  # an API endpoint a worker mentioned, not a source
            entry = found.setdefault(normalize(url), [url, []])
            if letter not in entry[1]:
                entry[1].append(letter)
    return found


def build_sources(run_dir):
    """Write sources.md and return its rows as (url, lanes) pairs."""
    done, _unfinished = split_lanes(run_dir)
    found = collect(run_dir, done)
    # Stable sort on the citing-lane count keeps first-appearance order on ties.
    rows = sorted(found.values(), key=lambda entry: -len(entry[1]))
    lines = ["# Sources", "| # | Source | Cited by |", "|---|---|---|"]
    for number, (url, letters) in enumerate(rows, 1):
        lines.append(f"| {number} | {url} | {', '.join(letters)} |")
    (run_dir / "sources.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{len(rows)} sources from {len(done)} lanes")
    return rows


def print_status(run_dir):
    done, unfinished = split_lanes(run_dir)
    print("done: " + (", ".join(done) or "none"))
    print("unfinished: " + (", ".join(unfinished) or "none"))


def selftest():
    with tempfile.TemporaryDirectory(prefix="dedup_selftest_") as tmp:
        run_dir = Path(tmp)
        plan = "# Plan\n\nQuestion: q\n\nA. one\nB. two\nC. three\n"
        (run_dir / "plan.md").write_text(plan, encoding="utf-8")
        lanes = {
            "A": "A\nSee https://www.Example.com/page/?utm_source=x#top\n"
                 "and https://other.org/x.\nSTATUS: DONE\n",
            "B": "B\nAlso http://example.com/page and `http://localhost:1234/v1`\n"
                 "STATUS: DONE\n",
            "C": "C\nHalf written https://only-c.net\n",
        }
        for letter, text in lanes.items():
            (run_dir / f"agent_{letter}.md").write_text(text, encoding="utf-8")
        quiet = io.StringIO()
        with contextlib.redirect_stdout(quiet):
            print_status(run_dir)
            rows = build_sources(run_dir)
        expected = "done: A, B\nunfinished: C\n"
        assert quiet.getvalue().startswith(expected), quiet.getvalue()
        assert len(rows) == 2, rows
        url, letters = rows[0]
        assert url == "https://www.Example.com/page/?utm_source=x#top", url
        assert letters == ["A", "B"], letters
        written = read_text(run_dir / "sources.md")
        assert "only-c.net" not in written
        assert "| 1 | https://www.Example.com/page/?utm_source=x#top | A, B |" in written
    print("selftest ok")


def main():
    parser = argparse.ArgumentParser(description="Write one source list.")
    parser.add_argument("run_dir", nargs="?", help="Run folder to read.")
    parser.add_argument("--status", action="store_true", help="List lanes only.")
    parser.add_argument("--selftest", action="store_true", help="Run the checks.")
    args = parser.parse_args()
    if args.selftest:
        selftest()
        return
    if not args.run_dir:
        parser.error("RUN_DIR is required unless --selftest is used")
    run_dir = Path(args.run_dir)
    if not run_dir.is_dir():
        print(f"Error: {run_dir} is not a directory.", file=sys.stderr)
        sys.exit(2)
    if args.status:
        print_status(run_dir)
    else:
        build_sources(run_dir)


if __name__ == "__main__":
    main()
