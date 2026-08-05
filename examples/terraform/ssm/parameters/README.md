# Platform parameters — SSM Parameter Store (Cloud Posse pattern on Simulith).
#
# https://docs.cloudposse.com/modules/library/aws/ssm-parameter-store/
#
# **Important:** `dev.tfvars` always targets Simulith (`use_simulith_endpoint = true`), even in workspace `aws`.
# For real AWS, use `dev.aws.tfvars` or `prod.tfvars`.

## Prerequisites

- Simulith or AWS credentials (see below)
- Terraform ≥ 1.6
- **Always** use `-parallelism=1` on apply and destroy against Simulith (SQLite / provider refresh)

## Which var-file?

| Target | Workspace | Var file | SSM path prefix |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `dev.tfvars` | `/SIMULITH/DEV/` |
| **Real AWS dev** | `aws` | `dev.aws.tfvars` | `/SIMULITH/DEV/` |
| **Real AWS prod** | `aws` | `prod.tfvars` | `/DEMOAPP/PROD/` |

The workspace name only isolates Terraform **state** — it does **not** switch the provider endpoint. That comes from `use_simulith_endpoint` in the var file.

27 parameters: secrets (`SecureString`), config (`String`), infra refs (VPC, subnets, RDS proxy, Cognito, SES, JWT).

## Run (Simulith local)

**Docker all-in-one:**

```bash
cd runtime/examples/terraform/ssm/parameters
terraform init
terraform workspace select default
terraform apply -var-file=dev.tfvars -parallelism=1
```

**Native `:4566`:** copy `dev.tfvars.native.example` → `dev.tfvars`.

## Run (real AWS dev)

Mock infra via `*_override` variables (`use_remote_state = false`). Set secrets via `TF_VAR_*`:

```bash
terraform workspace select -or-create aws
export TF_VAR_access_key_id=...
export TF_VAR_secret_access_key=...
export TF_VAR_secret_password=...
terraform apply -var-file=dev.aws.tfvars -parallelism=1
```

Verify in **AWS Console** → Systems Manager → Parameter Store → region **us-east-1** → path `/SIMULITH/DEV`.

```bash
aws ssm get-parameters-by-path --path /SIMULITH/DEV --recursive --region us-east-1
# No --endpoint-url — real AWS
```

**Git Bash (Windows):** MSYS rewrites `/SIMULITH/DEV` to a Windows path → `ValidationException`. Before CLI:

```bash
export MSYS2_ARG_CONV_EXCL="*"
aws ssm get-parameters-by-path --path /SIMULITH/DEV --recursive --region us-east-1
```

Do **not** use `//SIMULITH/DEV` (double slash sends a different name). PowerShell/CMD need no extra export. See [aws-cli-examples.md — SSM](../../../../aws-cli-examples.md#ssm-parameter-store).

## Run (real AWS prod)

Requires remote state keys: `{project_name}-proxy-state`, `-subnets-state`, `-secrets-state`, `-cognito-state`, `-ses-state`.

```bash
terraform workspace select aws
terraform apply -var-file=prod.tfvars -parallelism=1
```

## Verify (Simulith)

```bash
export AWS_ENDPOINT=http://127.0.0.1:9080/runtime
export AWS_DEFAULT_REGION=us-east-1

# Git Bash on Windows: export MSYS2_ARG_CONV_EXCL="*" first (same as AWS verify above)
aws ssm get-parameters-by-path --path /SIMULITH/DEV --recursive \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

**Console:** open SSM → path prefix `/SIMULITH/DEV` → Refresh. This example creates **27** parameters; the Console paginates `GetParametersByPath` (10 per page).

## GetParametersByPath (Terraform refresh)

The module includes `data "aws_ssm_parameters_by_path"` on [`path-data.tf`](path-data.tf). After apply, outputs should match managed parameters:

```bash
terraform output parameter_count
terraform output parameters_by_path_count
terraform output -json parameters_by_path_names | head
```

CLI equivalent (Git Bash: `export MSYS2_ARG_CONV_EXCL="*"` first):

```bash
aws ssm get-parameters-by-path --path /SIMULITH/DEV --recursive \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Standalone CLI walkthrough: [`../../../aws-cli/ssm/`](../../../aws-cli/ssm/).

## Destroy

```bash
# Simulith
terraform workspace select default
terraform destroy -var-file=dev.tfvars -parallelism=1

# Real AWS dev (same var-file as apply)
terraform workspace select aws
terraform destroy -var-file=dev.aws.tfvars -parallelism=1
```

## vs original module

| Original | Simulith twin |
| --- | --- |
| `module "store_write"` Cloud Posse | `aws_ssm_parameter "store_write"` + `overwrite = true` |
| `var.env` = `DEV` / `PROD` | Same |
| Remote state always | `use_remote_state` toggle + `*_override` mocks |
| Provider default AWS | `use_simulith_endpoint` → `:9080/runtime` |

## Related

- Minimal SSM demo: [`../`](../../../../README.md)
- [`terraform-integration.md`](../../../../terraform-integration.md)
