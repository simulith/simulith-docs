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
| `Publish` | Store message body (local delivery log) |
| `ListTopics` | List topic ARNs |
| `GetTopicAttributes` | Basic attributes |
| `DeleteTopic` | Remove topic and messages |

## Primary use cases

- **CloudWatch alarms** — metric alarms publish JSON to SNS topics in `AlarmActions` / `OKActions` / `InsufficientDataActions`. See [cloudwatch-alarms.md](cloudwatch-alarms.md).
- **CLI / Terraform** — create topics and publish test messages locally.

## Limits

- No subscriptions, email, SMS, or Lambda/SQS fan-out yet
- S3 bucket notifications to SNS not supported yet
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
```

## Persistence

Topics and published messages are stored in SQLite (`sns_topics`, `sns_messages`). Cleared on `simulith reset`.

## Matrix

See [compatibility-matrix.md](compatibility-matrix.md) · Backlog:
