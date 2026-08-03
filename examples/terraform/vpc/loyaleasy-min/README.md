# VPC loyaleasy-min — Simulith

Minimum loyaleasy networking slice: VPC, IGW, route tables, gateway endpoints (S3/DynamoDB), one database subnet, and Postgres security group.

Start Simulith locally, then:

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
terraform destroy -var-file=terraform.tfvars -auto-approve
```

Single-root example (no remote state S3). Full prod layout uses separate `vpc/` and `subnets/` modules in loyaleasy.
