# Music table — Simulith (minimal demo)

Minimal root module: one **DynamoDB** hash-key table against Simulith.

## Prerequisites

- Simulith on port **4566** — [quickstart](../../../../docs/quickstart.md)
- Terraform ≥ 1.6

## Run

```bash
cd runtime/examples/terraform/dynamodb/music
terraform init
terraform apply
```

Expected: one `aws_dynamodb_table` named `Music-tf` (override with `-var="table_name=..."`).

## Verify (optional)

```bash
export AWS_ENDPOINT=http://127.0.0.1:4566
export AWS_DEFAULT_REGION=us-east-1

aws dynamodb describe-table --table-name Music-tf \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

## Cleanup

Primary teardown — removes the table via Simulith **DeleteTable** (same as AWS):

```bash
terraform destroy
```

Type `yes` when prompted. No `simulith reset` or `terraform state rm` required for this module.

If destroy fails: confirm Simulith is running on `http://127.0.0.1:4566` and the provider endpoint matches. See [terraform-integration.md — Green path IaC](../../../../docs/terraform-integration.md#green-path-iac).

Service index: [../README.md](../README.md) · Guide: [terraform-integration.md](../../../../docs/terraform-integration.md)
