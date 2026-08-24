# Subnets root — Simulith green path (production pattern)

Six database subnets + route table associations aligned with unmodified **`subnets/`** roots. Outputs `database_subnet_*_id` and `vpc_id` for `postgresdb/` / `proxydb/` remote state.

```bash
cp terraform.tfvars.native.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -parallelism=1
terraform destroy -var-file=terraform.tfvars -parallelism=1
```

Native Simulith: `simulith_endpoint = "http://127.0.0.1:4566"`.

**Note:** Embedded minimal VPC + route tables for local apply. Production reads `vpc/` remote state instead.

See [`runtime/docs/vpc.md`](../../../vpc.md) · [`../vpc/network-min/`](../vpc/network-min/) (single-subnet subset).
