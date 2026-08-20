# vpc-rds-proxy-min — single-root Terraform green path

VPC + subnets + security groups + KMS + Secrets Manager + RDS Postgres + RDS Proxy — apply/destroy against Simulith (no remote state S3).

Combines slices from [`../postgres-min/`](../postgres-min/), [`../proxy-min/`](../proxy-min/), [`../../kms/cmk-min/`](../../kms/cmk-min/), and [`../../vpc/network-min/`](../../vpc/network-min/). Proxy idle/debug and default target-group pool percents use `ModifyDBProxy` / `DescribeDBProxyTargetGroups`. Local relay does not pool connections or terminate TLS.

## Resources

| Layer | Terraform |
| --- | --- |
| Secrets | `aws_kms_key`, `aws_kms_alias`, `aws_secretsmanager_secret` (+ version) |
| Network | `aws_vpc`, subnets (DB + proxy), security groups |
| RDS | `aws_db_subnet_group`, `aws_db_parameter_group`, `aws_db_instance.app_db` |
| Proxy | `aws_iam_role`, `aws_iam_policy`, `aws_db_proxy`, target group + target |

## Prerequisites

1. Simulith running: `simulith start --port 4566`
2. Docker available (Postgres sidecar on `CreateDBInstance`)

## Apply

```bash
cd runtime/examples/terraform/rds/vpc-rds-proxy-min
terraform init
terraform apply -parallelism=1 -auto-approve
```

## Verify

```bash
terraform output rds_proxy_endpoint
terraform output postgres_db_endpoint
# Proxy:
psql "postgresql://demoapp:local-dev-password@$(terraform output -raw rds_proxy_endpoint)/demoapp"
```

## Destroy

```bash
terraform destroy -parallelism=1 -auto-approve
```

Automated smoke: `maintainer workflow (private monorepo)`

Lambda probe: [`../../lambda-vpc-rds/transaction-min/`](../../lambda-vpc-rds/transaction-min/).
