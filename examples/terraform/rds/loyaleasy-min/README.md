# loyaleasy-min RDS on Simulith

Minimum Terraform subset mirroring `postgresdb/database.tf` for local green-path validation.

## Prerequisites

1. Simulith running: `simulith start --port 4566`
2. Docker available (Postgres sidecar starts on `CreateDBInstance`)

## Apply

```bash
cd runtime/examples/terraform/rds/loyaleasy-min
terraform init
terraform apply
```

## Verify

```bash
terraform output postgres_db_endpoint
terraform output postgres_db_port
psql -h "$(terraform output -raw postgres_db_endpoint)" -p "$(terraform output -raw postgres_db_port)" -U loyaleasy -d loyaleasy
```

## Destroy

```bash
terraform destroy
```
