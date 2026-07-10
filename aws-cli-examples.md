# AWS CLI examples — Simulith runtime

Copy-paste **AWS CLI v2** commands for MVP **DynamoDB** and **SQS** against Simulith.

> **New to Simulith?** Complete the [Quickstart](quickstart.md) first (run server, optional seed, minimal smoke test).

This guide is the **canonical CLI reference**. Service behavior, protocol details, and deviation tables live in [dynamodb.md](dynamodb.md) and [sqs.md](sqs.md).

---

## Prerequisites

- Simulith running on port **4566** ([quickstart](quickstart.md) — Docker or native)
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed
- Bash-style shell (Git Bash or WSL on Windows)

Simulith accepts any credentials when SigV4 validation is off (default). Set a region on every command.

---

## Common flags

Every example uses:

| Flag | Value (native / `:4566` published) | Value (Docker all-in-one) |
| --- | --- | --- |
| `--endpoint-url` | `http://127.0.0.1:4566` | `http://127.0.0.1:9080/runtime` |
| `--region` | `us-east-1` | `us-east-1` |

Optional shell helpers:

```bash
# Native Go, docker compose, or all-in-one + runtime-port overlay
export AWS_ENDPOINT=http://127.0.0.1:4566

# Docker all-in-one (Console http://localhost:9080)
# export AWS_ENDPOINT=http://127.0.0.1:9080/runtime

export AWS_DEFAULT_REGION=us-east-1
```

Then append to each command:

```bash
--endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

**Run the `export` lines above before copying any example block.**

**Git Bash (Windows):** if paths or URLs are rewritten, set `export MSYS2_ARG_CONV_EXCL="*"` before `file://` arguments.

Endpoint matrix (Terraform + Console): [terraform-integration.md — Endpoint matrix](terraform-integration.md#endpoint-matrix).

---

## DynamoDB

MVP operations: CreateTable, DescribeTable, DeleteTable, ListTables, Put/Get/Update/DeleteItem, Query, Scan.

### Create a table

```bash
aws dynamodb create-table \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --table-name Music \
  --attribute-definitions AttributeName=Artist,AttributeType=S \
  --key-schema AttributeName=Artist,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### DescribeTable

```bash
aws dynamodb describe-table \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --table-name Music
```

### ListTables

```bash
aws dynamodb list-tables \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

# Pagination (optional)
aws dynamodb list-tables \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --limit 1
```

### PutItem / GetItem

```bash
aws dynamodb put-item \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --table-name Music \
  --item '{"Artist":{"S":"Acme Band"},"AlbumTitle":{"S":"Songs About Life"}}'

aws dynamodb get-item \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --table-name Music \
  --key '{"Artist":{"S":"Acme Band"}}'
```

### BatchWriteItem (seed from JSON)

Up to **25** put/delete requests per call. Example fixture for the Terraform **user-table** module: [`user-table/user.json`](examples/terraform/dynamodb/user-table/user.json). Full walkthrough (Go, Docker, Terraform): [`user-table/README.md`](examples/terraform/dynamodb/user-table/README.md).

```bash
cd runtime/examples/terraform/dynamodb/user-table
export TABLE_NAME=$(terraform output -raw table_name)   # after terraform apply

aws dynamodb batch-write-item \
  --request-items file://user.json \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

The top-level key in `user.json` must match `$TABLE_NAME`.

### Query / Scan

```bash
aws dynamodb query \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --table-name Music \
  --key-condition-expression "Artist = :a" \
  --expression-attribute-values '{":a":{"S":"Acme Band"}}'

aws dynamodb scan \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --table-name Music
```

### UpdateItem / DeleteItem

```bash
aws dynamodb update-item \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --table-name Music \
  --key '{"Artist":{"S":"Acme Band"}}' \
  --update-expression "SET AlbumTitle = :t" \
  --expression-attribute-values '{":t":{"S":"Greatest Hits"}}'

aws dynamodb delete-item \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --table-name Music \
  --key '{"Artist":{"S":"Acme Band"}}'
```

### DeleteTable

```bash
aws dynamodb delete-table \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --table-name Music
```

Removes the table and all items. Simulith deletes immediately (no async `DELETING` state). Use for teardown and `terraform destroy` on DynamoDB examples.

See [dynamodb.md](dynamodb.md) for expression limits, attribute types, and AWS deviations.

---

## SQS

MVP operations: CreateQueue, SendMessage, SendMessageBatch, ReceiveMessage, DeleteMessage, DeleteMessageBatch, ChangeMessageVisibility, ChangeMessageVisibilityBatch, GetQueueAttributes, GetQueueUrl.

Queue URLs follow: `http://127.0.0.1:4566/000000000000/{queueName}` (account `000000000000`).

Re-running `create-queue` with the same name returns the existing URL when attributes match (Terraform-friendly). Different attributes → `QueueAlreadyExists`.

### Full message loop

```bash
QUEUE_URL=$(aws sqs create-queue \
  --queue-name my-queue \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --output text)

aws sqs send-message \
  --queue-url "$QUEUE_URL" \
  --message-body "hello from simulith" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

RECEIPT=$(aws sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --query 'Messages[0].ReceiptHandle' \
  --output text)

aws sqs delete-message \
  --queue-url "$QUEUE_URL" \
  --receipt-handle "$RECEIPT" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### SendMessageBatch / DeleteMessageBatch

```bash
aws sqs send-message-batch \
  --queue-url "$QUEUE_URL" \
  --entries Id=1,MessageBody=first Id=2,MessageBody=second \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

HANDLES=$(aws sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --max-number-of-messages 10 \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --query 'Messages[*].[MessageId,ReceiptHandle]' --output text)

# Build delete batch entries (Id + ReceiptHandle per line)
ENTRIES=""
while read -r mid handle; do
  ENTRIES+=" Id=${mid},ReceiptHandle=${handle}"
done <<< "$HANDLES"

aws sqs delete-message-batch \
  --queue-url "$QUEUE_URL" \
  --entries $ENTRIES \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Check `Failed` in batch responses even when the HTTP status is 200.

### CreateQueue

```bash
aws sqs create-queue \
  --queue-name my-queue \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### GetQueueUrl

Resolve `QueueUrl` by name (after create or [`simulith seed`](seed.md) `demo-queue`):

```bash
aws sqs get-queue-url \
  --queue-name demo-queue \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### ListQueues

List all queue URLs (optional prefix; pagination with `--max-results` and `--next-token`):

```bash
aws sqs list-queues \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

aws sqs list-queues \
  --queue-name-prefix demo \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### DeleteQueue

Remove a queue and all its messages (e.g. after tests or before recreating the same name):

```bash
aws sqs delete-queue \
  --queue-url "$QUEUE_URL" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### PurgeQueue

Empty a queue without deleting it (messages only):

```bash
aws sqs purge-queue \
  --queue-url "$QUEUE_URL" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Re-purging the same queue within 60 seconds returns `PurgeQueueInProgress`.

### ChangeMessageVisibility

Extend or shorten visibility for an in-flight message (workers that need more processing time):

```bash
aws sqs change-message-visibility \
  --queue-url "$QUEUE_URL" \
  --receipt-handle "$RECEIPT_HANDLE" \
  --visibility-timeout 0 \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Use `--visibility-timeout 0` to make the message immediately available again. Invalid or stale handles return `ReceiptHandleIsInvalid`.

Batch (up to 10 entries):

```bash
aws sqs change-message-visibility-batch \
  --queue-url "$QUEUE_URL" \
  --entries Id=1,ReceiptHandle="$RECEIPT_HANDLE",VisibilityTimeout=60 \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### GetQueueAttributes

```bash
aws sqs get-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attribute-names All \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### SetQueueAttributes

Update queue metadata (timeouts, retention, DLQ policy). Attributes merge into stored JSON; unsupported names (e.g. `Policy`, FIFO/KMS) are rejected.

```bash
# Visibility timeout
aws sqs set-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attributes VisibilityTimeout=90 \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

# RedrivePolicy (stored for GetQueueAttributes; Simulith does not redrive messages to DLQ yet)
# Use a JSON map for --attributes when the value contains quotes (Git Bash / AWS CLI v2).
aws sqs set-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attributes '{ "RedrivePolicy": "{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:my-dlq\",\"maxReceiveCount\":5}" }' \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

# Verify
aws sqs get-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attribute-names RedrivePolicy VisibilityTimeout \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### SendMessage

Requires `QUEUE_URL` from CreateQueue or the full loop above.

```bash
aws sqs send-message \
  --queue-url "$QUEUE_URL" \
  --message-body "hello from simulith" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Optional: `--delay-seconds 0` (0–900).

### ReceiveMessage

```bash
aws sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Save `ReceiptHandle` from the response for DeleteMessage. Optional: `--max-number-of-messages`, `--visibility-timeout`, `--wait-time-seconds` (0–20 long poll).

```bash
# Long poll up to 5 seconds on an empty queue (returns empty when wait expires)
aws sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --wait-time-seconds 5 \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### DeleteMessage

```bash
aws sqs delete-message \
  --queue-url "$QUEUE_URL" \
  --receipt-handle "$RECEIPT" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

See [sqs.md](sqs.md) for protocol notes, FIFO limits, and error codes.

---

## SSM Parameter Store

Use JSON 1.1 targets (`AmazonSSM.*`). See [ssm.md](ssm.md).

**Git Bash on Windows:** `--name /app/demo/api-url` is rewritten to `C:/Program Files/Git/app/demo/api-url` (see `aws … --debug`). Fix: `export MSYS2_ARG_CONV_EXCL="*"` or `export MSYS_NO_PATHCONV=1` in that shell before SSM commands. See [quickstart troubleshooting](quickstart.md#troubleshooting).

### PutParameter

```bash
aws ssm put-parameter \
  --name "/app/demo" \
  --value "hello" \
  --type String \
  --overwrite \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### GetParameter

```bash
aws ssm get-parameter \
  --name "/app/demo" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

### DeleteParameter

```bash
aws ssm delete-parameter \
  --name "/app/demo" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Removes the parameter; a subsequent `get-parameter` for the same name returns `ParameterNotFound`.

### DeleteParameters

```bash
aws ssm delete-parameters \
  --names "/app/demo/temp-a" "/app/demo/temp-b" "/app/demo/missing" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Deletes up to 10 names in one call. Missing or invalid names appear in `InvalidParameters` in the response (HTTP 200); existing names are listed under `DeletedParameters`.

### GetParameters

```bash
aws ssm get-parameters \
  --names "/app/demo/env" "/app/demo/api-url" "/app/missing" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Returns `Parameters` (sorted by name) and `InvalidParameters` for names that do not exist.

### GetParametersByPath

```bash
# One level under /app/demo (default Recursive=false)
aws ssm get-parameters-by-path \
  --path /app/demo \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

# All descendants (seed includes /app/demo/api-url, /app/demo/env)
aws ssm get-parameters-by-path \
  --path /app/demo \
  --recursive \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Optional pagination: `--max-results 2` and `--starting-token` (from `NextToken` in the prior response).

### Terraform (SSM)

Provision parameters with the AWS provider against Simulith (same endpoint as CLI). Full module: [`examples/terraform/ssm/`](examples/terraform/ssm/).

**Prerequisites:** `simulith start` on port 4566; Terraform >= 1.0; provider `hashicorp/aws` ~> 5.0.

Provider block (SSM endpoint only — add `dynamodb` / `sqs` if combined):

```hcl
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ssm = "http://127.0.0.1:4566"
  }
}
```

Apply and verify:

```bash
cd runtime/examples/terraform/ssm
terraform init
terraform apply

export AWS_ENDPOINT=http://127.0.0.1:4566
export AWS_DEFAULT_REGION=us-east-1

aws ssm get-parameter --name /app/tf-demo/log-level \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

# Optional: after simulith seed, list /app/demo + /app/tf-demo
aws ssm get-parameters-by-path --path /app --recursive \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Teardown: `terraform destroy` (Simulith **DeleteParameter** removes managed names).

Path-prefix reads in Terraform: copy [`path-data.tf.example`](examples/terraform/ssm/path-data.tf.example) after `simulith seed`. See [terraform-integration.md](terraform-integration.md#ssm--aws_ssm_parameter).

**Git Bash:** use `MSYS2_ARG_CONV_EXCL="*"` for CLI verify steps with `/app/...` paths (same as above).

---

## Lambda

Function CRUD is available locally (v0.15.0+). **InvokeFunction** is not shipped yet — see [lambda.md](lambda.md).

```bash
# Create a zip from a Node.js handler
cat > /tmp/index.js <<'EOF'
exports.handler = async (event) => ({
  statusCode: 200,
  body: JSON.stringify({ message: 'hello from simulith' })
});
EOF
cd /tmp && zip function.zip index.js

aws lambda create-function \
  --function-name my-fn \
  --runtime nodejs20.x \
  --handler index.handler \
  --role arn:aws:iam::000000000000:role/r \
  --zip-file fileb:///tmp/function.zip \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

aws lambda list-functions \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

aws lambda get-function \
  --function-name my-fn \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

aws lambda delete-function \
  --function-name my-fn \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

# Invoke (requires node or python3 on PATH)
aws lambda invoke \
  --function-name my-fn \
  --payload '{"key":"value"}' \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  /tmp/lambda-out.json
```

---

## Seeded data

After [`simulith seed`](seed.md) (Demo table + `demo-queue` + SSM `/app/demo/*`):

```bash
aws dynamodb describe-table \
  --table-name Demo \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

aws dynamodb get-item \
  --table-name Demo \
  --key '{"Id":{"S":"1"}}' \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

aws sqs receive-message \
  --queue-url http://127.0.0.1:4566/000000000000/demo-queue \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

aws ssm get-parameter \
  --name /app/demo/api-url \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

aws ssm get-parameter \
  --name /app/demo/env \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

aws ssm get-parameters-by-path \
  --path /app/demo \
  --recursive \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Expected: item `Alice` (Id `1`); message body `hello from seed`; SSM values `http://localhost:8080` and `local`; path listing returns at least two parameters.

---

## MVP limitations (summary)

| Area | Simulith MVP |
| --- | --- |
| DynamoDB ListTables | **Available** — names from SQLite; default page size 100 |
| DynamoDB GSI / LSI Query | Not supported |
| SQS FIFO queues | Not supported |
| SQS long polling | Short poll only |
| SQS SendMessageBatch / DeleteMessageBatch | Available (SML-039) |
| SSM Parameter Store | Put/Get/Delete + GetParameters/GetParametersByPath; Terraform [`examples/terraform/ssm/`](examples/terraform/ssm/); see [ssm.md](ssm.md) |
| Lambda | InvokeFunction sync (node/python on PATH), UpdateFunctionCode; see [lambda.md](lambda.md) |

Full deviation tables:

- [dynamodb.md — Local behavior deviations](dynamodb.md#local-behavior-deviations)
- [sqs.md — Deviations (MVP)](sqs.md#deviations-mvp)

---

## Related

- [quickstart.md](quickstart.md) — onboarding
- [sdk-examples.md](sdk-examples.md) — Go + Node.js SDK cookbook
- [terraform-integration.md](terraform-integration.md) — Terraform / IaC cookbook
- [compatibility.md](compatibility.md) — `simulith verify dynamodb`
- protocol.md — AWS JSON + Query wire formats
- smithy-contracts.md — API models
