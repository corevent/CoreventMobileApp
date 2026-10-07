"""Execute the staging preparator once and consume only its execution's logs."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from uuid import UUID


def extract_preparation(entries, expected_email):
    candidates = []
    for entry in entries:
        payload = entry.get("jsonPayload")
        if not isinstance(payload, dict):
            try:
                payload = json.loads(entry.get("textPayload", ""))
            except (ValueError, TypeError):
                continue
        if isinstance(payload, dict) and "schemaVersion" in payload:
            if payload.get("schemaVersion") != 1:
                raise ValueError("Unsupported preparation schemaVersion")
            for key in ("runId", "eventId", "userId", "freeTicketTypeId", "paidTicketTypeId", "orderId", "ticketId"):
                value = payload.get(key)
                if not isinstance(value, str):
                    raise ValueError(f"Invalid preparation field: {key}")
                UUID(value)
            if payload.get("email") != expected_email:
                raise ValueError("Prepared account does not match COREVENT_E2E_EMAIL")
            name = payload.get("freeTicketName")
            if not isinstance(name, str) or not name.strip() or "\n" in name or "\r" in name:
                raise ValueError("Invalid freeTicketName")
            if payload not in candidates:
                candidates.append(payload)
    if len(candidates) > 1:
        raise ValueError("Multiple preparation results in the same execution")
    return candidates[0] if candidates else None


def gcloud_json(*arguments):
    try:
        result = subprocess.run(
            ["gcloud", *arguments, "--format=json", "--quiet"],
            check=True, capture_output=True, text=True, timeout=660,
        )
    except subprocess.CalledProcessError as error:
        # Report CLI diagnostics, never the JSON output or credential file.
        for line in (error.stderr or "gcloud returned no error details").splitlines():
            print(f"gcloud: {line}", file=sys.stderr)
        raise
    return json.loads(result.stdout)


def main():
    project = os.environ["GCP_PROJECT_ID"]
    region = os.environ["GCP_REGION"]
    job = os.environ["GCP_PREPARE_JOB"]
    reports = Path("reports")
    reports.mkdir(exist_ok=True)
    execution = gcloud_json(
        "run", "jobs", "execute", job, f"--project={project}",
        f"--region={region}", "--wait",
    )
    execution_name = execution["metadata"]["name"].split("/")[-1]
    if not all(re.fullmatch(r"[a-zA-Z0-9_-]+", value) for value in (execution_name, job, region)):
        raise ValueError("Invalid Cloud Run execution identifiers")
    (reports / "preparation-execution.txt").write_text(execution_name + "\n")
    print(f"Preparation completed: {execution_name}", flush=True)
    log_filter = (
        'resource.type="cloud_run_job" '
        f'AND resource.labels.job_name="{job}" '
        f'AND resource.labels.location="{region}" '
        f'AND labels."run.googleapis.com/execution_name"="{execution_name}"'
    )
    # Log ingestion can lag behind the successful execution. Never rerun the job.
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        entries = gcloud_json(
            "logging", "read", log_filter, f"--project={project}",
            "--freshness=1d", "--order=asc", "--limit=200",
        )
        data = extract_preparation(entries, os.environ["COREVENT_E2E_EMAIL"])
        if data is not None:
            (reports / "preparation.json").write_text(json.dumps(data, indent=2) + "\n")
            with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
                output.write(f"event_id={data['eventId']}\n")
                output.write(f"free_ticket_name={data['freeTicketName']}\n")
            return
        time.sleep(5)
    raise RuntimeError("No preparation JSON found for this execution within 120 seconds")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        print(f"::error::Staging preparation failed: {error}", file=sys.stderr)
        sys.exit(1)
