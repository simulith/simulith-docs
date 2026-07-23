# AWS CLI — DynamoDB + SQS fan-out on Simulith

Three scripts demonstrating **application-level fan-out**: write a record to DynamoDB, enqueue a notification on SQS, then receive the message. No DynamoDB Streams.

**Source pattern:** [AWS SQS developer guide](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html) + [DynamoDB PutItem](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html#WorkingWithItems.WritingData).

## Prerequisites

- Simulith running ([quickstart](../../../quickstart.md))
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Bash (Git Bash on Windows)
- Table + queue from Terraform apply (recommended) or existing resources

## Environment

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
# Native / :4566
export AWS_ENDPOINT=http://127.0.0.1:4566
# Docker all-in-one
# export AWS_ENDPOINT=http://127.0.0.1:9080/runtime

# From terraform output (runtime/examples/terraform/dynamodb-sqs)
export TABLE_NAME=events-fanout-tf
export QUEUE_URL=http://127.0.0.1:4566/000000000000/events-fanout-tf-queue
export ITEM_ID=cli-event-1
```

Run from this directory:

```bash
cd runtime/examples/aws-cli/dynamodb-sqs
```

## Scripts

| Script | AWS operation | Simulith API |
| --- | --- | --- |
| [`01-put-item.sh`](01-put-item.sh) | `dynamodb put-item` | PutItem |
| [`02-send-message.sh`](02-send-message.sh) | `sqs send-message` | SendMessage |
| [`03-receive-message.sh`](03-receive-message.sh) | `sqs receive-message` | ReceiveMessage |

```bash
./01-put-item.sh
./02-send-message.sh
./03-receive-message.sh
```

Cleanup (after Terraform destroy or manual delete):

```bash
aws dynamodb delete-item \
  --table-name "$TABLE_NAME" \
  --key "{\"Id\":{\"S\":\"$ITEM_ID\"}}" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

## Limits

- No DynamoDB Streams, transactions, or FIFO queues
- Fan-out is **not atomic** across DynamoDB and SQS
- See [dynamodb.md](../../../dynamodb.md), [sqs.md](../../../sqs.md), [compatibility-matrix.md](../../../compatibility-matrix.md)

## Related

- Terraform module: [`../../terraform/dynamodb-sqs/`](../../terraform/dynamodb-sqs/)
- Green paths: [`../../terraform/dynamodb/music/`](../../terraform/dynamodb/music/) · [`../../terraform/sqs/`](../../terraform/sqs/)
