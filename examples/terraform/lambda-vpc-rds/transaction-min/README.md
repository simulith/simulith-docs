# Lambda + postgres-min — transaction probe green path

**demoapp `transaction-api` subset:** compose [`../../rds/postgres-min/`](../../rds/postgres-min/) with a Lambda in proxy subnets that TCP-probes the RDS Proxy endpoint on invoke.

Replaces duplicating VPC/RDS/proxy in [`../full-stack-min/`](../full-stack-min/) when validating the prod chain end-to-end.

## Resources

| Layer | Terraform |
| --- | --- |
|  data plane | `module.postgres_min` → vpc, kms, secrets, rds, proxy |
| Lambda | `aws_lambda_function.transaction_probe` with `vpc_config` + `RDS_PROXY_ENDPOINT` |

## Prerequisites

1. `simulith start` with Docker (RDS sidecar)
2. Terraform >= 1.5

## Apply

```bash
cd runtime/examples/terraform/lambda-vpc-rds/transaction-min
terraform init
terraform apply -parallelism=1 -auto-approve
```

## Invoke probe

```bash
aws --endpoint-url http://127.0.0.1:4566 lambda invoke \
  --function-name "$(terraform output -raw lambda_function_name)" \
  --payload '{}' out.json && cat out.json
```

Expect `{"connected":true,"endpoint":"127.0.0.1:..."}`.

## Destroy

```bash
terraform destroy -parallelism=1 -auto-approve
```

Automated smoke: `maintainer workflow (private monorepo)`
