# Terraform — Lambda on Simulith and AWS

`aws_lambda_function` + `aws_sqs_queue` + `aws_lambda_event_source_mapping` **apply** and **destroy** work on Simulith and real AWS.

## Prerequisites

- Simulith running for local apply ([quickstart](../../../quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x, archive provider ~> 2.x
- AWS credentials configured for real AWS apply

## Workspaces and var-files

| Target | Workspace | Var file | Default names |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `terraform.tfvars` | `worker-tf` / `worker-tf-queue` |
| **Real AWS dev** | `aws` | `terraform.aws-dev.tfvars` | `simulith-dev-worker-tf` |

The workspace name does **not** switch the endpoint — `use_simulith_endpoint` in the var file does.

> **Pitfall:** `terraform workspace select aws` + bare `terraform apply` still auto-loads **`terraform.tfvars`** (Simulith). Always pass `-var-file=terraform.aws-dev.tfvars` for AWS.

### Simulith endpoint

| How you run Simulith | `simulith_endpoint` |
| --- | --- |
| Docker all-in-one (Console `:9080`) | `http://127.0.0.1:9080/runtime` — default in `terraform.tfvars.example` |
| Native / host `:4566` | `http://127.0.0.1:4566` — `terraform.tfvars.native.example` |

CLI and Console must use the **same** runtime. See [endpoint matrix](../../../terraform-integration.md#endpoint-matrix).

## Apply (Simulith)

```bash
cd runtime/examples/terraform/lambda
cp terraform.tfvars.native.example terraform.tfvars   # or .example for Docker proxy
terraform init
terraform workspace select default
terraform apply
```

Use **`-parallelism=1`** if apply fails with SQLite contention (`failed to load queue metadata`) while the ESM poller is active:

```bash
terraform apply -parallelism=1
terraform destroy -parallelism=1
```

Expected plan: **3 to add** (SQS queue, Lambda function, event source mapping).

**Destroy (Simulith):**

```bash
terraform workspace select default
terraform destroy
```

Expected plan: **3 to destroy**.

## Apply (real AWS dev)

Set a valid **`lambda_role_arn`** (execution role with `lambda.amazonaws.com` trust and SQS read permissions for ESM).

```bash
terraform workspace select -or-create aws
cp terraform.aws-dev.tfvars.example terraform.aws-dev.tfvars   # edit role ARN
terraform apply -var-file=terraform.aws-dev.tfvars
terraform destroy -var-file=terraform.aws-dev.tfvars
```

## Manual test (AWS CLI — Simulith)

After apply:

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566

aws lambda list-functions --endpoint-url "$AWS_ENDPOINT"
aws lambda get-function --function-name worker-tf --endpoint-url "$AWS_ENDPOINT"
aws lambda invoke --function-name worker-tf --payload '{}' /tmp/out.json --endpoint-url "$AWS_ENDPOINT"
cat /tmp/out.json
# Expect greeting from environment_variables (default GREETING=hello-from-terraform)
aws lambda list-event-source-mappings --function-name worker-tf --endpoint-url "$AWS_ENDPOINT"
aws sqs get-queue-url --queue-name worker-tf-queue --endpoint-url "$AWS_ENDPOINT"
```

### UpdateFunctionConfiguration (in-place)

Changing `environment_variables` in `terraform.tfvars` and re-running **`terraform apply`** updates config via Simulith **`UpdateFunctionConfiguration`** (no function replace). Example:

```hcl
environment_variables = { GREETING = "updated-from-terraform" }
```

Re-apply, then invoke again — payload should reflect the new greeting.

**Source pattern:** [AWS Lambda environment variables](https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html) · [Terraform `aws_lambda_function` environment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#environment)

Imperative equivalent: [`../../aws-cli/lambda/`](../../aws-cli/lambda/) (create → update-config → invoke).

## Resources created

| Resource | Type | Name |
| --- | --- | --- |
| `aws_sqs_queue.worker` | Queue | `worker-tf-queue` |
| `aws_lambda_function.worker` | Function | `worker-tf` |
| `aws_lambda_event_source_mapping.worker` | ESM | SQS → Lambda |

## Limitations

- Simulith accepts any `lambda_role_arn` string — no `aws_iam_role` in this module
- Node.js handler zip only; invoke requires `node` on host (not validated by Terraform)
- No layers, aliases, versions, VPC, or `publish = true`
- [lambda.md](../../../lambda.md) — MVP API gaps

## Related

- [terraform-integration.md](../../../terraform-integration.md)
- [lambda.md](../../../lambda.md)
- [compatibility-matrix.md](../../../compatibility-matrix.md)
