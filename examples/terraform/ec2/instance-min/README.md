# EC2 instance-min — Simulith

Minimum **`aws_instance`** green path: VPC, subnet, security group, and one metadata-only instance (no SSH or boot on Simulith).

Start Simulith locally, then:

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve
terraform destroy -var-file=terraform.tfvars -parallelism=1 -auto-approve
```

Use a real AMI id when targeting AWS; Simulith accepts any `ami-*` string and persists instance metadata only.

**Green path:** apply then destroy with **`-parallelism=1`** — no `simulith reset` required.
