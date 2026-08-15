# Lambda VPC + RDS Proxy green path

Deploys VPC, RDS Postgres + Proxy, and a Lambda with `vpc_config`.

## Prerequisites

1. `simulith start` with Docker (RDS sidecar)
2. Terraform >= 1.5

## Apply

```bash
cd runtime/examples/terraform/lambda-vpc-rds/full-stack-min
terraform init
terraform apply -auto-approve
```

Invoke probe (AWS CLI against Simulith):

```bash
aws --endpoint-url http://127.0.0.1:4566 lambda invoke \
  --function-name "$(terraform output -raw lambda_function_name)" \
  --payload '{}' out.json && cat out.json
```

Expect `{"connected":true,"endpoint":"127.0.0.1:..."}`.

## Related

- [`../transaction-min/`](../transaction-min/) — **preferred:** composes `vpc-rds-proxy-min` + Lambda
- [`../../rds/vpc-rds-proxy-min/`](../../rds/vpc-rds-proxy-min/) — single-root VPC + RDS + Proxy without Lambda
- [`../../rds/proxy-min/`](../../rds/proxy-min/) — proxy only
- [`../../vpc/network-min/`](../../vpc/network-min/) — VPC only
