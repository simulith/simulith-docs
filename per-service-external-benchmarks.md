# Per-service external benchmarks (5 public repos)

Traceable, repeatable runs of **five pinned public GitHub repositories per matrix service** against Simulith on `:4566`. The goal is to **surface compatibility gaps** (failures become fixes or documented deferrals), not only to record green runs.

Related layers:

| Layer | Doc / path |
| --- | --- |
| In-repo verify | [compatibility.md](compatibility.md) |
| Tri-repo CI pins | [external-benchmarks.md](external-benchmarks.md) |
| Cross-service top-10 suite | [top10-benchmarks.md](top10-benchmarks.md) |
| **Per-service catalogs (this doc)** | `runtime/benchmarks/per-service/<service>/` |

---

## Directory layout

```text
runtime/benchmarks/per-service/
  README.md                 # index of services + catalog paths
  <service>/
    catalog.json              # exactly five pins (immutable SHAs)
    FINDINGS.md               # run log, probes, open gaps (maintained on each pass)
```

**Study / triage template (maintainer):**  (issue triage copy — not in public mirror).

---

## Pin rules

Same as [external-benchmarks.md](external-benchmarks.md#adding-a-pin):

- Public GitHub repository **outside** the `simulith` organization
- **40-character** commit SHA in `catalog.json` (not a branch name)
- Test command that **already exists** upstream (or minimal inline `-c` / `-e` harness documented in the catalog entry)
- Test must **not** start LocalStack, DynamoDB Local, or another emulator
- Runner **does not modify** the cloned checkout

Each catalog entry uses the same JSON shape as [top10-benchmarks.md](top10-benchmarks.md) (`id`, `url`, `sha`, `service`, `runtime`, `setup`, `test`, optional `env`, `cwd`).

---

## How to run (reproduce anytime)

**Prerequisites:** Go toolchain (or published Docker image), **Python 3** and **Node.js** for mixed catalogs, network to clone GitHub.

1. Start Simulith on port **4566** (health must return `ok`):

   ```bash
   cd runtime
   go run ./cmd/simulith start
   ```

   Or Docker per [quickstart.md](quickstart.md).

2. From the **repository root**, point the existing top-10 runner at a per-service catalog:

   **Linux / macOS:**

   ```bash
   export CATALOG_PATH=runtime/benchmarks/per-service/dynamodb/catalog.json
   node runtime/scripts/run-10-benchmarks.mjs
   ```

   **Windows (PowerShell):**

   ```powershell
   $env:CATALOG_PATH="runtime/benchmarks/per-service/dynamodb/catalog.json"
   node runtime/scripts/run-10-benchmarks.mjs
   ```

3. **Artifacts:** shallow clones and virtualenvs under `runtime/artifacts/external-benchmarks/<repo-id>/` (gitignored). Safe to delete and re-run; SHAs in `catalog.json` fix the version.

4. **Optional:** `SIMULITH_ENDPOINT` or `AWS_ENDPOINT_URL` if not using default `http://127.0.0.1:4566`.

5. **After the run:** append a row to `<service>/FINDINGS.md` (date, git commit of Simulith, pass/fail summary, inspector notes).

**Validate catalog JSON only (no clone, no runtime):**

```bash
node runtime/scripts/run-10-benchmarks.mjs --check
```

(`--check` validates the **default** top-10 file; for per-service catalogs, run the full harness once or validate JSON by hand until a dedicated checker exists.)

---

## Issue discovery workflow

1. Pick **five diverse** clients (SDK, community library, CLI, framework sample, application).
2. Add **probe tests** documented in `FINDINGS.md` (tests deliberately excluded elsewhere because they used to fail).
3. Run the harness; record **every FAIL** and recurring HTTP 4xx from request inspector telemetry.
4. Map failures to [compatibility-matrix.md](compatibility-matrix.md) operations.
5. File a runtime fix or document deferral in the service guide **What Simulith does not do** section — then re-run and update `FINDINGS.md`.

Do not replace a failing upstream test with a weaker one without recording the gap.

---

## Service status

| Service | Catalog | Last documented pass |
| --- | --- | --- |
| DynamoDB | `runtime/benchmarks/per-service/dynamodb/catalog.json` | `runtime/benchmarks/per-service/dynamodb/FINDINGS.md` |
| SQS | `runtime/benchmarks/per-service/sqs/catalog.json` | `runtime/benchmarks/per-service/sqs/FINDINGS.md` |
| S3 | `runtime/benchmarks/per-service/s3/catalog.json` | `runtime/benchmarks/per-service/s3/FINDINGS.md` |
| SSM | `runtime/benchmarks/per-service/ssm/catalog.json` | `runtime/benchmarks/per-service/ssm/FINDINGS.md` |
| SNS | `runtime/benchmarks/per-service/sns/catalog.json` | `runtime/benchmarks/per-service/sns/FINDINGS.md` |
| Lambda | `runtime/benchmarks/per-service/lambda/catalog.json` | `runtime/benchmarks/per-service/lambda/FINDINGS.md` |
| Secrets Manager | `runtime/benchmarks/per-service/secretsmanager/catalog.json` | `runtime/benchmarks/per-service/secretsmanager/FINDINGS.md` |
| EventBridge | `runtime/benchmarks/per-service/eventbridge/catalog.json` | `runtime/benchmarks/per-service/eventbridge/FINDINGS.md` |
| API Gateway | `runtime/benchmarks/per-service/apigateway/catalog.json` | `runtime/benchmarks/per-service/apigateway/FINDINGS.md` |
| Cognito | `runtime/benchmarks/per-service/cognito/catalog.json` | `runtime/benchmarks/per-service/cognito/FINDINGS.md` |
| SES | `runtime/benchmarks/per-service/ses/catalog.json` | `runtime/benchmarks/per-service/ses/FINDINGS.md` |
| IAM | `runtime/benchmarks/per-service/iam/catalog.json` | `runtime/benchmarks/per-service/iam/FINDINGS.md` |
| KMS | `runtime/benchmarks/per-service/kms/catalog.json` | `runtime/benchmarks/per-service/kms/FINDINGS.md` |
| Others | TBD — one service at a time | — |

---

## Continuous integration

Per-service catalogs are **not** required checks today. external-benchmarks.yml and [top10-benchmarks.md](top10-benchmarks.md) cover a smaller fixed set. When a service catalog is stable, a story may add an optional workflow slice filtered by `CATALOG_PATH`.

---

## Related

- [external-benchmarks.md](external-benchmarks.md)
- [top10-benchmarks.md](top10-benchmarks.md)
- [compatibility.md](compatibility.md)
