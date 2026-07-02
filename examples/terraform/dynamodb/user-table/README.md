# User table — Simulith green path (same module as AWS)

DynamoDB table for Cognito-synced user records. **One module** for Simulith local and AWS prod — toggle with `use_simulith_endpoint`.

| File | Role |
| --- | --- |
| `versions.tf` | Terraform + provider constraints |
| `provider.tf` | AWS provider (Simulith endpoint optional) |
| `variables.tf` | `project_name`, `environment`, `use_simulith_endpoint`, … |
| `locals.tf` | `is_prod`, `table_name` |
| `main.tf` | `aws_dynamodb_table.user` — PK, 2 GSIs, SSE, PITR, tags |
| `outputs.tf` | Table name/ARN + GSI names |
| `user.json` | Sample users for `batch-write-item` seed |
| `terraform.tfvars.example` | Simulith local — **Docker all-in-one** (`:9080/runtime`) |
| `terraform.tfvars.native.example` | Simulith local — native or `:4566` published on host |
| `terraform.aws-dev.tfvars.example` | Template → copy to **`terraform.aws-dev.tfvars`** (gitignored) |
| `terraform.aws-prod.tfvars.example` | Template → copy to **`terraform.aws-prod.tfvars`** (gitignored) |
| `prod.tf.example` | Notes for AWS apply |

Default **`environment=dev`** disables PITR and deletion protection so `terraform destroy` works on Simulith.

Table name: **`${var.project_name}_user`** (e.g. `loyaleasy_user`, `simulith_dev_user`).

> **Important:** Terraform, the AWS CLI, and the Console must use the **same** Simulith instance. See [terraform-integration.md — Endpoint matrix](../../../../terraform-integration.md#endpoint-matrix).

## Prerequisites

- Terraform ≥ 1.6
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (optional — verify and seed)
- Simulith running (pick **one** path below)

---

## 1. Start Simulith

### Option A — Docker all-in-one (Console + runtime)

Console at http://localhost:9080. Terraform/CLI endpoint: **`http://127.0.0.1:9080/runtime`**.

From repo `runtime/`:

```bash
docker compose -f docker-compose.all-in-one.yml up --build
```

Use `terraform.tfvars.example` or copy to `terraform.tfvars` (default endpoint `:9080/runtime`).

Optional: publish host **`:4566`** (same container as Console):

```bash
docker compose -f docker-compose.all-in-one.yml -f docker-compose.all-in-one.runtime-port.yml up --build
```

Then you may use `terraform.tfvars.native.example` (`:4566`) instead.

### Option B — Native Go

From repo `runtime/`:

```bash
go run ./cmd/simulith start
```

Health: `curl http://127.0.0.1:4566/health`

Use `terraform.tfvars.native.example` or set `simulith_endpoint = "http://127.0.0.1:4566"`.

### Option C — Docker runtime only (no Console)

From repo `runtime/`:

```bash
docker compose up --build
```

Endpoint: **`http://127.0.0.1:4566`**. Use `terraform.tfvars.native.example`.

---

## 2. Apply Terraform

### Which variables file loads?

Terraform **auto-loads only**:

- `terraform.tfvars`
- `*.auto.tfvars`

It does **not** auto-load `terraform.aws-dev.tfvars` or other named `*.tfvars` files. You must pass **`-var-file=...`** or copy the example to `terraform.tfvars` / `*.auto.tfvars`.

> **Pitfall:** If `terraform.tfvars` exists with `use_simulith_endpoint = true`, a bare `terraform apply` on workspace `aws` still uses **Simulith** settings — not AWS. Always pass the correct `-var-file` for the target.

### Local Simulith (`default` workspace)

```bash
cd runtime/examples/terraform/dynamodb/user-table
terraform workspace select default
cp terraform.tfvars.example terraform.tfvars   # edit project_name if needed
terraform init
terraform apply
```

**Native / `:4566`** (without editing `terraform.tfvars`):

```bash
terraform workspace select default
terraform apply -var-file=terraform.tfvars.native.example
```

### Real AWS (`aws` workspace)

Copy the example once (gitignored as `*.tfvars`):

```bash
cp terraform.aws-dev.tfvars.example terraform.aws-dev.tfvars
```

Use a **separate workspace** so local Simulith state stays in `default`:

```bash
terraform workspace new aws    # once
terraform workspace select aws
terraform apply -var-file=terraform.aws-dev.tfvars
```

**Prod on AWS:**

```bash
terraform workspace select aws
terraform apply -var-file=terraform.aws-prod.tfvars.example
# or: cp terraform.aws-prod.tfvars.example terraform.aws-prod.tfvars
#     terraform apply -var-file=terraform.aws-prod.tfvars
```

| Target | Workspace | Command |
| --- | --- | --- |
| Simulith (all-in-one) | `default` | `terraform apply` *(with `terraform.tfvars` from `.example`)* |
| Simulith (`:4566`) | `default` | `terraform apply -var-file=terraform.tfvars.native.example` |
| AWS dev (`simulith_dev_user`) | `aws` | `terraform apply -var-file=terraform.aws-dev.tfvars` |
| AWS prod | `aws` | `terraform apply -var-file=terraform.aws-prod.tfvars` |

| File | Table | PITR / deletion protection |
| --- | --- | --- |
| `terraform.aws-dev.tfvars.example` | `simulith_dev_user` | Off (`environment=dev`) |
| `terraform.aws-prod.tfvars.example` | `{project_name}_user` | On (`environment=prod`) |

**Prerequisites (AWS):** credentials configured (`aws sts get-caller-identity`). No `--endpoint-url` on CLI — real DynamoDB in `aws_region`.

**Seed on AWS** (workspace `aws`, no Simulith endpoint):

```bash
terraform workspace select aws
export AWS_DEFAULT_REGION=us-east-1
export TABLE_NAME=$(terraform output -raw table_name)

aws dynamodb batch-write-item \
  --request-items file://user.json \
  --region "$AWS_DEFAULT_REGION"

aws dynamodb scan --table-name "$TABLE_NAME" --region "$AWS_DEFAULT_REGION"
```

**Destroy (dev on AWS):**

```bash
terraform workspace select aws
terraform destroy -var-file=terraform.aws-dev.tfvars
```

**Destroy (prod):** disable deletion protection first (set `environment=dev` and re-apply, or AWS Console).

**Back to local Simulith:**

```bash
terraform workspace select default
terraform apply   # uses terraform.tfvars (Simulith)
```

After apply, note the table name from outputs:

```bash
terraform output table_name
```

---

## 3. Seed sample users (`user.json`)

[`user.json`](user.json) holds four sample users for **`BatchWriteItem`**. The top-level JSON key must match **`terraform output table_name`** (default example uses `loyaleasy_user`; adjust if `project_name` differs).

Set the CLI endpoint to match your Simulith path (same as Terraform):

```bash
# Docker all-in-one
export AWS_ENDPOINT=http://127.0.0.1:9080/runtime

# Native Go / docker compose / all-in-one + runtime-port overlay
# export AWS_ENDPOINT=http://127.0.0.1:4566

export AWS_DEFAULT_REGION=us-east-1
export TABLE_NAME=$(terraform output -raw table_name)
```

**Git Bash (Windows):** if `file://` paths misbehave:

```bash
export MSYS2_ARG_CONV_EXCL="*"
```

Seed:

```bash
cd runtime/examples/terraform/dynamodb/user-table

aws dynamodb batch-write-item \
  --request-items file://user.json \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
```

> Ensure the key inside `user.json` matches `$TABLE_NAME`. Edit the file if you changed `project_name`.

Verify items (Console: http://localhost:9080/dynamodb → **Refresh tables** → select table):

```bash
aws dynamodb scan \
  --table-name "$TABLE_NAME" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
```

Query via GSI:

```bash
aws dynamodb query \
  --table-name "$TABLE_NAME" \
  --index-name programId-cognito_sub-index \
  --key-condition-expression "programId = :p" \
  --expression-attribute-values '{":p":{"S":"PCM"}}' \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
```

---

## 4. Verify table metadata

```bash
aws dynamodb describe-table \
  --table-name "$TABLE_NAME" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

aws dynamodb describe-continuous-backups \
  --table-name "$TABLE_NAME" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
```

---

## 5. Cleanup

**Local Simulith** (`default` workspace):

```bash
terraform workspace select default
terraform destroy
```

**AWS** (`aws` workspace):

```bash
terraform workspace select aws
terraform destroy -var-file=terraform.aws-dev.tfvars
```

If `environment=prod`, disable deletion protection before destroy (same as AWS).

Do **not** use `simulith reset` for Terraform-managed tables unless you also remove state — prefer `terraform destroy`.

---

Service index: [../README.md](../../../../README.md) · Guide: [terraform-integration.md](../../../../terraform-integration.md)
