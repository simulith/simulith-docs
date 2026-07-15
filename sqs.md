# SQS — Simulith runtime

Local **Amazon SQS** emulation for the MVP Phase 5 subset.

## Protocol

SQS uses **AWS Query** (`application/x-www-form-urlencoded` + **XML** responses), not AWS JSON. Simulith multiplexes `POST /` between JSON (DynamoDB, SSM) and Query (SQS) by `Content-Type` and `Action=` body prefix.

## Implemented operations

| Operation | Status | Notes |
| --- | --- | --- |
| CreateQueue | **Available** | Standard queues only |
| SendMessage | **Available** | Standard queues; body + optional DelaySeconds |
| SendMessageBatch | **Available** | Up to 10 entries; partial success |
| ReceiveMessage | **Available** | Visibility timeout; long/short poll |
| DeleteMessage | **Available** | Receipt handle from ReceiveMessage |
| DeleteMessageBatch | **Available** | Up to 10 entries; partial success |
| ChangeMessageVisibility | **Available** | Extend or shorten in-flight visibility; invalid handle → error |
| ChangeMessageVisibilityBatch | **Available** | Up to 10 entries; partial success |
| GetQueueAttributes | **Available** | QueueArn, timeouts, approximate counts |
| GetQueueUrl | **Available** | Resolve URL by `QueueName` |
| ListQueues | **Available** | List stored `QueueUrl` values; optional prefix and pagination |
| DeleteQueue | **Available** | Remove queue and all messages by `QueueUrl` |
| PurgeQueue | **Available** | Delete all messages; queue remains; 60s throttle |
| SetQueueAttributes | **Available** | Update persisted queue metadata (incl. RedrivePolicy) |

## CreateQueue

Copy-paste CLI: **[aws-cli-examples.md — SQS](aws-cli-examples.md#sqs)**.

Response includes `QueueUrl` like:

```text
http://127.0.0.1:4566/000000000000/my-queue
```

Pattern: `{endpoint}/{accountId}/{queueName}` with default account `000000000000`.

Re-creating a queue with the **same name** returns the **stored** `QueueUrl` when requested attributes match (idempotent). Mismatched attributes return `QueueAlreadyExists`. Only attributes **specified in the request** are compared.

### Persistence

Queue metadata is stored in the same SQLite database as DynamoDB (`state.path`, default `.simulith/state.db`). Survives process restart.

`simulith reset` clears SQS queue and message rows along with DynamoDB state.

## SendMessage

See **[aws-cli-examples.md — SQS](aws-cli-examples.md#sqs)**.

Response includes `MessageId` and `MD5OfMessageBody`. Messages are stored in SQLite (`sqs_messages`) for ReceiveMessage.

Optional `DelaySeconds` (0–900) is stored; visibility is enforced when receiving.

## SendMessageBatch

See **[aws-cli-examples.md — SQS batch](aws-cli-examples.md#sendmessagebatch--deletemessagebatch)**.

Sends up to **10** messages per request. Returns HTTP **200** with `SendMessageBatchResultEntry` (success) and `BatchResultErrorEntry` (per-entry failure) lists — check `Failed` even on 200 (AWS partial-batch semantics).

Supports **Query** and **AWS JSON 1.0** (`AmazonSQS.SendMessageBatch`).

## ReceiveMessage

See **[aws-cli-examples.md — SQS](aws-cli-examples.md#sqs)**.

Response includes `Message` entries with `Body`, `MessageId`, `ReceiptHandle`, and `MD5OfBody`. Save `ReceiptHandle` for DeleteMessage.

Optional parameters:

- `MaxNumberOfMessages` (1–10, default 1)
- `VisibilityTimeout` (0–43200 seconds, default 30)
- `WaitTimeSeconds` (0–20, default: queue `ReceiveMessageWaitTimeSeconds` or `0`) — long poll; blocks until a message is available or wait expires
- `MessageSystemAttributeNames` / `MessageAttributeNames` — MVP subset when requested

Long polling uses a **200ms SQLite poll interval** (documented deviation from AWS distributed sampling). Explicit `WaitTimeSeconds=0` is short poll even when the queue default is greater than zero.

## DeleteMessage

See **[aws-cli-examples.md — SQS full loop](aws-cli-examples.md#sqs)**.

Returns HTTP 200 with an empty `DeleteMessageResponse` (Unit output — no result body). After a successful delete, the message is removed and will not be redelivered.

Delete works even while the message is within its visibility timeout (in-flight).

## DeleteMessageBatch

See **[aws-cli-examples.md — SQS batch](aws-cli-examples.md#sendmessagebatch--deletemessagebatch)**.

Deletes up to **10** messages by receipt handle. Partial per-entry errors use the same `Successful` / `Failed` pattern as SendMessageBatch. Stale handles report **success** (no-op), matching single DeleteMessage.

## GetQueueUrl

Returns the persisted `QueueUrl` for a queue **by name**. Supports **Query** (`Action=GetQueueUrl`) and **AWS JSON 1.0** (`AmazonSQS.GetQueueUrl`).

- `QueueName` (required) — same rules as CreateQueue
- `QueueOwnerAWSAccountId` (optional) — if set, must match local account `000000000000`

The URL returned is the value stored at CreateQueue or seed time (not recomputed from the HTTP Host header).

See **[aws-cli-examples.md — GetQueueUrl](aws-cli-examples.md#getqueueurl)**.

## ListQueues

Lists **stored** `QueueUrl` values for all queues in SQLite, ordered by queue name. Supports **Query** (`Action=ListQueues`) and **AWS JSON 1.0** (`AmazonSQS.ListQueues`).

- `QueueNamePrefix` (optional) — filter by queue **name** prefix (SQL `LIKE prefix%`)
- `MaxResults` (optional) — when set (1–1000), enables pagination with `NextToken`
- `NextToken` (optional) — Simulith MVP uses a decimal **offset** string (not an opaque AWS token)

When `MaxResults` is omitted, up to **1000** URLs are returned with no `NextToken`.

See **[aws-cli-examples.md — ListQueues](aws-cli-examples.md#listqueues)**.

## DeleteQueue

Deletes a queue and **all** of its messages by `QueueUrl`. Supports **Query** (`Action=DeleteQueue`) and **AWS JSON 1.0** (`AmazonSQS.DeleteQueue`).

- `QueueUrl` (required) — queue resolved by **name** in the URL path (same as other queue ops)
- Success returns an empty result body (HTTP 200)
- Unknown queue → `AWS.SimpleQueueService.NonExistentQueue` (SDK/clients often report as `QueueDoesNotExist`)

After **DeleteQueue**, the queue enters a **deleting tombstone** window (default **60 seconds**, overridable via `SIMULITH_SQS_DELETE_GRACE_SECONDS`). Messages are removed immediately. **GetQueueAttributes** and **GetQueueUrl** still succeed during the window (Terraform’s provider keeps polling). **SendMessage**, **ReceiveMessage**, and **SetQueueAttributes** return `QueueDoesNotExist`. **ListQueues** omits deleting queues. When the window expires, the queue row is purged and lookups return `QueueDoesNotExist` — **`terraform destroy`** on [`sqs/`](examples/terraform/sqs/) then completes (~60–90s total).

See **[aws-cli-examples.md — DeleteQueue](aws-cli-examples.md#deletequeue)**.

## PurgeQueue

Removes **all messages** from a queue (visible, delayed, and in-flight) without deleting the queue. Supports **Query** (`Action=PurgeQueue`) and **AWS JSON 1.0** (`AmazonSQS.PurgeQueue`).

- `QueueUrl` (required)
- Success returns an empty result body (HTTP 200)
- Unknown or **deleting** queue → `AWS.SimpleQueueService.NonExistentQueue`
- Second purge on the same queue within **60 seconds** → `AWS.SimpleQueueService.PurgeQueueInProgress`

See **[aws-cli-examples.md — PurgeQueue](aws-cli-examples.md#purgequeue)**.

## ChangeMessageVisibility

Adjusts the visibility timeout for an **in-flight** message identified by `ReceiptHandle`. Supports **Query** (`Action=ChangeMessageVisibility`) and **AWS JSON 1.0** (`AmazonSQS.ChangeMessageVisibility`).

- `QueueUrl` (required)
- `ReceiptHandle` (required) — from **ReceiveMessage**
- `VisibilityTimeout` (required) — 0–43200 seconds; `0` makes the message immediately available
- Invalid, stale, or wrong-queue handle → `ReceiptHandleIsInvalid` (HTTP 404), **not** a silent no-op (unlike DeleteMessage on stale handles)

**ChangeMessageVisibilityBatch** accepts up to 10 entries with partial success (same batch rules as SendMessageBatch / DeleteMessageBatch).

See **[aws-cli-examples.md — ChangeMessageVisibility](aws-cli-examples.md#changemessagevisibility)**.

## SetQueueAttributes

Updates persisted queue metadata for an existing queue. Supports **Query** (`Action=SetQueueAttributes`) and **AWS JSON 1.0** (`AmazonSQS.SetQueueAttributes`).

### Request

- `QueueUrl` (required)
- `Attribute.N.Name` / `Attribute.N.Value` (Query) or `Attributes` map (JSON)

### Settable attributes (MVP)

| Attribute | Validation |
| --- | --- |
| `VisibilityTimeout` | 0–43200 seconds |
| `DelaySeconds` | 0–900 |
| `ReceiveMessageWaitTimeSeconds` | 0–20; default long-poll wait when `WaitTimeSeconds` omitted on ReceiveMessage |
| `MessageRetentionPeriod` | 60–1209600 |
| `MaximumMessageSize` | 1024–1048576 |
| `RedrivePolicy` | JSON with `deadLetterTargetArn` + `maxReceiveCount` (stored only; no DLQ redrive) |

Unsupported attributes (FIFO, KMS, `Policy`, computed counts, timestamps) return `InvalidAttributeValue`.

Updates merge into existing `attributes_json`; `LastModifiedTimestamp` reflects `updated_at`.

See **[aws-cli-examples.md — SetQueueAttributes](aws-cli-examples.md#setqueueattributes)**.

## GetQueueAttributes

Returns queue metadata for an existing queue. Supports **Query** (`Action=GetQueueAttributes`) and **AWS JSON 1.0** (`AmazonSQS.GetQueueAttributes`).

### Request

- `QueueUrl` (required)
- `AttributeName.N` (Query) or `AttributeNames` (JSON) — use `All` or individual names below

### Supported attributes (MVP)

| Attribute | Notes |
| --- | --- |
| `QueueArn` | `arn:aws:sqs:{region}:{account}:{queueName}` |
| `VisibilityTimeout` | From CreateQueue attrs or default `30` |
| `DelaySeconds` | Stored or `0` |
| `ReceiveMessageWaitTimeSeconds` | Stored or `0` |
| `MessageRetentionPeriod` | Stored or `345600` |
| `MaximumMessageSize` | Stored or `262144` |
| `ApproximateNumberOfMessages` | Visible, not in-flight |
| `ApproximateNumberOfMessagesNotVisible` | In-flight (receipt handle set) |
| `ApproximateNumberOfMessagesDelayed` | Delayed, not yet visible |
| `RedrivePolicy` | Stored JSON (if set via CreateQueue or SetQueueAttributes) |
| `CreatedTimestamp` | Unix seconds from `created_at` |
| `LastModifiedTimestamp` | Unix seconds from `updated_at` (falls back to `created_at`) |

If no attribute names are requested, Simulith returns the **full MVP subset** above (Terraform-friendly; AWS returns empty when `AttributeNames` is omitted).

## Deviations (MVP)

| Area | AWS | Simulith |
| --- | --- | --- |
| FIFO queues | Supported | **Not supported** — `FifoQueue=true` or `.fifo` names rejected |
| Duplicate create | Returns existing `QueueUrl` when attributes match | **Same**; mismatch → `QueueAlreadyExists` |
| SendMessageBatch / DeleteMessageBatch / ChangeMessageVisibilityBatch | Up to 10 entries; partial errors | **Same** |
| FIFO send fields | MessageGroupId / deduplication | **Rejected** with `InvalidParameterValue` |
| QueueUrl host match | Strict URL must match queue | **Resolved by queue name** in URL path |
| Long polling | Distributed sampling | **SQLite poll loop** (~200ms); blocks up to `WaitTimeSeconds` or queue default |
| Receipt handle | AWS opaque token | **`simulith:{messageId}:{count}:{nonce}`** |
| Stale receipt handle on delete | May succeed without deleting message | **Same** — 200 OK no-op when handle does not match latest stored handle |
| Stale receipt handle on ChangeMessageVisibility | `ReceiptHandleIsInvalid` | **Same** — 404 when handle invalid or superseded |
| Queue attributes | Full validation | Stored; minimal validation |
| GetQueueAttributes empty names | Returns empty map | Returns **full MVP subset** |
| GetQueueUrl | Returns **stored** URL from create/seed | Does not rebuild host from current request |
| QueueOwnerAWSAccountId | Cross-account lookup | **Rejected** when account id ≠ local `000000000000` |
| ListQueues | Prefix filter on **name**; returns **stored** URLs | MVP `NextToken` is decimal **offset** when `MaxResults` is set (not opaque AWS token) |
| DeleteQueue | May take up to 60s; 60s cooldown before recreate same name | **Tombstone window** (~60s default; `SIMULITH_SQS_DELETE_GRACE_SECONDS`); messages removed immediately; GQA/GQU during window; no exact recreate cooldown |
| SetQueueAttributes | Propagation delay; full attribute surface | **Immediate** merge in SQLite; subset only; **RedrivePolicy stored only** (no automatic DLQ redrive) |

## Errors

Service faults use AWS Query XML (`ErrorResponse` with `Code`, `Message`, `Type`). Examples:

- `QueueAlreadyExists` — duplicate queue name
- `QueueDoesNotExist` / `AWS.SimpleQueueService.NonExistentQueue` — unknown queue (Query/XML uses the AWS code). **AWS JSON 1.0** responses use Smithy shape **`QueueDoesNotExist`** in `__type` / `x-amzn-errortype` (required for Terraform destroy waiter).
- `InvalidParameterValue` — invalid or missing `QueueName`, `QueueUrl`, `MessageBody`, or `ReceiptHandle`
- `ReceiptHandleIsInvalid` — malformed receipt handle or message not found (HTTP 404)

## Related

- [compatibility-matrix.md](compatibility-matrix.md) — public MVP operation × verify coverage matrix
- [compatibility.md](compatibility.md) — `simulith verify sqs` parity and smoke modes
- [aws-cli-examples.md](aws-cli-examples.md) — AWS CLI cookbook

- [quickstart.md](quickstart.md) — starting the runtime
