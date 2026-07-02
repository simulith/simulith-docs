# Console parity overview — Simulith Console vs AWS Console

Consolidated view of **Simulith Console vs AWS Management Console** for DynamoDB, SQS, and SSM: what the **local web UI ships today**, what is **missing**, and **backlog IDs**. (Engineering doc — “MVP” here denotes **scope boundary**, not user-facing Console copy; see FW-PRD-016 / SML-083.)

> **How to run Console:** [`console.md`](console.md) · App: [`../../console/`](../../console/README.md)  
> **API/runtime parity (% ops, verify):** [`aws-parity-overview.md`](aws-parity-overview.md) — different dimension  
> **Backlog:** `cursor/company/future-work/product/`

Last updated: 2026-06-09.

---

## Executive summary

Simulith Console is a **local ops dashboard** (Docker + Vite), not a clone of AWS Console. Scope: **DynamoDB, SQS, SSM** on localhost — no IAM, CloudWatch, or multi-region.

| Panel | MVP flows **in Console UI** | Reference set* | **Shipped** | Notes |
| --- | --- | ---: | ---: | --- |
| **Dashboard** | Health, seed, reset | 3 | **3 / 3 (100%)** | Parity metrics UI deferred |
| **DynamoDB** | List/create/delete table; Scan; put/edit/delete item (Simple + JSON document) | 7 | **7 / 7 (100%)** | GSI wizard / expression builders → CLI |
| **SQS** | List queues; peek; send; receive+delete | 5 | **4 / 5 (80%)** | Purge, FIFO, visibility deferred |
| **SSM** | Browse by path; put/edit/delete String param | 4 | **3 / 4 (75%)** | SecureString, batch delete deferred |
| **Cross-cutting** | Same-origin proxy; admin peek; verify report import | 3 | **3 / 3 (100%)** | Snapshot UI deferred |
| **Total (weighted)** | — | **21** | **~19 / 21 (~90%)** | Honest MVP subset |

\* **Reference set** = flows a developer expects when comparing Simulith Console to AWS Console for **local MVP demos** (not every AWS Console screen or wizard).

**Shipped stories:** FW-PRD-001 / SML-051 (Console v1), FW-PRD-002 / SML-052 (admin API + peek), FW-PRD-013 / SML-055 (service panels v2), FW-PRD-015 / SML-056 (DynamoDB JSON document).

**Validation smoke:** `maintainer workflow (private monorepo)` (Compose proxy on `:9080`).

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
| Indexes, streams, metrics tabs | Not in UI | Out of scope for Console MVP |

---

## SQS panel

Guide: [console.md](console.md) · API: [sqs.md](sqs.md) · Peek: [admin-api.md](admin-api.md#get-_simulithv1sqsmessages)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| List queues | **ListQueues** (SDK) | — |
| View messages (without consuming) | **Peek** via `GET /_simulith/v1/sqs/messages` | AWS has no exact peek — Simulith admin route |
| Send message | **SendMessage** form | — |
| Receive / delete message | **Receive one** + **Delete** (receipt handle) + **Purge queue** | — |
| FIFO queue UI | Not in UI | **FW-SQS-030** |
| Change visibility timeout | Not in UI | **FW-SQS-022** |

---

## SSM panel

Guide: [console.md](console.md) · API: [ssm.md](ssm.md)

| AWS Console flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| Browse parameters by path | **GetParametersByPath** — path prefix input | Advanced filters — **FW-SSM-021** |
| View parameter value | Table column | — |
| Create / update parameter | **PutParameter** — **String** or **SecureString** (mock encryption notice) | — |
| Delete parameter | **DeleteParameter** + confirm; **DeleteParameters** batch (API) | Batch multi-select UI — **FW-SSM-013** API shipped SML-062; Console optional Fase 7b |

---

## Verify panel

Guide: [console.md](console.md) · Schema: [compatibility.md](compatibility.md) · CI artifacts: [compatibility.md § CI](compatibility.md#continuous-integration-github-actions)

| Flow | Simulith Console | Gap / backlog |
| --- | --- | --- |
| View local verify report | **Upload** `.simulith/verify-last.json` or paste JSON | — |
| View CI parity smoke JSON | **Upload** `verify-{dynamodb,sqs,ssm}.json` or `verify-docker-*.json` from artifact zip | Live GitHub artifact URL fetch — auth/CORS |
| Structured parity diff | **Upload** report with `diffDetail` — table Path / AWS / Simulith (**SML-077**) | — |
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
| IAM, CloudWatch, X-Ray | Not in scope | Post-MVP services |

---

## Out of scope (Console)

- Full AWS Console feature parity (wizards, dashboards, alarms, tags UI for every resource)
- Services beyond MVP (S3, Lambda, ECS, …)
- Multi-account, multi-region, SSO
- Replacing AWS CLI/SDK for automation or CI

---

## Active Console backlog (P2 product)

Console MVP panels **~95%** shipped. **Fase 7b** ✅ complete (**SML-077** Verify diff, **SML-078** Purge SQS, **SML-079** SecureString SSM). `ROADMAP-COMMERCIAL-PARITY.md`.

Full product backlog: `future-work/product/README.md`.

---

## Maintenance

Update this overview when:

- Shipping or removing a **Console panel** capability ([`console.md`](console.md) same PR).
- Closing an **`FW-PRD-*`** that changes Console UX.
- Changing smoke coverage (`run-console-v2-smoke.mjs`).

Follow `cursor/company/DOCUMENTATION-GOVERNANCE.md`. **Do not** duplicate API operation tables here — link to [`compatibility-matrix.md`](compatibility-matrix.md) and [`aws-parity-overview.md`](aws-parity-overview.md).

On ship, update **one line** in [`aws-parity-overview.md`](aws-parity-overview.md) Console summary (executive cross-link only).

---

## Related

- [console.md](console.md) — run, architecture, troubleshooting
- [aws-parity-overview.md](aws-parity-overview.md) — API / Terraform executive summary
- [compatibility-matrix.md](compatibility-matrix.md) — HTTP operation truth table
- [admin-api.md](admin-api.md) — seed, reset, peek routes
