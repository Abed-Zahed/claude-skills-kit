import argparse
import sys
import time
from pathlib import Path

DROP = Path("D:/Projects/Agent_Orchestrator/ollama_dropfolder")
TASK_DIR = DROP / "tasks"
DONE_DIR = DROP / "done"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--slug", required=True)
    parser.add_argument("--working-dir", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--timeout", type=int, default=300)
    parser.add_argument("--poll-interval", type=float, default=5.0)
    args = parser.parse_args()

    TASK_DIR.mkdir(parents=True, exist_ok=True)
    task_path = TASK_DIR / f"{args.slug}.txt"
    task_path.write_text(
        f"{args.working_dir}\n{args.model}\n{args.prompt}", encoding="utf-8"
    )

    done_path = DONE_DIR / f"{args.slug}_done.txt"
    elapsed = 0.0
    while elapsed < args.timeout:
        if done_path.exists():
            print(done_path.read_text(encoding="utf-8", errors="replace"), end="")
            sys.exit(0)
        time.sleep(args.poll_interval)
        elapsed += args.poll_interval

    print(
        f"Error: task {args.slug} did not complete within {args.timeout} "
        "seconds. The watcher (JobHunter_Ollama_DropfolderWatcher scheduled "
        "task) may not be running.",
        file=sys.stderr,
    )
    sys.exit(1)


if __name__ == "__main__":
    main()
