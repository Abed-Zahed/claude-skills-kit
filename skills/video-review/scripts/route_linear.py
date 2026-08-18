import argparse
import subprocess
import sys

JOB_KEYWORDS = ("job", "cv", "resume", "application", "recruiter")
AZURE_KEYWORDS = ("azure", "chocolate", "choco", "business")


def resolve_route(ticket_id, route_hint):
    if ticket_id.startswith("JOB-"):
        return "job_hunter"
    if ticket_id.startswith("SOLO-"):
        return "azure"
    hint = route_hint.lower()
    if any(k in hint for k in JOB_KEYWORDS):
        return "job_hunter"
    if any(k in hint for k in AZURE_KEYWORDS):
        return "azure"
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ticket-id", required=True)
    parser.add_argument("--description", required=True)
    parser.add_argument("--route-hint", required=True)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    target = resolve_route(args.ticket_id, args.route_hint)
    if target is None:
        sys.stderr.write(
            "Error: routing is ambiguous; the ticket ID prefix or route "
            "hint needs to be more specific.\n"
        )
        sys.exit(1)

    if target == "job_hunter":
        cmd = [
            "python", "-m", "src.linear_push",
            "--update", args.ticket_id,
            "-d", args.description,
        ]
        cwd = r"D:\Projects\Job_hunter"
    else:
        cmd = [
            "python", "linear_push.py",
            "--update", args.ticket_id,
            "-d", args.description,
            "--project", "Azure Projects",
        ]
        cwd = r"D:\Projects\Azure\Azure_projects"

    if args.dry_run:
        print(f"Dry run: command={cmd}, cwd={cwd}")
        sys.exit(0)

    result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if result.stdout:
        sys.stdout.write(result.stdout)
    if result.stderr:
        sys.stderr.write(result.stderr)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
