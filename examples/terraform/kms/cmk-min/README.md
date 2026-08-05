# Terraform — KMS cmk-min

Minimum CMK + alias + Secrets Manager secret with `kms_key_id`.

## Prerequisites

1. Simulith running on `:4566`
2. Terraform >= 1.5

## Apply / destroy

```bash
cd runtime/examples/terraform/kms/cmk-min
terraform init
terraform apply -var-file=terraform.tfvars -parallelism=1
terraform destroy -var-file=terraform.tfvars -parallelism=1
```

Use `terraform.tfvars.native.example` when running against host `:4566` without the Console proxy.
