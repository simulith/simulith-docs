# AWS parity overview — Simulith

Consolidated view of **Simulith vs AWS** for **seventeen** shipped services: what is **implemented**, what is **missing**, **coverage percentages**, and **Terraform** status.

> **Audience:** evaluators comparing Simulith to AWS at scale. **Developers** can use [compatibility-matrix.md](compatibility-matrix.md) and service guides for day-to-day work.

> **Important:** **Tier A %** = **`available / ref`** on a curated op list per service ([methodology](#tier-a-methodology-standard)) — the **reliable** progress metric. **Tier B** is **indicative only** ([methodology](#tier-b-indicative-not-audited)) — do not treat as precise AWS parity.

> **Console panels:** [console.md](console.md) · **Operation × verify:** [compatibility-matrix.md](compatibility-matrix.md)

Last updated: 2026-08-20..

---

## Which number should I use?

| Question | Where to look | Reliable? |
| --- | --- | --- |
| Did we ship what we promised for POC / Terraform / workers? | **Tier A** — `% (available / ref)` in the table below | **Yes** — enumerated per service |
| Does behavior match real AWS on curated paths? | **Verify** column + [`compatibility-matrix.md`](compatibility-matrix.md) | **Yes** — scenario-backed |
| How much of the full AWS API catalog exists? | **AWS catalog scale** (Tier B) | **Indicative only** — see [Tier B methodology](#tier-b-indicative-not-audited) |
| Are Console, seed, and public docs done? | [Expansion surfaces](#expansion-surfaces-service-readiness) | **Yes** — checklist |

**Rule of thumb:** trust **Tier A + verify + matrix** for decisions; treat Tier B bands as rough context, not a sales percentage.

---

## Executive summary

| Service | API ops **available** | Verified vs AWS (`simulith verify`) | Tier A coverage* | AWS catalog scale† |
| --- | ---: | ---: | ---: | ---: |
| **DynamoDB** | 17 | 17 / 17 (100%) | **100%** (17 / 17) | medium (~38%‡) |
| **SQS** | 14 | 14 / 14 (100%) | **93%** (14 / 15) | medium–high (~64%‡) |
| **SSM** (Parameter Store) | 10 | 10 / 10 (100%) | **90%** (9 / 10) | high (~83%‡) |
| **S3** | 21 | 8 / 8 scenarios (100%) | **100%** (9 / 9 ref) | medium (~50%‡) |
| **Lambda** | 22 | 9 / 9 scenarios (100%) | **100%** (7 / 7 Tier A) | low (~29%‡) |
| **API Gateway** | 14 | 4 / 4 scenarios | **100%** (4 / 4 Tier A) | low (~18%‡) |
| **Secrets Manager** | 4 | 2 / 2 scenarios | **100%** (4 / 4) | low (~5%‡) |
| **Cognito** | 16 | 2 / 2 scenarios | **90%** (18 / 20) | **low subset** |
| **SES** | 4 | 2 / 2 scenarios | **100%** (12 / 12) | **low subset** |
| **EventBridge** | 5 | 2 / 2 scenarios | **100%** (10 / 10) | **low subset** |
| **VPC** | 8 | 5 / 5 scenarios | **100%** (17 / 17) | **low subset** |
| **RDS** | 9 | 2 / 2 scenarios | **100%** (17 / 17) | **low subset** |
| **IAM** | 3 | 2 / 2 scenarios | **100%** (9 / 9) | **low subset** |
| **KMS** | 11 | 2 / 2 scenarios | **100%** (12 / 12) | **low subset** |
| **Route 53** | 7 | 2 / 2 scenarios | **100%** (7 / 7) | **low subset** |
| **ACM** | 5 | 2 / 2 scenarios | **100%** (5 / 5) | **low subset** |
| **CloudFront** | 9 | 2 / 2 scenarios | **100%** (9 / 9) | **low subset** |
| **Total** | **179** | 17 services with verify | **~98%** Tier A (180 / 184 ref) | — |

\* **Tier A — POC / IaC / worker patterns:** `% (available / ref)` on a **curated, enumerated op list** per service ([methodology](#tier-a-methodology-standard)). **Use this for progress.**

† **AWS catalog scale (Tier B — indicative):** rough sense of Simulith vs the **full AWS API surface**. **Not CI-gated; denominators are manual estimates** (Foundation) or **not audited** (expansion → **low subset** only). See [Tier B methodology](#tier-b-indicative-not-audited).

‡ Foundation / B1–B4 only: legacy **`~NN% (available / ~catalog)`** from a one-time manual pass (~45 DynamoDB ops, ~22 SQS, …). Treat as **order-of-magnitude**, not a contract.

**How to read progress:** **Tier A** = committed eval/IaC ops shipped · **Verify** = curated scenarios vs real AWS · **Tier B** = rough catalog context only · [Expansion surfaces](#expansion-surfaces-service-readiness) = Terraform / Console / seed / docs.

**Lambda expansion:** complete. **API Gateway B3:** complete. **Secrets Manager B4:** complete. Seed demo secret **`demo-secret`** in default fixture.

---

## Tier A methodology (standard)

Same rules as Foundation (DynamoDB / SQS / SSM — `ROADMAP-COMMERCIAL-PARITY.md`) and expansion B1–B4 (S3 / Lambda / API Gateway / Secrets Manager).

| Rule | Detail |
| --- | --- |
| **Unit** | Individual **AWS API operation names** (not matrix row groups, not Console flows) |
| **Reference set** | Enumerated per service below; open gaps stay in the set with `FW-*` in the product backlog |
| **Numerator** | Ops in the set marked **available** in [`compatibility-matrix.md`](compatibility-matrix.md) |
| **Denominator** | Total ops in that service’s Tier A list (includes P2/P3 deferrals still counted, e.g. FIFO, `SignUp`) |
| **Display** | **`NN% (available / ref)`** — e.g. **93% (14 / 15)** |
| **≠ AWS parity** | Full AWS catalog → [Tier B](#tier-b-indicative-not-audited) (indicative bands only) |

When shipping a **new service**, add the Tier A table to the product backlog and this overview in the same PR (`DOCUMENTATION-GOVERNANCE.md`). Tier B: label **low subset** until a catalog denominator is audited (optional future `FW-CMP-*`).

---

## Tier B (indicative — not audited)

Tier B answers: **roughly how much of AWS’s full API catalog does Simulith cover?** Today this is **not** a reliable metric — document it for context only.

| Issue | Detail |
| --- | --- |
| **No mechanical source** | Unlike Tier A, Tier B is **not** computed from [`compatibility-matrix.md`](compatibility-matrix.md) + Smithy in CI |
| **Foundation / B1–B4** | Legacy **`~NN%`** used manual catalog guesses (~45 DynamoDB ops, ~22 SQS, ~12 SSM, ~40 S3, …) from a one-time review — **order-of-magnitude** |
| **Expansion services** | Placeholder **`~300`** denominators were **never audited** — removed from the executive table; use **low subset** instead |
| **Numerator inconsistency** | “API ops available” counts **matrix rows**, while Tier A counts **individual operation names** — Tier B % mixed both; do not reconcile |
| **What to trust** | **Tier A `(available / ref)`**, **verify scenarios**, and the **compatibility matrix** — not Tier B % |

**Future (optional):** script against vendored Smithy / AWS API models per service (`FW-CMP-*`) to replace bands with audited denominators — same rigor as Tier A.

---

## Expansion surfaces (service readiness)

Per-service checklist beyond raw API counts — same **seven surfaces** as `SERVICE-EXPANSION-TEMPLATE.md`.

| Service | Tier A API | Verify | Terraform | Console | Seed | Docs sync |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| **DynamoDB** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **SQS** | 93% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **SSM** | 90% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **S3** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Lambda** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **API Gateway** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Secrets Manager** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Cognito** | 90% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **SES** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **EventBridge** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **VPC** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **RDS** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **IAM** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **KMS** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Route 53** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **ACM** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |
| **CloudFront** | 100% | ✅ | ✅ | ✅ | ✅ | ✅ |

**Legend:** ✅ shipped · ⏳ open in the product backlog (expansion depth).

**Tier A aggregate (184 ref ops):** Foundation **40 / 42** · S3–Secrets Manager **24 / 24** · Cognito–CloudFront **116 / 118** · **Overall ~98% (180 / 184)**.

---

## How to read the tables

| Column | Meaning |
| --- | --- |
| **Available** | HTTP handler shipped — see service guide for documented limits |
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

PutParameter, GetParameter, DeleteParameter, **DeleteParameters**, GetParameters, GetParametersByPath, DescribeParameters (supported filters), **AddTagsToResource**, **RemoveTagsFromResource**, **ListTagsForResource**.

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

Simulith Console ships panels through **IAM** plus verify import (~**60 / 60** reference flows — see [`console.md`](console.md)).

---

## S3

Guide: [s3.md](s3.md) · Backlog: the product backlog

### Implemented (functional)

CreateBucket (idempotent), ListBuckets, DeleteBucket (empty), PutObject, GetObject, HeadObject, DeleteObject, CopyObject, DeleteObjects (batch), ListObjectsV2 (prefix, max-keys, continuation-token), **ListObjectVersions**, **multipart upload**, bucket versioning / SSE-S3 / lifecycle / tagging config.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| SSE-KMS | P3 | FW-S3-023 |
| Noncurrent version history / delete markers | P3 | remainder after  |

### Tier A reference set (9 ops)

CreateBucket, ListBuckets, DeleteBucket, PutObject, GetObject, HeadObject, DeleteObject, ListObjectsV2, Put/Get bucket versioning.

9 **available** = **100%** Tier A S3 (9 / 9). CopyObject / DeleteObjects / multipart / SSE-S3 / lifecycle / tagging are shipped extras outside this ref set.

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

### Tier A reference set (20 ops)

| Operation | Tier A | Status |
| --- | ---: | --- |
| CreateUserPool, DescribeUserPool, DeleteUserPool | ✓ | available |
| CreateUserPoolClient, ListUserPoolClients, DeleteUserPoolClient | ✓ | available |
| CreateGroup, GetGroup, ListGroups, DeleteGroup | ✓ | available |
| JWKS `GET /.well-known/jwks.json` | ✓ | available |
| AdminCreateUser, AdminGetUser, AdminSetUserPassword, AdminConfirmSignUp | ✓ | available |
| AdminEnableUser, AdminDisableUser, AdminInitiateAuth | ✓ | available |
| **SignUp**, **ConfirmSignUp** | ✓ | **gap** (P2 follow-up) |

18 **available** = **90%** Tier A Cognito (18 / 20). Shipped extras (ListUserPools, UpdateUserPool, UserPoolDomain, Lambda triggers) are outside this ref set.

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

### Tier A reference set (12 ops)

VerifyEmailIdentity, DeleteIdentity, ListIdentities, GetIdentityVerificationAttributes; CreateTemplate, GetTemplate, UpdateTemplate, DeleteTemplate, ListTemplates; SendEmail, SendTemplatedEmail, SendRawEmail.

12 **available** = **100%** Tier A SES (12 / 12).

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

### Tier A reference set (10 ops)

PutRule, DeleteRule, DescribeRule, ListRules, EnableRule, DisableRule, PutTargets, RemoveTargets, ListTargetsByRule, PutEvents.

10 **available** = **100%** Tier A EventBridge (10 / 10). Custom event buses (`CreateEventBus`) remain P3.

---

## VPC (EC2 networking)

Guide: [vpc.md](vpc.md) · Backlog: the product backlog

### Implemented

CreateVpc / DescribeVpcs / DeleteVpc / ModifyVpcAttribute / DescribeVpcAttribute; CreateSubnet / DescribeSubnets / DeleteSubnet; CreateSecurityGroup + ingress/egress rules; IGW attach/detach; **Elastic IP** (AllocateAddress / Describe / Disassociate / Release); **NAT Gateway** (Create/Describe/Delete — stub ENI + documentation-range public IP; no packet NAT); **Network ACLs** (default + custom metadata — no packet filter); route tables + routes (`GatewayId` or `NatGatewayId`) + associations; gateway VPC endpoints (S3/DynamoDB metadata); **Interface VPC endpoints** (subnet/SG/private DNS + stub ENI/DNS entries — no PrivateLink data plane); CreateTags / DescribeTags. **Lambda `VpcConfig`** on CreateFunction / UpdateFunctionConfiguration; invoke reaches RDS Proxy endpoint when configured (metadata path — no real ENI). Terraform green path [`examples/terraform/vpc/network-min/`](examples/terraform/vpc/network-min/) + [`vpc/interface-endpoint-min/`](examples/terraform/vpc/interface-endpoint-min/) + [`vpc/nat-gateway-min/`](examples/terraform/vpc/nat-gateway-min/) + [`vpc/network-acl-min/`](examples/terraform/vpc/network-acl-min/) + [`lambda-vpc-rds/full-stack-min/`](examples/terraform/lambda-vpc-rds/full-stack-min/) (apply local). **Console panel `/vpc`**. Public docs sync. **`simulith verify vpc`** (5 scenarios).

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Public messaging (landing/Hub) | P2 | **Shipped ** |
| Seed demo VPC | P2 |  |
| Public docs sync (mirror smoke) | P2 | **Shipped ** |

### Tier A reference set (17 ops)

CreateVpc, DescribeVpcs, DeleteVpc; CreateSubnet, DescribeSubnets, DeleteSubnet; CreateSecurityGroup, DescribeSecurityGroups, AuthorizeSecurityGroupIngress, AuthorizeSecurityGroupEgress; CreateInternetGateway, AttachInternetGateway; CreateRouteTable, DescribeRouteTables, CreateRoute, AssociateRouteTable; CreateVpcEndpoint; Lambda **VpcConfig** on CreateFunction / UpdateFunctionConfiguration.

17 **available** = **100%** Tier A VPC (17 / 17). NAT Gateway + EIP and Network ACLs are shipped beyond this original ref set — metadata only; no packet path.

---

## RDS (Postgres sidecar)

Guide: [rds.md](rds.md) · Backlog: the product backlog

### Implemented

CreateDBSubnetGroup / DescribeDBSubnetGroups / DeleteDBSubnetGroup; CreateDBParameterGroup / DescribeDBParameterGroups / DeleteDBParameterGroup; **ModifyDBParameterGroup / DescribeDBParameters**; CreateDBInstance / **ModifyDBInstance** / DescribeDBInstances / DeleteDBInstance; **CreateDBProxy / DescribeDBProxies / DeleteDBProxy**; **ModifyDBProxy**; **RegisterDBProxyTargets / DescribeDBProxyTargets / DeregisterDBProxyTargets**; **ModifyDBProxyTargetGroup / DescribeDBProxyTargetGroups**. Instance endpoint `127.0.0.1:<hostPort>`; proxy endpoint `127.0.0.1:<proxyPort>` via TCP relay. Terraform green path [`examples/terraform/rds/postgres-min/`](examples/terraform/rds/postgres-min/) + [`proxy-min/`](examples/terraform/rds/proxy-min/) (apply local) + [`vpc-rds-proxy-min/`](examples/terraform/rds/vpc-rds-proxy-min/). **Console panel `/rds`**. Default seed instance **`demo-db`**. Product messaging + docs sync. SQLite `rds_db_*`. SigV4 `rds` + `X-Amz-Target: AmazonRDSv2014-10-31.*`. **`simulith verify rds`** (2 scenarios; Docker required).

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Seed demo instance | P2 | **Shipped ** |
| Public messaging (landing/Hub) | P2 | **Shipped ** |
| Public docs sync (mirror smoke) | P2 | **Shipped ** |
| MySQL / MariaDB engines | P3 | — |

### Tier A reference set (17 ops)

CreateDBSubnetGroup, DescribeDBSubnetGroups, DeleteDBSubnetGroup; CreateDBParameterGroup, DescribeDBParameterGroups, DeleteDBParameterGroup; ModifyDBParameterGroup, DescribeDBParameters; CreateDBInstance, ModifyDBInstance, DescribeDBInstances, DeleteDBInstance; CreateDBProxy, DescribeDBProxies, DeleteDBProxy; RegisterDBProxyTargets, DeregisterDBProxyTargets; ModifyDBProxyTargetGroup (stub).

17 **available** = **100%** Tier A RDS (17 / 17). ModifyDBInstance and ModifyDBProxy / DescribeDBProxyTargetGroups are shipped extras outside this original ref set.

---

## KMS

Guide: [kms.md](kms.md) · Backlog: the product backlog

### Implemented

CreateKey / DescribeKey; CreateAlias / ListAliases / DeleteAlias; Encrypt / Decrypt; ScheduleKeyDeletion (mock symmetric envelope); **EnableKeyRotation / DisableKeyRotation / GetKeyRotationStatus**. Secrets Manager accepts `KmsKeyId` on CreateSecret. **Terraform green path** [`examples/terraform/kms/cmk-min/`](examples/terraform/kms/cmk-min/) — apply + destroy with `enable_key_rotation`. **`simulith verify kms`**. **Console panel `/kms`**. SQLite `kms_keys`, `kms_aliases`. SigV4 `kms` JSON 1.1 (`TrentService.*`).

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Grants / multi-Region / AWS-identical key-material rotation | P3 | EnableKeyRotation is a stored flag |

### Tier A reference set (12 ops)

CreateKey, DescribeKey, CreateAlias, ListAliases, DeleteAlias, Encrypt, Decrypt, GetKeyPolicy, ScheduleKeyDeletion, GetKeyRotationStatus, EnableKeyRotation, DisableKeyRotation.

12 **available** = **100%** Tier A KMS (12 / 12).

---

## Route 53

Guide: [route53.md](route53.md) · Backlog: the product backlog

### Implemented

CreateHostedZone / ListHostedZones / GetHostedZone / DeleteHostedZone; ChangeResourceRecordSets / ListResourceRecordSets / GetChange (A/CNAME subset). **Terraform green path** [`examples/terraform/route53/zone-min/`](examples/terraform/route53/zone-min/) — apply + destroy. **`simulith verify route53`**. **Console panel `/route53`**. SQLite `route53_*`. SigV4 `route53` REST/XML + JSON. **Local DNS stub** — records not served by a real resolver.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Alias records, routing policies, health checks | P2+ | FW-R53-010+ |
| Private zones + VPC association | P3 | — |

### Tier A reference set (7 ops)

CreateHostedZone, ListHostedZones, GetHostedZone, DeleteHostedZone, ChangeResourceRecordSets, ListResourceRecordSets, GetChange.

7 **available** = **100%** Tier A Route 53 (7 / 7).

---

## ACM

Guide: [acm.md](acm.md) · Backlog: the product backlog

### Implemented

RequestCertificate / DescribeCertificate / ListCertificates / DeleteCertificate / ListTagsForCertificate (DNS validation subset). **Local validation stub** — first describe/list flips `PENDING_VALIDATION` → `ISSUED`; no real CA or DNS resolver. **Terraform green path** [`examples/terraform/acm/cert-min/`](examples/terraform/acm/cert-min/) — hosted zone + certificate + validation records + `aws_acm_certificate_validation`; apply + destroy. **`simulith verify acm`**. **Console panel `/acm`**. **Seed** demo cert **`demo.simulith.local`**. SQLite `acm_*`. SigV4 `acm` JSON 1.1.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Email validation, imported certs, private CA | P2+ | + |
| Cross-region replication | P3 | — |

### Tier A reference set (5 ops)

RequestCertificate, DescribeCertificate, ListCertificates, DeleteCertificate, ListTagsForCertificate.

5 **available** = **100%** Tier A ACM (5 / 5).

---

## CloudFront

Guide: [cloudfront.md](cloudfront.md) · Backlog: the product backlog

CreateOriginAccessControl / GetOriginAccessControl / CreateDistribution / GetDistribution / ListDistributions / GetDistributionConfig / UpdateDistribution / DeleteDistribution / DeleteOriginAccessControl. **Local CDN stub** — no edge caching. **Terraform green path** [`examples/terraform/cloudfront/cdn-min/`](examples/terraform/cloudfront/cdn-min/). **`simulith verify cloudfront`**. **Console panel `/cloudfront`**. **Seed** demo OAC + distribution **`E0DEMOCF00001`**. SQLite `cloudfront_*`. SigV4 `cloudfront` REST/XML.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Real edge caching / POP | P3 | Out of scope (local stub) |
| Lambda@Edge, WAF, signed URLs | P3 | — |

### Tier A reference set (9 ops)

CreateOriginAccessControl, GetOriginAccessControl, CreateDistribution, GetDistribution, ListDistributions, GetDistributionConfig, UpdateDistribution, DeleteDistribution, DeleteOriginAccessControl.

9 **available** = **100%** Tier A CloudFront (9 / 9).

---

## IAM

Guide: [iam.md](iam.md) · Backlog: the product backlog

### Implemented

CreateRole / GetRole / DeleteRole; CreatePolicy / GetPolicy / **GetPolicyVersion** / DeletePolicy; AttachRolePolicy / DetachRolePolicy / ListAttachedRolePolicies / **ListRolePolicies** (empty inline list) (RDS Proxy role subset). Terraform green-path [`examples/terraform/iam/proxy-roles-min/`](examples/terraform/iam/proxy-roles-min/). **`simulith verify iam`**. **Console panel `/iam`**. SQLite `iam_*`. SigV4 `iam` Query API.

### Notable gaps (tracked)

| Gap | Priority | Backlog |
| --- | --- | --- |
| Lambda execution roles (depth) | P1 |  |

### Tier A reference set (9 ops)

CreateRole, GetRole, DeleteRole; CreatePolicy, GetPolicy, DeletePolicy; AttachRolePolicy, DetachRolePolicy, ListAttachedRolePolicies.

9 **available** = **100%** Tier A IAM (9 / 9). Lambda execution roles are a **depth** story outside this ref set.

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
