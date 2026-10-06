#!/usr/bin/env bash
set -euo pipefail

mode="${1:?Specify controlled or e2e}"
mkdir -p reports
args=(--flavor integration --no-pub --reporter expanded "--file-reporter=json:reports/${mode}.jsonl")
case "$mode" in
  controlled) target=integration_test/controlled ;;
  e2e)
    target=integration_test/e2e/all_test.dart
    for key in COREVENT_API_URL COREVENT_E2E_EMAIL COREVENT_E2E_PASSWORD COREVENT_E2E_EVENT_ID COREVENT_E2E_FREE_TICKET_NAME; do
      : "${!key:?Missing $key}"
      args+=("--dart-define=${key}=${!key}")
    done
    ;;
  *) echo 'Unknown test mode' >&2; exit 64 ;;
esac

# This runs while the emulator is alive; the action shuts it down afterwards.
started=$(date +%s)
adb logcat -c
adb logcat -v threadtime > "reports/${mode}-logcat.log" 2>&1 &
logcat_pid=$!
trap 'kill "$logcat_pid" 2>/dev/null || true' EXIT
set +e
flutter test "$target" "${args[@]}" 2>&1 | tee "reports/${mode}.log"
pipeline_status=("${PIPESTATUS[@]}")
result=${pipeline_status[0]}
if [[ "$result" -eq 0 && "${pipeline_status[1]}" -ne 0 ]]; then
  result=${pipeline_status[1]}
fi
set -e
finished=$(date +%s)
printf '{"exitCode":%s,"elapsedSeconds":%s}\n' "$result" "$((finished-started))" > "reports/${mode}-timing.json"
exit "$result"
