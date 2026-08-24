# SES root — Simulith green path (production pattern)

Email identity + OTP template aligned with unmodified **`ses/`** roots (`from_email`, `otp_template_name` outputs for `parameters/` remote state). No SMTP delivery — Send* captured in local outbox.

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
terraform destroy -var-file=terraform.tfvars -auto-approve
```

Native Simulith: `simulith_endpoint = "http://127.0.0.1:4566"`.

See [`runtime/docs/ses.md`](../../../ses.md) · parameters twin [`../ssm/parameters/`](../ssm/parameters/).
