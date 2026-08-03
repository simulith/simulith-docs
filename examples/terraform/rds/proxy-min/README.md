# RDS Proxy green path

Minimum loyaleasy `proxydb/` subset: IAM role + RDS instance + RDS Proxy + target.

## Prerequisites

1. Simulith running (`simulith start`) with Docker available
2. Terraform >= 1.5, AWS provider >= 5

## Apply

```bash
cd runtime/examples/terraform/rds/proxy-min
terraform init
terraform apply -auto-approve
```

Connect via proxy endpoint output:

```bash
# Endpoint is host:port (e.g. 127.0.0.1:25432)
psql "postgresql://loyaleasy:local-dev-password@$(terraform output -raw rds_proxy_endpoint)/loyaleasy"
```

## Destroy

```bash
terraform destroy -auto-approve
```

See also: [`../loyaleasy-min/`](../loyaleasy-min/) (RDS instance only), [`../../iam/loyaleasy-min/`](../../iam/loyaleasy-min/) (IAM only).
