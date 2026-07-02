# Terraform — SSM Parameter Store on Simulith

**Modules in this folder:**

| Path | Purpose |
| --- | --- |
| [`main.tf`](./main.tf) (this directory) | Minimal green path — `/app/tf-demo/*` |
| [`parameters/`](./parameters/) | Platform parameters — `/SIMULITH/DEV/*` locally (Cloud Posse–equivalent shape) |

---

`aws_ssm_parameter` **terraform apply** and **destroy** work against Simulith when the runtime is listening on `http://127.0.0.1:4566` (provider uses PutParameter, GetParameter, DescribeParameters, DeleteParameter).

Optional **`aws_ssm_parameters_by_path`** data source (see [`path-data.tf.example`](./path-data.tf.example)) uses GetParametersByPath — run [`simulith seed`](../../../seed.md) first so `/app/demo/*` exists.

**Green path:** apply → optional verify → destroy without `simulith reset` workarounds. Validated with `hashicorp/aws` ~> 5.x (SML-057).

## Prerequisites

- `simulith start` (or Docker runtime on port 4566)
- Terraform >= 1.0
- AWS provider ~> 5.x
- Optional: AWS CLI v2 to verify after apply

## Apply

```bash
cd runtime/examples/terraform/ssm
terraform init
terraform apply -parallelism=1
```

Creates:

- `/app/tf-demo/service-name` = `demo-service`
- `/app/tf-demo/log-level` = `debug`
- `/app/tf-demo/api-token` = `demo-secret-token` (`SecureString` — mock local encryption; no AWS KMS)

Use **`-parallelism=1`** — SQLite can reject parallel PutParameter calls.

## Verify (CLI)

```bash
export AWS_ENDPOINT=http://127.0.0.1:4566
export AWS_DEFAULT_REGION=us-east-1

aws ssm get-parameter --name /app/tf-demo/log-level \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

# After simulith seed — list demo + tf-demo under /app
aws ssm get-parameters-by-path --path /app --recursive \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

**Git Bash on Windows:** export `MSYS2_ARG_CONV_EXCL="*"` before CLI commands with `/app/...` paths. See [aws-cli-examples.md](../../../aws-cli-examples.md#ssm-parameter-store).

## Destroy

```bash
terraform destroy -parallelism=1
```

Simulith implements **DeleteParameter** — destroy removes Terraform-managed parameters. Use **`-parallelism=1`** on destroy as well (parallel deletes can fail with SQLite contention).

Seed parameters (`/app/demo/*`) are unchanged unless you imported them into state.

See [Green path IaC](../../../terraform-integration.md#green-path-iac) for the full apply/destroy walkthrough.

## Import existing parameters

When a parameter already exists locally (CLI, seed, or manual create), bind Terraform state with the **parameter name** as the import ID:

```bash
cd runtime/examples/terraform/ssm
terraform init

terraform import aws_ssm_parameter.log_level /app/tf-demo/log-level

terraform plan -parallelism=1   # expect no drift when value/type match main.tf
terraform destroy -parallelism=1
```

See [terraform-integration.md — Import](../../../terraform-integration.md#import-existing-resources-mvp).

## Path prefix data source

1. `simulith seed`
2. Copy `path-data.tf.example` → `path-data.tf`
3. `terraform apply -parallelism=1` — output lists names under `/app/demo`

## Limitations

- `DescribeParameters` MVP (Name Equals/BeginsWith) — required for Terraform provider refresh
- **DeleteParameters** batch delete (SML-062) — CLI/SDK; Terraform still uses **DeleteParameter** per resource
- Parameter **tags** supported on `aws_ssm_parameter` (SML-070)
- See [ssm.md](../../../ssm.md) for API deviations

## Related

- [terraform-integration.md](../../../terraform-integration.md)
- [aws-cli-examples.md](../../../aws-cli-examples.md#ssm-parameter-store)
