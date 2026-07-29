# EventBridge schedule → Lambda — green path on Simulith

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
terraform destroy -var-file=terraform.tfvars -auto-approve
```

See [`runtime/docs/eventbridge.md`](../../../eventbridge.md).
