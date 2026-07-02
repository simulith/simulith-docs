# Terraform — SQS on Simulith and AWS

`aws_sqs_queue` **apply** and **destroy** work on Simulith and real AWS (provider calls **CreateQueue**, **GetQueueAttributes**, **DeleteQueue**).

## Prerequisites

- Simulith running for local apply ([quickstart](../../../docs/quickstart.md))
- Terraform ≥ 1.6, AWS provider ~> 5.x
- AWS credentials configured for real AWS apply

## Workspaces and var-files

Use **workspaces** to isolate Terraform **state**. Use **var-files** to pick Simulith vs AWS endpoint.

| Target | Workspace | Var file | Queue name (default) |
| --- | --- | --- | --- |
| **Simulith local** | `default` | `terraform.tfvars` | `app-queue-tf` |
| **Real AWS dev** | `aws` | `terraform.aws-dev.tfvars` | `simulith-dev-app-queue-tf` |

The workspace name does **not** switch the endpoint — `use_simulith_endpoint` in the var file does.

> **Pitfall:** `terraform workspace select aws` + bare `terraform apply` still auto-loads **`terraform.tfvars`** (Simulith). Always pass `-var-file=terraform.aws-dev.tfvars` for AWS.

### Simulith endpoint

| How you run Simulith | `simulith_endpoint` |
| --- | --- |
| Docker all-in-one (Console `:9080`) | `http://127.0.0.1:9080/runtime` — default in `terraform.tfvars.example` |
| Native / host `:4566` | `http://127.0.0.1:4566` — `terraform.tfvars.native.example` |

CLI and Console must use the **same** runtime. See [endpoint matrix](../../../docs/terraform-integration.md#endpoint-matrix).

## Apply (Simulith)

```bash
cd runtime/examples/terraform/sqs
cp terraform.tfvars.example terraform.tfvars   # once
terraform init
terraform workspace select default
terraform apply
```

**Destroy (Simulith):** expect **~60–90 seconds** — DeleteQueue tombstones the queue; after the grace window Terraform’s waiter sees `QueueDoesNotExist` and completes (provider timeout default: 3m).

```bash
terraform workspace select default
terraform destroy
```

Use the **same** `terraform.tfvars` / endpoint as apply. If destroy times out at 3m, rebuild Simulith (includes JSON `QueueDoesNotExist` fix) or `terraform state rm aws_sqs_queue.app` once the queue is gone in Console/CLI.

See [Green path IaC](../../../docs/terraform-integration.md#green-path-iac).

## Apply (real AWS dev)

```bash
terraform workspace select -or-create aws
cp terraform.aws-dev.tfvars.example terraform.aws-dev.tfvars   # once
terraform apply -var-file=terraform.aws-dev.tfvars
terraform destroy -var-file=terraform.aws-dev.tfvars
```

Verify in AWS Console → SQS → **us-east-1**, or:

```bash
aws sqs get-queue-url --queue-name simulith-dev-app-queue-tf --region us-east-1
```

## Manual test (AWS CLI — Simulith)

After apply (or after [seed](../../../docs/seed.md) for `demo-queue`):

```bash
export AWS_ENDPOINT=http://127.0.0.1:9080/runtime
export AWS_DEFAULT_REGION=us-east-1

# Git Bash on Windows:
# export MSYS2_ARG_CONV_EXCL="*"

aws sqs list-queues --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

QUEUE_URL=$(aws sqs get-queue-url --queue-name app-queue-tf \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" --output text)

aws sqs send-message --queue-url "$QUEUE_URL" --message-body "hello from cli" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"

aws sqs receive-message --queue-url "$QUEUE_URL" \
  --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
```

Full loop (send → receive → delete): [aws-cli-examples.md — SQS](../../../docs/aws-cli-examples.md#sqs).

## Console (Simulith only)

1. Open **http://localhost:9080** (all-in-one).
2. Dashboard → **Seed demo data** (optional — creates `demo-queue` with one message).
3. **SQS** tab → **Refresh** → select **`app-queue-tf`** (after Terraform apply) or **`demo-queue`** (after seed).
4. **Peek** — non-destructive view of messages.
5. **Send message** / **Receive message** / **Delete** — full consume cycle (needs receipt handle from Receive).
6. **Purge queue** — empty all messages.

Peek does not expose receipt handles; use **Receive message** before **Delete**. AWS queues are not visible in the Console.

## Limitations

- Standard queues only (no `.fifo`)
- [sqs.md](../../../docs/sqs.md) — MVP deviations

## Related

- [standard-queue.tf.example](./standard-queue.tf.example) — minimal snippet
- [terraform-integration.md — Workspaces](../../../docs/terraform-integration.md#workspaces-and--var-file-user-table--real-aws)
- [console.md](../../../docs/console.md)
