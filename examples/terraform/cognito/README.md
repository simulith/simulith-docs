# Terraform — Cognito User Pool (Simulith)

Green path for `aws_cognito_user_pool` (OPTIONAL software-token MFA) + client + group against Simulith.

## Prerequisites

- Simulith running (`simulith start` or Docker) on `:4566`
- Terraform >= 1.6

## Apply

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
```

JWKS:

```bash
curl -s "$(terraform output -raw jwks_url)"
```

## Destroy

```bash
terraform destroy -var-file=terraform.tfvars -auto-approve
```

## Limits

See [`runtime/docs/cognito.md`](../../../cognito.md). Domain / Hosted UI not in this module.
