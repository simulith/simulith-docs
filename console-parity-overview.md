# Console parity overview — Simulith Console vs AWS Console

Consolidated view of **Simulith Console vs AWS Management Console** for all **shipped service panels** (Foundation through RDS): what the **local web UI ships today**, what is **missing**, and **backlog IDs**.

> **How to run Console:** [`console.md`](console.md) · App: [`../../console/`](console.md)
> **API/runtime parity (% ops, verify):** [`aws-parity-overview.md`](aws-parity-overview.md) — different dimension

Last updated: 2026-08-10..

---

## Executive summary

Simulith Console is a **local ops dashboard** (Docker + Vite), not a clone of AWS Console. **Shipped panels:** DynamoDB, SQS, SSM, S3, Lambda, API Gateway, Secrets Manager, EventBridge, Cognito, SES, VPC, RDS, **KMS**, and Verify import — no IAM/CloudWatch UI yet (API-only).

| Panel | Shipped flows **in Console UI** | Reference set* | **Shipped** | Notes |
| --- | --- | ---: | ---: | --- |
| **Dashboard** | Health, seed, reset | 3 | **3 / 3 (100%)** | Parity metrics UI deferred |
| **DynamoDB** | List/create/delete table; Scan; put/edit/delete item (Simple + JSON document) | 7 | **7 / 7 (100%)** | GSI wizard / expression builders → CLI |
| **SQS** | List queues; peek; send; receive+delete; purge | 5 | **5 / 5 (100%)** | FIFO, visibility deferred |
| **SSM** | Browse by path; put/edit/delete String + SecureString | 4 | **4 / 4 (100%)** | StringList / batch delete UI deferred |
| **S3** | List/create/delete bucket; list objects; upload/download/delete object | 6 | **6 / 6 (100%)** | CopyObject / batch delete UI deferred |
| **Lambda** | List functions; view config; invoke JSON; delete function | 4 | **4 / 4 (100%)** | Create/update code UI deferred; ESM UI deferred |
| **API Gateway** | List REST APIs; resources; stage URL; HTTP invoke; delete API | 5 | **5 / 5 (100%)** | Create resource/method UI deferred |
| **Secrets Manager** | List/create/delete secrets; reveal value | 4 | **4 / 4 (100%)** | Rotation UI deferred |
| **EventBridge** | List schedule rules; inspect targets; last invoke (admin peek) | 3 | **3 / 3 (100%)** | PutEvents UI deferred |
| **Cognito** | List pools; inspect clients/groups; JWKS link | 3 | **3 / 3 (100%)** | Hosted UI / sign-in deferred |
| **SES** | Identity + template list; outbox after Seed | 3 | **3 / 3 (100%)** | Send form deferred |
| **VPC** | List VPCs/subnets/SG; Lambda VpcConfig context | 3 | **3 / 3 (100%)** | ENI wizard deferred |
| **RDS** | List DB instances; proxy endpoint hint | 2 | **2 / 2 (100%)** | Create instance UI deferred |
| **KMS** | List aliases; describe key; create CMK + alias; encrypt/decrypt | 4 | **4 / 4 (100%)** | ScheduleKeyDeletion UI deferred |
| **Verify** | Import verify JSON report | 1 | **1 / 1 (100%)** | Run verify from CLI |
| **Cross-cutting** | Same-origin proxy; admin peek | 2 | **2 / 2 (100%)** | Snapshot UI deferred |
| **Total (weighted)** | — | **56** | **~56 / 56 (~100%)** | Documented subset |

\* **Reference set** = flows a developer expects when comparing Simulith Console to AWS Console for **local development** (not every AWS Console screen or wizard).

---

## How to read the tables

| Column | Meaning |
| --- | --- |
| **AWS Console** | Typical capability in AWS Management Console |
| **Simulith Console** | What the SPA ships today (`console/`) |
| **Gap / backlog** | Not in UI; often `FW-PRD-*` or service `FW-*` when runtime API also missing |
| **Workaround** | CLI, SDK, or admin API until backlog ships |

When **runtime API already supports** an action but Console does not, the gap is **product/UX** (`FW-PRD-*`). When the API is also missing, see [`aws-parity-overview.md`](aws-parity-overview.md) and service future-work.

---

## Dashboard

Guide: [console.md](console.md) · Admin: [admin-api.md](admin-api.md)

| AWS Console (concept) | Simulith Console | Gap |
| --- | --- | --- |
| Service health / region context | **Connected** status, runtime listen, region | Live verify trigger — CLI only |
| Load demo / sample data | **Seed demo data** (`POST /_simulith/v1/seed`) | — |
| Clear sandbox | **Reset local state** | — |
| Account switcher, IAM | Not applicable (single local account) | Out of scope |

---

## DynamoDB panel

Guide: [console.md](console.md) · API: [dynamodb.md](dynamodb.md)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List tables | **ListTables** + dropdown | — |
| Create table (wizard) | **CreateTable** — hash key String only | Sort key / GSI / TTL wizards — CLI/Terraform |
| Delete table | **DeleteTable** + confirm | — |
| Browse items (Scan/Query) | **Scan** table + pagination | Query builder, filters, ProjectionExpression — CLI |
| Create / replace item | **Put item** — Simple strings or **JSON document** (Map/List) | — |
| Edit item attributes | **Edit** — Simple scalars or **JSON document** (GetItem → PutItem) | Visual attribute-type editor — out of scope |
| Delete item | **Delete item** + confirm | — |
| Indexes, streams, metrics tabs | Not in UI | Out of scope for Console |

---

## SQS panel

Guide: [console.md](console.md) · API: [sqs.md](sqs.md) · Peek: [admin-api.md](admin-api.md#get-_simulithv1sqsmessages)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List queues | **ListQueues** (SDK) | — |
| View messages (without consuming) | **Peek** via `GET /_simulith/v1/sqs/messages` | AWS has no exact peek — Simulith admin route |
| Send message | **SendMessage** form | — |
| Receive / delete message | **Receive one** + **Delete** (receipt handle) + **Purge queue** | — |
| FIFO queue UI | Not in UI | **** |
| Change visibility timeout | Not in UI | **** |

---

## SSM panel

Guide: [console.md](console.md) · API: [ssm.md](ssm.md)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| Browse parameters by path | **GetParametersByPath** — path prefix input | Advanced filters — **** |
| View parameter value | Table column | — |
| Create / update parameter | **PutParameter** — **String** or **SecureString** (mock encryption notice) | — |
| Delete parameter | **DeleteParameter** + confirm; **DeleteParameters** batch (API) | Batch multi-select UI — **** API shipped ; Console optional Fase 7b |

---

## S3 panel

Guide: [console.md](console.md) · API: [s3.md](s3.md)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List buckets | **ListBuckets** — bucket selector | — |
| Create / delete bucket | **CreateBucket** form; **DeleteBucket** + confirm (empty only) | — |
| Browse objects | **ListObjectsV2** — prefix filter + pagination | — |
| Upload object | File input → **PutObject** | Multipart deferred |
| Download object | **GetObject** → browser download | — |
| Delete object | **DeleteObject** + confirm | **DeleteObjects** batch UI deferred |
| Copy object | Not in UI | API shipped ; Console optional |

---

## Lambda panel

Guide: [console.md](console.md) · API: [lambda.md](lambda.md)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List functions | **ListFunctions** — function selector | — |
| View configuration | **GetFunction** — runtime, handler, role, timeout, memory, env | — |
| Test invoke | **Invoke** — JSON payload + response (RequestResponse) | Requires node/python3 on runtime host |
| Delete function | **DeleteFunction** + confirm | — |
| Create / update code | Not in UI | CLI / Terraform (`examples/terraform/lambda`) |
| Event source mappings | Not in UI | **** API shipped; Console optional |

---

## API Gateway panel

Guide: [console.md](console.md) · API: [apigateway.md](apigateway.md)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List REST APIs | **GetRestApis** — API selector | — |
| View API / resources | **GetRestApi** + **GetResources** | — |
| Stage invoke URL | Stage name input + **GetStage**; copyable invoke base | **GetStages** not in runtime — manual stage name |
| Test HTTP invoke | **fetch** to `/_user_request_/…` | Requires deployed stage + Lambda proxy |
| Delete API | **DeleteRestApi** + confirm | — |
| Create API / resources / deploy | Not in UI | CLI / Terraform (`examples/terraform/apigateway`) |

---

## EventBridge panel

Guide: [console.md](console.md) · API: [eventbridge.md](eventbridge.md) · Peek: [admin-api.md](admin-api.md#get-_simulithv1eventbridgerules)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List rules | **ListRules** — rule selector | — |
| View rule / schedule | **DescribeRule** — state, schedule, bus, description | — |
| View targets | **ListTargetsByRule** | — |
| Last invocation time | Admin **`/_simulith/v1/eventbridge/rules`** (`lastInvokedAt`) | Not in AWS ListRules |
| Create / delete rule or targets | Not in UI | CLI / Terraform (`examples/terraform/eventbridge`) |
| PutEvents / custom buses | Not in UI |  deferred |

---

## Cognito panel

Guide: [console.md](console.md) · API: [cognito.md](cognito.md)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List user pools | **ListUserPools** — pool selector | — |
| View pool | **DescribeUserPool** — id, ARN, status, created | — |
| App clients | **ListUserPoolClients** | — |
| Groups | **ListGroups** | — |
| JWKS | Link to `/{userPoolId}/.well-known/jwks.json` | — |
| Create / delete pool or clients | Not in UI | CLI / Terraform (`examples/terraform/cognito`) |
| Users / AdminCreateUser | Not in UI | ListUsers not implemented; Admin* via CLI |

---

## SES panel

Guide: [console.md](console.md) · API: [ses.md](ses.md) · Peek: [admin-api.md](admin-api.md#get-_simulithv1sesoutbox)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List identities | **ListIdentities** + verification status | — |
| List templates | **ListTemplates** | — |
| Sent / captured mail | Admin **`/_simulith/v1/ses/outbox`** (local outbox) | Not an AWS SES API |
| Create / delete identity or template | Not in UI | CLI / Terraform (`examples/terraform/ses`) |
| Real SMTP delivery | Not in UI | Explicitly out of scope (capture only) |

---

## VPC panel

Guide: [console.md](console.md) · API: [vpc.md](vpc.md)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List VPCs | **DescribeVpcs** — VPC selector | — |
| View subnets | **DescribeSubnets** (filtered by VPC) | — |
| Security groups + rules | **DescribeSecurityGroups** — ingress/egress summary | — |
| Create / delete VPC resources | Not in UI | CLI / Terraform (`examples/terraform/vpc/network-min`) |
| Real ENI / network isolation | Not in UI | Metadata path only (see vpc.md) |

---

## RDS panel

Guide: [console.md](console.md) · API: [rds.md](rds.md)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List DB instances | **DescribeDBInstances** — instance selector | — |
| Instance detail + endpoint | Engine, status, subnet group, sidecar host:port | — |
| Create / delete DB instances | Not in UI | CLI / Terraform (`examples/terraform/rds/postgres-min`) |
| RDS Proxy targets | Not in UI | CLI / Terraform `proxy-min` |

---

## KMS panel

Guide: [console.md](console.md) · API: [kms.md](kms.md)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List keys / aliases | **ListAliases** — alias selector | Keys without aliases → create alias or CLI |
| Key detail | **DescribeKey** by alias or key id | — |
| Create CMK + alias | **CreateKey** + optional **CreateAlias** | ScheduleKeyDeletion UI deferred |
| Encrypt / decrypt | Local round-trip (**Encrypt** / **Decrypt**) | Mock envelope — not AWS ciphertext |

---

## Verify panel

Guide: [console.md](console.md) · Schema: [compatibility.md](compatibility.md) · CI artifacts: [compatibility.md § CI](compatibility.md#continuous-integration-github-actions)

| Flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| View local verify report | **Upload** `.simulith/verify-last.json` or paste JSON | — |
| View CI parity smoke JSON | **Upload** `verify-{dynamodb,sqs,ssm,s3}.json` or `verify-docker-*.json` from artifact zip | Live GitHub artifact URL fetch — auth/CORS |
| Structured parity diff | **Upload** report with `diffDetail` — table Path / AWS / Simulith | — |
| Run verify from UI | Not in UI | CLI `simulith verify` or CI pipeline |
| HTML diff report | Not in UI | `simulith report --output-html` CLI |

---

## Cross-cutting (Console product)

| Topic | Simulith Console | Gap / backlog |
| --- | --- | --- |
| Same-origin `/runtime` + `/_simulith` proxy | Shipped (nginx / Vite) | — |
| Snapshot save/restore UI | CLI + admin API only | Optional UI (no FW yet) |
| Verify / CI parity report in UI | **File upload** + scenario table (`/verify`) | Live verify run; GitHub URL fetch |
| Single-port demo (one URL) | **`docker-compose.all-in-one.yml`** — Console on `:9080` only | Optional runtime-port overlay for `:4566` |
| IAM, CloudWatch, X-Ray | Not in scope | Expansion services |

---

## Out of scope (Console)

- Full AWS Console feature parity (wizards, dashboards, alarms, tags UI for every resource)
- Services beyond shipped set (ECS, …)
- Multi-account, multi-region, SSO
- Replacing AWS CLI/SDK for automation or CI

---

## Active Console backlog (P2 product)

Console panels **~95%** shipped. **Fase 7b** ✅ complete. `ROADMAP-COMMERCIAL-PARITY.md`.

Full product backlog: the product backlog.

---

## Related

- [console.md](console.md) — run, architecture, troubleshooting
- [aws-parity-overview.md](aws-parity-overview.md) — API / Terraform executive summary
- [compatibility-matrix.md](compatibility-matrix.md) — HTTP operation truth table
- [admin-api.md](admin-api.md) — seed, reset, peek routes
