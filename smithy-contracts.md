# Smithy contracts — Simulith MVP

How Simulith uses official AWS Smithy JSON AST models as the **structural** contract source for local emulation.

## Source of truth

| Layer | Source | Role |
| --- | --- | --- |
| **Structure** | [aws/api-models-aws](https://github.com/aws/api-models-aws) (Smithy JSON AST, Apache-2.0) | Operations, input/output shapes, HTTP bindings, error shapes |
| **Behavior** | Compatibility runner (Phase 4) + tests against real AWS | Semantics, edge cases, pagination, conditionals |
| **Human reference** | AWS API docs | Examples and DX guides only — not copied into the repo |

When docs conflict on **scope**, follow `cursor/company/mvp-work-plan.md`. When they conflict on **shape**, prefer the vendored Smithy model at the pinned commit.

## MVP service models

Subset for the MVP (DynamoDB, SSM first; SQS uses a different protocol — see below):

| Service | Model path (upstream) | API version | Protocol |
| --- | --- | --- | --- |
| DynamoDB | `models/dynamodb/service/2012-08-10/dynamodb-2012-08-10.json` | 2012-08-10 | `awsJson1_0` |
| SSM (Parameter Store) | `models/ssm/service/2014-11-06/ssm-2014-11-06.json` | 2014-11-06 | `awsJson1_1` |
| SQS | `models/sqs/service/2012-11-05/sqs-2012-11-05.json` | 2012-11-05 | **`awsQuery`** / `awsQueryCompatible` — **SML-014+** |

### Protocol note (important)

- **SML-004** implements **AWS JSON** protocols: `awsJson1_0` and `awsJson1_1`.
- **SML-014+** implements **AWS Query** for SQS (`awsQueryCompatible`): form body + XML responses.

## Vendoring strategy

1. **Pin** an `api-models-aws` commit SHA in `runtime/internal/contracts/MODELS.md` (added during SML-004 implementation).
2. **Vendor** only the three JSON files above under:

   ```text
   runtime/internal/contracts/models/
   ├── dynamodb-2012-08-10.json
   ├── ssm-2014-11-06.json
   └── sqs-2012-11-05.json   # SML-014+ Query registry
   ```

3. **Do not** submodule the full `api-models-aws` repo (700+ services).
4. **Refresh** models intentionally (PR + note in `implementation-notes.md`), not on every upstream daily release.

## Build-time vs runtime

| Approach | MVP choice | Rationale |
| --- | --- | --- |
| Parse Smithy AST at **build time** | **Yes (recommended)** | Generate or embed operation routing tables; fail CI if model parse breaks |
| Parse Smithy AST on **every request** | No | Large JSON files; unnecessary per-request cost |
| Full `smithy-go` codegen for all shapes | Defer | Heavy for MVP; start with routing + dynamic JSON for stub responses |

SML-004 delivers the **protocol layer** (HTTP + headers + JSON envelope). Service handlers (DynamoDB CRUD, etc.) consume the same contract metadata in later phases.

## What Smithy gives Simulith

- Operation IDs and `X-Amz-Target` values (e.g. `DynamoDB_20120810.PutItem`)
- Request/response member names and types
- `@http` traits (method, URI, `Content-Type`)
- Service error shapes for SML-006

## What Smithy does not give

- Local persistence semantics
- IAM authorization rules
- Full runtime edge-case behavior
- Cross-service interactions

Document intentional deviations in `runtime/docs/` and in the feature's `implementation-notes.md`.

## MVP operations (subset)

Smithy models cover the **full service AST**; Simulith implements a **documented subset** (see matrix).

| Service | MVP operations (original) | Shipped locally |
| --- | --- | --- |
| DynamoDB | CreateTable, DescribeTable, PutItem, GetItem, UpdateItem, DeleteItem, Query, Scan | + ListTables, DeleteTable, UpdateTable, GSI/LSI, tags — [compatibility-matrix.md](compatibility-matrix.md) |
| SSM | PutParameter, GetParameter | + DeleteParameter, GetParameters*, DescribeParameters — [ssm.md](ssm.md); verify: `simulith verify ssm` |
| SQS | CreateQueue, SendMessage, ReceiveMessage, DeleteMessage | + GetQueueUrl, GetQueueAttributes, batches, long poll, … — [sqs.md](sqs.md) |

## Related docs

- Product scope: `cursor/company/mvp-work-plan.md`
- Runtime context: `cursor/projects/runtime/project-context.md`
- SML-004 analysis: `cursor/analysis/features/_core/simulith-aws-json-protocol-support/analysis.md`
- AWS models README: [api-models-aws README](https://github.com/aws/api-models-aws/blob/main/README.md)
