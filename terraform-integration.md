# Terraform integration — Simulith runtime

Use the **`hashicorp/aws` provider** to provision **DynamoDB**, **SQS**, **SSM Parameter Store**, **S3**, and **Lambda** resources against Simulith locally.

> **New to Simulith?** Complete the [Quickstart](quickstart.md) first (run server on port **4566**).

This guide is the **canonical IaC reference**. Examples live under [`examples/terraform/`](examples/terraform/), organized by service:

| Service | Path | Apply on Simulith |
| --- | --- | --- |
| DynamoDB (demo) | [`dynamodb/music/`](examples/terraform/dynamodb/music/) | Yes |
| DynamoDB (user table) | [`dynamodb/user-table/`](examples/terraform/dynamodb/user-table/) | Yes (PK only) |
| SQS | [`sqs/`](examples/terraform/sqs/) | Yes |
| SSM Parameter Store | [`ssm/`](examples/terraform/ssm/) | Yes |
| S3 | [`s3/`](examples/terraform/s3/) | Yes — bucket + 2 objects |
| Lambda | [`lambda/`](examples/terraform/lambda/) | Yes — function + SQS ESM; env vars + config update on re-apply |
| API Gateway | [`apigateway/`](examples/terraform/apigateway/) | Yes — REST API + Lambda proxy + stage |
| Secrets Manager | [`secretsmanager/`](examples/terraform/secretsmanager/) | Yes — secret + version |

For imperative examples see [AWS CLI examples](aws-cli-examples.md) and [SDK examples](sdk-examples.md). **Honest integration examples** (AWS-derived Terraform + CLI): [below](#honest-integration-examples).

Parity gaps and post-MVP backlog:  (DynamoDB, SQS, SSM).

**Consolidated parity table (% by service, Terraform, Console):** [aws-parity-overview.md](aws-parity-overview.md).

---

## Prerequisites

- Simulith running ([quickstart](quickstart.md) — native `:4566`, Docker, or **all-in-one Console** on `:9080`)
- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.6
- Optional: [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to verify resources after apply

Simulith accepts dummy credentials when SigV4 validation is off (default).

---

## Endpoint matrix

Terraform, the AWS CLI, and the **Simulith Console** must target the **same** runtime. Mixed endpoints create tables in one SQLite DB while the Console lists another.

| How you run Simulith | Terraform / CLI endpoint | Console |
| --- | --- | --- |
| **Docker all-in-one** (`docker-compose.all-in-one.yml`) | `http://127.0.0.1:9080/runtime` | http://localhost:9080/dynamodb |
| Native (`go run ./cmd/simulith start`) | `http://127.0.0.1:4566` | N/A (or dev overlay on `:9080` + `:4566`) |
| Docker + published `:4566` (`docker-compose.yml` or `all-in-one.runtime-port.yml`) | `http://127.0.0.1:4566` | `:9080` Console proxies same container if all-in-one |

**User-table defaults:** [`terraform.tfvars.example`](examples/terraform/dynamodb/user-table/terraform.tfvars.example) uses `:9080/runtime` (all-in-one). For native / host `:4566`, use [`terraform.tfvars.native.example`](examples/terraform/dynamodb/user-table/terraform.tfvars.native.example).

Quick check — list tables on both URLs; only one should show your Terraform table if endpoints were mismatched:

```bash
aws dynamodb list-tables --endpoint-url http://127.0.0.1:4566 --region us-east-1
aws dynamodb list-tables --endpoint-url http://127.0.0.1:9080/runtime --region us-east-1
```

See [console.md](console.md) for the all-in-one Compose command.

### Workspaces and `-var-file` (Simulith vs real AWS)

Modules [`user-table`](examples/terraform/dynamodb/user-table/), [`sqs`](examples/terraform/sqs/), and [`ssm/parameters`](examples/terraform/ssm/parameters/) use the **same** `.tf` for Simulith and AWS. Separate **targets** with:

1. **Terraform workspace** — isolates state (`default` = local, `aws` = real AWS).
2. **`-var-file`** — picks Simulith vs AWS credentials/endpoints.

Create the AWS workspace once with **`terraform workspace new aws`** (there is no `workspace create` subcommand), or use **`terraform workspace select -or-create aws`**.

Terraform **auto-loads only** `terraform.tfvars` and `*.auto.tfvars`. Named files require **`-var-file=...`**.

| Target | Workspace | Var file (examples) |
| --- | --- | --- |
| Simulith (Docker all-in-one) | `default` | `terraform.tfvars` or `dev.tfvars` |
| Simulith (`:4566`) | `default` | `*.native.example` → local tfvars |
| AWS dev | `aws` | `terraform.aws-dev.tfvars` (DDB, SQS) · `dev.aws.tfvars` (SSM parameters) |
| AWS prod (SSM Loyaleasy) | `aws` | `prod.tfvars` (SSM parameters) |

> **Pitfall:** `terraform workspace select aws` + bare `terraform apply` still loads **`terraform.tfvars`** if present — usually Simulith settings. Always pass the AWS `-var-file`.

Module READMEs: [`user-table`](examples/terraform/dynamodb/user-table/README.md) · [`sqs`](examples/terraform/sqs/README.md) · [`ssm/parameters`](examples/terraform/ssm/parameters/README.md).

---

## Provider configuration

Point the AWS provider at Simulith with **custom endpoints** and **skip** flags so Terraform does not call real AWS metadata services.

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb = "http://127.0.0.1:4566"
    sqs      = "http://127.0.0.1:4566"
    ssm      = "http://127.0.0.1:4566"
    s3       = "http://127.0.0.1:4566"
    lambda   = "http://127.0.0.1:4566"
  }
}
```

| Setting | Value |
| --- | --- |
| Endpoint (native / `:4566` published) | `http://127.0.0.1:4566` |
| Endpoint (Docker all-in-one) | `http://127.0.0.1:9080/runtime` |
| Region | `us-east-1` |
| Credentials | `test` / `secret` |

See [Endpoint matrix](#endpoint-matrix) above. Docker **all-in-one** does not publish `:4566` on the host by default — use the Console proxy URL for Terraform so resources appear in the Console DynamoDB panel.

There is **no Simulith-specific Terraform provider** — use `hashicorp/aws` with endpoints, the same pattern LocalStack and similar tools use.

---

## DynamoDB — `aws_dynamodb_table`

MVP: hash key only, on-demand billing. Mirrors the Music table from [AWS CLI examples](aws-cli-examples.md#dynamodb).

```hcl
resource "aws_dynamodb_table" "music" {
  name         = "Music-tf"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Artist"

  attribute {
    name = "Artist"
    type = "S"
  }
}
```

**GSI / LSI:** supported when defined at **CreateTable** — Query with `IndexName` (MVP subset). **User table green path:** [`dynamodb/user-table/`](examples/terraform/dynamodb/user-table/) — GSIs, tags, SSE, PITR metadata, deletion protection (`environment=prod`). **Avoid for MVP:** streams, TTL, real PITR restore.

See [dynamodb.md](dynamodb.md) for expression limits and AWS deviations.

---

## SQS — `aws_sqs_queue`

Standard queue only (no FIFO):

```hcl
resource "aws_sqs_queue" "app" {
  name = "app-queue-tf"
}
```

Queue URLs follow: `http://{host}/000000000000/{queueName}` (e.g. `http://127.0.0.1:9080/runtime/...` via all-in-one proxy, or `:4566` native).

Runnable module: [`examples/terraform/sqs/`](examples/terraform/sqs/) — `use_simulith_endpoint`, workspaces (`default` / `aws`), `terraform.aws-dev.tfvars` for real AWS.

**GetQueueAttributes** is implemented, so `terraform apply` succeeds. **`terraform destroy`**: **DeleteQueue** tombstones the queue (~60s grace); the provider polls until **GetQueueAttributes** returns **`QueueDoesNotExist`**. On Simulith expect **~60–90 seconds** (provider timeout default: 3m). JSON responses map tombstone expiry to shape **`QueueDoesNotExist`** for the HashiCorp waiter.

Use `-parallelism=1` if applying DynamoDB and SQS in one run (SQLite).

See [sqs.md](sqs.md) for protocol notes and error codes.

---

## SSM — `aws_ssm_parameter`

String parameters under a path prefix (twelve-factor style `/app/<env>/...`):

```hcl
resource "aws_ssm_parameter" "log_level" {
  name  = "/app/tf-demo/log-level"
  type  = "String"
  value = "debug"
}
```

Read existing parameters by path prefix (after [`simulith seed`](seed.md)):

```hcl
data "aws_ssm_parameters_by_path" "demo" {
  path      = "/app/demo"
  recursive = true
}
```

Runnable modules: [`examples/terraform/ssm/`](examples/terraform/ssm/) (minimal `/app/tf-demo/*`) · [`examples/terraform/ssm/parameters/`](examples/terraform/ssm/parameters/) (27× `/SIMULITH/DEV/*` locally). **DeleteParameter** is implemented — `terraform destroy` removes managed parameters. Use **`-parallelism=1`** on apply and destroy (SQLite). Console SSM browse paginates `GetParametersByPath` (10 per page).

See [ssm.md](ssm.md) and [aws-cli-examples.md — SSM](aws-cli-examples.md#ssm-parameter-store) for CLI equivalents and Git Bash path notes (`MSYS2_ARG_CONV_EXCL="*"`).

---

## S3 — `aws_s3_bucket` + `aws_s3_object`

Bucket creation, object upload, and clean destroy:

```hcl
resource "aws_s3_bucket" "app" {
  bucket        = "app-assets-tf"
  force_destroy = true  # delete objects before bucket on terraform destroy
}

resource "aws_s3_object" "config" {
  bucket       = aws_s3_bucket.app.id
  key          = "config/app.json"
  content      = jsonencode({ environment = "local" })
  content_type = "application/json"
}
```

> **Required:** `s3_use_path_style = true` in the provider when pointing at Simulith. The provider's post-create read cycle calls `HeadBucket`, `GetBucketLocation`, `GetBucketVersioning`, and several other configuration reads — all handled by Simulith with sensible empty stubs.

Runnable module: [`examples/terraform/s3/`](examples/terraform/s3/) — 1 bucket + 2 objects, workspace isolation (`default` / `aws`).

```bash
cd runtime/examples/terraform/s3
cp terraform.tfvars.example terraform.tfvars   # once; set simulith_endpoint
terraform init && terraform apply
terraform destroy
```

See [s3.md](s3.md) for API coverage and [examples/terraform/s3/README.md](examples/terraform/s3/README.md) for full walkthrough.

---

## Green path IaC

**Green path** = `terraform init` → `apply` → optional CLI verify → **`terraform destroy`** completes without `simulith reset` + `terraform state rm` workarounds. Simulith implements the delete APIs Terraform expects locally.

### Module matrix

| Module | Apply | Destroy | Simulith APIs used |
| --- | --- | --- | --- |
| [`dynamodb/music/`](examples/terraform/dynamodb/music/) | Green | Green | CreateTable, DescribeTable, DeleteTable |
| [`dynamodb/user-table/`](examples/terraform/dynamodb/user-table/) | Green | Green | CreateTable + GSIs, UpdateTable (SSE/deletion protection), UpdateContinuousBackups (PITR metadata), tags |
| [`sqs/`](examples/terraform/sqs/) | Green | Green | CreateQueue, GetQueueAttributes, DeleteQueue — destroy ~60–90s on Simulith |
| [`ssm/`](examples/terraform/ssm/) | Green | Green | PutParameter, GetParameter, DescribeParameters, DeleteParameter — `-parallelism=1` |
| [`ssm/parameters/`](examples/terraform/ssm/parameters/) | Green | Green | 27 params; `dev.tfvars` / `dev.aws.tfvars`; `-parallelism=1` |
| [`s3/`](examples/terraform/s3/) | Green | Green | CreateBucket, HeadBucket, GetBucketLocation, GetBucketVersioning, PutObject, HeadObject, DeleteObject, DeleteBucket — `s3_use_path_style = true` |
| [`lambda/`](examples/terraform/lambda/) | Green | Green | CreateFunction, GetFunction, DeleteFunction, CreateQueue, GetQueueAttributes, DeleteQueue, Create/List/Get/DeleteEventSourceMapping |
| [`apigateway/`](examples/terraform/apigateway/) | Green | Green | RestApi CRUD reads/deletes, resource/method/integration, deployment/stage, Lambda AddPermission/RemovePermission/GetPolicy — `-parallelism=1` |
| [`secretsmanager/`](examples/terraform/secretsmanager/) | Green | Green | CreateSecret, DescribeSecret, PutSecretValue, GetSecretValue, DeleteSecret — `-parallelism=1` |

Index: [`examples/terraform/README.md`](examples/terraform/README.md).

### Walkthrough (any module)

1. Start Simulith — [quickstart](quickstart.md) or [console.md](console.md) (all-in-one: `http://127.0.0.1:9080/runtime` for Terraform).
2. `cd` into a module directory (e.g. `runtime/examples/terraform/dynamodb/music`).
3. `terraform init && terraform apply` — type `yes`.
4. Optional: verify with AWS CLI (see [Verify resources](#verify-resources) below).
5. **`terraform destroy`** — type `yes`. Resource removed from Simulith; Terraform state empty. For the SSM module, use **`terraform destroy -parallelism=1`** (same as apply).

Use **`-parallelism=1`** for the SSM example (apply and destroy), the **API Gateway** example (SQLite contention), and when applying multiple services in one run.

---

## Honest integration examples

**:** examples derived from AWS documentation, trimmed to Simulith's **documented subset**. Each README cites the AWS source and lists limits.

| Pattern | Terraform | AWS CLI | Notes |
| --- | --- | --- | --- |
| Lambda create + config patch + invoke | [`lambda/`](examples/terraform/lambda/) | [`aws-cli/lambda/`](examples/aws-cli/lambda/) | Re-apply after changing `environment_variables` → `UpdateFunctionConfiguration` |
| Lambda Go (`provided.al2023`) | — | [`aws-cli/lambda-go/`](examples/aws-cli/lambda-go/) | Build `bootstrap` with `go`; invoke without Node |
| API Gateway → Lambda HTTP | [`apigateway/`](examples/terraform/apigateway/) | — | `curl $(terraform output -raw invoke_url)` after apply |
| Secrets Manager → Lambda env | [`secretsmanager-lambda/`](examples/terraform/secretsmanager-lambda/) | [`aws-cli/secretsmanager/`](examples/aws-cli/secretsmanager/) | `aws_secretsmanager_secret_version` data source → `environment.variables`; re-apply after secret rotation |
| DynamoDB + SQS fan-out | [`dynamodb-sqs/`](examples/terraform/dynamodb-sqs/) | [`aws-cli/dynamodb-sqs/`](examples/aws-cli/dynamodb-sqs/) | PutItem + SendMessage dual-write; no DynamoDB Streams |
| S3 object lifecycle | [`s3/`](examples/terraform/s3/) | [`aws-cli/s3/`](examples/aws-cli/s3/) | put/head/get/list/copy/delete-objects via `s3api` |
| SSM parameters path | [`ssm/parameters/`](examples/terraform/ssm/parameters/) | [`aws-cli/ssm/`](examples/aws-cli/ssm/) | `aws_ssm_parameters_by_path` refresh + GetParametersByPath CLI |

**Smoke (local CI / validation):**

```bash
# Simulith must be on :4566, or use --managed
maintainer workflow (private monorepo) --managed
maintainer workflow (private monorepo) --module lambda
maintainer workflow (private monorepo) --module secretsmanager-lambda
maintainer workflow (private monorepo) --module dynamodb-sqs
maintainer workflow (private monorepo) --module s3
maintainer workflow (private monorepo) --module ssm-path
```

Backlog: .

### When to use `simulith reset`

Use [`simulith reset`](persistence.md) for **non-Terraform** experiments (CLI smoke, manual tables, seed fixtures) or orphaned resources **outside** Terraform state. It is **not** required to tear down the shipped example modules after a normal apply.

If destroy fails: check Simulith is running, endpoint matches the provider, and no other process holds the SQLite DB lock. **SQS:** wait up to ~90s on Simulith; if timeout at 3m, rebuild runtime (JSON `QueueDoesNotExist` for destroy waiter) or `terraform state rm aws_sqs_queue.<name>`. **SSM parameters:** use `-parallelism=1`; Console path `/SIMULITH/DEV` for Terraform-managed params.

### Import existing resources (MVP)

**DynamoDB tables** — supported for tables that already exist locally (e.g. after `simulith seed` or a manual CreateTable):

```bash
cd runtime/examples/terraform/dynamodb/music
terraform init

# Table must exist locally; import ID is the table name
terraform import aws_dynamodb_table.music Music-tf

terraform plan    # expect no drift for matching schema
terraform destroy # removes table when done
```

**ListTables** supports discovery; import binds Terraform state to an existing table name.

**SQS queues** — `terraform import aws_sqs_queue.<name> <queue-url>` may work when the queue exists; not validated as part of the MVP green-path examples — prefer apply with a new queue name.

**SSM parameters** — supported when the parameter already exists locally (CLI, seed, or manual PutParameter). Import ID is the **parameter name** (leading `/`):

```bash
cd runtime/examples/terraform/ssm
terraform init

# Parameter must exist locally, e.g. after CLI PutParameter or simulith seed
terraform import aws_ssm_parameter.log_level /app/tf-demo/log-level

terraform plan -parallelism=1   # expect no drift when value/type match main.tf
terraform destroy -parallelism=1
```

**DescribeParameters** (Name Equals/BeginsWith) and **GetParameter** return **`Tier: Standard`** and **`DataType: text`** for String parameters — required for `hashicorp/aws` ~> 5.x provider refresh.

Prod-only attributes (FIFO SQS, batch SSM edge cases) — see future-work. The **user-table** module is green on Simulith with full prod shape — full command walkthrough (Go, Docker, Terraform, **`batch-write-item` seed**): [`dynamodb/user-table/`](examples/terraform/dynamodb/user-table/README.md).

---

## Apply and destroy

Minimal DynamoDB demo: [`examples/terraform/dynamodb/music/`](examples/terraform/dynamodb/music/).

```bash
cd runtime/examples/terraform/dynamodb/music
terraform init
terraform apply
```

Review the plan, type `yes`. Outputs include `table_name`.

### Teardown

Prefer **`terraform destroy`** — see [Green path IaC](#green-path-iac). `terraform destroy` removes the table via Simulith **DeleteTable** (immediate, same intent as AWS). If destroy hangs, check that Simulith is running and the endpoint matches the provider.

```bash
terraform destroy
```

For a clean slate **outside** Terraform-managed resources, use [`simulith reset`](persistence.md) — not required for example module teardown.

---

## Verify resources

After apply, confirm with AWS CLI (same endpoint as the provider — see [Endpoint matrix](#endpoint-matrix)):

```bash
# Native / :4566
export AWS_ENDPOINT=http://127.0.0.1:4566
# Docker all-in-one
# export AWS_ENDPOINT=http://127.0.0.1:9080/runtime
export AWS_DEFAULT_REGION=us-east-1

aws dynamodb describe-table --table-name Music-tf \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

For SQS queues created via [CLI](aws-cli-examples.md#sqs) or [SDK](sdk-examples.md), use `get-queue-url` similarly.

For SSM parameters created via Terraform or [CLI](aws-cli-examples.md#ssm-parameter-store):

```bash
aws ssm get-parameters-by-path --path /app/tf-demo --recursive \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Or use the [SDK examples](sdk-examples.md) with the same endpoint.

---

## MVP limitations (summary)

| Area | Simulith MVP |
| --- | --- |
| DynamoDB ListTables | **Available** — discovery; supports import workflow |
| DynamoDB DeleteTable | **Available** — **`terraform destroy`** green on example modules |
| DynamoDB `terraform import` | **Documented** for table name → `aws_dynamodb_table` (MVP) |
| DynamoDB GSI / LSI | **Query with IndexName** when indexes defined at CreateTable or added via **UpdateTable** (MVP subset) |
| DynamoDB UpdateTable | **Available** — billing, SSE, deletion protection, stream metadata, GSI add/update/delete |
| DynamoDB streams / PITR restore / TTL | Not supported (PITR **metadata** APIs shipped for Terraform) |
| SQS FIFO queues | Not supported |
| SQS GetQueueAttributes | **Available** — `aws_sqs_queue` apply supported |
| SQS DeleteQueue / terraform destroy | **Available** — deleting tombstone window for provider poll |
| Resource tags | **Available** — DynamoDB table tags via TagResource / ListTagsOfResource |
| Parallel apply | Use `-parallelism=1` if applying DDB + SQS in one module (SQLite contention) |
| SSM Parameter Store | Put/Get/Delete + GetParameters/GetParametersByPath; examples [`ssm/`](examples/terraform/ssm/); see [ssm.md](ssm.md) |
| SSM DescribeParameters | **MVP** (Name Equals/BeginsWith) — Terraform `aws_ssm_parameter` refresh |
| SSM DeleteParameters (batch) | **Available** — up to 10 names; partial `InvalidParameters` |
| SSM terraform import | **Documented** — parameter name → `aws_ssm_parameter` (MVP) |
| S3 `aws_s3_bucket` | **Available** — `CreateBucket`, `HeadBucket`, `GetBucketLocation/Versioning/ACL/Accelerate`, stub config reads; `s3_use_path_style = true` required |
| S3 `aws_s3_object` | **Available** — `PutObject`, `HeadObject`, `DeleteObject`; single-part only |
| S3 `force_destroy` | **Available** — clears objects before `DeleteBucket` on destroy |
| S3 multipart / versioning / ACL writes | Not supported |
| Lambda `aws_lambda_function` + SQS ESM | **Available** — green path [`lambda/`](examples/terraform/lambda/) |
| IAM / VPC | Out of scope |

Full deviation tables:

- [dynamodb.md — Local behavior deviations](dynamodb.md#local-behavior-deviations)
- [sqs.md — Deviations (MVP)](sqs.md#deviations-mvp)
- [ssm.md — Deviations (MVP)](ssm.md#deviations-mvp)

---

## Alternatives to Terraform

| Approach | When to use |
| --- | --- |
| [`simulith seed`](seed.md) | Curated Demo table + demo-queue + demo-bucket + demo-fn fixture |
| [AWS CLI examples](aws-cli-examples.md) | One-off commands |
| [SDK examples](sdk-examples.md) | Application code integration |

---

## Related

- [quickstart.md](quickstart.md) — onboarding
- [docker.md](docker.md) — container workflow
- [persistence.md](persistence.md) — SQLite state and reset
- [compatibility.md](compatibility.md) — parity vs real AWS

Production AWS Terraform in this repo lives under `infrastructure/` and targets **real AWS**, not Simulith.

## Examples by service

| Example | Simulith apply | Prod-only (see future work) |
| --- | --- | --- |
| [`dynamodb/music/`](examples/terraform/dynamodb/music/) | Hash key demo table | — |
| [`dynamodb/user-table/`](examples/terraform/dynamodb/user-table/) | Hash key + 2 GSIs, PAY_PER_REQUEST, tags, SSE, PITR metadata | Same module on AWS with `environment=prod` |
| [`sqs/`](examples/terraform/sqs/) | Standard queue apply | FIFO, redrive, tags |
| [`s3/`](examples/terraform/s3/) | Bucket + 2 objects apply | Multipart, versioning, ACL writes |
