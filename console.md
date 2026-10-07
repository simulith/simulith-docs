# Simulith Console

Web GUI for local Simulith — health, seed/reset, and **service panels** for DynamoDB, SQS, SSM, S3, Lambda, API Gateway, Secrets Manager, EventBridge, SNS, SES, CloudWatch (Logs + Metrics + Alarms + Dashboards + Insights), Cognito, VPC, RDS, IAM, KMS, Route 53, ACM, CloudFront, CloudFormation (read-only), and Verify. Deploy stacks via CLI, SDK, or [`serverless-simulith`](https://www.npmjs.com/package/serverless-simulith) — inspect them in the Console **CloudFormation** panel ([cloudformation.md](cloudformation.md) · [serverless-integration.md](serverless-integration.md)).

For first-time runtime onboarding, see [quickstart.md](quickstart.md).

---

## Quick run (Docker)

### Full product — published images

Pulls published images (`simulith/simulith` + `simulith/console`) — no checkout or `--build`. From any folder containing the compose file:

```bash
SIMULITH_VERSION=0.1.0 docker compose -f docker-compose.all-in-one.published.yml up
# omit SIMULITH_VERSION for :latest
```

Same single entry URL as below (`http://localhost:9080`). Details: release.md, [docker.md](docker.md).

### Workshop demo — all-in-one

One Compose file, **one host URL** — runtime + Console. Runtime is reached via Console proxy (`/runtime`, `/_simulith`); **`:4566` is not published** on the host by default.

From `runtime/`:

```bash
docker compose -f docker-compose.all-in-one.yml up --build
```

| Entry | URL |
| --- | --- |
| **Console + runtime proxy** | http://localhost:9080 |

Override demo port: `SIMULITH_DEMO_PORT=9090 docker compose -f docker-compose.all-in-one.yml up --build`.

Optional **direct runtime** on `:4566` (Terraform/CLI examples that hardcode the port):

```bash
docker compose -f docker-compose.all-in-one.yml -f docker-compose.all-in-one.runtime-port.yml up --build
```

AWS CLI via proxy: `--endpoint-url http://127.0.0.1:9080/runtime`

### Dev overlay — two files, both ports

From `runtime/`:

```bash
docker compose -f docker-compose.yml -f docker-compose.console.yml up --build
```

| Service | URL |
| --- | --- |
| **Console** | http://localhost:9080 |
| **Runtime** (AWS CLI/SDK direct) | http://localhost:4566 |

Default Console host port is **9080** (not 8080) to avoid conflicts with other local services. Override: `SIMULITH_CONSOLE_PORT=8080 docker compose ...`.

1. Open the **Dashboard** — runtime **Connected**, categorized **service grid**, and **Seed demo data** / **Reset local state** in the header.
2. Click **Seed demo data** — loads the built-in fixture (`Demo` table, `demo-queue`, SSM params under `/app/demo/*`, S3 `demo-bucket`, Lambda `demo-fn` + SQS ESM, API Gateway `demo-api`, Secrets Manager `demo-secret`, EventBridge `demo-rule` → `demo-fn`, CloudWatch Logs `/aws/lambda/demo-fn`, Cognito `demo-pool`, SES `demo@simulith.local` + `demo-template`, RDS `demo-db`).
3. Open **DynamoDB** or **S3** — Lovable full-width tables + stacked detail. Put/edit/delete items; S3 Objects/Properties/Permissions tabs.
4. Open **SQS** — queue table, create/edit attributes, peek, send, poll messages, delete/return, **purge queue**.
5. Open **SSM** — browse by path, put/edit/delete String and **SecureString** (mock encryption notice).
6. Open **Lambda** — **Functions**: resource list + tabs: Configuration, Test, Code, Triggers, **Monitor**; edit configuration, delete; **Layers**: catalog + versions.
7. Open **API Gateway** — API table, **Resources** / **Stages** / **Test** tabs, and **Custom domain names**.
8. Open **Secrets Manager** — list secrets, reveal value (mock storage), create and delete secrets.
9. Open **EventBridge** — list rules, **Create rule** (schedule or pattern + optional Lambda target), delete rule, inspect targets, last invoke peek, **Send test event** (PutEvents).
10. Open **CloudWatch** → **Logs** — list log groups (`/aws/lambda/demo-fn` after Seed), streams, and recent events via **GetLogEvents**.
11. Open **CloudWatch** → **Metrics** — **ListMetrics**, **Put metric data**, and **GetMetricStatistics** for the last hour.
12. Open **CloudWatch** → **Alarms** — **DescribeAlarms**, **Create alarm**, and **Delete**.
13. Open **CloudWatch** → **Dashboards** — **ListDashboards** / **GetDashboard**, **Create dashboard** / **Edit JSON**, or delete via Console.
14. Open **CloudWatch** → **Insights** — run a Logs Insights query (**StartQuery** + **GetQueryResults**) against a log group.
15. Open **Cognito** — pools, **Users** admin, **Auth debugger**.
16. Open **SES** — list identity (`demo@simulith.local`), template (`demo-template`), **Send test email** (plain or templated), and outbox (seeded + new captures).
17. Open **Verify** — import `verify-last.json` or CI artifact JSON (`verify-dynamodb.json`, `verify-s3.json`, etc.).
19. Click **Reset local state** — clears all panels.

Console README: [`../../console/README.md`](console.md).

---

## Architecture

```text
Browser (host :9080 → container :8080)
    │
    ▼
Console nginx
    ├── /              → SPA (React)
    ├── /runtime/*     → proxy → simulith:4566/*   (AWS SDK / health)
    └── /_simulith/*   → proxy → simulith:4566/_simulith/*  (seed/reset/peek)
```

The Console uses **same-origin proxies** so the browser does not need CORS on the runtime. nginx rewrites `/runtime` → runtime root (same as Vite dev); **both** `/runtime` and `/runtime/health` must proxy — a `/runtime/`‑only rule breaks DynamoDB SDK POSTs.

### Console UI (v3)

- **Shell** — dark OKLCH theme, **ConsoleShell** + categorized sidebar.
- **Dashboard** — service cards with best-effort resource counts; seed, reset, health.
- **Panels** — Lovable full-width tables + **panel-stack** detail on shipped routes; parity depth –445 (batch deletes, test sends, Lambda edit/ESM, etc.).

### Runtime admin routes

Canonical reference: **[Admin API](admin-api.md)** (`/_simulith/v1/*`).

Registered in the runtime on the **same SQLite store** as AWS handlers. Console nginx proxies `/_simulith/*` to the runtime.

| Method | Path | Summary |
| --- | --- | --- |
| `GET` | `/_simulith/v1/status` | Listen address + region |
| `POST` | `/_simulith/v1/seed` | Default demo fixture |
| `POST` | `/_simulith/v1/reset` | Clear local state |
| `GET` | `/_simulith/v1/snapshot` | Export snapshot JSON |
| `POST` | `/_simulith/v1/snapshot` | Import snapshot JSON |
| `GET` | `/_simulith/v1/sqs/messages?queueName=` | Peek messages (non-destructive) |
| `GET` | `/_simulith/v1/eventbridge/rules` | Peek schedule rules + lastInvokedAt |
| `GET` | `/_simulith/v1/ses/outbox` | Peek captured SES messages |
| `GET` | `/_simulith/v1/sns/messages?topicArn=` | Peek SNS publish log (optional topic filter) |
| `GET` | `/_simulith/v1/cloudwatch/events?logGroupName=&logStreamName=` | Peek recent log events (admin fallback — Console uses **GetLogEvents** API) |

**Security:** local development only — no authentication in the Console. Do not expose admin routes on untrusted networks without a gateway.

---

## Service panels

| Panel | Capabilities | Limits |
| --- | --- | --- |
| **DynamoDB** | Table search + **Overview** + **Explore items** + **Indexes**; Scan/Query Run; GSI query, scalar FilterExpression, **Create index**; CreateTable, DeleteTable, Put/Update/Delete (Simple + **JSON document**) | Scan on a GSI, extra filter functions, GSI delete → CLI; sort key on Create table still ComingSoon |
| **SQS** | **:** ListQueues table, CreateQueue, SetQueueAttributes, DeleteQueue, peek (admin), SendMessage, ReceiveMessage (1–10), ChangeMessageVisibility, DeleteMessage, PurgeQueue; **:** DLQ redrive (**StartMessageMoveTask**); **:** FIFO create/send | — |
| **SSM** | GetParametersByPath, PutParameter (**String** + **SecureString**), DeleteParameter, **DeleteParameters** (batch) | SecureString = mock local encryption (not KMS); StringList → CLI |
| **S3** | Bucket inventory, breadcrumbs/folders, object overview; CreateBucket, DeleteBucket, upload/download/copy/delete, **DeleteObjects** batch; bucket policy, CORS, tags, **PutBucketVersioning** Enable/Suspend; SSE-S3 **PutBucketEncryption** and block public access | SSE-KMS and multipart → CLI |
| **Lambda** | **Functions:** ListFunctions, GetFunction, tabs, **UpdateFunctionConfiguration**, **UpdateFunctionCode**, Invoke, DeleteFunction, **Monitor**. **Triggers:** ESM CRUD. **Layers:** publish/delete | Graph widgets; auto `AWS/Lambda` metrics on invoke; invoke needs node/python3 on PATH |
| **API Gateway** | **:** API table, Resources/Stages/Test tabs; **CreateRestApi** dialog; GetResources, Add route, **CreateDeployment** / **CreateStage**, GetStage, HTTP invoke, DeleteRestApi; custom domain tabs | Existing stage not auto-updated on deploy; full multi-step wizard → CLI/Terraform |
| **Secrets Manager** | ListSecrets, GetSecretValue (reveal), CreateSecret, DeleteSecret | Mock plain-text storage (not KMS); seeded `demo-secret` via **Seed** |
| **EventBridge** | ListRules, DescribeRule, ListTargetsByRule, **PutRule** / delete rule + targets, **PutEvents**, **ListEventBuses**; last invoke via admin peek | Custom bus create/delete → CLI |
| **CloudWatch Logs** | DescribeLogGroups, DescribeLogStreams, **GetLogEvents**, **FilterLogEvents**; **CreateLogGroup**, **PutLogEvents** | Delete group/stream → CLI/Terraform; other CW tabs read-only |
| **CloudWatch Metrics** | **ListMetrics**, **GetMetricStatistics**, **PutMetricData** | GetMetricData batch via CLI/SDK |
| **CloudWatch Alarms** | **DescribeAlarms**, **PutMetricAlarm**, **DeleteAlarms** | SetAlarmState / SNS ARNs via CLI |
| **CloudWatch Dashboards** | **ListDashboards**, **GetDashboard**, **PutDashboard**, **DeleteDashboards** | Opaque JSON body; no widget rendering |
| **CloudWatch Insights** | **StartQuery**, **GetQueryResults** | CWLI subset + depth (`stats count()`, `not like`, multi-group); read-only |
| **Cognito** | ListUserPools, clients, groups, JWKS; **Users** admin CRUD; **Auth debugger** — InitiateAuth / AdminInitiateAuth | Hosted UI; USER_SRP_AUTH wizard; pool/client create via CLI/Terraform |
| **SES** | ListIdentities, **VerifyEmailIdentity**, **DeleteIdentity**, ListTemplates, **CreateTemplate**, **DeleteTemplate**, **SendEmail** / **SendTemplatedEmail**; outbox via admin peek | No SMTP; seeded `demo@simulith.local` + `demo-template` via **Seed** |
| **SNS** | ListTopics, ListSubscriptionsByTopic, **CreateTopic** (standard and FIFO), **Subscribe** (optional exact-match filter policy), **Publish** (FIFO group/dedup ids and string message attributes), **DeleteTopic**, **Unsubscribe**; recent publishes via admin peek | Seeded `demo-alarm` via **Seed**; topic attributes → CLI |
| **VPC** | DescribeVpcs, DescribeSubnets, DescribeSecurityGroups (ingress/egress rules) | Create/delete UI deferred; metadata networking only; use Terraform `vpc/network-min` |
| **RDS** | **DB instances:** DescribeDBInstances (status, engine, sidecar endpoint). **DB Proxies:** DescribeDBProxies, targets, connection pool | Create/delete UI deferred; Postgres sidecar requires Docker; seeded `demo-db` via **Seed** |
| **IAM** | **ListRoles**, GetRole, ListAttachedRolePolicies, GetPolicy; create RDS Proxy bundle; **DetachRolePolicy**, **DeleteRole**; browse roles | Metadata only (no enforcement); use Terraform `iam/proxy-roles-min` |
| **KMS** | ListAliases, DescribeKey, CreateKey + alias, Encrypt/Decrypt, **ScheduleKeyDeletion** | Mock envelope crypto; use Terraform `kms/cmk-min` |
| **Route 53** | ListHostedZones, CreateHostedZone, ChangeResourceRecordSets (A/CNAME UPSERT), delete record | Local DNS stub — not a real resolver; private zone UI deferred |
| **ACM** | ListCertificates, RequestCertificate (DNS validation), DescribeCertificate, **ListTagsForCertificate**, **DeleteCertificate** | Local validation stub — not a real CA; add/remove tags UI deferred; seeded demo cert via **Seed** |
| **CloudFront** | ListDistributions, GetDistribution, GetOriginAccessControl, CreateOriginAccessControl, CreateDistribution, **DeleteDistribution** | Local CDN stub — no edge caching; use Terraform `cloudfront/cdn-min` |
| **CloudFormation** | DescribeStacks, ListStackResources, DescribeStackEvents, GetTemplate (read-only) | Create/update/delete from UI deferred — use CLI, SDK, or [`serverless-simulith`](https://www.npmjs.com/package/serverless-simulith); see [`cloudformation.md`](cloudformation.md) |

Panel capabilities are documented in the **Service panels** section below.

### DynamoDB JSON document mode

- **Put item** → **JSON document** tab: paste a plain JSON object; nested objects become **Map**, arrays become **List** (via `@aws-sdk/util-dynamodb` → PutItem).
- **Edit item** → **GetItem** loads the full item; **JSON document** tab saves with **PutItem** (replaces the entire item — attributes omitted from JSON are removed).
- **Simple** tab remains for string scalars; use JSON for nested documents.

---

## Verify panel

Import and inspect **`CompatibilityReport` v1** JSON in the browser — no server-side verify run.

| Source | File(s) | Notes |
| --- | --- | --- |
| Local CLI | `.simulith/verify-last.json` | `simulith verify dynamodb --save-last` (or sqs/ssm/s3) |
| CI artifact | `verify-dynamodb.json`, `verify-sqs.json`, `verify-ssm.json`, `verify-s3.json`, `verify-docker-*.json` | Jobs **Parity smoke** / **Parity smoke (Docker)** |
| Trust bundle | Same JSON files inside the zip | `mode: smoke` — no `compatibilityPercent` |

Failed **parity** scenarios may include optional **`diffDetail`** (`path`, `aws`, `simulith`) from runtime ; Console renders a field-by-field table. Legacy reports with only `diff` text still work.

**Import flow:** Console → **Verify** → upload one or more JSON files (or paste JSON). Multiple uploads show tabs per service.

**CI artifact URL (ship criteria):** GitHub does not allow unauthenticated browser fetch of artifact URLs. Download the artifact zip from the PR/run **Checks** tab → extract JSON → upload in Console. See [`compatibility.md`](compatibility.md) § CI and [`../../console/README.md`](console.md).

Schema reference: the runtime. Smoke vs parity modes: [`compatibility.md`](compatibility.md).

---

## Local dev (native runtime + Vite)

```bash
# terminal 1
cd runtime && go run ./cmd/simulith start

# terminal 2
cd console && npm install && npm run dev
```

Vite dev server proxies `/runtime` and `/_simulith` to `http://127.0.0.1:4566`.

---

## Still deferred

| Area | Follow-up |
| --- | --- |
| Live verify run from Console (admin trigger) | CLI `simulith verify` — import JSON on Verify panel instead |
| CloudFormation stack browser | Console `/cloudformation` (read-only) or CLI — [cloudformation.md](cloudformation.md) |
| Snapshot save/restore UI | CLI `simulith snapshot` |
| Full AWS Console parity | See [console.md](console.md) |

---

## Troubleshooting

| Issue | Fix |
| --- | --- |
| Wrong app on `:8080` (e.g. another login page) | Use **http://localhost:9080** — Simulith Console default host port |
| Need a different port | `SIMULITH_CONSOLE_PORT=9090 docker compose -f docker-compose.yml -f docker-compose.console.yml up` |
| Console up but **Unavailable** | Ensure runtime is healthy: `curl http://localhost:4566/health` |
| SDK errors from Console | Confirm `/runtime` proxy (not `/runtime/` only) — see Architecture above |

---

## Related

- [`docker.md`](docker.md) — runtime container
- [`seed.md`](seed.md) — fixture contents
- [`persistence.md`](persistence.md) — state store
- Future work: `product/README.md` · Parity: [`console.md`](console.md)
