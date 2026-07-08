# Simulith — Local administration API

Reserved HTTP routes under **`/_simulith/v1/`** for local developer and Console operations that are **not** part of the public AWS API. They use the **same SQLite store** as the running runtime (in-process).

**Related:** [Console](console.md) (GUI proxy), [Snapshot](snapshot.md) (CLI), [Seed](seed.md).

---

## Security

- **Local development only** — no authentication in MVP.
- Do not expose `/_simulith/*` on untrusted networks without a gateway.
- Console and Docker nginx proxy these paths on the same origin as the SPA.

---

## Routing

Admin routes are registered **before** the AWS multiplex handler on `POST /`. Requests to `/_simulith/v1/*` never hit DynamoDB/SQS/SSM protocol code.

```text
GET  /health                    → public liveness (not admin)
/_simulith/v1/*                 → this document
POST /                          → AWS JSON / Query multiplex
```

---

## Common response shape

Success:

```json
{ "status": "ok", ... }
```

Error:

```json
{ "status": "error", "message": "..." }
```

HTTP status matches outcome (`405` method not allowed, `400` bad request, `404` unknown admin path).

---

## Endpoints

### `GET /_simulith/v1/status`

Runtime admin status (Console dashboard).

**Response 200:**

```json
{
  "status": "ok",
  "listen": "0.0.0.0:4566",
  "region": "us-east-1"
}
```

---

### `POST /_simulith/v1/seed`

Load the **built-in demo fixture** (same as `simulith seed`). Pre-clears DynamoDB, SQS, SSM, and S3 state, then applies the default profile.

**Response 200:**

```json
{ "status": "ok", "action": "seed" }
```

---

### `POST /_simulith/v1/reset`

Clear all local DynamoDB, SQS, SSM, and S3 state (`ResetLocalState`).

**Response 200:**

```json
{ "status": "ok", "action": "reset" }
```

---

### `GET /_simulith/v1/snapshot`

Export full local state as a **snapshot JSON document** (same format as `simulith snapshot save`). Includes DynamoDB, SQS, and SSM.

**Response 200:** snapshot document with `"kind": "simulith-snapshot"`.

---

### `POST /_simulith/v1/snapshot`

Import a snapshot JSON document into the live store.

| Query | Default | Description |
| --- | --- | --- |
| `noReset` | `false` | When `true`, skip pre-clear before import |

**Request body:** snapshot document (`Content-Type: application/json`, max **32 MiB**).

**Response 200:**

```json
{ "status": "ok", "action": "snapshot_import" }
```

---

### `GET /_simulith/v1/sqs/messages`

**Peek** queue messages without calling `ReceiveMessage` — does **not** change visibility or receipt handles (FW-SQS-020 / Floci-style inspection).

| Query | Required | Description |
| --- | --- | --- |
| `queueName` | yes | SQS queue name (e.g. `demo-queue`) |

**Response 200:**

```json
{
  "status": "ok",
  "queueName": "demo-queue",
  "messages": [
    {
      "messageId": "...",
      "body": "hello from seed",
      "md5Body": "...",
      "delaySeconds": 0,
      "visibleAfter": "...",
      "receiveCount": 0
    }
  ]
}
```

Empty queue: `"messages": []`.

---

## Examples (curl)

Runtime on `:4566`:

```bash
curl -s http://127.0.0.1:4566/_simulith/v1/status

curl -s -X POST http://127.0.0.1:4566/_simulith/v1/seed

curl -s http://127.0.0.1:4566/_simulith/v1/snapshot -o snapshot.json

curl -s -X POST http://127.0.0.1:4566/_simulith/v1/snapshot \
  -H "Content-Type: application/json" \
  --data-binary @snapshot.json

curl -s "http://127.0.0.1:4566/_simulith/v1/sqs/messages?queueName=demo-queue"
```

Via Console nginx proxy (`:9080`):

```bash
curl -s http://127.0.0.1:9080/_simulith/v1/status
```

---

## Deferred (not in this API version)

| Capability | Follow-up |
| --- | --- |
| Trigger `simulith verify` from admin API | Optional follow-up — use CLI or Console **Verify** panel import (FW-PRD-005 shipped SML-059) |
| DELETE on peek endpoint | Optional — use PurgeQueue (FW-SQS-021 shipped SML-064) |
| Console snapshot save/restore UI | Optional follow-up; CLI + admin API exist |

---

## Implementation

- Package: `runtime/internal/admin/`
- Registered in: `runtime/internal/runtime/server.go` (before AWS catch-all)
