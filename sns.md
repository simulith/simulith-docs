# Amazon SNS — Simulith

**SNS topics + publish** for local alarm notifications, CLI/Terraform `aws_sns_topic`, and message inspection.

## Overview

- **SigV4 service name:** `sns`
- **Protocol:** AWS Query (`application/x-www-form-urlencoded`)
- **API version:** `2010-03-31`
- **Same port** as other services (default `:4566`)

## Operations

| Operation | Notes |
| --- | --- |
| `CreateTopic` | Persist topic metadata |
| `Subscribe` / `Unsubscribe` / `ListSubscriptionsByTopic` | Protocols **`lambda`**, **`sqs`** |
| `Publish` | Local delivery log + fan-out to subscriptions |
| `ListTopics` | List topic ARNs |
| `GetTopicAttributes` | Basic attributes |
| `SetTopicAttributes` | Accept provider tuning attrs (Terraform) |
| `GetSubscriptionAttributes` | SQS/Lambda subscriptions confirmed |
| `DeleteTopic` | Remove topic, subscriptions, and messages |

## Primary use cases

- **CloudWatch alarms** — metric alarms publish JSON to SNS topics in `AlarmActions` / `OKActions` / `InsufficientDataActions`. See [cloudwatch-alarms.md](cloudwatch-alarms.md).
- **CLI / Terraform** — create topics and publish test messages locally.

## Limits

- **Fan-out:** `Publish` invokes Lambda asynchronously (SNS event shape) and enqueues SQS notification JSON; no email/SMS/mobile
- S3 → SNS: `TopicConfiguration` on bucket notifications; example [`examples/aws-cli/s3-sns/`](examples/aws-cli/s3-sns/)
- **`simulith verify sns`** — 2 scenarios (topic lifecycle + SQS fan-out smoke)
- Topics must exist before `Publish` (including alarm dispatch)

## Seed

Default `simulith seed` includes topic **`demo-alarm`** (`arn:aws:sns:us-east-1:000000000000:demo-alarm`).

## Example (AWS CLI)

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
EP=http://localhost:4566

aws sns create-topic --name my-topic --endpoint-url "$EP"
aws sns publish --topic-arn arn:aws:sns:us-east-1:000000000000:my-topic \
  --message '{"hello":"world"}' --endpoint-url "$EP"
aws sns list-topics --endpoint-url "$EP"

# Subscribe Lambda or SQS, then publish (fan-out)
aws sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:my-topic \
  --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:my-queue --endpoint-url "$EP"
```

## Terraform

Green-path module: [`examples/terraform/sns/`](examples/terraform/sns/) — `aws_sns_topic` + `aws_sqs_queue` + `aws_sns_topic_subscription` (protocol **sqs**). Provider `endpoints { sns = … sqs = … }` on `:4566`. See [terraform-integration.md](terraform-integration.md).

```bash
cd runtime/examples/terraform/sns
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply -var-file=terraform.tfvars -auto-approve
```

## Persistence

Topics, subscriptions, and published messages are stored in SQLite (`sns_topics`, `sns_subscriptions`, `sns_messages`). Cleared on `simulith reset`.

## Verify

```bash
simulith verify sns --skip-aws          # Simulith-only (2 scenarios)
simulith verify sns                     # AWS parity on topic/publish subset
simulith verify sns --filter topic      # prefix filter
```

## Matrix

See [compatibility-matrix.md](compatibility-matrix.md) · Backlog:
