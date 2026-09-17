# Terraform — CloudWatch Metrics on Simulith and AWS

Publishes a **custom metric datapoint** (`PutMetricData`) on apply. There is no Terraform resource for arbitrary custom metrics — this module uses `terraform_data` + AWS CLI, matching how teams often bootstrap metrics in IaC.

**Apply** and **destroy** succeed on Simulith and real AWS. Destroy does not delete historical datapoints (same as AWS).

## Prerequisites

- Simulith running for local apply ([quickstart](../../../quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x
- **AWS CLI v2** on `PATH` (used by the apply-time provisioner)

## Workspaces and var-files

| Target | Workspace | Var file | Default namespace |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `terraform.tfvars` | `Simulith/Terraform` |
| **Real AWS dev** | `aws` | `terraform.aws-dev.tfvars` | (create from example when needed) |

### Simulith endpoint

| How you run Simulith | `simulith_endpoint` |
| --- | --- |
| Docker all-in-one (Console `:9080`) | `http://127.0.0.1:9080/runtime` — default in `terraform.tfvars.example` |
| Native / host `:4566` | `http://127.0.0.1:4566` — `terraform.tfvars.native.example` |

Provider `endpoints { cloudwatch = … }` routes **CloudWatch Metrics** to Simulith. See [endpoint matrix](../../../terraform-integration.md#endpoint-matrix).

## Apply (Simulith)

```bash
cd runtime/examples/terraform/cloudwatch-metrics
cp terraform.tfvars.native.example terraform.tfvars   # or .example for Docker proxy
terraform init
terraform workspace select default
terraform apply -parallelism=1
```

Expected plan: **1 to add** (`terraform_data.custom_metric`).

Verify the metric:

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566

aws cloudwatch list-metrics \
  --endpoint-url "$AWS_ENDPOINT" \
  --namespace "$(terraform output -raw metric_namespace)" \
  --metric-name "$(terraform output -raw metric_name)"
```

## Destroy (Simulith)

```bash
terraform destroy -parallelism=1
```

Expected plan: **1 to destroy**. Datapoints already stored remain until `simulith reset` (documented limit).

## Provider notes

- **`skip_requesting_account_id = true`** — Simulith uses fixed account `000000000000`.
- **`aws_cloudwatch_metric_alarm`** — see [`../cloudwatch-alarms/`](../cloudwatch-alarms/).
- Re-apply after changing `metric_value` replaces the `terraform_data` resource and publishes again.

## Related

- [cloudwatch-metrics.md](../../../cloudwatch-metrics.md)
- [terraform-integration.md — Green path IaC](../../../terraform-integration.md#green-path-iac)
- Automated smoke: `maintainer workflow (private monorepo)`
