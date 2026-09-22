# Terraform — CloudWatch Dashboards on Simulith and AWS

`aws_cloudwatch_dashboard` **apply** and **destroy** work on Simulith and real AWS.

## Prerequisites

- Simulith running for local apply ([quickstart](../../../quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x

## Apply (Simulith)

```bash
cd runtime/examples/terraform/cloudwatch-dashboards
cp terraform.tfvars.native.example terraform.tfvars   # or .example for Docker proxy
terraform init
terraform apply -parallelism=1
```

Expected plan: **1 to add** (dashboard).

Verify:

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566

aws cloudwatch get-dashboard \
  --endpoint-url "$AWS_ENDPOINT" \
  --dashboard-name "$(terraform output -raw dashboard_name)"
```

## Destroy

```bash
terraform destroy -parallelism=1
```

See [terraform-integration.md](../../../terraform-integration.md) for endpoint matrix and workspace notes.
