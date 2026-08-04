# Terraform — KMS loyaleasy-min

Minimum loyaleasy `secrets/` subset: CMK + alias + Secrets Manager secret with `kms_key_id`.

## Prerequisites

- Simulith running (`simulith start` or Docker)
- Terraform >= 1.5

## Apply (Simulith)

```bash
cd runtime/examples/terraform/kms/loyaleasy-min
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -parallelism=1
```

## Destroy

```bash
terraform destroy -var-file=terraform.tfvars -parallelism=1
```

## Outputs

- `kms_key_arn` — use in proxydb IAM policy (`kms:Decrypt`)
- `secret_arn` — use in RDS Proxy auth block
