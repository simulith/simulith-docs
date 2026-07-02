# Persistence — Simulith runtime

Local state for **DynamoDB**, **SQS**, and **SSM Parameter Store** is stored in SQLite.

## Configuration

| Setting | Default | Env override |
| --- | --- | --- |
| Driver | `sqlite` | `SIMULITH_STATE_DRIVER` |
| Path | `./.simulith/state.db` | `SIMULITH_STATE_PATH` |

YAML (`config.yaml`):

```yaml
state:
  driver: sqlite
  path: ./.simulith/state.db
```

The same resolution order as the HTTP server applies: flags → env → file → defaults (`internal/config`).

## Schema

```sql
CREATE TABLE dynamodb_tables (
  name TEXT PRIMARY KEY,
  definition_json TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE dynamodb_items (
  table_name TEXT NOT NULL,
  item_key TEXT NOT NULL,
  item_json TEXT NOT NULL,
  PRIMARY KEY (table_name, item_key)
);

CREATE TABLE sqs_queues ( ... );
CREATE TABLE sqs_messages ( ... );

CREATE TABLE ssm_parameters (
  name TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  value TEXT NOT NULL,
  version INTEGER NOT NULL DEFAULT 1,
  last_modified TEXT NOT NULL,
  data_type TEXT,
  tags_json TEXT
);
```

- **DynamoDB** — table metadata in `dynamodb_tables`; items in `dynamodb_items`
- **SQS** — queue metadata in `sqs_queues`; messages in `sqs_messages`
- **SSM** — parameters in `ssm_parameters` (full parameter name as primary key)

Data survives process restarts. Reopening the database file preserves all rows.

**HTTP:** PutParameter and GetParameter are implemented over AWS JSON 1.1. See [ssm.md](ssm.md).

## Docker

`docker-compose.yml` mounts a named volume at `/app/.simulith`, so `state.db` persists across container recreates.

Optional bind mount for host-visible state:

```yaml
volumes:
  - ./.simulith:/app/.simulith
```

## Reset

Clear all local **DynamoDB, SQS, and SSM** state:

```bash
simulith reset
```

Uses the configured `state.path`. **Stop a running server first** — an open SQLite handle may lock the database file on some platforms.

After reset:

- `dynamodb_tables` and `dynamodb_items` are empty
- `sqs_queues` and `sqs_messages` are empty
- `ssm_parameters` is empty
- CreateQueue / PutItem / SendMessage work on a clean store

No confirmation prompt (non-interactive by design).

See also [seed.md](seed.md) for loading fixtures after reset, and [snapshot.md](snapshot.md) for full-state save/restore.

## Snapshots

Snapshot v1 documents may include an optional `"ssm"` section:

```json
"ssm": {
  "parameters": [
    {
      "name": "/app/dev/api-url",
      "type": "String",
      "value": "http://localhost:8080",
      "version": 1,
      "lastModified": "2026-06-01T12:00:00Z"
    }
  ]
}
```

Older snapshot files without `"ssm"` still restore; SSM rows are cleared when restore runs with the default pre-reset.

## Related

- [dynamodb.md](dynamodb.md) — DynamoDB operations and item storage
- [sqs.md](sqs.md) — SQS queues and messages
- [docker.md](docker.md) — container volumes and healthcheck
- [quickstart.md](quickstart.md) — getting started
