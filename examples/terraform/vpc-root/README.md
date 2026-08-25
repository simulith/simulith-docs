# Vpc root — Simulith green path (production pattern)

VPC + IGW + route tables + S3/DynamoDB gateway endpoints aligned with unmodified **`vpc/`** roots. Outputs `vpc_id`, `vpc_cidr_block`, `public_route_table_id`, `private_route_table_id` for **subnets/** remote state.

```bash
cp terraform.tfvars.native.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -parallelism=1
terraform destroy -var-file=terraform.tfvars -parallelism=1
```

Native Simulith: `simulith_endpoint = "http://127.0.0.1:4566"`.

**Note:** Subnets and security groups live in **subnets/** and **secrets/** roots. This module is vpc-only (production split). See [`../vpc/network-min/`](../vpc/network-min/) for a single-root subset with one subnet + DB SG.

See [`runtime/docs/vpc.md`](../../../vpc.md).
