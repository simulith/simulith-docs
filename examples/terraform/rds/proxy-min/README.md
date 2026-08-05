# RDS Proxy green path

Minimum subset: IAM role + RDS instance + RDS Proxy + target.

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
psql "postgresql://demoapp:local-dev-password@$(terraform output -raw rds_proxy_endpoint)/demoapp"
```

## Destroy

```bash
terraform destroy -auto-approve
```

See also: [`../postgres-min/`](../postgres-min/) (RDS instance only), [`../../iam/proxy-roles-min/`](../../iam/proxy-roles-min/) (IAM only).
