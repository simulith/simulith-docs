# SES green path — Simulith

Email identity + template against local Simulith (`:4566`). No SMTP delivery; Send* is captured in the local outbox.

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
terraform destroy -var-file=terraform.tfvars -auto-approve
```

See [`runtime/docs/ses.md`](../../../ses.md).
