# Terraform — Secrets Manager on Simulith and AWS

`aws_secretsmanager_secret` + `aws_secretsmanager_secret_version` **apply** and **destroy** work on Simulith and real AWS.

## Prerequisites

- Simulith running for local apply ([quickstart](../../../quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x

## Workspaces and var-files

| Target | Workspace | Var file | Default name |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `terraform.tfvars` | `app-config-tf` |
| **Real AWS dev** | `aws` | `terraform.aws-dev.tfvars` | (create from example when needed) |

The workspace name does **not** switch the endpoint — `use_simulith_endpoint` in the var file does.

### Simulith endpoint

| How you run Simulith | `simulith_endpoint` |
| --- | --- |
| Docker all-in-one (Console `:9080`) | `http://127.0.0.1:9080/runtime` — default in `terraform.tfvars.example` |
| Native / host `:4566` | `http://127.0.0.1:4566` — `terraform.tfvars.native.example` |

Provider `endpoints` block routes **Secrets Manager** to Simulith. See [endpoint matrix](../../../terraform-integration.md#endpoint-matrix).

## Apply (Simulith)

```bash
cd runtime/examples/terraform/secretsmanager
cp terraform.tfvars.native.example terraform.tfvars   # or .example for Docker proxy
terraform init
terraform workspace select default
terraform apply -parallelism=1
```

Use **`-parallelism=1`** on apply and destroy (SQLite single-writer; same guidance as SSM/API Gateway).

Expected plan: **2 to add** (secret + secret version).

Verify the value:

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566

aws secretsmanager get-secret-value \
  --endpoint-url "$AWS_ENDPOINT" \
  --secret-id "$(terraform output -raw secret_name)"
```

Expected JSON includes `"managed_by":"terraform"`.

## Destroy (Simulith)

```bash
terraform destroy -parallelism=1
```

Expected plan: **2 to destroy**. `recovery_window_in_days = 0` maps to immediate local delete.

## Provider notes

- **`skip_requesting_account_id = true`** — Simulith uses fixed account `000000000000`.
- **Plain `SecretString` only** — no KMS keys, rotation, or resource policies on Simulith.

## Related

- **Secret → Lambda env:** [`../secretsmanager-lambda/`](../secretsmanager-lambda/) (Terraform data source pattern)
- AWS CLI scripts: [`../../aws-cli/secretsmanager/`](../../aws-cli/secretsmanager/)
- [secretsmanager.md](../../../secretsmanager.md)
- [terraform-integration.md — Green path IaC](../../../terraform-integration.md#green-path-iac)
