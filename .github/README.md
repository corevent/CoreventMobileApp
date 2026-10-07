# Test automation

## Workflows

- **Development APK** (`workflows/development-apk.yml`): runs on pushes to
  `develop` and manual dispatch on that branch. Generates code, runs analysis
  and unit/widget tests, builds a debug APK with the `development` flavor,
  then publishes a GitHub pre-release with the APK and its SHA-256 checksum.
  It uses `COREVENT_API_URL` from the `staging` Environment and requires no
  signing secrets or GCP authentication. The `.development` application ID
  keeps its installation and session separate from production and integration.
  Each run creates a `dev-RUN-ATTEMPT` tag; production releases remain unchanged.
  Download `corevent-development.apk` from **Releases**. Android integration
  remains in the Tests workflow; this publication does not wait for that workflow.
  GitHub runners generate debug signing keys, so installing another build can
  require uninstalling the previous development app, which clears its local data.
- **Tests** (`workflows/tests.yml`): runs on pull requests, pushes to `main` or
  `develop`, and manual dispatch. Checks formatting, generation, analysis, unit,
  widget and contract tests, then Android integration with fixtures. No API or
  Google Cloud credentials are required. Flutter 3.47.5, Java 17 and an Android
  API 33 x86_64 emulator are used.
- **Staging E2E** (`workflows/e2e.yml`): manual dispatch in GitHub Actions. Runs
  the existing preparation Job, reads its structured result, then executes the
  ten E2E scenarios on one emulator through `integration_test/e2e/all_test.dart`.
  The workflow changes data in staging and serializes preparation plus tests.

The E2E workflow requires `.github/workflows/e2e.yml` on the repository's default
branch for its manual dispatch entry to appear in Actions. Configure the
`staging` Environment to allow only trusted branches such as `main` and `develop`.
Preparation must not be launched manually or by another repository while this
suite is running: GitHub concurrency protects only workflows in this repository.

## GitHub configuration

In **Settings → Environments → staging**, add:

| Type | Name | Value |
| --- | --- | --- |
| Variable | `GCP_PROJECT_ID` | `corevent-staging-510316` |
| Variable | `GCP_REGION` | `us-central1` |
| Variable | `GCP_PREPARE_JOB` | Existing Cloud Run preparation Job name |
| Variable | `COREVENT_API_URL` | `https://corevent-staging-api-666040325433.us-central1.run.app` |
| Variable | `GCP_WIF_PROVIDER` | `projects/NUMBER/locations/global/workloadIdentityPools/POOL/providers/PROVIDER` |
| Variable | `GCP_SERVICE_ACCOUNT` | Service account email for GitHub Actions |
| Secret | `COREVENT_E2E_EMAIL` | Email of the account created by the preparator |
| Secret | `COREVENT_E2E_PASSWORD` | Password of that account |

`eventId` and `freeTicketName` are read automatically from the preparation JSON.
The generated `reports/preparation.json` is an output artifact, not an E2E input
configuration file. No API keys, database passwords or QR secrets are stored in
GitHub by these workflows.

## Google Cloud configuration

Configure [Workload Identity Federation](https://github.com/google-github-actions/auth)
for GitHub's OIDC provider. Restrict the provider to this repository and trusted
refs/environment. Grant its matching principal `roles/iam.workloadIdentityUser`
on the GitHub service account so it can impersonate that account.

The GitHub service account needs:

- `roles/run.invoker` on the preparation Job to execute it.
- `roles/logging.viewer` on the staging project to read the result logs.

The preparation Job itself uses its own runtime service account and existing
database/Secret Manager/network permissions. It must use the updated API image,
command `node`, argument `dist/database/seeds/prepare-e2e.js`, `NODE_ENV=staging`,
one task, parallelism one and zero automatic retries. Its database and
`QR_CODE_SECRET` must match the staging API.

The workflow does not deploy the API, run migrations or modify the Job's
configuration. Ensure those are current before dispatching the suite.

## Results and failure behavior

Artifacts are uploaded even after failure:

- Unit: LCOV, readable log and JSON-lines test results; retained for 14 days.
- Android integration: readable log, JSON-lines results, logcat and command
  duration/exit code; retained for 14 days.
- E2E: the same Android reports plus preparation identifiers/result; retained
  for 7 days. APKs and authentication files are not uploaded.

Flutter failures preserve the failing exit code. Preparation failure, an invalid
schema, account mismatch or ambiguous output prevents E2E execution. Logs are
filtered by the exact execution name returned by `gcloud`, not the latest Job
execution. The reader tolerates log-ingestion delay for up to 120 seconds without
starting another preparation.

The photo scenario remains enabled and can fail until its initial avatar URL is
fixed. External payment, email and process-restart scenarios remain manual.
Coverage is reported but there is no automated coverage threshold gate yet.

After the first successful CI run, require the **Unit, widget and contract tests**
and **Android integration with fixtures** checks in branch protection. The
manually dispatched E2E workflow should not be a required check on every PR.

## Local checks for CI helpers

```sh
python -m unittest discover -s .github/scripts -p 'test_*.py'
bash -n .github/scripts/run-android-tests.sh
```

These checks neither execute the Cloud Run Job nor contact the API. To run the
Android suite locally, continue using the Flutter commands in the main README.
