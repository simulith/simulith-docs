# Compatibility verification — Simulith runtime

Measure behavioral parity between **Simulith** and **real AWS** for all **fifteen** shipped services (DynamoDB, SQS, SSM, S3, Lambda, API Gateway, Secrets Manager, Cognito, SES, EventBridge, VPC, RDS, IAM, KMS, Route 53).

For a **public operation × verify coverage matrix**, see [compatibility-matrix.md](compatibility-matrix.md).

## Commands

```bash
simulith verify dynamodb
simulith verify sqs
simulith verify ssm
simulith verify s3
simulith verify lambda
simulith verify apigateway
simulith verify secretsmanager
simulith verify cognito
simulith verify ses
simulith verify eventbridge
simulith verify vpc
simulith verify rds
simulith verify iam
simulith verify kms
simulith verify route53
```

Each subcommand requires a running Simulith server (`simulith start` or Docker Compose).

## Modes

### Full parity (AWS + Simulith)

Runs six curated scenarios on both targets and compares normalized JSON responses:

1. CreateTable + DescribeTable
2. PutItem + GetItem
3. Query
4. Scan
5. UpdateItem
6. DeleteItem

Prerequisites:

- AWS credentials configured (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, or shared config)
- IAM: `dynamodb:CreateTable`, `dynamodb:DeleteTable`, `dynamodb:DescribeTable`, `dynamodb:ListTables`, `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:Query`, `dynamodb:Scan`, `dynamodb:UpdateItem`, `dynamodb:DeleteItem`
- Simulith reachable at the configured endpoint
- SigV4 validation **off** (default) — verify uses static test credentials against Simulith

```bash
export AWS_REGION=us-east-1
simulith start   # separate terminal
simulith verify dynamodb
```

AWS tables use unique names (`simulith-verify-<timestamp>-*`). Each scenario deletes its table on **both** AWS and Simulith when it finishes; a final sweep removes any that remain on each side. AWS cleanup requires IAM permission `dynamodb:DeleteTable`. Simulith cleanup uses local `DeleteTable` (immediate). If cleanup fails, a warning is printed — delete orphans manually, fix IAM (AWS), or run `simulith reset` for unrelated local state.

### Simulith-only smoke (`--skip-aws`)

Use in CI or offline when AWS credentials are unavailable. Runs the same scenarios against Simulith only and checks for success (no parity comparison). Verify tables are deleted locally after each scenario — no orphan `simulith-verify-*` tables remain.

```bash
simulith verify dynamodb --skip-aws
```

### Extended scenarios (opt-in)

Four additional scenarios cover admin APIs, GSI Query, conditional writes, batch writes, batch reads, projection expressions, ADD/DELETE updates, 1 MB Scan pagination, and parallel Scan. They are **not** run by default (CI smoke stays six scenarios). Use `--filter` with a name prefix, or `--filter extended` to run all thirteen:

| Scenario | Operations |
| --- | --- |
| `list-tables` | CreateTable, ListTables (membership assert) |
| `delete-table` | CreateTable, DeleteTable, ListTables absent |
| `query-gsi` | CreateTable + GSI, PutItem, Query with `IndexName` |
| `conditional-put` | PutItem, conditional duplicate Put (`ConditionalCheckFailedException`) |
| `update-table` | UpdateTable metadata (billing, stream) |
| `table-tags` | TagResource, ListTagsOfResource, UntagResource |
| `batch-write-item` | BatchWriteItem put + delete |
| `batch-get-item` | BatchGetItem (found keys only) |
| `transact-write-get-items` | TransactWriteItems + TransactGetItems |
| `projection-expression` | GetItem + Query with ProjectionExpression |
| `update-expression-add-delete` | UpdateItem ADD number + DELETE set elements |
| `query-scan-1mb-pagination` | Scan with ~1 MB page boundary |
| `parallel-scan` | Scan with Segment / TotalSegments |

```bash
simulith verify dynamodb --skip-aws --filter list-tables
simulith verify dynamodb --skip-aws --filter extended
simulith verify dynamodb --filter query-gsi    # full parity when AWS creds available
```

Empty `--filter` runs **default six only**. Prefix matching applies to both default and extended names (e.g. `--filter delete` runs `delete-item` and `delete-table`).

## Flags and environment

| Flag / env | Default | Purpose |
| --- | --- | --- |
| `--endpoint` | `http://127.0.0.1:4566` | Simulith base URL |
| `SIMULITH_ENDPOINT` | — | Same as `--endpoint` |
| `--region` | `us-east-1` | AWS region for both clients |
| `AWS_REGION` | — | Same as `--region` |
| `--skip-aws` | `false` | Simulith-only smoke |
| `--filter` | — | Run scenarios matching name prefix (e.g. `put-get`) |
| `--timeout` | `20m` | Maximum duration for the full verify run |
| `--output` | — | Write JSON compatibility report to path |
| `--save-last` | `false` | Also write JSON to `.simulith/verify-last.json` |

Exit code **0** when all scenarios pass **and** cleanup completes (AWS when not `--skip-aws`, Simulith always). **Non-zero** on scenario failure or when strict cleanup leaves orphaned tables. Report files are still written when `--output` or `--save-last` is set, even on failure.

## Output

Console summary per scenario:

```text
Running 6 DynamoDB scenario(s)

PASS  create-describe-table
...
6 passed, 0 failed
```

### JSON and HTML reports

Write a JSON report during verify:

```bash
simulith verify dynamodb --skip-aws --output report.json
simulith verify dynamodb --output report.json --save-last   # also writes .simulith/verify-last.json
```

Render HTML and print a compatibility summary. Failed parity scenarios show the **first divergent JSON path** with AWS and Simulith values side by side:

```bash
simulith report --input report.json --output-html report.html
simulith report   # reads .simulith/verify-last.json when --save-last was used
```

**Compatibility percentage** = `(passed / total) × 100` for full AWS parity runs (`mode: parity`). Smoke runs (`--skip-aws`, `mode: smoke`) omit the percentage — they do not compare against AWS.

JSON schema (`version: 1`):

| Field | Description |
| --- | --- |
| `service` | `dynamodb` |
| `mode` | `parity` or `smoke` |
| `summary.total` / `passed` / `failed` | Scenario counts |
| `summary.compatibilityPercent` | Present for parity only |
| `scenarios[]` | Per-scenario pass/fail, error, diff snippet |
| `scenarios[].diffDetail` | Optional first JSON path diff (`path`, `aws`, `simulith`) when parity fails |
| `cleanupFailed` | Tables not deleted during cleanup (AWS and/or Simulith) |

Example workflow:

```bash
simulith start   # separate terminal
simulith verify dynamodb --output reports/dynamodb.json
simulith report -i reports/dynamodb.json -o reports/dynamodb.html
```

## Simulith cleanup

Verify deletes each `simulith-verify-*` table on Simulith via **DeleteTable** when a scenario finishes (and sweeps any remaining tracked tables at the end). Deletion is immediate locally. Use `simulith reset` only to clear **non-verify** local state (seeded Demo table, manual experiments).

---

## SSM verification

```bash
simulith verify ssm
```

### Modes

**Full parity** runs nine curated scenarios on both AWS and Simulith and compares normalized JSON responses:

1. PutParameter + GetParameter
2. PutParameter overwrite
3. GetParameters (batch)
4. GetParametersByPath (recursive)
5. DeleteParameter + not-found check
6. DeleteParameters (batch + InvalidParameters)
7. DescribeParameters (Name BeginsWith)
8. SecureString Put/Get with `WithDecryption`
9. Parameter tags (Add/List/Remove)

Prerequisites:

- AWS credentials configured
- IAM: `ssm:PutParameter`, `ssm:GetParameter`, `ssm:GetParameters`, `ssm:GetParametersByPath`, `ssm:DeleteParameter`, `ssm:DeleteParameters`
- Simulith reachable at the configured endpoint

Parameter names use a unique prefix (`/simulith-verify-<timestamp>/...`). Each scenario deletes its AWS parameters when it finishes; a final sweep removes any that remain.

**Simulith-only smoke** (`--skip-aws`):

```bash
simulith verify ssm --skip-aws
```

### Flags

Same flags as DynamoDB verify (`--endpoint`, `--region`, `--skip-aws`, `--filter`, `--timeout`, `--output`, `--save-last`). JSON reports use `service: ssm`.

### Simulith cleanup

SSM parameters persist in SQLite. Run `simulith reset` to clear local SSM state between verify runs.

---

## SQS verification

```bash
simulith verify sqs
```

### Modes

**Full parity** runs ten curated scenarios on both AWS and Simulith and compares normalized JSON responses:

1. CreateQueue + GetQueueUrl
2. SendMessage + ReceiveMessage + DeleteMessage
3. GetQueueAttributes (VisibilityTimeout, DelaySeconds)
4. ListQueues (name prefix)
5. DeleteQueue
6. SetQueueAttributes + GetQueueAttributes
7. SendMessageBatch + ReceiveMessage
8. DeleteMessageBatch
9. PurgeQueue + empty receive + GetQueueUrl
10. ChangeMessageVisibility (hide → change timeout → receive again)

Prerequisites:

- AWS credentials configured
- IAM: `sqs:CreateQueue`, `sqs:DeleteQueue`, `sqs:ListQueues`, `sqs:GetQueueUrl`, `sqs:GetQueueAttributes`, `sqs:SetQueueAttributes`, `sqs:SendMessage`, `sqs:SendMessageBatch`, `sqs:ReceiveMessage`, `sqs:DeleteMessage`, `sqs:DeleteMessageBatch`, `sqs:PurgeQueue`, `sqs:ChangeMessageVisibility`
- Simulith reachable at the configured endpoint
- Standard queues only (verify subset)

Queue names use a unique prefix (`simulith-verify-<timestamp>-*`). Each scenario deletes its queues on **both** AWS and Simulith when it finishes; a final sweep removes any that remain.

**Simulith-only smoke** (`--skip-aws`):

```bash
simulith verify sqs --skip-aws
```

### Flags

Same flags as DynamoDB verify (`--endpoint`, `--region`, `--skip-aws`, `--filter`, `--timeout`, `--output`, `--save-last`). JSON reports use `service: sqs`.

### Simulith cleanup

Verify deletes each `simulith-verify-*` queue on Simulith via **DeleteQueue** when a scenario finishes. Use `simulith reset` to clear unrelated local SQS state.

---

## Lambda verification

```bash
simulith verify lambda
```

### Modes

**Full parity** runs six curated scenarios on both AWS and Simulith and compares normalized JSON responses:

1. Function CRUD lifecycle (Create, List, Get, Delete)
2. Invoke sync payload (RequestResponse; compares status + JSON body)
3. UpdateFunctionCode (CodeSha256 changes)
4. SQS event source mapping lifecycle (Create/List/Get/Delete; creates SQS queue in scenario)
5. ListFunctions after create
6. GetFunction Code.Location

Prerequisites:

- AWS credentials configured
- `SIMULITH_VERIFY_LAMBDA_ROLE_ARN` — Lambda execution role ARN (trust `lambda.amazonaws.com`; SQS + Lambda permissions for ESM scenario)
- Simulith reachable at the configured endpoint
- **`node`** on PATH for invoke scenario (skipped automatically when missing)

Function and queue names use a unique prefix (`simulith-verify-<timestamp>-*`). Scenarios delete AWS functions, ESMs, and queues when they finish; a final sweep removes any that remain.

**Simulith-only smoke** (`--skip-aws`):

```bash
simulith verify lambda --skip-aws
```

### Flags

Same flags as DynamoDB verify (`--endpoint`, `--region`, `--skip-aws`, `--filter`, `--timeout`, `--output`, `--save-last`). JSON reports use `service: lambda`.

### Simulith cleanup

Verify deletes each `simulith-verify-*` function on Simulith via **DeleteFunction** when a scenario finishes. Use `simulith reset` to clear unrelated local Lambda state.

---

## Continuous integration (GitHub Actions)

Every pull request and push to `main`/`master` runs the **`Parity smoke`** job in `.github/workflows/ci.yml` (alongside runtime unit tests).

### What runs

The job builds `simulith`, seeds local state, starts the HTTP server on `:4566`, then runs **Simulith-only verify smoke** (`--skip-aws`) for:

| Service | Command | Default scenarios |
| --- | --- | --- |
| DynamoDB | `simulith verify dynamodb --skip-aws` | 6 |
| SQS | `simulith verify sqs --skip-aws` | 10 |
| SSM | `simulith verify ssm --skip-aws` | 10 |
| S3 | `simulith verify s3 --skip-aws` | 6 |
| Lambda | `simulith verify lambda --skip-aws` | 9 |
| API Gateway | `simulith verify apigateway --skip-aws` | 4 |
| Secrets Manager | `simulith verify secretsmanager --skip-aws` | 2 |
| Cognito | `simulith verify cognito --skip-aws` | 2 |
| SES | `simulith verify ses --skip-aws` | 2 |
| EventBridge | `simulith verify eventbridge --skip-aws` | 2 |
| RDS | `simulith verify rds --skip-aws` | 2 |
| VPC | `simulith verify vpc --skip-aws` | 2 |
| IAM | `simulith verify iam --skip-aws` | 2 |
| KMS | `simulith verify kms --skip-aws` | 2 |

No AWS credentials are required. Reports use JSON schema `version: 1` with **`mode: smoke`** (no `compatibilityPercent`). Lambda **invoke** scenario is skipped when `node` is not on PATH. RDS scenarios are skipped when **Docker** is not on PATH.

**Extended DynamoDB scenarios** (`--filter extended`, 13 total) are **not** part of the default PR job — they add time and overlap with default smoke coverage goals; run them locally or set `VERIFY_DDB_EXTENDED=true` when invoking the script below.

### Artifacts

On completion (pass or fail), the workflow uploads **`parity-verify-reports`** containing:

```text
runtime/artifacts/
  verify-dynamodb.json
  verify-sqs.json
  verify-ssm.json
  verify-s3.json
  verify-lambda.json
  verify-apigateway.json
  verify-secretsmanager.json
  verify-cognito.json
  verify-ses.json
  verify-eventbridge.json
  verify-rds.json
  verify-vpc.json
  verify-iam.json
  verify-kms.json
```

Download from the PR **Checks** tab → **Parity smoke** → **Artifacts**.

**Simulith Console:** extract the JSON files and upload on the **Verify** panel — see [console.md](console.md) § Verify panel.

The job **fails** when any verify command exits non-zero (scenario failure or cleanup failure).

### Reproduce locally

From `runtime/` after building the binary:

```bash
go build -o bin/simulith ./cmd/simulith
SIMULITH_BIN=./bin/simulith ARTIFACTS_DIR=artifacts bash ./scripts/ci-verify-smoke.sh
```

Optional extended DynamoDB report:

```bash
VERIFY_DDB_EXTENDED=true SIMULITH_BIN=./bin/simulith bash ./scripts/ci-verify-smoke.sh
```

Inspect JSON: `simulith report -i artifacts/verify-dynamodb.json`

### Docker Compose verify

The **`Parity smoke (Docker)`** job in `.github/workflows/ci.yml` validates the **shipped runtime Docker image**: Compose builds and starts Simulith on `:4566`, seeds state in a one-off container, then runs the same **verify smoke** commands from a host-built CLI (`--skip-aws`). No manual `simulith start` step.

| Service | Artifact |
| --- | --- |
| DynamoDB | `artifacts/verify-docker-dynamodb.json` |
| SQS | `artifacts/verify-docker-sqs.json` |
| SSM | `artifacts/verify-docker-ssm.json` |
| S3 | `artifacts/verify-docker-s3.json` |
| Lambda | `artifacts/verify-docker-lambda.json` |

RDS verify runs in the **host-runtime** Parity smoke job only (`verify-rds.json`) — the shipped Docker image does not include docker for Postgres sidecars.

Download **`parity-verify-docker-reports`** from the PR Checks tab. The job **fails** when verify or compose health checks fail.

**Reproduce locally** (requires Docker; from `runtime/`):

```bash
go build -o bin/simulith ./cmd/simulith
SIMULITH_BIN=./bin/simulith ARTIFACTS_DIR=artifacts bash ./scripts/ci-verify-smoke-docker.sh
```

Optional all-in-one workshop stack (runtime `:4566` published via overlay):

```bash
COMPOSE_MODE=all-in-one SIMULITH_BIN=./bin/simulith bash ./scripts/ci-verify-smoke-docker.sh
```

Uses `docker-compose.yml` by default, or `docker-compose.all-in-one.yml` + `docker-compose.all-in-one.runtime-port.yml` when `COMPOSE_MODE=all-in-one`.

**Enterprise Trust bundle:** zip with matrix + smoke JSON/HTML + quickstart — [`trust-bundle.md`](trust-bundle.md):

```bash
bash ./scripts/build-trust-bundle.sh
# → dist/simulith-trust-bundle-YYYYMMDD.zip
```

---

## Related

- [trust-bundle.md](trust-bundle.md) — enterprise evaluation zip
- [compatibility-matrix.md](compatibility-matrix.md) — public operation × verify coverage matrix
- [dynamodb.md](dynamodb.md) — DynamoDB operations
- [ssm.md](ssm.md) — SSM operations

- [quickstart.md](quickstart.md) — starting the runtime
