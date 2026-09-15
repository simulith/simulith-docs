# Terraform — CloudWatch Logs on Simulith and AWS

`aws_cloudwatch_log_group` **apply** and **destroy** work on Simulith and real AWS.

## Prerequisites

- Simulith running for local apply ([quickstart](../../../quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x

## Workspaces and var-files

| Target | Workspace | Var file | Default name |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `terraform.tfvars` | `/aws/lambda/demo-tf` |
| **Real AWS dev** | `aws` | `terraform.aws-dev.tfvars` | (create from example when needed) |

The workspace name does **not** switch the endpoint — `use_simulith_endpoint` in the var file does.

### Simulith endpoint

| How you run Simulith | `simulith_endpoint` |
| --- | --- |
| Docker all-in-one (Console `:9080`) | `http://127.0.0.1:9080/runtime` — default in `terraform.tfvars.example` |
| Native / host `:4566` | `http://127.0.0.1:4566` — `terraform.tfvars.native.example` |

Provider `endpoints { logs = … }` routes **CloudWatch Logs** to Simulith. See [endpoint matrix](../../../terraform-integration.md#endpoint-matrix).

## Apply (Simulith)

```bash
cd runtime/examples/terraform/cloudwatch
cp terraform.tfvars.native.example terraform.tfvars   # or .example for Docker proxy
terraform init
terraform workspace select default
terraform apply -parallelism=1
```

Expected plan: **1 to add** (log group).

Verify the group:

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566

aws logs describe-log-groups \
  --endpoint-url "$AWS_ENDPOINT" \
  --log-group-name-prefix "$(terraform output -raw log_group_name)"
```

Optional — create a stream and event via CLI (not in this Terraform module; `DeleteLogStream` is not emulated yet):

```bash
aws logs create-log-stream \
  --endpoint-url "$AWS_ENDPOINT" \
  --log-group-name "$(terraform output -raw log_group_name)" \
  --log-stream-name demo-stream
```

## Destroy (Simulith)

```bash
terraform destroy -parallelism=1
```

Expected plan: **1 to destroy**. Deleting the log group removes nested streams and events locally.

## Provider notes

- **`skip_requesting_account_id = true`** — Simulith uses fixed account `000000000000`.
- **No tags or `retention_in_days`** in this module — avoids `TagResource` / `PutRetentionPolicy` APIs not yet emulated.
- **`aws_cloudwatch_log_stream`** as a Terraform resource is deferred — destroy requires `DeleteLogStream`.

## Related

- [cloudwatch.md](../../../cloudwatch.md)
- [terraform-integration.md — Green path IaC](../../../terraform-integration.md#green-path-iac)
- Automated smoke: `maintainer workflow (private monorepo)`
