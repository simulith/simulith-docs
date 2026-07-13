# Snapshot — Simulith runtime

Save and restore **local SQLite state** (DynamoDB + SQS + SSM) as a versioned JSON snapshot. **S3 and Lambda are not included** in snapshot v1 — metadata lives in SQLite but object bytes and function zips are filesystem-backed; use [seed.md](seed.md) or AWS API to recreate.

## Commands

```bash
simulith snapshot save [--config path] [--file path]
simulith snapshot restore [--config path] --file path [--no-reset]
```

- **`save --file`** — output path (default: `.simulith/snapshots/snapshot.json`)
- **`restore --file`** — snapshot to import (**required**)
- **`restore --no-reset`** — skip pre-clear before import (advanced; expect conflicts on duplicate resources)
- **`--config`** — same config resolution as `start` / `reset` / `seed`

**Stop a running server first** if it holds the database open (same guidance as [persistence.md](persistence.md#reset)).

## Seed vs snapshot

| | Seed (`simulith seed`) | Snapshot (`simulith snapshot`) |
| --- | --- | --- |
| Purpose | Curated demo/dev fixture | Full runtime state checkpoint |
| Format | Seed fixture v1 (no `kind`) | Snapshot v1 (`kind: simulith-snapshot`) |
| Message IDs | Generated at apply | Preserved exactly |
| SQS in-flight state | Not captured | Preserved (visibility, receipt handles) |
| Typical use | Onboarding, repeatable baseline | Bug repro, rollback mid-session |

## Workflow

```bash
simulith start
# ... exercise app via AWS CLI/SDK ...
# stop server

simulith snapshot save --file ./checkpoints/before-test.json
# ... more changes ...

simulith snapshot restore --file ./checkpoints/before-test.json
simulith start
```

## Snapshot schema (v1)

```json
{
  "kind": "simulith-snapshot",
  "version": 1,
  "exportedAt": "2026-05-27T12:00:00Z",
  "dynamodb": {
    "tables": [{ "name": "Demo", "definition": { "...": "..." } }],
    "items": [{ "tableName": "Demo", "itemKey": "...", "item": { "...": "..." } }]
  },
  "sqs": {
    "queues": [{ "name": "demo-queue", "queueUrl": "http://...", "attributes": {} }],
    "messages": [{
      "messageId": "...",
      "queueName": "demo-queue",
      "body": "...",
      "md5Body": "...",
      "delaySeconds": 0,
      "visibleAfter": "...",
      "receiveCount": 0,
      "attributes": { "TraceId": { "Type": "String", "Value": "abc" } }
    }]
  }
}
```

- **`kind`** must be `simulith-snapshot` — seed fixture files are rejected
- Empty `dynamodb`, `sqs`, or `ssm` sections are valid (partial snapshots)
- **S3 / Lambda** — not exported in v1 (see [persistence.md](persistence.md))

Re-export snapshots after Simulith schema upgrades if restore fails on older files.

## Out of scope (MVP)

- Binary SQLite file copy — JSON v1 only
- S3 object bytes and Lambda deployment zips in snapshot — deferred
- Snapshot registry/list/delete CLI — use the filesystem

## Related

- [seed.md](seed.md) — curated fixtures
- [persistence.md](persistence.md) — state path, reset
- [sqs.md](sqs.md) — queue/message storage
