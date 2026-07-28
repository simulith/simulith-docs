# AWS CLI — Lambda on Simulith

Three scripts derived from the [AWS Lambda getting started](https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html) flow, trimmed to Simulith's documented subset.

## Prerequisites

- Simulith running ([quickstart](../../../quickstart.md))
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Bash + `zip` (Git Bash on Windows)
- **Node.js** on PATH (Simulith invokes node subprocess)

## Environment

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
# Native / :4566
export AWS_ENDPOINT=http://127.0.0.1:4566
# Docker all-in-one
# export AWS_ENDPOINT=http://127.0.0.1:9080/runtime

export FUNCTION_NAME=cli-demo-fn
```

Run from this directory:

```bash
cd runtime/examples/aws-cli/lambda
```

## Scripts

| Script | AWS operation | Simulith API |
| --- | --- | --- |
| [`01-create-function.sh`](01-create-function.sh) | `create-function` | CreateFunction |
| [`02-update-configuration.sh`](02-update-configuration.sh) | `update-function-configuration` | UpdateFunctionConfiguration |
| [`03-invoke.sh`](03-invoke.sh) | `invoke` | InvokeFunction (sync) |

```bash
./01-create-function.sh
./03-invoke.sh                    # greeting unset or from create
./02-update-configuration.sh
./03-invoke.sh                    # greeting=hello-from-cli
```

Cleanup:

```bash
aws lambda delete-function --function-name "$FUNCTION_NAME" --endpoint-url "$AWS_ENDPOINT"
```

## Limits

- Dummy IAM role ARN only (no `aws_iam_role`)
- Node.js zip inline; no layers, VPC, or aliases
- Go bootstrap: [`../lambda-go/`](../lambda-go/)
- Java handler: [`../lambda-java/`](../lambda-java/)
- See [lambda.md](../../../lambda.md) and [compatibility-matrix.md](../../../compatibility-matrix.md)

## Related

- Terraform module: [`../../terraform/lambda/`](../../terraform/lambda/)
- API Gateway HTTP pattern: [`../../terraform/apigateway/`](../../terraform/apigateway/)
