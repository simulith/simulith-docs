# AWS CLI — Java Lambda on Simulith

Runnable flow derived from [Building Lambda functions with Java](https://docs.aws.amazon.com/lambda/latest/dg/lambda-java.html), trimmed to Simulith's documented subset.

## Prerequisites

- Simulith running ([quickstart](../../../quickstart.md))
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Bash + `zip` (Git Bash on Windows; `python` zip fallback supported)
- **[JDK](https://adoptium.net/)** on PATH (`java` + `javac`) to compile `App.class`

## Environment

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
# Native / :4566
export AWS_ENDPOINT=http://127.0.0.1:4566
# Docker all-in-one
# export AWS_ENDPOINT=http://127.0.0.1:9080/runtime

export FUNCTION_NAME=cli-java-demo-fn
# Optional: java11 | java17 | java21 (default java17)
# export JAVA_RUNTIME=java17
```

Run from this directory:

```bash
cd runtime/examples/aws-cli/lambda-java
```

## Scripts

| Script | AWS operation | Simulith API |
| --- | --- | --- |
| [`01-create-function.sh`](01-create-function.sh) | `create-function` | CreateFunction (`java17`, zip with `App.class`) |
| [`02-update-configuration.sh`](02-update-configuration.sh) | `update-function-configuration` | UpdateFunctionConfiguration |
| [`03-invoke.sh`](03-invoke.sh) | `invoke` | InvokeFunction (sync) |

```bash
./01-create-function.sh
./03-invoke.sh
./02-update-configuration.sh
./03-invoke.sh                    # GREETING=hello-from-java-cli
```

Cleanup:

```bash
aws lambda delete-function --function-name "$FUNCTION_NAME" --endpoint-url "$AWS_ENDPOINT"
```

## Build notes

- Handler format: `App::handleRequest` (`ClassName::methodName`).
- Compile with `javac --release 11` so the zip runs on `java11`, `java17`, and `java21`.
- Class files live at the **zip root** (not `App/` package path).

## Limits

- Dummy IAM role ARN only (no `aws_iam_role`)
- Single-class handler; no layers, VPC, or aliases
- See [lambda.md](../../../lambda.md) (Java) and [compatibility-matrix.md](../../../compatibility-matrix.md)

## Related

- Node.js CLI demo: [`../lambda/`](../lambda/)
- Go `provided.al2023` demo: [`../lambda-go/`](../lambda-go/)
- Terraform module: [`../../terraform/lambda/`](../../terraform/lambda/)
