# AWS parity overview — Simulith MVP

Consolidated view of **Simulith vs AWS** for shipped services (Foundation + S3 + Lambda + API Gateway + Secrets Manager expansion): what is **implemented**, what is **missing**, **coverage percentages**, and **Terraform** status.

> **Console vs AWS Console (UI):** [`console.md`](console.md) — separate dimension
> **Operational detail (operation × verify):** [`compatibility-matrix.md`](compatibility-matrix.md)

Last updated: 2026-08-04..

> **Release history:** [`parity-release-history.md`](parity-release-history.md) — ops/verify series per release.

---

## Executive summary

| Service | API ops **available** | Verified vs AWS (`simulith verify`) | Tier A coverage* | Tier B coverage† |
| --- | ---: | ---: | ---: | ---: |
| **DynamoDB** | 17 | 17 / 17 (100%) | **100%** (17 / 17) | **~38%** (17 / ~45) |
| **SQS** | 14 | 14 / 14 (100%) | **93%** (14 / 15) | **~55%** (14 / ~22) |
| **SSM** (Parameter Store) | 9 | 10 / 10 (100%) | **100%** (10 / 10) | **~58%** (9 / ~12) |
| **S3** | 8 | 8 / 8 (100%) | **89%** (8 / 9) | **~20%** (8 / ~40) |
| **Lambda** | 21 | 9 / 9 scenarios (100%) | **100%** (7 / 7 Tier A) | **~13%** (21 / ~75) |
| **API Gateway** | 4 | 4 / 4 scenarios | **100%** (4 / 4 Tier A) | **~5%** (4 / ~80) |
| **Secrets Manager** | 4 | 2 / 2 scenarios | — | **~5%** (4 / ~80) |
| **Cognito** | 23 | 2 / 2 scenarios | — | **~8%** (23 / ~300) |
| **SES** | 12 | 2 / 2 scenarios | — | **~4%** (12 / ~300) |
| **EventBridge** | 9 | 2 / 2 scenarios | — | **~3%** (9 / ~300) |
| **VPC (EC2)** | 33 | 2 / 2 scenarios | — | **~11%** (33 / ~300) |
| **RDS** | 15 | 2 / 2 scenarios | — | **~5%** (15 / ~300) |
| **IAM** | 9 | — | — | **~3%** (9 / ~300) |
| **KMS** | 6 | — | — | **~2%** (6 / ~300) |
| **Total** | **165** | Foundation **48 / 48** ops · Lambda **9 / 9** scenarios | — | — |

\* **Tier A — POC / IaC / worker patterns:** operations we **ship** plus **P2 backlog** items teams hit in real evals (batch APIs, purge, SSM batch delete, etc.). Source: this doc + service the product backlog.

† **Tier B — full AWS API catalog (approx.):** share of the **documented AWS operation surface** for that service. Simulith intentionally implements a **subset**; low Tier B % is expected and not a product failure mode.

**Lambda expansion:** MVP + P2 complete. **API Gateway B3:** complete. **Secrets Manager B4:** complete. Seed demo secret **`demo-secret`** in default fixture.

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

CreateBucket (idempotent), ListBuckets, DeleteBucket (empty), PutObject, GetObject, HeadObject, DeleteObject, CopyObject, DeleteObjects (batch), ListObjectsV2 (prefix, max-keys, continuation-token), **multipart upload**.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Versioning | P3 | FW-S3-021 |

### Tier A reference set (9 ops)

9 **available** = **100%** Tier A S3 coverage (DeleteObjects batch is additional).

---

## Lambda

Guide: [lambda.md](lambda.md) · Backlog: the product backlog

### Implemented

CreateFunction, ListFunctions, GetFunction, DeleteFunction, InvokeFunction (sync + async Event), UpdateFunctionCode, **UpdateFunctionConfiguration** (`VpcConfig` subnets + security groups), **SQS Event Source Mapping** (Create/List/Get/Delete + background poll), **Function URLs**, **Lambda Layers** (publish/list/get/delete + `Layers` on CreateFunction). Default seed includes **`demo-fn`**.

Metadata in SQLite (`lambda_functions`, `lambda_event_source_mappings`, `lambda_layer_versions`). Function zip at `{data-dir}/lambda/{name}/code.zip`; layer zips at `{data-dir}/lambda/layers/{name}/{version}/code.zip`.

**ESM poller:** enabled mappings poll SQS every ~1s, invoke target function with `Records` batch, delete messages on success.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Aliases, versions, Go runtime | P3 | ,  |

**Shipped:** async invoke (`InvocationType: Event`) and Function URLs.

**Shipped:** Lambda Layers (`PublishLayerVersion`, layer CRUD, `Layers` on CreateFunction, nodejs `NODE_PATH` on invoke). **:** python `PYTHONPATH` on invoke.

**Shipped:** `VpcConfig` on CreateFunction / UpdateFunctionConfiguration; invoke reachability to RDS Proxy endpoint (`127.0.0.1:<port>`) when VpcConfig set. Terraform [`examples/terraform/lambda-vpc-rds/full-stack-min/`](examples/terraform/lambda-vpc-rds/full-stack-min/). No real ENI — metadata + host-network invoke path.

### Tier A reference set (7 ops)

7 **available** = **100%** Tier A Lambda coverage.

---

## API Gateway

Guide: [apigateway.md](apigateway.md) · Backlog: the product backlog

### Implemented

CreateRestApi, GetRestApis, GetRestApi, DeleteRestApi, CreateResource, PutMethod, PutIntegration (`AWS_PROXY`), CreateDeployment, CreateStage, stage HTTP invoke (`/_user_request_/` → Lambda). `simulith verify apigateway`, Terraform green path, Console panel, default seed REST API **`demo-api`** (stage `dev` → `demo-fn`). SQLite `apigateway_*` tables. SigV4 `apigateway` for management; invoke path without SigV4.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| HTTP API (v2), authorizers, custom domains | P3 | + |

Management + stage invoke operations — see [apigateway.md](apigateway.md) and [compatibility-matrix.md](compatibility-matrix.md).

---

## Secrets Manager

Guide: [secretsmanager.md](secretsmanager.md) · Backlog: the product backlog

### Implemented

CreateSecret, DescribeSecret, PutSecretValue, GetSecretValue, ListSecrets, DeleteSecret, GetResourcePolicy stub (plain `SecretString`). `simulith verify secretsmanager`. Terraform green path [`examples/terraform/secretsmanager/`](examples/terraform/secretsmanager/). Console panel `/secretsmanager`. Default seed secret **`demo-secret`**. SQLite `secretsmanager_secrets`. SigV4 `secretsmanager` + `X-Amz-Target: SecretsManager.*`.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Console, seed | — | — |
| Rotation, resource policies, KMS CMK | P3 | + |

See [secretsmanager.md](secretsmanager.md) for limits.

---

## Cognito

Guide: [cognito.md](cognito.md) · Backlog: the product backlog

### Implemented

CreateUserPool, DescribeUserPool, ListUserPools, DeleteUserPool, UpdateUserPool; UserPoolClient CRUD; Group CRUD; UserPoolDomain CRUD (metadata); JWKS GET `/{userPoolId}/.well-known/jwks.json`. AdminCreateUser, AdminGetUser, AdminSetUserPassword, AdminConfirmSignUp, AdminEnableUser, AdminDisableUser, AdminInitiateAuth (RS256 Access/Id tokens). **Lambda triggers** PreSignUp + PostConfirmation on admin lifecycle. Terraform green path [`examples/terraform/cognito/`](examples/terraform/cognito/). **`simulith verify cognito`** (2 scenarios). Console panel `/cognito`. Default seed pool **`demo-pool`**. Product messaging + docs sync.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| SignUp / ConfirmSignUp public APIs | P2 | follow-up |
| Console / seed / messaging | P1–P2 | **Shipped**  / 175 / 176 / 177 |

---

## SES

Guide: [ses.md](ses.md) · Backlog: the product backlog

### Implemented

VerifyEmailIdentity, DeleteIdentity, ListIdentities, GetIdentityVerificationAttributes; CreateTemplate / GetTemplate / UpdateTemplate / DeleteTemplate / ListTemplates; SendEmail / SendTemplatedEmail / SendRawEmail (local outbox). Terraform green path [`examples/terraform/ses/`](examples/terraform/ses/). **`simulith verify ses`** (2 scenarios). Console panel `/ses`. Default seed identity **`demo@simulith.local`** + template **`demo-template`**. Product messaging + docs sync.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Seed demo identity/template | P2 | **Shipped ** |
| Public messaging (landing/Hub) | P2 | **Shipped ** |
| Public docs sync (mirror smoke) | P2 | **Shipped ** |

---

## EventBridge

Guide: [eventbridge.md](eventbridge.md) · Backlog: the product backlog

### Implemented

PutRule, DeleteRule, DescribeRule, ListRules, EnableRule, DisableRule, PutTargets, RemoveTargets, ListTargetsByRule; **PutEvents** on default bus with event-pattern rules → Lambda; schedule poller → Lambda InvokeSync. Terraform green path [`examples/terraform/eventbridge/`](examples/terraform/eventbridge/). **`simulith verify eventbridge`** (2 scenarios).

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Custom event buses | P3 |  |
| Console panel | P1 | **Shipped ** |

---

## VPC (EC2 networking)

Guide: [vpc.md](vpc.md) · Backlog: the product backlog

### Implemented

CreateVpc / DescribeVpcs / DeleteVpc / ModifyVpcAttribute / DescribeVpcAttribute; CreateSubnet / DescribeSubnets / DeleteSubnet; CreateSecurityGroup + ingress/egress rules; IGW attach/detach; route tables + routes + associations; gateway VPC endpoints (S3/DynamoDB metadata); CreateTags / DescribeTags. **Lambda `VpcConfig`** on CreateFunction / UpdateFunctionConfiguration; invoke reaches RDS Proxy endpoint when configured (metadata path — no real ENI). Terraform green path [`examples/terraform/vpc/network-min/`](examples/terraform/vpc/network-min/) + [`lambda-vpc-rds/full-stack-min/`](examples/terraform/lambda-vpc-rds/full-stack-min/) (apply local). **Console panel `/vpc`**. **`simulith verify vpc`** (2 scenarios).

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Interface VPC endpoints | P3 |  |

---

## RDS (Postgres sidecar)

Guide: [rds.md](rds.md) · Backlog: the product backlog

### Implemented

CreateDBSubnetGroup / DescribeDBSubnetGroups / DeleteDBSubnetGroup; CreateDBParameterGroup / DescribeDBParameterGroups / DeleteDBParameterGroup (minimal stub); CreateDBInstance / DescribeDBInstances / DeleteDBInstance (**Postgres 15 Docker sidecar**); **CreateDBProxy / DescribeDBProxies / DeleteDBProxy**; **RegisterDBProxyTargets / DeregisterDBProxyTargets**; **ModifyDBProxyTargetGroup** (stub). Instance endpoint `127.0.0.1:<hostPort>`; proxy endpoint `127.0.0.1:<proxyPort>` via TCP relay. Terraform green path [`examples/terraform/rds/postgres-min/`](examples/terraform/rds/postgres-min/) + [`proxy-min/`](examples/terraform/rds/proxy-min/) (apply local). **Console panel `/rds`**. SQLite `rds_db_*`. SigV4 `rds` + `X-Amz-Target: AmazonRDSv2014-10-31.*`. **`simulith verify rds`** (2 scenarios; Docker required).

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| MySQL / MariaDB engines | P3 | — |
| RDS Proxy Console panel | P2 | — |

---

## KMS

Guide: [kms.md](kms.md) · Backlog: the product backlog

### Implemented

CreateKey / DescribeKey; CreateAlias / ListAliases; Encrypt / Decrypt (mock symmetric envelope). Secrets Manager accepts `KmsKeyId` on CreateSecret. Terraform green-path [`examples/terraform/kms/cmk-min/`](examples/terraform/kms/cmk-min/). SQLite `kms_keys`, `kms_aliases`. SigV4 `kms` JSON 1.1 (`TrentService.*`).

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| `simulith verify kms` | P1 |  |
| Console panel | P1 |  |
| Grants / rotation / multi-Region | P3 | — |

---

## IAM

Guide: [iam.md](iam.md) · Backlog: the product backlog

### Implemented

CreateRole / GetRole / DeleteRole; CreatePolicy / GetPolicy / DeletePolicy; AttachRolePolicy / DetachRolePolicy / ListAttachedRolePolicies (RDS Proxy role subset). Terraform green-path [`examples/terraform/iam/proxy-roles-min/`](examples/terraform/iam/proxy-roles-min/). SQLite `iam_*`. SigV4 `iam` Query API.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| `simulith verify iam` | P1 |  |
| Console panel | P1 |  |
| Product messaging / docs sync | P2 |  /  |

---

## What to do next (priority)

**Next depth:** Cognito SignUp / ConfirmSignUp APIs (optional follow-up).

| Priority | Theme | Backlog |
| --- | --- | --- |
| **Breadth** | EventBridge custom buses |  (remainder) |

---

## Related

- [compatibility-matrix.md](compatibility-matrix.md) — operation-level truth table
- [compatibility.md](compatibility.md) — running verify

- [console.md](console.md) — Console vs AWS Console (UI)
