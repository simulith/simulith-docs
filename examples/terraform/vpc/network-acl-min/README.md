# VPC network-acl-min — Simulith

Custom Network ACL (ingress/egress allow-all + subnet association). Metadata only — rules are not enforced on packets; AWS SDKs still talk to the Simulith HTTP endpoint.

Start Simulith locally, then:

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
terraform destroy -var-file=terraform.tfvars -auto-approve
```

**Green path:** `terraform apply -parallelism=1` then **`terraform destroy -parallelism=1`**.
