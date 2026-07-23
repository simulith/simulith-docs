# Terraform — DynamoDB + SQS fan-out (no Streams)

Cross-service pattern: persist an **event record** in **DynamoDB** and enqueue an **async notification** on **SQS** — application-level dual-write, not DynamoDB Streams.

**Source pattern:** [AWS — asynchronous processing](https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html) (Simulith uses explicit PutItem + SendMessage instead of stream/Lambda triggers).

## Prerequisites

- Simulith running ([quickstart](../../../quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x

## Workspaces and var-files

| Target | Workspace | Var file | Default names |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `terraform.tfvars` | table `events-fanout-tf`, queue `events-fanout-tf-queue` |
| **Real AWS dev** | `aws` | `terraform.aws-dev.tfvars` | (create from example when needed) |

Provider `endpoints` block routes **DynamoDB** and **SQS** to Simulith. See [endpoint matrix](../../../terraform-integration.md#endpoint-matrix).

## Apply (Simulith)

```bash
cd runtime/examples/terraform/dynamodb-sqs
cp terraform.tfvars.native.example terraform.tfvars
terraform init
terraform workspace select default
terraform apply -parallelism=1
```

Use **`-parallelism=1`** on apply and destroy.

Expected plan: **2 to add** (table + queue).

Verify fan-out with CLI scripts (after export from outputs):

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566
export TABLE_NAME="$(terraform output -raw table_name)"
export QUEUE_URL="$(terraform output -raw queue_url)"

cd ../../aws-cli/dynamodb-sqs
./01-put-item.sh
./02-send-message.sh
./03-receive-message.sh
```

## Destroy (Simulith)

```bash
terraform destroy -parallelism=1
```

Expected plan: **2 to destroy**. SQS delete may take up to ~90s on Simulith; retry destroy if the waiter times out (see [terraform-integration.md](../../../terraform-integration.md#when-to-use-simulith-reset)).

## Simulith limits

- No DynamoDB Streams, Lambda triggers, or FIFO queues
- Standard SQS only; short poll on receive
- Table: single hash key `Id` (String), on-demand billing
- Fan-out is **manual dual-write** — not transactional across DDB + SQS

## Related

- Green path DynamoDB: [`../dynamodb/music/`](../dynamodb/music/)
- Green path SQS: [`../sqs/`](../sqs/)
- AWS CLI fan-out scripts: [`../../aws-cli/dynamodb-sqs/`](../../aws-cli/dynamodb-sqs/)
- [dynamodb.md](../../../dynamodb.md) · [sqs.md](../../../sqs.md)
- [terraform-integration.md — Honest integration examples](../../../terraform-integration.md#honest-integration-examples)
