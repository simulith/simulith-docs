# AWS CLI — Go Lambda (provided.al2023) on Simulith

Runnable flow derived from [Building Lambda functions with Go](https://docs.aws.amazon.com/lambda/latest/dg/lambda-golang.html) and the [custom runtime `bootstrap` contract](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-custom.html), trimmed to Simulith's documented subset.

## Prerequisites

- Simulith running ([quickstart](../../../quickstart.md))
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Bash + `zip` (Git Bash on Windows)
- **[Go](https://go.dev/dl/)** on PATH to compile `bootstrap` (no Node/Python required for invoke)

## Environment

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
# Native / :4566
export AWS_ENDPOINT=http://127.0.0.1:4566
# Docker all-in-one
# export AWS_ENDPOINT=http://127.0.0.1:9080/runtime

export FUNCTION_NAME=cli-go-demo-fn
```

Run from this directory:

```bash
cd runtime/examples/aws-cli/lambda-go
```

## Scripts

| Script | AWS operation | Simulith API |
| --- | --- | --- |
| [`01-create-function.sh`](01-create-function.sh) | `create-function` | CreateFunction (`provided.al2023`, zip with `bootstrap`) |
| [`02-update-configuration.sh`](02-update-configuration.sh) | `update-function-configuration` | UpdateFunctionConfiguration |
| [`03-invoke.sh`](03-invoke.sh) | `invoke` | InvokeFunction (sync) |

```bash
./01-create-function.sh
./03-invoke.sh
./02-update-configuration.sh
./03-invoke.sh                    # GREETING=hello-from-go-cli
```

Cleanup:

```bash
aws lambda delete-function --function-name "$FUNCTION_NAME" --endpoint-url "$AWS_ENDPOINT"
```

## Build notes

- **Local Simulith (Windows/macOS/Linux):** `go build` targets your host OS — the script names the binary `bootstrap` or `bootstrap.exe` accordingly.
- **Deploy to real AWS Linux:** set `GOOS=linux GOARCH=amd64` before `go build` in `01-create-function.sh` (or build manually) so the binary matches Lambda's execution environment.

## Limits

- Dummy IAM role ARN only (no `aws_iam_role`)
- Single-file bootstrap; no layers, VPC, or aliases
- See [lambda.md](../../../lambda.md) (Go / `provided*`) and [compatibility-matrix.md](../../../compatibility-matrix.md)

## Related

- Node.js CLI demo: [`../lambda/`](../lambda/)
- Java CLI demo: [`../lambda-java/`](../lambda-java/)
- Terraform module: [`../../terraform/lambda/`](../../terraform/lambda/)
