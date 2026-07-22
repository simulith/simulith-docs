# Using Simulith — local development vs AWS

You started Simulith with Docker — **what next?** This guide is the **second step** after [quickstart](quickstart.md) and [docker](docker.md): how to work with DynamoDB, SQS, SSM, S3, Lambda, API Gateway, and Secrets Manager locally, and how that compares to real AWS.

> **Installation:** not covered here — see [quickstart](quickstart.md) or [Docker Hub overviews](https://hub.docker.com/r/simulith/simulith).

---

## Verify Simulith is running

Pick the health check that matches how you started Simulith:

| How you run | Health URL | Expected |
| --- | --- | --- |
| **Runtime + Console** (`docker run`) | `http://localhost:9080/runtime/health` | `{"status":"ok"}` |
| **Runtime only** (`docker run`) | `http://localhost:4566/health` | `{"status":"ok"}` |

```bash
# Runtime + Console (docker run)
curl http://localhost:9080/runtime/health

# Runtime-only image
curl http://127.0.0.1:4566/health
```

Open the **Console** at **http://localhost:9080** when using runtime + Console — the dashboard should show **Connected**. Details: [console.md](console.md).

---

## Mental model

Simulith is a **local HTTP server** that speaks the same AWS APIs your apps already use (AWS CLI, SDKs, Terraform `hashicorp/aws`). Your code does **not** change for local dev — you add an **endpoint URL** (and often dummy credentials).

```text
Your app / CLI / Terraform
        │
        │  AWS SDK or CLI (+ --endpoint-url locally)
        ▼
┌───────────────────┐     ┌─────────────────────────┐
│ Simulith (local)  │     │ AWS (cloud)             │
│ SQLite on disk    │     │ Managed services, IAM   │
│ Subset of APIs    │     │ Full service catalog    │
└───────────────────┘     └─────────────────────────┘
```

**Same:** command shapes, request/response JSON, Terraform resources for the [green path](terraform-integration.md#green-path-iac).

**Different:** where data lives, credentials, account IDs, billing, and which operations exist. See the comparison table below and [AWS parity overview](aws-parity-overview.md) for the operation inventory (do not expect every AWS API locally).

---

## Simulith vs AWS — developer comparison

| Topic | Real AWS | Simulith (local) |
| --- | --- | --- |
| **Endpoint** | Regional HTTPS (`*.amazonaws.com`) | `http://127.0.0.1:4566` or `http://127.0.0.1:9080/runtime` (Console proxy) — see [endpoint matrix](#endpoint-matrix) |
| **Region** | Any enabled region | Any region string works; examples use `us-east-1` |
| **Credentials** | IAM user/role, SSO, etc. | Any static pair when SigV4 is off (default): e.g. `test` / `secret` |
| **Account ID** | Your 12-digit account | Fixed **`000000000000`** in ARNs and queue URLs |
| **Data storage** | AWS-managed, multi-AZ | **SQLite** under `/app/.simulith` in Docker (mount a volume to persist) — [persistence.md](persistence.md) |
| **Billing / quotas** | AWS pricing and service limits | None — limited by disk and documented API subset |
| **Services (available)** | Full catalogs | **DynamoDB**, **SQS**, **SSM Parameter Store**, **S3**, **Lambda**, **API Gateway** (REST subset), **Secrets Manager** — [aws-parity-overview.md](aws-parity-overview.md) |
| **API coverage** | Complete per service | **Subset** — 54 verify scenarios across DynamoDB, SQS, SSM, S3, and Lambda — [compatibility-matrix.md](compatibility-matrix.md) |
| **Console** | AWS Management Console | **Simulith Console** (local web UI) — [console.md](console.md) · [Console vs AWS Console](console.md) |
| **Reset state** | Delete resources in AWS | `simulith reset`, Console **Reset**, or admin API — [admin-api.md](admin-api.md) |
| **Promote to AWS** | Deploy to cloud | Same Terraform/modules — switch workspace + `-var-file` — [terraform-integration.md](terraform-integration.md#workspaces-and--var-file-simulith-vs-real-aws) |

When something behaves differently from AWS, check the service guide (**[dynamodb.md](dynamodb.md)**, **[sqs.md](sqs.md)**, **[s3.md](s3.md)**, **[lambda.md](lambda.md)**, **[apigateway.md](apigateway.md)**, **[secretsmanager.md](secretsmanager.md)**) for documented deviations before assuming a bug.

---

## Endpoint matrix

CLI, SDK, Terraform, and the **Console** must target the **same** runtime. Mixed endpoints write to different SQLite files.

| How you run Simulith | AWS CLI / SDK / Terraform endpoint | Simulith Console |
| --- | --- | --- |
| **Runtime + Console** (`docker run`, Console proxy) | `http://127.0.0.1:9080/runtime` | http://localhost:9080 |
| **Runtime only** (`docker run`) | `http://127.0.0.1:4566` | N/A |
| **Runtime + Console** (also `-p 4566:4566` on runtime) | `http://127.0.0.1:4566` | http://localhost:9080 |

Shell helper (pick one):

```bash
# All-in-one — Console proxy path (runtime + Console via docker run)
export AWS_ENDPOINT=http://127.0.0.1:9080/runtime

# Runtime-only on host :4566
# export AWS_ENDPOINT=http://127.0.0.1:4566

export AWS_DEFAULT_REGION=us-east-1
```

Append to every AWS CLI command:

```bash
--endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Full Terraform matrix and pitfall notes: [terraform-integration.md — Endpoint matrix](terraform-integration.md#endpoint-matrix).

Quick sanity check — list DynamoDB tables on the URL you intend to use:

```bash
aws dynamodb list-tables --endpoint-url "$AWS_ENDPOINT" --region us-east-1
```

---

## Choose your workflow

After Docker is up, most teams use one or more of these paths:

### 1. Simulith Console (no terminal)

Best for **exploration**, demos, and users who prefer a GUI.

1. Open **http://localhost:9080**
2. **Seed demo data** on the dashboard (or load seed via CLI — [seed.md](seed.md))
3. Explore **DynamoDB**, **SQS**, **SSM**, **S3**, and **Lambda** panels (`demo-fn` after Seed)
4. **Lambda panel:** list, config, invoke with JSON — sync invoke needs `node`/`python3` on the runtime host PATH — [lambda.md](lambda.md)
5. Optional: **Verify** panel — import compatibility JSON from CI

Walkthrough: [console.md — Quick run](console.md#quick-run-docker). UI gaps vs AWS Console: [console.md](console.md).

### 2. AWS CLI

Best for **scripts** and quick checks. Same commands as AWS — add `--endpoint-url`.

```bash
# Describe seeded table (after seed)
aws dynamodb describe-table \
  --table-name Demo \
  --endpoint-url "$AWS_ENDPOINT" --region us-east-1

# SQS queue URL uses fixed account 000000000000
aws sqs receive-message \
  --queue-url http://127.0.0.1:4566/000000000000/demo-queue \
  --endpoint-url "$AWS_ENDPOINT" --region us-east-1
```

> **Queue URLs:** with Console proxy, use the **endpoint host** in the queue URL that matches `$AWS_ENDPOINT` (host `:9080` when using `/runtime`).

Cookbook: [aws-cli-examples.md](aws-cli-examples.md).

### 3. AWS SDK (Go, Node, Python)

Best for **application code**. Point the SDK client at the same endpoint as the CLI.

| Setting | Value |
| --- | --- |
| Endpoint | Same as `$AWS_ENDPOINT` above |
| Region | `us-east-1` (or your choice) |
| Credentials | Static dummy pair (default local mode) |

Examples: [sdk-examples.md](sdk-examples.md) · runnable code in [`examples/`](examples/).

### 4. Terraform (`hashicorp/aws`)

Best for **IaC** and **promoting** the same modules to AWS later.

1. Run Simulith (runtime + Console containers, or runtime-only on `:4566`)
2. Use provider `endpoints` + `skip_*` flags — see [terraform-integration.md](terraform-integration.md)
3. **Green path:** `terraform apply` / `destroy` on Simulith — [Green path IaC](terraform-integration.md#green-path-iac)
4. **AWS:** `terraform workspace select aws` + AWS `-var-file` — same `.tf` files

Examples: [`examples/terraform/`](examples/terraform/).

---

## Typical first session (runtime + Console)

```bash
docker network create simulith-net 2>/dev/null || true

docker run -d --name simulith --network simulith-net \
  -v simulith-data:/app/.simulith \
  simulith/simulith:latest

docker run -d --name simulith-console --network simulith-net \
  -p 9080:8080 \
  simulith/console:latest

# Verify (new terminal)
curl http://localhost:9080/runtime/health

# Open Console → Seed demo data → browse DynamoDB / SQS / SSM

export AWS_ENDPOINT=http://127.0.0.1:9080/runtime
export AWS_DEFAULT_REGION=us-east-1
aws dynamodb describe-table --table-name Demo \
  --endpoint-url "$AWS_ENDPOINT" --region us-east-1
```

---

## Local state vs AWS resources

| Action | Simulith | AWS |
| --- | --- | --- |
| **Persist data** | Docker volume on `/app/.simulith` — [docker.md](docker.md#persistence) | Resources in your account |
| **Clear everything** | Console **Reset**, `simulith reset`, or admin API | Delete stacks/resources |
| **Snapshot / restore** | `simulith snapshot` — [snapshot.md](snapshot.md) | Backup services (out of MVP scope) |
| **Seed fixtures** | `simulith seed` or Console button — [seed.md](seed.md) | Create resources manually or via IaC |

Stop the server before host-side `simulith seed` against a Docker volume — see [quickstart troubleshooting](quickstart.md#troubleshooting).

---

## Promote local work to AWS

Simulith is for **development and testing** — production stays on AWS.

1. Keep **the same** Terraform modules or application code
2. On Simulith: workspace `default` + Simulith `-var-file`
3. On AWS: workspace `aws` + credentials/endpoints for real AWS — [Workspaces and var-file](terraform-integration.md#workspaces-and--var-file-simulith-vs-real-aws)
4. Run `simulith verify` before relying on parity claims — [compatibility.md](compatibility.md)

Positioning: Simulith **complements** AWS for local development and testing — not a replacement for production workloads.

---

## What is not the same as AWS

Do **not** expect locally:

- IAM policy enforcement (unless strict SigV4 mode)
- Multi-region replication, streams, FIFO SQS, multipart S3, etc.
- Every DynamoDB/SQS/SSM/S3 operation AWS documents

**Where to look:**

| Question | Doc |
| --- | --- |
| Which API ops ship? | [compatibility-matrix.md](compatibility-matrix.md) |
| % coverage and gaps | [aws-parity-overview.md](aws-parity-overview.md) |
| Console UI gaps | [console.md](console.md) |
| DynamoDB limits / deviations | [dynamodb.md](dynamodb.md) |
| SQS limits / deviations | [sqs.md](sqs.md) |
| Lambda limits / deviations | [lambda.md](lambda.md) |

---

## Troubleshooting (usage)

| Issue | Fix |
| --- | --- |
| Console **Disconnected** | Check `/runtime/health`; restart `simulith` and `simulith-console` containers |
| CLI works but Console shows empty data | Wrong endpoint — CLI and Console must share one runtime ([endpoint matrix](#endpoint-matrix)) |
| `ResourceNotFoundException` on seeded names | Run seed (Console or `simulith seed`) |
| Queue URL / account errors | Use account **`000000000000`** in queue URLs |
| Git Bash rewrites `/app/...` SSM paths | `export MSYS2_ARG_CONV_EXCL="*"` — [quickstart](quickstart.md#troubleshooting) |
| Stale data after tests | Console **Reset** or `simulith reset` |

Docker-specific issues (ports, bind address): [docker.md — Troubleshooting](docker.md#troubleshooting).

---

## Next steps

| Topic | Guide |
| --- | --- |
| AWS CLI cookbook | [aws-cli-examples.md](aws-cli-examples.md) |
| SDK cookbook | [sdk-examples.md](sdk-examples.md) |
| Terraform + green path | [terraform-integration.md](terraform-integration.md) |
| Console panels | [console.md](console.md) |
| API parity summary | [aws-parity-overview.md](aws-parity-overview.md) |
| All runtime docs | [README.md](README.md) |

---

## Related

- Installation: [quickstart.md](quickstart.md) · [docker.md](docker.md) · [Docker Hub — runtime](https://hub.docker.com/r/simulith/simulith)
