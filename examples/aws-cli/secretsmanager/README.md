# AWS CLI — Secrets Manager on Simulith

Three scripts derived from the [AWS Secrets Manager user guide](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html), trimmed to Simulith's documented subset.

## Prerequisites

- Simulith running ([quickstart](../../../quickstart.md))
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Bash (Git Bash on Windows)

## Environment

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
# Native / :4566
export AWS_ENDPOINT=http://127.0.0.1:4566
# Docker all-in-one
# export AWS_ENDPOINT=http://127.0.0.1:9080/runtime

export SECRET_NAME=cli-demo-secret
```

Run from this directory:

```bash
cd runtime/examples/aws-cli/secretsmanager
```

## Scripts

| Script | AWS operation | Simulith API |
| --- | --- | --- |
| [`01-create-secret.sh`](01-create-secret.sh) | `create-secret` | CreateSecret |
| [`02-put-secret-value.sh`](02-put-secret-value.sh) | `put-secret-value` | PutSecretValue |
| [`03-get-secret-value.sh`](03-get-secret-value.sh) | `get-secret-value` | GetSecretValue |

```bash
./01-create-secret.sh
./03-get-secret-value.sh
./02-put-secret-value.sh
./03-get-secret-value.sh    # password should be rotated-local
```

Cleanup:

```bash
aws secretsmanager delete-secret \
  --secret-id "$SECRET_NAME" \
  --force-delete-without-recovery \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
```

## Cross-service: secret → Lambda env

For Terraform **data source → Lambda environment** (deploy-time injection), see [`../../terraform/secretsmanager-lambda/`](../../terraform/secretsmanager-lambda/).

Runtime SDK fetch (`GetSecretValue` inside the handler) is supported by Simulith but not scripted here — use the Terraform pattern for green-path validation.

## Limits

- Plain `SecretString` only (no KMS, rotation, or resource policies)
- Immediate delete with `--force-delete-without-recovery`
- See [secretsmanager.md](../../../secretsmanager.md) and [compatibility-matrix.md](../../../compatibility-matrix.md)

## Related

- Green path Terraform: [`../../terraform/secretsmanager/`](../../terraform/secretsmanager/)
- Secret → Lambda env pattern: [`../../terraform/secretsmanager-lambda/`](../../terraform/secretsmanager-lambda/)
- Lambda CLI examples: [`../lambda/`](../lambda/)
