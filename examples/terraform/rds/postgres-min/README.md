# postgres-min RDS on Simulith

Minimum Terraform subset for a Postgres instance with embedded VPC/subnet/security group — local green-path validation.

**Green path:** `terraform apply -parallelism=1` then **`terraform destroy -parallelism=1`** — no `simulith reset` required. **Docker required** for the Postgres sidecar.

## Prerequisites

1. Simulith running: `simulith start --port 4566`
2. Docker available (Postgres sidecar starts on `CreateDBInstance`)

## Apply

```bash
cd runtime/examples/terraform/rds/postgres-min
terraform init
terraform apply
```

## Verify

```bash
terraform output postgres_db_endpoint
terraform output postgres_db_port
psql -h "$(terraform output -raw postgres_db_endpoint)" -p "$(terraform output -raw postgres_db_port)" -U demoapp -d demoapp
```

## Destroy

```bash
terraform destroy
```
