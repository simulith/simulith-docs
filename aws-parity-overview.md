# AWS parity overview — Simulith MVP

Consolidated view of **Simulith vs AWS** for shipped services (Foundation + S3 + Lambda expansion): what is **implemented**, what is **missing**, **coverage percentages**, and **Terraform** status.

> **Console vs AWS Console (UI):** [`console.md`](console.md) — separate dimension
> **Operational detail (operation × verify):** [`compatibility-matrix.md`](compatibility-matrix.md)

Last updated: 2026-07-14..

---

## Executive summary

| Service | API ops **available** | Verified vs AWS (`simulith verify`) | Tier A coverage* | Tier B coverage† |
| --- | ---: | ---: | ---: | ---: |
| **DynamoDB** | 17 | 17 / 17 (100%) | **100%** (17 / 17) | **~38%** (17 / ~45) |
| **SQS** | 14 | 14 / 14 (100%) | **93%** (14 / 15) | **~55%** (14 / ~22) |
| **SSM** (Parameter Store) | 9 | 9 / 9 (100%) | **100%** (10 / 10) | **~58%** (9 / ~12) |
| **S3** | 8 | 8 / 8 (100%) | **89%** (8 / 9) | **~20%** (8 / ~40) |
| **Lambda** | 21 | 9 / 9 scenarios (100%) | **100%** (7 / 7 Tier A) | **~13%** (21 / ~75) |
| **Total** | **69** | Foundation **48 / 48** ops · Lambda **9 / 9** scenarios | — | — |

\* **Tier A — POC / IaC / worker patterns:** operations we **ship** plus **P2 backlog** items teams hit in real evals (batch APIs, purge, SSM batch delete, etc.). Source: this doc + service the product backlog.

† **Tier B — full AWS API catalog (approx.):** share of the **documented AWS operation surface** for that service. Simulith intentionally implements a **subset**; low Tier B % is expected and not a product failure mode.

**Lambda expansion:** MVP + P2 complete. **P2 shipped:**  async invoke + Function URLs, ** Layers**. **Next:** API Gateway B3 runtime; analysis kickoff .

---

## How to read the tables

| Column | Meaning |
| --- | --- |
| **Available** | HTTP handler shipped — see service guide for MVP limits |
| **Verify** | Curated scenario compares Simulith to real AWS |
| **Gap** | Not implemented; often tracked as `FW-*` in future-work |
| **Partial** | Works for Terraform/CLI subset with documented deviations |

---

## DynamoDB

Guide: [dynamodb.md](dynamodb.md) · Backlog: the product backlog

### Implemented (functional)

| Category | Operations |
| --- | --- |
| Table lifecycle | CreateTable, DescribeTable, ListTables, DeleteTable, UpdateTable |
| Items | PutItem, **BatchWriteItem**, **BatchGetItem**, **TransactWriteItems**, **TransactGetItems**, GetItem, UpdateItem, DeleteItem, Query, Scan |
| Tags | TagResource, UntagResource, ListTagsOfResource |

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Streams, TTL, export/import, real PITR restore | P3 | + (PITR **metadata** APIs shipped for Terraform) |

### Tier A reference set (17 ops)

17 **available** = **100%** Tier A DynamoDB coverage.

---

## SQS

Guide: [sqs.md](sqs.md) · Backlog: the product backlog

### Implemented (functional)

CreateQueue (standard, idempotent), SendMessage, SendMessageBatch, ReceiveMessage (long poll), DeleteMessage, DeleteMessageBatch, GetQueueAttributes, GetQueueUrl, ListQueues, DeleteQueue, **PurgeQueue**, **ChangeMessageVisibility** (+ batch), SetQueueAttributes.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| FIFO queues | P3 |  |
| TagQueue / ListQueueTags | P3 |  |

**Admin peek (non-AWS route):** `GET /_simulith/v1/sqs/messages` — shipped; used for local debug, not AWS API parity.

### Tier A reference set (15 ops)

14 **available** + FIFO CreateQueue path = **93%**.

---

## SSM Parameter Store

Guide: [ssm.md](ssm.md) · Backlog: the product backlog

### Implemented (functional)

PutParameter, GetParameter, DeleteParameter, **DeleteParameters**, GetParameters, GetParametersByPath, DescribeParameters (MVP filters), **AddTagsToResource**, **RemoveTagsFromResource**, **ListTagsForResource**.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Full ParameterFilters / labels | P3 |  |
| Runnable SDK samples (Go/Node/Python) | DX | SSM section deferred in sdk-examples |

### Tier A reference set (10 ops)

9 **available** tag + SecureString APIs shipped; full ParameterFilters remain P3 defer = **90%** Tier A SSM (9/10).

---

## Terraform vs Simulith

Guide: [terraform-integration.md](terraform-integration.md) · Examples: [`examples/terraform/`](examples/terraform/)

### Green path matrix

| Module | Apply | Destroy | Notes |
| --- | --- | --- | --- |
| [`dynamodb/music/`](examples/terraform/dynamodb/music/) | Green | Green | CreateTable, DescribeTable, DeleteTable |
| [`dynamodb/user-table/`](examples/terraform/dynamodb/user-table/) | Green | Green | PK + 2 GSIs, tags, SSE, PITR metadata (`environment=dev` default) |
| [`sqs/`](examples/terraform/sqs/) | Green | Green | DeleteQueue tombstone; destroy ~60–90s — [README](examples/terraform/sqs/README.md) |
| [`ssm/`](examples/terraform/ssm/) | Green | Green | Put/Get/Describe/Delete; `-parallelism=1` |
| [`ssm/parameters/`](examples/terraform/ssm/parameters/) | Green | Green | `/SIMULITH/DEV/*`; `dev.tfvars` / `dev.aws.tfvars` |
| [`s3/`](examples/terraform/s3/) | Green | Green | 1 bucket + 2 objects; `s3_use_path_style = true` |
| [`lambda/`](examples/terraform/lambda/) | Green | Green | 1 function + 1 queue + 1 ESM; `endpoints { lambda, sqs }` |

### Terraform — still pending

| Item | Impact | Backlog |
| --- | --- | --- |
| Terraform CI job (apply/destroy in GitHub Actions) | Repeatable IaC smoke | deferred in  |
| Import for SQS queues | Secondary workflows | terraform-integration.md |
| Prod-only `.example` files (GSI prod, FIFO, SSE) | Expect partial — not green without reading limits | service future-work |

DynamoDB **import** for tables and SSM **import** for parameters are **documented**. SQS import remains secondary.

---

## Console vs AWS Console

**Full panel-by-panel analysis:** [`console.md`](console.md).

Simulith Console ships MVP panels for DynamoDB, SQS, SSM, verify report import, and single-port workshop demo (~**92%** of reference Console flows — see [`console.md`](console.md)).

---

## S3

Guide: [s3.md](s3.md) · Backlog: the product backlog

### Implemented (functional)

CreateBucket (idempotent), ListBuckets, DeleteBucket (empty), PutObject, GetObject, HeadObject, DeleteObject, CopyObject, DeleteObjects (batch), ListObjectsV2 (prefix, max-keys, continuation-token).

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Multipart upload | P3 | FW-S3-007 |
| Multipart upload, versioning | P3 | FW-S3-020, FW-S3-021 |

### Tier A reference set (9 ops)

9 **available** = **100%** Tier A S3 coverage (DeleteObjects batch is additional).

---

## Lambda

Guide: [lambda.md](lambda.md) · Backlog: the product backlog

### Implemented

CreateFunction, ListFunctions, GetFunction, DeleteFunction, InvokeFunction (sync + async Event), UpdateFunctionCode, **SQS Event Source Mapping** (Create/List/Get/Delete + background poll), **Function URLs**, **Lambda Layers** (publish/list/get/delete + `Layers` on CreateFunction). Default seed includes **`demo-fn`**.

Metadata in SQLite (`lambda_functions`, `lambda_event_source_mappings`, `lambda_layer_versions`). Function zip at `{data-dir}/lambda/{name}/code.zip`; layer zips at `{data-dir}/lambda/layers/{name}/{version}/code.zip`.

**ESM poller:** enabled mappings poll SQS every ~1s, invoke target function with `Records` batch, delete messages on success.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Aliases, versions, Go runtime | P3 | ,  |

**Shipped:** async invoke (`InvocationType: Event`) and Function URLs.

**Shipped:** Lambda Layers (`PublishLayerVersion`, layer CRUD, `Layers` on CreateFunction, nodejs `NODE_PATH` on invoke).

### Tier A reference set (7 ops)

7 **available** = **100%** Tier A Lambda coverage.

---

## What to do next (priority)

**Next (API Gateway B3):** per the product backlog and `product-vision.md`.

| Priority | Theme | Backlog |
| --- | --- | --- |
| **B3** | API Gateway | TBD |

---

## Related

- [compatibility-matrix.md](compatibility-matrix.md) — operation-level truth table
- [compatibility.md](compatibility.md) — running verify

- [console.md](console.md) — Console vs AWS Console (UI)
