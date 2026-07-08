# Compatibility matrix — Simulith MVP

Public reference for **local API support** vs **`simulith verify` coverage** on DynamoDB, SQS, and SSM.

**Public mirror (prospects, sales, Hub):** [simulith-docs/compatibility-matrix.md](https://github.com/simulith/simulith-docs/blob/main/compatibility-matrix.md)

**Consolidated summary (percentages, Terraform, Console):** [`aws-parity-overview.md`](aws-parity-overview.md).

**Important:** **available** means the operation is implemented in the local runtime (often with MVP limits — see the service guide). **Verify** means a curated scenario in [`simulith verify`](compatibility.md) compares Simulith to real AWS (or smoke-only with `--skip-aws`). Shipped locally ≠ verified against AWS.

> **Backlog (gaps):** `cursor/company/future-work/` · Policy: `DOCUMENTATION-GOVERNANCE.md`

Last updated: 2026-07-08 (SML-112 — S3 CopyObject + DeleteObjects).

## Summary

| Metric | Count |
| --- | --- |
| Services in matrix | 4 (DynamoDB, SQS, SSM, S3) |
| Operations **available** locally | 51 |
| Default verify scenarios | DynamoDB 6, SQS 10, SSM 9, S3 6 |
| DynamoDB extended verify scenarios | 13 (`--filter extended`) |

Run verification: [`compatibility.md`](compatibility.md).

**Trust bundle:** packaged matrix + verify smoke reports for enterprise POCs — [`trust-bundle.md`](trust-bundle.md) · sales guide: `cursor/company/sales/trust-bundle.md`.

## Legend

### API status

| Status | Meaning |
| --- | --- |
| **available** | HTTP handler shipped; see service doc for MVP limits |
| **partial** | Implemented with documented gaps vs AWS |
| **gap** | Not implemented |

### Verify

| Value | Meaning |
| --- | --- |
| **yes** (`scenario`) | Default `simulith verify <service>` (no filter) |
| **extended** (`scenario`) | DynamoDB only: `simulith verify dynamodb --filter <name>` |
| **no** | Not in verify subset |

---

## DynamoDB

Guide: [dynamodb.md](dynamodb.md) · Verify: `simulith verify dynamodb` (6 default + 13 extended)

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateTable | available | yes (`create-describe-table`) | |
| DescribeTable | available | yes (`create-describe-table`) | |
| PutItem | available | yes (`put-get-item`); extended (`conditional-put`) | ConditionExpression covered by extended scenario |
| BatchWriteItem | available | extended (`batch-write-item`) | Up to 25 put/delete requests |
| BatchGetItem | available | extended (`batch-get-item`, `projection-expression`) | Up to 100 keys; projection optional |
| TransactWriteItems | available | extended (`transact-write-get-items`) | Put/Delete/Update/ConditionCheck |
| TransactGetItems | available | extended (`transact-write-get-items`, `projection-expression`) | Ordered reads; projection optional |
| GetItem | available | yes (`put-get-item`); extended (`projection-expression`) | ProjectionExpression MVP subset |
| Query (base table) | available | yes (`query`); extended (`projection-expression`, `query-scan-1mb-pagination`) | KeyCondition MVP subset; 1 MB page cap |
| Query (GSI / LSI) | available | extended (`query-gsi`) | Requires `IndexName` |
| Scan | available | yes (`scan`); extended (`projection-expression`, `query-scan-1mb-pagination`, `parallel-scan`) | Parallel `Segment`/`TotalSegments` |
| UpdateItem | available | yes (`update-item`); extended (`update-expression-add-delete`) | ADD/DELETE on numbers and sets |
| DeleteItem | available | yes (`delete-item`) | |
| DeleteTable | available | extended (`delete-table`) | Also used by verify cleanup |
| ListTables | available | extended (`list-tables`) | |
| UpdateTable | available | extended (`update-table`) | Stream metadata — see dynamodb.md |
| TagResource / UntagResource / ListTagsOfResource | available | extended (`table-tags`) | Table tags in metadata |

**Not in matrix (gap):** streams API, export/import, etc.

---

## SQS

Guide: [sqs.md](sqs.md) · Verify: `simulith verify sqs` (10 scenarios) · Standard queues only

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateQueue | available | yes (`create-get-queue-url`) | Standard queues; idempotent create |
| GetQueueUrl | available | yes (`create-get-queue-url`) | |
| SendMessage | available | yes (`send-receive-delete`) | |
| ReceiveMessage | available | yes (`send-receive-delete`) | Short poll in verify |
| DeleteMessage | available | yes (`send-receive-delete`) | |
| GetQueueAttributes | available | yes (`get-queue-attributes`) | Subset of attributes in scenario |
| ListQueues | available | yes (`list-queues`) | |
| DeleteQueue | available | yes (`delete-queue`) | Also used by verify cleanup |
| SetQueueAttributes | available | yes (`set-queue-attributes`) | |
| SendMessageBatch | available | yes (`send-message-batch`) | |
| DeleteMessageBatch | available | yes (`delete-message-batch`) | |
| PurgeQueue | available | yes (`purge-queue`) | 60s throttle between purges |
| ChangeMessageVisibility | available | yes (`change-message-visibility`) | Invalid handle → error |
| ChangeMessageVisibilityBatch | available | yes (`change-message-visibility`) | Same scenario as single |

**Not in matrix (gap):** FIFO queues, etc.

---

## SSM Parameter Store

Guide: [ssm.md](ssm.md) · Verify: `simulith verify ssm` (9 scenarios)

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| PutParameter | available | yes (`put-get-parameter`, `put-overwrite`, `secure-string`) | SecureString mock encryption |
| GetParameter | available | yes (`put-get-parameter`, `secure-string`) | `WithDecryption` for SecureString |
| DeleteParameter | available | yes (`delete-parameter`) | |
| DeleteParameters | available | yes (`delete-parameters`) | Batch delete up to 10 names (SML-062) |
| GetParameters | available | yes (`get-parameters-batch`) | Up to 10 names |
| GetParametersByPath | available | yes (`get-parameters-by-path`) | |
| DescribeParameters | available | yes (`describe-parameters`) | Terraform refresh; MVP filters only |
| AddTagsToResource | available | yes (`parameter-tags`) | Parameter resources only |
| RemoveTagsFromResource | available | yes (`parameter-tags`) | Parameter resources only |
| ListTagsForResource | available | yes (`parameter-tags`) | Parameter resources only |

**Not in matrix (gap):** full ParameterFilters, labels, real AWS KMS, etc.

---

## S3

Guide: [s3.md](s3.md) · Verify: `simulith verify s3` (6 scenarios)

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateBucket | available | yes (`create-list-delete-bucket`, `put-get-object`, `head-object`, `delete-object`, `list-objects-v2-prefix`, `object-round-trip`) | Idempotent; names 3–63 chars |
| ListBuckets | available | yes (`create-list-delete-bucket`) | |
| DeleteBucket | available | yes (`create-list-delete-bucket`) | Empty bucket only |
| PutObject | available | yes (`put-get-object`, `object-round-trip`, `list-objects-v2-prefix`) | Single-part; Content-Type from header |
| GetObject | available | yes (`put-get-object`, `object-round-trip`) | Body + Content-Type, Content-Length, ETag |
| HeadObject | available | yes (`head-object`) | Existence check; Content-Length |
| DeleteObject | available | yes (`delete-object`) | Idempotent (204) |
| CopyObject | available | — | Same/cross-bucket via `x-amz-copy-source` |
| DeleteObjects | available | — | Batch up to 1000 keys (`POST ?delete`) |
| ListObjectsV2 | available | yes (`list-objects-v2-prefix`) | prefix, max-keys, continuation-token |

**Not in matrix (gap):** multipart upload, versioning, CORS, SSE-KMS, S3 Select.

---

## Verify scenario index

Quick reference — full runbook in [compatibility.md](compatibility.md).

| Service | Default scenarios | Extended (DynamoDB only) |
| --- | --- | --- |
| DynamoDB | `create-describe-table`, `put-get-item`, `query`, `scan`, `update-item`, `delete-item` | `list-tables`, `delete-table`, `query-gsi`, `conditional-put`, `update-table`, `table-tags`, `batch-write-item`, `batch-get-item` |
| SQS | `create-get-queue-url`, `send-receive-delete`, `get-queue-attributes`, `list-queues`, `delete-queue`, `set-queue-attributes`, `send-message-batch`, `delete-message-batch`, `purge-queue`, `change-message-visibility` | — |
| SSM | `put-get-parameter`, `put-overwrite`, `get-parameters-batch`, `get-parameters-by-path`, `delete-parameter`, `delete-parameters`, `describe-parameters`, `secure-string`, `parameter-tags` | — |
| S3 | `create-list-delete-bucket`, `put-get-object`, `head-object`, `delete-object`, `list-objects-v2-prefix`, `object-round-trip` | — |

```bash
simulith verify dynamodb --skip-aws
simulith verify dynamodb --skip-aws --filter extended
simulith verify sqs --skip-aws
simulith verify ssm --skip-aws
simulith verify s3 --skip-aws
```

---

## Maintenance

Update this matrix in the **same change** when you ship or remove an MVP HTTP operation. Follow `cursor/company/DOCUMENTATION-GOVERNANCE.md` — do not duplicate this table in `future-work/`.

When you update:

- Ship or remove an MVP HTTP operation (update service doc + this table + [`aws-parity-overview.md`](aws-parity-overview.md) if summary changes).
- Add or rename a verify scenario (`internal/verify/<service>/scenarios.go` + [compatibility.md](compatibility.md)).

Source of truth for handlers: [dynamodb.md](dynamodb.md), [sqs.md](sqs.md), [ssm.md](ssm.md). Source of truth for verify names: `runtime/internal/verify/*/scenarios.go`. Gaps and priority: `future-work/`.

---

## Related

- [compatibility.md](compatibility.md) — running verify and reports
- [quickstart.md](quickstart.md) — onboarding
- [README.md](README.md) — doc index
- Product backlog: `cursor/company/future-work/compatibility/README.md`
