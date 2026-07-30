# Simulith Console

Web GUI for local Simulith — health, seed/reset, and **service panels** for DynamoDB, SQS, SSM, S3, Lambda, API Gateway, Secrets Manager, EventBridge, and Verify.

For first-time runtime onboarding, see [quickstart.md](quickstart.md).

---

## Quick run (Docker)

### Full product — published images

Pulls published images (`simulith/simulith` + `simulith/console`) — no checkout or `--build`. From any folder containing the compose file:

```bash
SIMULITH_VERSION=0.1.0 docker compose -f docker-compose.all-in-one.published.yml up
# omit SIMULITH_VERSION for :latest
```

Same single entry URL as below (`http://localhost:9080`). Details: [release.md](https://simulith.dev), [docker.md](docker.md).

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

1. Open the Console dashboard — expect **Connected** when runtime is healthy.
2. Click **Seed demo data** — loads the built-in fixture (`Demo` table, `demo-queue`, SSM params under `/app/demo/*`, S3 `demo-bucket`, Lambda `demo-fn` + SQS ESM, API Gateway `demo-api`, Secrets Manager `demo-secret`).
3. Open **DynamoDB** — browse, create tables, put/edit/delete items (Simple strings or **JSON document** for Map/List).
4. Open **SQS** — list queues, peek messages, send, receive+delete, **purge queue**.
5. Open **SSM** — browse by path, put/edit/delete String and **SecureString** (mock encryption notice).
6. Open **S3** — list/create/delete buckets, list objects by prefix, upload/download/delete objects.
7. Open **Lambda** — list functions, inspect config, invoke with JSON payload, delete function (invoke needs node/python3 on runtime host).
8. Open **API Gateway** — list REST APIs, load stage, copy invoke URL, HTTP smoke invoke, delete API.
9. Open **Secrets Manager** — list secrets, reveal value (mock storage), create and delete secrets.
10. Open **EventBridge** — list schedule rules, inspect targets, see last invoke time (admin peek).
10. Open **Verify** — import `verify-last.json` or CI artifact JSON (`verify-dynamodb.json`, `verify-s3.json`, etc.).
11. Click **Reset local state** — clears all panels.

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

**Security:** local development only — no authentication in the Console. Do not expose admin routes on untrusted networks without a gateway.

---

## Service panels (v2)

| Panel | Capabilities | Limits |
| --- | --- | --- |
| **DynamoDB** | ListTables, Scan, CreateTable (hash key String), DeleteTable, Put/Update/Delete item (Simple), **JSON document** put/edit (Map/List via GetItem → PutItem) | GSIs / expressions → CLI; visual attribute editor deferred |
| **SQS** | ListQueues, peek (admin API), SendMessage, ReceiveMessage + DeleteMessage, **PurgeQueue** | Peek has no receipt handle; FIFO / visibility deferred |
| **SSM** | GetParametersByPath, PutParameter (**String** + **SecureString**), DeleteParameter | SecureString = mock local encryption (not KMS); StringList / batch delete UI deferred |
| **S3** | ListBuckets, CreateBucket, DeleteBucket, ListObjectsV2 (prefix + pagination), PutObject upload, GetObject download, DeleteObject | CopyObject / DeleteObjects batch UI deferred; seeded `demo-bucket` via Dashboard **Seed** |
| **Lambda** | ListFunctions, GetFunction (config + env), Invoke (RequestResponse JSON), DeleteFunction | Create/update code UI deferred; seeded `demo-fn` via Dashboard **Seed**; invoke needs node/python3 on runtime host PATH |
| **API Gateway** | List REST APIs, GetResources, GetStage, HTTP invoke, DeleteRestApi | Create/deploy UI deferred; seeded `demo-api` via **Seed** |
| **Secrets Manager** | ListSecrets, GetSecretValue (reveal), CreateSecret, DeleteSecret | Mock plain-text storage (not KMS); seeded `demo-secret` via **Seed** |
| **EventBridge** | ListRules, DescribeRule, ListTargetsByRule; last invoke via admin peek | Create/delete UI deferred; no seed rule yet; CLI / Terraform |

Full gap analysis: [console.md](console.md).

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
