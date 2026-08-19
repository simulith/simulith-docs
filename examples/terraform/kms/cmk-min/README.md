# Terraform — KMS cmk-min

Minimum CMK + alias + Secrets Manager secret with `kms_key_id`. `enable_key_rotation = true` so unmodified `aws_kms_key` rotation applies.

**Green path:** `terraform apply` and `terraform destroy` with `-parallelism=1` against Simulith on `:4566`.

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
