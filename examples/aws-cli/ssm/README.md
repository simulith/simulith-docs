# AWS CLI — SSM Parameter Store path prefix on Simulith

Three scripts demonstrating **path-prefix reads** with `GetParametersByPath`: write a parameter, list everything under a prefix, then fetch one by name.

**Source pattern:** [AWS Systems Manager Parameter Store — working with parameters](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-su-create.html) + [GetParametersByPath](https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_GetParametersByPath.html).

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

export PARAM_PATH=/app/cli-demo
export PARAM_NAME=/app/cli-demo/log-level
export PARAM_VALUE=info
```

**Git Bash on Windows:** export `MSYS2_ARG_CONV_EXCL="*"` before SSM commands so `/app/...` is not rewritten to a Windows path. See [aws-cli-examples.md — SSM](../../../aws-cli-examples.md#ssm-parameter-store).

Run from this directory:

```bash
cd runtime/examples/aws-cli/ssm
```

## Scripts

| Script | AWS operation | Simulith API |
| --- | --- | --- |
| [`01-put-parameter.sh`](01-put-parameter.sh) | `ssm put-parameter` | PutParameter |
| [`02-get-parameters-by-path.sh`](02-get-parameters-by-path.sh) | `ssm get-parameters-by-path` | GetParametersByPath |
| [`03-get-parameter.sh`](03-get-parameter.sh) | `ssm get-parameter` | GetParameter |

```bash
./01-put-parameter.sh
./02-get-parameters-by-path.sh
./03-get-parameter.sh
```

Cleanup:

```bash
aws ssm delete-parameter \
  --name "$PARAM_NAME" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
```

## Cross-service: Terraform path readback

For Terraform **`aws_ssm_parameters_by_path`** refresh on a large parameter set (27× `/SIMULITH/DEV/*`), see [`../../terraform/ssm/parameters/`](../../terraform/ssm/parameters/).

After apply:

```bash
terraform output parameters_by_path_count   # should match parameter_count (27 locally)
terraform output -json parameters_by_path_names | head
```

Verify with CLI (same path as Terraform):

```bash
export MSYS2_ARG_CONV_EXCL="*"   # Git Bash only
aws ssm get-parameters-by-path \
  --path /SIMULITH/DEV \
  --recursive \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
```

## Limits

- String parameters only in these scripts (SecureString supported by Simulith — see Terraform module)
- No ParameterFilters / labels / StringList
- See [ssm.md](../../../ssm.md) and [compatibility-matrix.md](../../../compatibility-matrix.md)

## Related

- Minimal Terraform demo: [`../../terraform/ssm/`](../../terraform/ssm/)
- Platform parameters + path data source: [`../../terraform/ssm/parameters/`](../../terraform/ssm/parameters/)
- Seed fixture `/app/demo/*`: [seed.md](../../../seed.md)
