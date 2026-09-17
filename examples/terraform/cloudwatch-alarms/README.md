# Terraform — CloudWatch Alarms on Simulith and AWS

`aws_cloudwatch_metric_alarm` **apply** and **destroy** work on Simulith and real AWS.

## Prerequisites

- Simulith running for local apply ([quickstart](../../../quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x

## Workspaces and var-files

| Target | Workspace | Var file | Default name |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `terraform.tfvars` | `demo-tf-alarm` |
| **Real AWS dev** | `aws` | `terraform.aws-dev.tfvars` | (create from example when needed) |

The workspace name does **not** switch the endpoint — `use_simulith_endpoint` in the var file does.

### Simulith endpoint

| How you run Simulith | `simulith_endpoint` |
| --- | --- |
| Docker all-in-one (Console `:9080`) | `http://127.0.0.1:9080/runtime` — default in `terraform.tfvars.example` |
| Native / host `:4566` | `http://127.0.0.1:4566` — `terraform.tfvars.native.example` |

Provider `endpoints { cloudwatch = … }` routes **CloudWatch Alarms** (monitoring API) to Simulith. See [endpoint matrix](../../../terraform-integration.md#endpoint-matrix).

## Apply (Simulith)

```bash
cd runtime/examples/terraform/cloudwatch-alarms
cp terraform.tfvars.native.example terraform.tfvars   # or .example for Docker proxy
terraform init
terraform workspace select default
terraform apply -parallelism=1
```

Expected plan: **1 to add** (metric alarm).

Verify the alarm:

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566

aws cloudwatch describe-alarms \
  --endpoint-url "$AWS_ENDPOINT" \
  --alarm-names "$(terraform output -raw alarm_name)"
```

## Destroy (Simulith)

```bash
terraform destroy -parallelism=1
```

Expected plan: **1 to destroy**. Alarm definitions are fully removed locally (unlike custom metric datapoints).

## Provider notes

- **`skip_requesting_account_id = true`** — Simulith uses fixed account `000000000000`.
- **No tags, dimensions, or `alarm_actions`** in this module — avoids TagResource APIs and keeps the minimal PutMetricAlarm subset.
- Alarm state stays **`INSUFFICIENT_DATA`** — evaluation is  remainder.

## Related

- [cloudwatch-alarms.md](../../../cloudwatch-alarms.md)
- [terraform-integration.md — Green path IaC](../../../terraform-integration.md#green-path-iac)
- Automated smoke: `maintainer workflow (private monorepo)`
