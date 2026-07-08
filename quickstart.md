# Simulith Runtime — Quickstart

Get from zero to a **working local AWS-compatible runtime** with a DynamoDB + SQS smoke test in **under five minutes**.

This guide is the **stable onboarding entry point** for the MVP. It is not tied to a single user story.

> **Story validation:** To QA a specific feature (SML-001, SML-002, …), use that story's checklist — index: `cursor/analysis/shared/runtime-validation-index.md`.

---

## What you get

Simulith runs a local HTTP server (default port **4566**) that AWS CLI and SDKs can target with `--endpoint-url`. The MVP ships:

| Service | Status |
| --- | --- |
| DynamoDB | CreateTable, CRUD, Query, Scan — [dynamodb.md](dynamodb.md) |
| SQS | CreateQueue, Send/Receive/DeleteMessage — [sqs.md](sqs.md) |
| SSM | Put/GetParameter (SQLite persistence) |

State persists in SQLite. Developer commands: seed, reset, snapshot — see [persistence.md](persistence.md).

---

## Prerequisites

Pick **one** run path:

| Path | You need |
| --- | --- |
| **Docker** (recommended) | Docker Desktop or Engine + Compose |
| **Native** | Go 1.24+ ([go.dev/dl](https://go.dev/dl/)) |

For the **smoke test** below:

- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (any credentials work against the local endpoint; region `us-east-1` is used in examples)

**Windows:** Examples use Bash-style lines. Git Bash or WSL works best; adapt paths for PowerShell if needed.

All commands assume you are in the **`runtime/`** module directory:

```bash
cd runtime
```

---

## Five-minute path (overview)

1. Load the demo fixture (`simulith seed`) — server must not be running
2. Start Simulith (Docker or native)
3. Verify `/health`
4. Smoke-test DynamoDB, SQS, and SSM with AWS CLI

Detailed steps follow.

---

## 1. Load demo data

The built-in seed profile creates a DynamoDB table `Demo`, SQS queue `demo-queue`, SSM parameters under `/app/demo/*`, and S3 bucket `demo-bucket`. Details: [seed.md](seed.md).

**Stop the server first** if it is already running (SQLite lock). Seed writes directly to the state database.

**Native:**

```bash
cd runtime
go run ./cmd/simulith seed
```

**Docker** (uses the Compose named volume — do **not** run host `go run seed` unless you enable the bind mount in [docker.md](docker.md)):

```bash
cd runtime
docker compose run --rm --entrypoint simulith simulith seed
```

---

## 2. Start Simulith

### Option A — Docker workshop demo (Console + runtime, one URL)

Recommended for **first contact** and workshops — FW-PRD-012 / SML-060. See [console.md](console.md) and [docker.md](docker.md).

```bash
cd runtime
docker compose -f docker-compose.all-in-one.yml up --build
```

Open **http://localhost:9080** — use **Seed demo data** on the Dashboard, then explore DynamoDB / SQS / SSM panels.

Runtime health via proxy:

```bash
curl http://localhost:9080/runtime/health
```

Expected: `{"status":"ok"}`. Host `:4566` is **not** required for this path.

### Option B — Docker (runtime only)

See [docker.md](docker.md) for volumes, healthcheck, and troubleshooting.

```bash
cd runtime
docker compose up --build
```

In another terminal:

```bash
curl http://localhost:4566/health
```

Expected: `{"status":"ok"}`

Compose binds `0.0.0.0:4566` so the host can reach the server.

### Option C — Native

```bash
cd runtime
go mod download
go run ./cmd/simulith start
```

In another terminal:

```bash
curl http://127.0.0.1:4566/health
```

Bare `simulith` defaults to `start`:

```bash
go run ./cmd/simulith
```

Build a binary (optional):

```bash
go build -o simulith ./cmd/simulith
./simulith start
```

---

## 3. Smoke test (AWS CLI)

With the server running:

**DynamoDB — describe seeded table:**

```bash
aws dynamodb describe-table \
  --table-name Demo \
  --endpoint-url http://127.0.0.1:4566 \
  --region us-east-1
```

**SQS — receive seeded message:**

```bash
aws sqs receive-message \
  --queue-url http://127.0.0.1:4566/000000000000/demo-queue \
  --endpoint-url http://127.0.0.1:4566 \
  --region us-east-1
```

Expected: table metadata for `Demo`; message body `hello from seed`; SSM parameter `/app/demo/api-url` value `http://localhost:8080`.

```bash
aws ssm get-parameter --name /app/demo/api-url \
  --endpoint-url http://127.0.0.1:4566 --region us-east-1
```

For more CLI operations, see **[AWS CLI examples](aws-cli-examples.md)**. This quickstart only proves the endpoint works.

**Automated equivalent** (no AWS CLI): from `runtime/` run `go test ./internal/runtime -run TestSmoke_MVP -count=1`, or from repo root `maintainer workflow (private monorepo)`. See scripts/README.md.

---

## CLI commands at a glance

| Command | Purpose | Doc |
| --- | --- | --- |
| `simulith start` | Run HTTP runtime | this guide |
| `simulith seed` | Load demo fixture | [seed.md](seed.md) |
| `simulith reset` | Clear DynamoDB + SQS state | [persistence.md](persistence.md) |
| `simulith snapshot save\|restore` | Export/import full state | [snapshot.md](snapshot.md) |
| `simulith verify dynamodb` | Compare DynamoDB against real AWS | [compatibility.md](compatibility.md) |
| `simulith verify ssm` | Compare SSM against real AWS | [compatibility.md](compatibility.md) |
| `simulith report` | HTML report from verify JSON | [compatibility.md](compatibility.md) |

---

## Configuration (optional)

Copy the example config:

```bash
cp config.example.yaml config.yaml
```

Auto-loads `./config.yaml` when present. Precedence: **flags > env > file > defaults**.

| Variable | Default (native) | Notes |
| --- | --- | --- |
| `SIMULITH_HOST` | `127.0.0.1` | Use `0.0.0.0` in Docker |
| `SIMULITH_PORT` | `4566` | |
| `SIMULITH_STATE_PATH` | `./.simulith/state.db` | See [persistence.md](persistence.md) |
| `SIMULITH_LOG_LEVEL` | `info` | |

Flags: `--config`, `--host`, `--port`

Container-specific config: [docker.md](docker.md).

---

## Health contract

| Method | Path | Body |
| --- | --- | --- |
| `GET` | `/health` | `{"status":"ok"}` |

---

## Next steps

| Topic | Guide |
| --- | --- |
| **Using Simulith (local vs AWS)** | [using-simulith.md](using-simulith.md) — **read this after Docker is running** |
| DynamoDB operations | [dynamodb.md](dynamodb.md) |
| SQS operations | [sqs.md](sqs.md) |
| Persistence, reset, state path | [persistence.md](persistence.md) |
| Compatibility testing | [compatibility.md](compatibility.md) |
| Compatibility matrix (API + verify) | [compatibility-matrix.md](compatibility-matrix.md) |
| AWS CLI examples | [aws-cli-examples.md](aws-cli-examples.md) |
| SDK examples | [sdk-examples.md](sdk-examples.md) |
| Terraform integration | [terraform-integration.md](terraform-integration.md) — start with [Green path IaC](terraform-integration.md#green-path-iac) |
| Simulith Console (GUI) | [console.md](console.md) |
| Protocol & errors | protocol.md |
| Smithy contracts | smithy-contracts.md |
| All runtime docs | [README.md](README.md) |

Product roadmap: `cursor/company/mvp-work-plan.md`.

---

## Troubleshooting

| Issue | Fix |
| --- | --- |
| `go: command not found` | Install Go 1.24+, reopen terminal |
| Port in use | `--port 8787` or `SIMULITH_PORT=8787` |
| LocalStack also on 4566 | Change port on one tool |
| `simulith seed` / `reset` fails with DB locked | Stop the running server first |
| Docker smoke fails after host `go run seed` | Default Compose uses a **named volume** — seed with `docker compose run --rm --entrypoint simulith simulith seed`, or enable bind mount in [docker.md](docker.md) |
| AWS CLI errors | Install AWS CLI v2; set `--region us-east-1` and `--endpoint-url` on every command |
| SSM `ValidationException` … must begin with a forward slash` (Git Bash) | MSYS rewrites `/app/...` to `C:/Program Files/Git/app/...`. Before AWS CLI: `export MSYS2_ARG_CONV_EXCL="*"` or `export MSYS_NO_PATHCONV=1` (do not use `--name //app/...` — that sends a double-slash name and returns `ParameterNotFound`) |
| Docker health check fails | See [docker.md](docker.md) |

---

## Related

- Module overview: [../README.md](README.md)
- Full doc index: [README.md](README.md)
