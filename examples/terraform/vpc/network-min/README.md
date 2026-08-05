# VPC network-min — Simulith

Minimum networking slice: VPC, IGW, route tables, gateway endpoints (S3/DynamoDB), one database subnet, and Postgres security group.

Start Simulith locally, then:

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
terraform destroy -var-file=terraform.tfvars -auto-approve
```

Single-root example (no remote state S3) for local validation.

**Green path:** `terraform apply -parallelism=1` then **`terraform destroy -parallelism=1`** — no `simulith reset` required.
