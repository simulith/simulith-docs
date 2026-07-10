# AWS parity overview — Simulith MVP

Consolidated view of **Simulith vs AWS** for the three MVP services: what is **implemented**, what is **missing**, **coverage percentages**, and **Terraform** status.

> **Console vs AWS Console (UI):** [`console-parity-overview.md`](console-parity-overview.md) — separate dimension  
> **Operational detail (operation × verify):** [`compatibility-matrix.md`](compatibility-matrix.md)  
> **Backlog IDs:** `cursor/company/future-work/`  
> **MVP scope:** `cursor/company/mvp-work-plan.md`

Last updated: 2026-07-10 (SML-121 — Lambda InvokeFunction sync subprocess).

---

## Executive summary

| Service | API ops **available** | Verified vs AWS (`simulith verify`) | Tier A coverage* | Tier B coverage† |
| --- | ---: | ---: | ---: | ---: |
| **DynamoDB** | 17 | 17 / 17 (100%) | **100%** (17 / 17) | **~38%** (17 / ~45) |
| **SQS** | 14 | 14 / 14 (100%) | **93%** (14 / 15) | **~55%** (14 / ~22) |
| **SSM** (Parameter Store) | 9 | 9 / 9 (100%) | **100%** (10 / 10) | **~58%** (9 / ~12) |
| **S3** | 8 | 8 / 8 (100%) | **89%** (8 / 9) | **~20%** (8 / ~40) |
| **Lambda** | 6 | — (SML-123 planned) | **~86%** (6 / 7 Tier A) | **~8%** (6 / ~75) |
| **Total** | **54** | **48 / 48 (100%)** verified | — | — |

\* **Tier A — POC / IaC / worker patterns:** operations we **ship** plus **P2 backlog** items teams hit in real evals (batch APIs, purge, SSM batch delete, etc.). Source: this doc + service `future-work/*/README.md`.

† **Tier B — full AWS API catalog (approx.):** share of the **documented AWS operation surface** for that service. Simulith intentionally implements a **subset**; low Tier B % is expected and not a product failure mode.

**Lambda is the second expansion service** (SML-120+). Function CRUD (SML-120) + sync invoke (SML-121). Next: SQS ESM (SML-122), verify (SML-123), Terraform (SML-124), Console panel (SML-125). ECS, EC2, VPC remain out of scope.

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

Guide: [dynamodb.md](dynamodb.md) · Backlog: `future-work/dynamodb/`

### Implemented (functional)

| Category | Operations |
| --- | --- |
| Table lifecycle | CreateTable, DescribeTable, ListTables, DeleteTable, UpdateTable |
| Items | PutItem, **BatchWriteItem**, **BatchGetItem**, **TransactWriteItems**, **TransactGetItems**, GetItem, UpdateItem, DeleteItem, Query, Scan |
| Tags | TagResource, UntagResource, ListTagsOfResource |

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Streams, TTL, export/import, real PITR restore | P3 | FW-DDB-020+ (PITR **metadata** APIs shipped for Terraform) |

### Tier A reference set (17 ops)

17 **available** = **100%** Tier A DynamoDB coverage.

---

## SQS

Guide: [sqs.md](sqs.md) · Backlog: `future-work/sqs/`

### Implemented (functional)

CreateQueue (standard, idempotent), SendMessage, SendMessageBatch, ReceiveMessage (long poll), DeleteMessage, DeleteMessageBatch, GetQueueAttributes, GetQueueUrl, ListQueues, DeleteQueue, **PurgeQueue**, **ChangeMessageVisibility** (+ batch), SetQueueAttributes.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| FIFO queues | P3 | FW-SQS-030 |
| TagQueue / ListQueueTags | P3 | FW-SQS-031 |

**Admin peek (non-AWS route):** `GET /_simulith/v1/sqs/messages` — shipped (SML-052); used for local debug, not AWS API parity.

### Tier A reference set (15 ops)

14 **available** + FIFO CreateQueue path = **93%**.

---

## SSM Parameter Store

Guide: [ssm.md](ssm.md) · Backlog: `future-work/ssm/`

### Implemented (functional)

PutParameter, GetParameter, DeleteParameter, **DeleteParameters**, GetParameters, GetParametersByPath, DescribeParameters (MVP filters), **AddTagsToResource**, **RemoveTagsFromResource**, **ListTagsForResource**.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Full ParameterFilters / labels | P3 | FW-SSM-021 |
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

### Terraform — still pending

| Item | Impact | Backlog |
| --- | --- | --- |
| Terraform CI job (apply/destroy in GitHub Actions) | Repeatable IaC smoke | deferred in SML-024 |
| Import for SQS queues | Secondary workflows | terraform-integration.md |
| Prod-only `.example` files (GSI prod, FIFO, SSE) | Expect partial — not green without reading limits | service future-work |

DynamoDB **import** for tables and SSM **import** for parameters are **documented** (SML-041, SML-057). SQS import remains secondary.

---

## Console vs AWS Console

**Full panel-by-panel analysis:** [`console-parity-overview.md`](console-parity-overview.md).

Simulith Console (**FW-PRD-001** + **FW-PRD-013** / SML-055 + **FW-PRD-015** / SML-056 + **FW-PRD-005** / SML-059 Verify panel + **FW-PRD-012** / SML-060 all-in-one Compose) ships MVP panels for DynamoDB, SQS, SSM, verify report import, and single-port workshop demo (~**92%** of reference Console flows — see [`console-parity-overview.md`](console-parity-overview.md)).

---

## S3

Guide: [s3.md](s3.md) · Backlog: `future-work/s3/`

### Implemented (functional)

CreateBucket (idempotent), ListBuckets, DeleteBucket (empty), PutObject, GetObject, HeadObject, DeleteObject, CopyObject, DeleteObjects (batch), ListObjectsV2 (prefix, max-keys, continuation-token).

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Console S3 panel | P2 | FW-S3-011 |
| Multipart upload | P3 | FW-S3-007 |
| Multipart upload, versioning | P3 | FW-S3-020, FW-S3-021 |

### Tier A reference set (9 ops)

9 **available** = **100%** Tier A S3 coverage (DeleteObjects batch is additional).

---

## Lambda

Guide: [lambda.md](lambda.md) · Backlog: `future-work/lambda/`

### Implemented (SML-120 + SML-121)

CreateFunction, ListFunctions, GetFunction, DeleteFunction, **InvokeFunction** (sync subprocess), **UpdateFunctionCode**.

Metadata in SQLite (`lambda_functions`). Zip stored at `{data-dir}/lambda/{name}/code.zip`. Protocol: `rest-json` on `/2015-03-31/functions/…`.

**Invoke:** `nodejs*` and `python*` runtimes execute handler code via subprocess (`node` / `python3` on PATH). `Environment.Variables` injected; `Timeout` honored. Docker image does not include Node/Python — use host binaries or extend the image for container-only workflows.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Event Source Mapping SQS | P1 | FW-LAM-003 / SML-122 |
| simulith verify lambda | P1 | FW-LAM-004 / SML-123 |
| Terraform green path | P1 | FW-LAM-005 / SML-124 |
| Console Lambda panel | P1 | FW-LAM-006 / SML-125 |
| Async invoke + Function URLs | P2 | FW-LAM-007 |

### Tier A reference set (7 ops)

6 **available** = **~86%** Tier A Lambda coverage. Remaining Tier A: CreateEventSourceMapping (SML-122).

---

## What to do next (priority)

**Lambda expansion activa:** SML-120 + **SML-121** shipped (CRUD + sync invoke). Siguiente: **SML-122** (SQS ESM). Verify MVP ops **40/40** ✅ (**SML-080**). **Reservado:** **SML-081** / FW-CMP-012.

| Priority | Theme | Story |
| --- | --- | --- |
| **P1** | Lambda SQS ESM + verify + Terraform + Console | SML-122–125 |
| **P3** | Historial parity entre releases | **SML-081** / FW-CMP-012 ← reservado |

---

## Maintenance

Update this overview when:

- Shipping or removing an HTTP operation ([`compatibility-matrix.md`](compatibility-matrix.md) same PR).
- Changing Terraform green path status ([`terraform-integration.md`](terraform-integration.md)).
- Shipping Console capabilities ([`console-parity-overview.md`](console-parity-overview.md) + [`console.md`](console.md) + `FW-PRD-*`).

Follow `cursor/company/DOCUMENTATION-GOVERNANCE.md`. **Do not** copy the full matrix here — link to it. **Do not** list P2 backlog in detail — link to `future-work/`.

---

## Related

- [compatibility-matrix.md](compatibility-matrix.md) — operation-level truth table
- [compatibility.md](compatibility.md) — running verify
- smithy-contracts.md — structural contract (Smithy AST)
- [console-parity-overview.md](console-parity-overview.md) — Console vs AWS Console (UI)
- mvp-work-plan.md — MVP exit criteria (met)
