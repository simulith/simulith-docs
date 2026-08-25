# Proxydb root — Simulith green path (production pattern)

RDS Proxy + IAM role/policy aligned with unmodified **`proxydb/`** roots. Outputs `rds_proxy_endpoint`, `rds_proxy_sg`, `rds_proxy_arn` for `parameters/` remote state.

```bash
cp terraform.tfvars.native.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -parallelism=1
terraform destroy -var-file=terraform.tfvars -parallelism=1
```

Native Simulith: `simulith_endpoint = "http://127.0.0.1:4566"`.

**Docker required** for the Postgres sidecar (embedded RDS instance for proxy target).

**Note:** Self-contained embedded VPC/subnets/secrets/postgres deps. Production reads `subnets/`, `secrets/`, `postgresdb/` remote state instead.

See [`runtime/docs/rds.md`](../../../rds.md) · [`../rds/proxy-min/`](../rds/proxy-min/) (subset).
