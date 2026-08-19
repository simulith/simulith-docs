# VPC nat-gateway-min — Simulith

Public NAT Gateway (EIP + NAT in a public subnet, default route on a private table). Metadata only — no NAT/IGW packet forwarding; AWS SDKs still talk to the Simulith HTTP endpoint.

Start Simulith locally, then:

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
terraform destroy -var-file=terraform.tfvars -auto-approve
```

**Green path:** `terraform apply -parallelism=1` then **`terraform destroy -parallelism=1`**.
