# DynamoDB — Simulith runtime

Local DynamoDB table metadata and item storage (Phase 3 MVP).

## Operations

| Operation | Status | Notes |
| --- | --- | --- |
| CreateTable | **Available** | Metadata persisted in SQLite |
| DescribeTable | **Available** | Reads stored metadata |
| PutItem | **Available** | Full item replace by primary key |
| BatchWriteItem | **Available** | Up to 25 put/delete requests; no per-item conditions |
| BatchGetItem | **Available** | Up to 100 keys; missing keys omitted |
| TransactWriteItems | **Available** | Up to 100 actions; atomic all-or-nothing |
| TransactGetItems | **Available** | Up to 100 keys; ordered `Responses` |
| GetItem | **Available** | Point read; omits `Item` when missing |
| Query | **Available** | Base table + GSI/LSI via `IndexName`; MVP KeyCondition + Filter |
| Scan | **Available** | Full table read; Filter + pagination + parallel `Segment`/`TotalSegments` |
| UpdateItem | **Available** | MVP UpdateExpression (`SET`, `REMOVE`) + conditions |
| DeleteItem | **Available** | Key delete with MVP ConditionExpression |
| DeleteTable | **Available** | Cascade delete items + table metadata |
| UpdateTable | **Available** | MVP metadata updates (billing, SSE, deletion protection, GSI, stream) |
| ListTables | **Available** | Names from `dynamodb_tables`; MVP pagination |
| TagResource / UntagResource / ListTagsOfResource | **Available** | Table ARN tags in metadata blob; merge on tag; CreateTable tags persisted |
| DescribeContinuousBackups | **Available** | Continuous backups **ENABLED**; PITR status from stored flag |
| UpdateContinuousBackups | **Available** | Toggle PITR metadata (Terraform `point_in_time_recovery`); no real restore |

## Resource tags (MVP)

- **TagResource** — merge tags by key on table ARN (`arn:aws:dynamodb:{region}:000000000000:table/{name}`)
- **UntagResource** — remove listed tag keys
- **ListTagsOfResource** — returns `Tags` array (empty `[]` when none)
- **CreateTable** — optional `Tags` stored alongside table metadata
- Tags are **not** returned on DescribeTable (matches AWS)
- Index/stream ARNs and tag limits not enforced yet

## Query / Scan (MVP)

- **Base table** — Query without `IndexName`
- **GSI / LSI** — Query with `IndexName` matching CreateTable metadata; KeyCondition uses index key attribute names; index keys read from item attributes (sparse GSI: items missing the GSI hash attribute are skipped)
- **KeyConditionExpression** (Query): partition `=`; optional range `=`, comparisons, `BETWEEN`, `begins_with`
- **FilterExpression**: `AND`-combined scalar comparisons on item attributes
- **ExpressionAttributeNames** (`#name`) and **ExpressionAttributeValues** (`:val`) supported
- **ProjectionExpression** — comma-separated top-level attributes on GetItem, Query, Scan, BatchGetItem, TransactGetItems; missing attrs omitted
- **Limit** caps evaluated items per page; **1 MB** caps returned item payload per page; **ExclusiveStartKey** / **LastEvaluatedKey** use table primary-key AttributeMap
- **Parallel Scan** — `Segment` + `TotalSegments` (1–1_000_000) must be provided together; segment assignment uses canonical key hash (local)
- **ScanIndexForward** controls range-key sort order on Query (default ascending)
- **Count** = returned items; **ScannedCount** = items evaluated (before filter trim)
- Empty result sets return `"Items":[]`
- **Index projection** — responses return full items (ALL); KEYS_ONLY / INCLUDE not applied yet

Not supported yet: nested document paths in ProjectionExpression, full expression language.

## ListTables (MVP)

- Returns table **names** sorted ascending from SQLite
- **`Limit`** — optional; default **100**; valid range **1–100**
- **`ExclusiveStartTableName`** — exclusive cursor; use **`LastEvaluatedTableName`** from the prior page
- Empty account → `"TableNames":[]`

## UpdateItem / DeleteItem (MVP)

- **UpdateExpression**: `SET`, `REMOVE`, **`ADD`**, **`DELETE`**; `#names` and `:values` supported
- **ConditionExpression** (UpdateItem, DeleteItem, PutItem): `attribute_exists`, `attribute_not_exists`, scalar comparisons, `AND`
- **UpdateItem upsert**: creates item when key missing (unless condition prevents)
- **DeleteItem**: idempotent when item absent (no condition)
- **ReturnValues**: `NONE` (default), `ALL_NEW`, `ALL_OLD` on UpdateItem/DeleteItem
- Condition failure → `ConditionalCheckFailedException`

Not supported yet: `if_not_exists`, legacy `AttributeUpdates`/`Expected`, ReturnValues `UPDATED_*`.

## BatchWriteItem (MVP)

- **RequestItems** — map of table name or ARN → up to **25** total `PutRequest` / `DeleteRequest` entries across all tables
- **PutRequest** — same item validation as PutItem (no per-item conditions)
- **DeleteRequest** — same key validation as DeleteItem (idempotent when missing; no conditions)
- Success returns **`UnprocessedItems`: `{}`** (no throttling simulation)
- Unknown table → `ResourceNotFoundException`; invalid batch → `ValidationException`

Not supported yet: per-item conditions, partial `UnprocessedItems` for capacity, `ReturnConsumedCapacity`, `ReturnItemCollectionMetrics`.

**CLI seed example** (Terraform user-table + `user.json`): [`examples/terraform/dynamodb/user-table/README.md`](examples/terraform/dynamodb/user-table/README.md).

**Cross-service fan-out:** [`examples/terraform/dynamodb-sqs/`](examples/terraform/dynamodb-sqs/) + CLI [`examples/aws-cli/dynamodb-sqs/`](examples/aws-cli/dynamodb-sqs/) — PutItem + SendMessage (no Streams).

## BatchGetItem (MVP)

- **RequestItems** — map of table name or ARN → `Keys` (up to **100** keys total across all tables)
- Returns **`Responses`** with found items only; missing keys omitted (same as AWS)
- **`UnprocessedKeys`: `{}`** on success (no throttling simulation)
- Unknown table → `ResourceNotFoundException`; >100 keys → `ValidationException`
- **`ProjectionExpression`** — top-level attributes + `#names`; **`AttributesToGet`** → `ValidationException` (legacy)

Not supported yet: partial `UnprocessedKeys`, `ReturnConsumedCapacity`.

## TransactWriteItems / TransactGetItems (MVP)

- **TransactWriteItems** — up to **100** `TransactItems`; exactly one of Put, Delete, Update, or ConditionCheck per item
- Validates all conditions first; applies all writes atomically or returns **`TransactionCanceledException`** with **`CancellationReasons`**
- Duplicate table+key in one transaction → **`ValidationException`**
- **TransactGetItems** — up to **100** ordered reads; missing items return **null** in `Responses`; optional **`ProjectionExpression`**
- Unknown table → `ResourceNotFoundException`

Not supported yet: `ClientRequestToken` idempotency, `ReturnValuesOnConditionCheckFailure`, `ReturnConsumedCapacity`.

## UpdateTable (MVP)

- **BillingMode** / **ProvisionedThroughput** — switch or adjust provisioned settings on table metadata
- **DeletionProtectionEnabled** — when `true`, **DeleteTable** returns `ValidationException`
- **SSESpecification** — stores **SSEDescription** (`ENABLED` / KMS); no real encryption
- **StreamSpecification** — enable/disable stream metadata (no real streams)
- **GlobalSecondaryIndexUpdates** — one GSI **Create**, **Update** (throughput), or **Delete** per request; merges **AttributeDefinitions**
- Returns **ACTIVE** immediately (no `UPDATING` wait)
- Unknown table → `ResourceNotFoundException`

Not supported yet: **ReplicaUpdates**, **TableClass**, **OnDemandThroughput**, LSI add via UpdateTable, real stream/SSE behavior.

## Continuous backups / PITR (Terraform metadata)

- **DescribeContinuousBackups** — `ContinuousBackupsStatus` always **ENABLED**; `PointInTimeRecoveryStatus` **ENABLED** or **DISABLED** from stored flag
- **UpdateContinuousBackups** — sets `PointInTimeRecoveryEnabled`; when enabled, returns stub `EarliestRestorableDateTime` / `LatestRestorableDateTime` (35-day window)
- **No real backups** — `RestoreTableToPointInTime` and export APIs are not implemented
- Enables **`aws_dynamodb_table.point_in_time_recovery`** green path on Simulith — see [`examples/terraform/dynamodb/user-table/`](examples/terraform/dynamodb/user-table/)

## Persistence

Data is stored in SQLite (`state.path`, default `./.simulith/state.db`):

```sql
CREATE TABLE dynamodb_tables (
  name TEXT PRIMARY KEY,
  definition_json TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE dynamodb_items (
  table_name TEXT NOT NULL,
  item_key TEXT NOT NULL,
  item_json TEXT NOT NULL,
  PRIMARY KEY (table_name, item_key)
);
```

- **Table metadata** — CreateTable JSON blob in `dynamodb_tables`
- **Items** — full AttributeMap JSON in `dynamodb_items`; key is canonical JSON of primary-key attributes

Restarting the runtime preserves tables and items.

See [persistence.md](persistence.md) for configuration, Docker volumes, and `simulith reset`.

## Attribute types (PutItem / GetItem)

Supported DynamoDB wire types:

| Type | Wire key | Notes |
| --- | --- | --- |
| String | `S` | |
| Number | `N` | String-encoded (AWS JSON) |
| Binary | `B` | Base64 string |
| String set | `SS` | Non-empty |
| Number set | `NS` | Non-empty |
| Binary set | `BS` | Non-empty |
| Map | `M` | Nested AttributeValues |
| List | `L` | Nested AttributeValues |
| Null | `NULL` | Must be `true` |
| Boolean | `BOOL` | |

Key attributes must use scalar types (`S`, `N`, or `B`) matching the table `AttributeDefinitions`.

**Console:** Map/List item editing in the web UI — **JSON document** tab; Simple tab for string scalars. See [`console.md`](console.md).

## Local behavior deviations

| AWS behavior | Simulith (MVP) |
| --- | --- |
| CreateTable returns `CREATING`, later `ACTIVE` | Returns **`ACTIVE` immediately** |
| DeleteTable async `DELETING` → eventual removal | **Immediate** delete; `DescribeTable` → `ResourceNotFoundException` |
| UpdateTable async `UPDATING` | **Immediate** `ACTIVE`; metadata-only changes |
| DeleteTable with deletion protection | **Blocked** — `ValidationException` |
| ConditionExpression on PutItem | **Supported** (MVP subset) |
| ConditionExpression failure | **`ConditionalCheckFailedException`** |
| Legacy `AttributeUpdates` / `Expected` | **Not supported** — `ValidationException` |
| ProjectionExpression on GetItem / Query / Scan / BatchGetItem / TransactGetItems | **Supported** — top-level attrs + `#names`; missing attrs omitted |
| AttributesToGet (legacy) | **Not supported** — `ValidationException` |
| IndexName on Query | **Supported** — GSI/LSI from CreateTable metadata; unknown index → `ValidationException` |
| GSI `IndexStatus` on DescribeTable | **ACTIVE** immediately (Terraform `aws_dynamodb_table` wait) |
| Index projection (KEYS_ONLY / INCLUDE) | Ignored — full item returned (ALL) |
| Parallel Scan segment assignment | **Supported** — FNV hash of canonical key `% TotalSegments` (may differ from AWS physical partitions) |
| ReturnValues / ConsumedCapacity | Not returned |
| ConsistentRead | Ignored (local store is strongly consistent) |
| Regional account limits, IAM | Not enforced |
| Streams / SSE metadata | Stored when sent; no real side effects |
| PITR / continuous backups | **Metadata** via DescribeContinuousBackups / UpdateContinuousBackups; no restore |
| Resource tags on table ARN | **Supported** via TagResource / ListTagsOfResource |
| Tag limits / index ARN tags | Not enforced |

## Example (AWS CLI)

Copy-paste commands for all MVP operations: **[aws-cli-examples.md](aws-cli-examples.md#dynamodb)**.

Quick sample:

```bash
export AWS_ENDPOINT=http://127.0.0.1:4566 AWS_DEFAULT_REGION=us-east-1
aws dynamodb put-item --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" \
  --table-name Music --item '{"Artist":{"S":"Acme Band"}}'
```

See the cookbook for CreateTable, Query, Scan, UpdateItem, and DeleteItem.

## Errors

Service faults use the runtime:

- `TableAlreadyExistsException` — duplicate CreateTable
- `ResourceNotFoundException` — operation on unknown table
- `ValidationException` — invalid keys, attribute shapes, unsupported expressions
- `ConditionalCheckFailedException` — condition expression evaluated to false

## Related

- [aws-cli-examples.md](aws-cli-examples.md) — AWS CLI cookbook
- `protocol.md` — AWS JSON wire format
- `smithy-contracts.md` — Smithy model source
- [compatibility-matrix.md](compatibility-matrix.md) — public MVP operation × verify coverage matrix
- [compatibility.md](compatibility.md) — `simulith verify dynamodb` (default 6 scenarios; extended ListTables/DeleteTable/GSI/conditional via `--filter`)
