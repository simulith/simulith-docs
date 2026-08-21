# lambda-roles-min IAM on Simulith

Lambda execution role + inline policy subset for local Terraform validation (`aws_iam_role_policy`).

## Apply

```bash
cd runtime/examples/terraform/iam/lambda-roles-min
terraform init
terraform apply -parallelism=1
```

## Destroy

```bash
terraform destroy -parallelism=1
```
