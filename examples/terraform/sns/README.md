# SNS topic + SQS subscription — Simulith green path

`aws_sns_topic` + `aws_sns_topic_subscription` (protocol **sqs**) aligned with CloudWatch alarm notification patterns. Simulith supports **lambda** and **sqs** subscriptions only (no email/SMS).

**Prerequisite:** Simulith listening on port **4566** ([Quickstart](../../../quickstart.md)).

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -var-file=terraform.tfvars -auto-approve
terraform destroy -var-file=terraform.tfvars -auto-approve
```

Native Simulith: `simulith_endpoint = "http://127.0.0.1:4566"`.

After apply, optional smoke:

```bash
aws sns publish --topic-arn "$(terraform output -raw topic_arn)" \
  --message '{"AlarmName":"demo"}' --endpoint-url http://127.0.0.1:4566
aws sqs receive-message --queue-url "$(terraform output -raw queue_url)" \
  --endpoint-url http://127.0.0.1:4566
```

See [`runtime/docs/sns.md`](../../../sns.md) · [`runtime/docs/terraform-integration.md`](../../../terraform-integration.md).
