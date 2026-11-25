# EC2 asg-min — Simulith

Green path for **`aws_launch_template`** + **`aws_autoscaling_group`** against Simulith (`autoscaling` + `ec2` on port 4566).

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -parallelism=1 -auto-approve
terraform destroy -var-file=terraform.tfvars -parallelism=1 -auto-approve
```

Use `-parallelism=1` on Simulith (same bar as `instance-min`).

**Verify:** `simulith verify ec2 --filter autoscaling-launch-template-group --skip-aws`
