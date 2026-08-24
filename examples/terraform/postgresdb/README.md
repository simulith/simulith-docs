# Postgresdb root — Simulith green path (production pattern)

RDS Postgres + DB subnet group (3 subnets) + parameter group + DB SG aligned with unmodified **`postgresdb/`** roots. Outputs `postgres_db_*` for `proxydb/` remote state.

```bash
cp terraform.tfvars.native.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -parallelism=1
terraform destroy -var-file=terraform.tfvars -parallelism=1
```

Native Simulith: `simulith_endpoint = "http://127.0.0.1:4566"`.

**Docker required** for the Postgres sidecar on `CreateDBInstance`.

**Note:** Embedded VPC + 3 subnets for local apply. Production reads `subnets/` remote state instead.

See [`runtime/docs/rds.md`](../../../rds.md) · [`../rds/postgres-min/`](../rds/postgres-min/) (2-subnet subset).
