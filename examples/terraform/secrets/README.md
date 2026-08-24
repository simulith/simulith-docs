# Secrets root — Simulith green path (production pattern)

KMS CMK + Secrets Manager secret + interface VPC endpoint aligned with unmodified **`secrets/`** roots. Outputs `secret_name` and `secrets_manager_sg` for `parameters/` remote state.

```bash
cp terraform.tfvars.native.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -parallelism=1
terraform destroy -var-file=terraform.tfvars -parallelism=1
```

Native Simulith: `simulith_endpoint = "http://127.0.0.1:4566"`.

**Note:** `aws_kms_key` omits resource tags — Simulith KMS has no `TagResource` yet (same as [`../kms/cmk-min/`](../kms/cmk-min/)). Other resources keep production-style tags.

See [`runtime/docs/secretsmanager.md`](../../../secretsmanager.md) · [`../kms/cmk-min/`](../kms/cmk-min/) (KMS-only subset).
