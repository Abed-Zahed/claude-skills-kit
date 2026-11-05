"""Dispatch one Track A task and wait for its done file.

Task file format: line 1 working directory, line 2 model, then optional
KEY=value header lines, then the prompt.
"""

import argparse
import os
import re
import sys
import tempfile
import time
from pathlib import Path


DEFAULT_TASK_NAME = "ClaudeSkills_Ollama_DropfolderWatcher"
SLUG_PATTERN = re.compile(r"^[A-Za-z0-9._-]+$")
# The only keys run_dropfolder_task.ps1 accepts.
HEADER_KEYS = ("TimeoutMinutes", "MaxTurns", "OutFile", "BudgetKey", "BudgetBase")


def get_drop_dir():
    value = os.environ.get("TRACK_A_DIR")
    if not value:
        # Scheduled-task callers get no shell env; the drop folder sits beside this script.
        sibling = Path(__file__).resolve().parent / "ollama_dropfolder"
        if sibling.is_dir():
            return sibling
        print(
            "Error: TRACK_A_DIR is not set and no ollama_dropfolder sits beside this "
            "script. Set TRACK_A_DIR to the Track A dropfolder path.",
            file=sys.stderr,
        )
        sys.exit(1)
    return Path(value).expanduser()


def parse_headers(items):
    """Validate --header KEY=VALUE items. Exit 2 on any bad key or value."""
    headers = []
    for item in items or []:
        key, sep, value = item.partition("=")
        if not sep:
            print(
                f"Error: --header expects KEY=VALUE, got {item!r}.",
                file=sys.stderr,
            )
            sys.exit(2)
        if key not in HEADER_KEYS:
            print(
                "Error: --header KEY must be one of "
                + ", ".join(HEADER_KEYS)
                + f"; got {key!r}.",
                file=sys.stderr,
            )
            sys.exit(2)
        if not value.strip():
            print(
                f"Error: --header {key} needs a non-empty value.",
                file=sys.stderr,
            )
            sys.exit(2)
        if "\n" in value or "\r" in value:
            print(
                f"Error: --header {key} value must not contain a newline.",
                file=sys.stderr,
            )
            sys.exit(2)
        headers.append((key, value.strip()))
    return headers


def read_prompt(args):
    """Return the prompt text from --prompt, or read --prompt-file as UTF-8."""
    if args.prompt is not None:
        return args.prompt
    path = Path(args.prompt_file)
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        print(f"Error: cannot read --prompt-file {path}: {exc}", file=sys.stderr)
        sys.exit(2)


def build_task_content(working_dir, model, headers, prompt):
    """Build the task file text: dir, model, headers in order, then the prompt."""
    lines = [working_dir, model]
    lines.extend(f"{key}={value}" for key, value in headers)
    lines.append(prompt)
    return "\n".join(lines)


def write_task_file(task_dir, slug, content):
    """Write <slug>.txt.tmp then rename, so the watcher never reads half a file."""
    task_dir.mkdir(parents=True, exist_ok=True)
    task_path = task_dir / f"{slug}.txt"
    tmp_path = task_dir / f"{slug}.txt.tmp"
    tmp_path.write_text(content, encoding="utf-8")
    os.replace(tmp_path, task_path)
    return task_path


def run(args):
    if not SLUG_PATTERN.match(args.slug):
        print(
            "Error: --slug may contain only letters, digits, and the characters "
            "'.', '_', and '-'.",
            file=sys.stderr,
        )
        sys.exit(1)

    # Validate everything before a task file exists, so a bad call writes nothing.
    headers = parse_headers(args.header)
    prompt = read_prompt(args)

    drop = get_drop_dir()
    task_dir = drop / "tasks"
    done_dir = drop / "done"
    task_name = os.environ.get("TRACK_A_TASK_NAME", DEFAULT_TASK_NAME)

    done_dir.mkdir(parents=True, exist_ok=True)
    write_task_file(
        task_dir,
        args.slug,
        build_task_content(args.working_dir, args.model, headers, prompt),
    )

    inflight_path = task_dir / f"{args.slug}.txt.inflight"
    done_path = done_dir / f"{args.slug}_done.txt"
    elapsed = 0.0
    while elapsed < args.timeout:
        if done_path.exists():
            print(done_path.read_text(encoding="utf-8", errors="replace"), end="")
            sys.exit(0)
        time.sleep(args.poll_interval)
        elapsed += args.poll_interval

    if inflight_path.exists():
        print(
            f"Error: task {args.slug} did not complete within {args.timeout} "
            "seconds. It is still running, claimed by the watcher.",
            file=sys.stderr,
        )
    else:
        print(
            f"Error: task {args.slug} did not complete within {args.timeout} "
            f"seconds. The watcher scheduled task '{task_name}' may not be running.",
            file=sys.stderr,
        )
    sys.exit(1)


def build_parser():
    parser = argparse.ArgumentParser(
        description="Write one Track A task file and wait for its done file.",
    )
    parser.add_argument("--slug", required=True)
    parser.add_argument("--working-dir", required=True)
    parser.add_argument("--model", required=True)
    prompt_group = parser.add_mutually_exclusive_group(required=True)
    prompt_group.add_argument("--prompt", help="Prompt text inline.")
    prompt_group.add_argument(
        "--prompt-file",
        metavar="PATH",
        help="Read the prompt from PATH as UTF-8 instead of --prompt.",
    )
    parser.add_argument(
        "--header",
        action="append",
        metavar="KEY=VALUE",
        help=(
            "Task file header line, repeatable and written in the order given, "
            "after the model line. KEY must be one of "
            + ", ".join(HEADER_KEYS)
            + "."
        ),
    )
    parser.add_argument("--timeout", type=int, default=1500)
    parser.add_argument("--poll-interval", type=float, default=5.0)
    parser.add_argument(
        "--selftest",
        action="store_true",
        help="Run the built-in checks against a temporary drop folder and exit.",
    )
    return parser


def selftest():
    """Exercise the writer against a temporary drop folder, then print ok."""

    def call(argv):
        try:
            main(argv)
        except SystemExit as exc:
            return exc.code
        return 0

    previous = os.environ.get("TRACK_A_DIR")
    with tempfile.TemporaryDirectory(prefix="dispatch_selftest_") as tmp:
        drop = Path(tmp)
        tasks = drop / "tasks"
        done = drop / "done"
        tasks.mkdir()
        done.mkdir()
        os.environ["TRACK_A_DIR"] = str(drop)
        try:
            # (a) headers land between the model line and the prompt.
            (done / "alpha_done.txt").write_text("ok\n", encoding="utf-8")
            code = call(
                [
                    "--slug",
                    "alpha",
                    "--working-dir",
                    "D:\\work",
                    "--model",
                    "m:cloud",
                    "--header",
                    "BudgetKey=rf_selftest",
                    "--header",
                    "BudgetBase=60",
                    "--prompt",
                    "PROMPT LINE",
                ]
            )
            assert code == 0, f"good dispatch exited {code}"
            lines = (tasks / "alpha.txt").read_text(encoding="utf-8").split("\n")
            assert lines[0] == "D:\\work", lines
            assert lines[1] == "m:cloud", lines
            assert lines[2] == "BudgetKey=rf_selftest", lines
            assert lines[3] == "BudgetBase=60", lines
            assert lines[4:] == ["PROMPT LINE"], lines

            # (b) an unknown header key exits 2 and writes nothing.
            code = call(
                [
                    "--slug",
                    "bad",
                    "--working-dir",
                    "D:\\work",
                    "--model",
                    "m:cloud",
                    "--header",
                    "NotAKey=1",
                    "--prompt",
                    "x",
                ]
            )
            assert code == 2, f"bad key exited {code}"
            assert not (tasks / "bad.txt").exists()

            # (c) --prompt-file content is used.
            prompt_file = drop / "prompt_from_file.md"
            prompt_file.write_text("FROM FILE", encoding="utf-8")
            (done / "beta_done.txt").write_text("ok\n", encoding="utf-8")
            code = call(
                [
                    "--slug",
                    "beta",
                    "--working-dir",
                    "D:\\work",
                    "--model",
                    "m:cloud",
                    "--prompt-file",
                    str(prompt_file),
                ]
            )
            assert code == 0, f"prompt-file dispatch exited {code}"
            beta = (tasks / "beta.txt").read_text(encoding="utf-8").split("\n")
            assert beta[2:] == ["FROM FILE"], beta

            # (d) no temporary file is left behind and nothing else was written.
            written = sorted(p.name for p in tasks.iterdir())
            assert written == ["alpha.txt", "beta.txt"], written
        finally:
            if previous is None:
                os.environ.pop("TRACK_A_DIR", None)
            else:
                os.environ["TRACK_A_DIR"] = previous
    print("selftest ok")


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if "--selftest" in argv:
        selftest()
        return
    run(build_parser().parse_args(argv))


if __name__ == "__main__":
    main()
