# Terraform — Secrets Manager → Lambda environment

Cross-service pattern: store JSON in **Secrets Manager**, read it at apply time with the [`aws_secretsmanager_secret_version`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) data source, and inject into **Lambda** `environment.variables`.

**Source pattern:** [AWS — retrieve secrets in Lambda](https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets_lambda.html) (Simulith uses the **deploy-time env injection** variant via Terraform, not runtime SDK fetch).

## Prerequisites

- Simulith running ([quickstart](../../../quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x
- **Node.js** on PATH (Simulith invokes node for Lambda)

## Workspaces and var-files

| Target | Workspace | Var file | Default names |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `terraform.tfvars` | secret `app-config-lambda-tf`, function `secret-env-worker-tf` |
| **Real AWS dev** | `aws` | `terraform.aws-dev.tfvars` | (create from example when needed) |

Provider `endpoints` block routes **Secrets Manager** and **Lambda** to Simulith. See [endpoint matrix](../../../terraform-integration.md#endpoint-matrix).

## Apply (Simulith)

```bash
cd runtime/examples/terraform/secretsmanager-lambda
cp terraform.tfvars.native.example terraform.tfvars   # or Docker proxy variant
terraform init
terraform workspace select default
terraform apply -parallelism=1
```

Use **`-parallelism=1`** on apply and destroy (SQLite single-writer).

Expected plan: **4 to add** (secret, secret version, Lambda function, plus data source read).

Verify the secret value:

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566

aws secretsmanager get-secret-value \
  --endpoint-url "$AWS_ENDPOINT" \
  --secret-id "$(terraform output -raw secret_name)"
```

Invoke Lambda and assert env-backed config:

```bash
aws lambda invoke \
  --function-name "$(terraform output -raw function_name)" \
  --payload '{}' \
  --endpoint-url "$AWS_ENDPOINT" \
  /tmp/secret-lambda-out.json

cat /tmp/secret-lambda-out.json
# expect username "admin" and secret_source "env-from-data-source"
```

## Re-apply after secret rotation

Change `secret_string` in `main.tf` (or use `aws_secretsmanager_secret_version` with a new version), then:

```bash
terraform apply -parallelism=1
```

Terraform re-reads the data source and updates Lambda environment via **UpdateFunctionConfiguration**.

## Destroy (Simulith)

```bash
terraform destroy -parallelism=1
```

Expected plan: **3 to destroy** (secret, secret version, Lambda). `recovery_window_in_days = 0` maps to immediate local delete.

## Simulith limits

- Plain `SecretString` only — no KMS, rotation, or resource policies
- Dummy IAM role ARN (no `aws_iam_role`)
- Secret value in Lambda env is **visible in console/API** — same as AWS; for runtime fetch use SDK + `SECRET_ARN` (out of scope here)
- No VPC, layers, or aliases

## Related

- Green path Secrets Manager only: [`../secretsmanager/`](../secretsmanager/)
- Lambda + SQS module: [`../lambda/`](../lambda/)
- AWS CLI scripts: [`../../aws-cli/secretsmanager/`](../../aws-cli/secretsmanager/)
- [secretsmanager.md](../../../secretsmanager.md) · [lambda.md](../../../lambda.md)
- [terraform-integration.md — Honest integration examples](../../../terraform-integration.md#honest-integration-examples)
