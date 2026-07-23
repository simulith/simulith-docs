# Terraform — API Gateway on Simulith and AWS

`aws_api_gateway_rest_api` + `aws_api_gateway_resource` + method + `AWS_PROXY` Lambda integration + deployment + stage + `aws_lambda_permission` **apply** and **destroy** work on Simulith and real AWS.

## Prerequisites

- Simulith running for local apply ([quickstart](../../../quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x, archive provider ~> 2.x
- AWS credentials and a valid Lambda execution role for real AWS apply

## Workspaces and var-files

| Target | Workspace | Var file | Default names |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `terraform.tfvars` | `hello-tf` API + function |
| **Real AWS dev** | `aws` | `terraform.aws-dev.tfvars` | (create from example when needed) |

The workspace name does **not** switch the endpoint — `use_simulith_endpoint` in the var file does.

### Simulith endpoint

| How you run Simulith | `simulith_endpoint` |
| --- | --- |
| Docker all-in-one (Console `:9080`) | `http://127.0.0.1:9080/runtime` — default in `terraform.tfvars.example` |
| Native / host `:4566` | `http://127.0.0.1:4566` — `terraform.tfvars.native.example` |

Provider `endpoints` block routes **both** `apigateway` and `lambda` to Simulith. CLI and Console must use the **same** runtime. See [endpoint matrix](../../../terraform-integration.md#endpoint-matrix).

## Apply (Simulith)

```bash
cd runtime/examples/terraform/apigateway
cp terraform.tfvars.native.example terraform.tfvars   # or .example for Docker proxy
terraform init
terraform workspace select default
terraform apply -parallelism=1
```

Use **`-parallelism=1`** on apply and destroy (SQLite single-writer; same guidance as SQS/SSM modules).

Expected plan: **8 to add** (RestApi, Lambda, permission, resource, method, integration, deployment, stage).

After apply, invoke the stage URL (no SigV4):

```bash
curl "$(terraform output -raw invoke_url)"
```

Expected JSON includes `"managed_by":"terraform"`.

## Source pattern (AWS → Simulith)

This module mirrors a common AWS tutorial flow:

1. **REST API** + `{proxy+}` resource + **ANY** method
2. **AWS_PROXY** integration to Lambda
3. **Deployment** + **stage** (`prod`)
4. **`aws_lambda_permission`** for `apigateway.amazonaws.com`

Simulith subset: no authorizers, usage plans, or custom domains — see [apigateway.md](../../../apigateway.md).

**Related modules**

- Lambda only (SQS ESM): [`../lambda/`](../lambda/)
- Imperative CLI: [`../../aws-cli/lambda/`](../../aws-cli/lambda/)

After the Lambda module apply, you can point API Gateway at the same function name — or use this standalone stack (`hello-tf`).

## Destroy (Simulith)

```bash
terraform destroy -parallelism=1
```

Expected plan: **8 to destroy**.

## Provider notes

- **`skip_requesting_account_id = true`** — Simulith uses fixed account `000000000000`. The module sets `source_arn` on `aws_lambda_permission` with that account explicitly (Terraform cannot infer it when account lookup is skipped).
- **`lambda_role_arn`** — any ARN is accepted locally; real AWS needs a valid execution role.

## Manual test (AWS CLI — Simulith)

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566

aws apigateway get-rest-apis --endpoint-url "$AWS_ENDPOINT"
aws lambda list-functions --endpoint-url "$AWS_ENDPOINT"
```

Guide: [terraform-integration.md — Green path IaC](../../../terraform-integration.md#green-path-iac) · API Gateway: [apigateway.md](../../../apigateway.md)
