"""Transferability check for the kit.

Simulates a user installing each skill on a clean machine: copies the skill
folder (and ollama-addon/, as the README tells add-on users to) into a
throwaway home directory, then checks that everything the skill points at
still resolves there.

    python tests/check_structure.py        exit 0 = pass, 1 = failures listed
"""
import json
import pathlib
import py_compile
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILL_DIRS = sorted(p for base in ("created", "collected") for p in (ROOT / base).iterdir() if p.is_dir())
PRIVATE = re.compile(r"[A-Z]:[\\/](Projects|Work)\b|C:[\\/]Users[\\/](?!<|%|\$)|cool_|Administrator|Abed|Zahed|Defuzzy|furssai|"
                     r"Job.?Hunter|Agent_Orchestrator|Azure Choc|Reel.?checker|chat_id\.txt|Faction", re.I)
MODEL = re.compile(r"\b(deepseek-v\d|glm-\d|kimi-k\d|qwen\d)", re.I)
# Skills whose job depends on something outside stock Claude Code.
NEEDS_SETUP = {"polish-prompt", "tailor-jd", "task-status", "web-scraping", "video-review",
               "internal-focus-group", "improve-system"}
# Relative file references: markdown links and backticked paths with a known extension.
REF = re.compile(r"\]\(([^)#\s]+)\)|`([\w./-]+\.(?:md|ps1|py|json|txt))`|(?<![\w/~$<.`])((?:[\w-]+/)+[\w.-]+\.(?:md|ps1|py|json|txt))")

failures = []


def fail(msg):
    failures.append(msg)


def frontmatter(text):
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}
    out, key = {}, None
    for line in m.group(1).splitlines():
        km = re.match(r"(\w[\w-]*):\s?(.*)", line)
        if km:
            key = km.group(1)
            out[key] = km.group(2)
        elif key:
            out[key] += " " + line.strip()
    return out


with tempfile.TemporaryDirectory() as tmp:
    home = pathlib.Path(tmp) / "home" / ".claude"
    shutil.copytree(ROOT / "ollama-addon", home / "ollama-addon")
    for sd in SKILL_DIRS:
        dest = home / "skills" / sd.name
        shutil.copytree(sd, dest)
        skill_md = next((p for p in dest.iterdir() if p.name.lower() == "skill.md"), None)
        if not skill_md:
            fail(f"{sd.name}: no SKILL.md")
            continue
        if skill_md.name != "SKILL.md":
            fail(f"{sd.name}: file is {skill_md.name}, must be SKILL.md (case-sensitive filesystems)")
        text = skill_md.read_text(encoding="utf-8")
        fm = frontmatter(text)
        if fm.get("name", "").strip() != sd.name:
            fail(f"{sd.name}: frontmatter name is {fm.get('name')!r}, expected {sd.name!r}")
        desc = fm.get("description", "").strip()
        if not desc or len(desc) > 1024:
            fail(f"{sd.name}: description missing or over 1024 chars ({len(desc)})")
        if sd.name in NEEDS_SETUP:
            if "Setup:" not in desc:
                fail(f"{sd.name}: description has no 'Setup:' sentence")
            if "## Setup check" not in text:
                fail(f"{sd.name}: no '## Setup check' section")
        if sd.parent.name == "collected":
            continue  # third-party text, checked for references only by its author
        for f in dest.rglob("*"):
            if not f.is_file() or f.suffix not in {".md", ".ps1", ".py", ".json", ".txt"}:
                continue
            body = f.read_text(encoding="utf-8")
            rel = f"{sd.name}/{f.relative_to(dest).as_posix()}"
            for m in PRIVATE.finditer(body):
                fail(f"{rel}: private string {m.group(0)!r}")
            if MODEL.search(body):
                fail(f"{rel}: hardcoded model name {MODEL.search(body).group(0)!r}")
            if f.suffix == ".md":
                for m in REF.finditer(body):
                    ref = (m.group(1) or m.group(2) or m.group(3)).strip()
                    if ref.startswith(("http", "~", "$", "<", "/")) or "*" in ref:
                        continue
                    # Only shipped files matter; runtime outputs (reports/..., tailored/...) are created later.
                    shipped = any(ROOT.rglob(pathlib.PurePosixPath(ref.lstrip("./")).as_posix())) if ".." not in ref else True
                    if not shipped:
                        continue
                    candidates = [f.parent / ref, dest / ref, home / ref, home / "skills" / ref]
                    if not any(c.exists() for c in candidates):
                        fail(f"{rel}: reference {ref!r} is a kit file that is not installed with the skill")
            if f.suffix == ".json":
                try:
                    json.loads(body)
                except ValueError as e:
                    fail(f"{rel}: invalid JSON ({e})")
            if f.suffix == ".py":
                try:
                    py_compile.compile(str(f), doraise=True, cfile=str(pathlib.Path(tmp) / "x.pyc"))
                except py_compile.PyCompileError as e:
                    fail(f"{rel}: {e.msg}")

ps1 = [str(p) for p in ROOT.rglob("*.ps1")]
if ps1 and shutil.which("powershell"):
    script = ("$bad=0; foreach($f in $args){$e=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($f,[ref]$null,[ref]$e);"
              "if($e.Count){Write-Output \"$f : $($e[0].Message)\"; $bad++}}; exit $bad")
    r = subprocess.run(["powershell", "-NoProfile", "-Command", script, *ps1], capture_output=True, text=True)
    for line in r.stdout.splitlines():
        fail(f"PowerShell parse: {line}")

if failures:
    print(f"FAIL: {len(failures)} problem(s)")
    for f in failures:
        print(" -", f)
    sys.exit(1)
print(f"PASS: {len(SKILL_DIRS)} skills install cleanly")
