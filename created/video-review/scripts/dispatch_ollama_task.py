import argparse
import os
import re
import sys
import time
from pathlib import Path


DEFAULT_TASK_NAME = "ClaudeSkills_Ollama_DropfolderWatcher"
SLUG_PATTERN = re.compile(r"^[A-Za-z0-9._-]+$")


def get_drop_dir():
    value = os.environ.get("TRACK_A_DIR")
    if not value:
        print(
            "Error: TRACK_A_DIR is not set. Set it to the Track A dropfolder path.",
            file=sys.stderr,
        )
        sys.exit(1)
    return Path(value).expanduser()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--slug", required=True)
    parser.add_argument("--working-dir", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--timeout", type=int, default=1500)
    parser.add_argument("--poll-interval", type=float, default=5.0)
    args = parser.parse_args()

    if not SLUG_PATTERN.match(args.slug):
        print(
            "Error: --slug may contain only letters, digits, and the characters "
            "'.', '_', and '-'.",
            file=sys.stderr,
        )
        sys.exit(1)

    drop = get_drop_dir()
    task_dir = drop / "tasks"
    done_dir = drop / "done"
    task_name = os.environ.get("TRACK_A_TASK_NAME", DEFAULT_TASK_NAME)

    task_dir.mkdir(parents=True, exist_ok=True)
    done_dir.mkdir(parents=True, exist_ok=True)

    task_path = task_dir / f"{args.slug}.txt"
    tmp_path = task_dir / f"{args.slug}.txt.tmp"
    tmp_path.write_text(
        f"{args.working_dir}\n{args.model}\n{args.prompt}", encoding="utf-8"
    )
    os.replace(tmp_path, task_path)

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


if __name__ == "__main__":
    main()
