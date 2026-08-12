# Simulith Runtime — Quickstart

Get from zero to a **working local AWS-compatible runtime** with a DynamoDB + SQS smoke test in **under five minutes**.

This guide is the **stable onboarding entry point** for evaluators and developers. **Docker** (published images) is the recommended path — no repository checkout required.

---

## What you get

Simulith runs a local HTTP server (default port **4566**) that AWS CLI and SDKs can target with `--endpoint-url`. Shipped services:

| Service | Status |
| --- | --- |
| DynamoDB | CreateTable, CRUD, Query, Scan — [dynamodb.md](dynamodb.md) |
| SQS | CreateQueue, Send/Receive/DeleteMessage — [sqs.md](sqs.md) |
| SSM | Put/GetParameter (SQLite persistence) — [ssm.md](ssm.md) |
| S3 | Bucket/object CRUD — [s3.md](s3.md) |
| Lambda | Function CRUD, sync invoke, SQS ESM — [lambda.md](lambda.md) |
| API Gateway | REST API CRUD + stage invoke — [apigateway.md](apigateway.md) |
| Secrets Manager | Secret CRUD + GetSecretValue — [secretsmanager.md](secretsmanager.md) |
| EventBridge | Schedule rules → Lambda — [eventbridge.md](eventbridge.md) |
| Cognito | User Pool + Admin* + JWKS — [cognito.md](cognito.md) |
| SES | Identity, templates, Send* (local outbox) — [ses.md](ses.md) |
| VPC | VPC/subnet/SG, Lambda VpcConfig; verify, Terraform green path, Console `/vpc` — [vpc.md](vpc.md) |
| RDS | Postgres sidecar + proxy; verify, Terraform green path, Console `/rds` (Docker on runtime host) — [rds.md](rds.md) |
| IAM | Roles/policies subset (RDS Proxy) — [iam.md](iam.md) |
| KMS | CMK encrypt/decrypt; Secrets Manager `KmsKeyId` — [kms.md](kms.md) |
| Route 53 | Hosted zones + A/CNAME records; verify, Terraform green path, Console `/route53` — [route53.md](route53.md) |
| ACM | DNS-validated certificates; verify, Terraform green path, Console `/acm` — [acm.md](acm.md) |

State persists in SQLite. Developer commands: seed, reset, snapshot — see [persistence.md](persistence.md).

---

## Prerequisites

| Path | You need |
| --- | --- |
| **Docker** (recommended) | Docker Desktop or Engine |
| **Native (from source)** | Go 1.24+ ([go.dev/dl](https://go.dev/dl/)) and a monorepo checkout — see [Appendix: native](#appendix-native-from-source) |

For the **smoke test** below:

- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (any credentials work against the local endpoint; region `us-east-1` is used in examples)

**Windows:** Examples use Bash-style lines. Git Bash or WSL works best; adapt paths for PowerShell if needed.

---

## Five-minute path (overview)

1. Pull and run Simulith (Docker)
2. Load demo data (Console **Seed** button or CLI)
3. Verify `/health`
4. Smoke-test DynamoDB, SQS, and SSM with AWS CLI

---

## 1. Run Simulith (Docker)

### Option A — Runtime + Console (recommended)

One entry URL at **http://localhost:9080**. The runtime container must be named **`simulith`** on the same Docker network.

```bash
docker network create simulith-net 2>/dev/null || true

docker run -d --name simulith --network simulith-net \
  -v simulith-data:/app/.simulith \
  simulith/simulith:latest

docker run -d --name simulith-console --network simulith-net \
  -p 9080:8080 \
  simulith/console:latest
```

Open **http://localhost:9080** — use **Seed demo data** on the Dashboard, then explore service panels.

Health via Console proxy:

```bash
curl http://localhost:9080/runtime/health
```

Expected: `{"status":"ok"}`. Optional direct runtime port: add `-p 4566:4566` to the `simulith` container.

**Stop:** `docker rm -f simulith-console simulith && docker network rm simulith-net`

More layouts (Compose, volumes, troubleshooting): [docker.md](docker.md) · [console.md](console.md).

### Option B — Runtime only (CLI / SDK)

```bash
docker run --rm -p 4566:4566 \
  -v simulith-data:/app/.simulith \
  simulith/simulith:latest
```

In another terminal:

```bash
curl http://127.0.0.1:4566/health
```

Expected: `{"status":"ok"}`.

---

## 2. Demo data

The built-in seed profile creates a DynamoDB table `Demo`, SQS queue `demo-queue`, SSM parameters under `/app/demo/*`, S3 bucket `demo-bucket`, Lambda function `demo-fn` (with SQS ESM to `demo-queue`), API Gateway REST API `demo-api`, Secrets Manager secret `demo-secret`, EventBridge rule `demo-rule` (`rate(5 minutes)` → `demo-fn`), Cognito User Pool `demo-pool` (client `demo-client`, group `admin`), SES identity `demo@simulith.local` with template `demo-template`, VPC **`demo-vpc`** with database subnet and **`demo-postgres-sg`**, and RDS Postgres instance `demo-db` (Docker required on runtime host). Details: [seed.md](seed.md).

**Console (Option A):** Dashboard → **Seed demo data** (runtime must be healthy).

**CLI (runtime container):** stop conflicting writers first (SQLite lock), then:

```bash
docker exec simulith simulith seed
```

For native installs from source, see [Appendix: native](#appendix-native-from-source).

---

## 3. Smoke test (AWS CLI)

With the server running, use the endpoint that matches your layout:

| Layout | `--endpoint-url` |
| --- | --- |
| Runtime + Console | `http://127.0.0.1:9080/runtime` |
| Runtime only | `http://127.0.0.1:4566` |

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

Expected: table metadata for `Demo`; message body `hello from seed`; SSM parameter `/app/demo/api-url` value `http://localhost:8080`; Lambda `demo-fn`, EventBridge `demo-rule`, Cognito `demo-pool`, SES `demo-template`, VPC `demo-vpc`, and RDS `demo-db` listed after seed.

```bash
aws ssm get-parameter --name /app/demo/api-url \
  --endpoint-url http://127.0.0.1:4566 --region us-east-1

aws lambda list-functions --endpoint-url http://127.0.0.1:4566 --region us-east-1
```

For more CLI operations, see **[AWS CLI examples](aws-cli-examples.md)**. This quickstart only proves the endpoint works.

---

## CLI commands at a glance

| Command | Purpose | Doc |
| --- | --- | --- |
| `simulith start` | Run HTTP runtime | this guide |
| `simulith seed` | Load demo fixture | [seed.md](seed.md) |
| `simulith reset` | Clear DynamoDB + SQS + SSM + S3 + Lambda state | [persistence.md](persistence.md) |
| `simulith snapshot save\|restore` | Export/import full state (DDB/SQS/SSM only in v1) | [snapshot.md](snapshot.md) |
| `simulith verify <service>` | AWS parity smoke — `dynamodb`, `sqs`, `ssm`, `s3`, `lambda`, `apigateway`, `secretsmanager`, `cognito`, `ses`, `eventbridge`, `rds`, `vpc` (add `--skip-aws` for CI-style) | [compatibility.md](compatibility.md) |
| `simulith report` | HTML report from verify JSON | [compatibility.md](compatibility.md) |

---

## Configuration (optional)

When running from source, copy the example config:

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

---

## Troubleshooting

| Issue | Fix |
| --- | --- |
| Port in use | Map another host port, e.g. `-p 8787:4566` |
| LocalStack also on 4566 | Change port on one tool |
| `simulith seed` / `reset` fails with DB locked | Stop the running server first |
| Console shows **Unavailable** | Ensure runtime is healthy; container must be named `simulith` on the same network |
| AWS CLI errors | Install AWS CLI v2; set `--region us-east-1` and `--endpoint-url` on every command |
| SSM `ValidationException` … must begin with a forward slash` (Git Bash) | MSYS rewrites `/app/...` to `C:/Program Files/Git/app/...`. Before AWS CLI: `export MSYS2_ARG_CONV_EXCL="*"` or `export MSYS_NO_PATHCONV=1` |
| Docker health check fails | See [docker.md](docker.md) |
| `go: command not found` (native path only) | Install Go 1.24+, reopen terminal |

---

## Appendix: native from source

For **Simulith contributors** building from the monorepo (`runtime/` module):

```bash
cd runtime
go run ./cmd/simulith seed    # server must be stopped
go run ./cmd/simulith start
```

Workshop Compose (build from repo): `docker compose -f docker-compose.all-in-one.yml up --build` — see [console.md](console.md).

---

## Related

- Full doc index: [README.md](README.md)
- Product site: [simulith.dev](https://simulith.dev)
