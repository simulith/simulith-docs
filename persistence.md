# Persistence — Simulith runtime

Local state for **DynamoDB**, **SQS**, **SSM Parameter Store**, **S3**, and **Lambda** is stored in SQLite. S3 object bytes and Lambda deployment zips live on the filesystem beside the database.

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

CREATE TABLE ssm_parameters ( ... );

CREATE TABLE s3_buckets ( ... );
CREATE TABLE s3_objects ( ... );

CREATE TABLE lambda_functions ( ... );
CREATE TABLE lambda_event_source_mappings ( ... );
```

- **DynamoDB** — table metadata in `dynamodb_tables`; items in `dynamodb_items`
- **SQS** — queue metadata in `sqs_queues`; messages in `sqs_messages`
- **SSM** — parameters in `ssm_parameters` (full parameter name as primary key)
- **S3** — bucket names in `s3_buckets`; object metadata in `s3_objects`; object bytes under `{data-dir}/s3/{bucket}/…` — [s3.md](s3.md)
- **Lambda** — function metadata in `lambda_functions`; SQS mappings in `lambda_event_source_mappings`; zip payloads under `{data-dir}/lambda/{function-name}/code.zip` — [lambda.md](lambda.md)

`{data-dir}` defaults to the directory containing `state.db` (e.g. `./.simulith/`).

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

Clear all local **DynamoDB, SQS, SSM, S3, and Lambda** state:

```bash
simulith reset
```

Uses the configured `state.path`. **Stop a running server first** — an open SQLite handle may lock the database file on some platforms.

After reset:

- `dynamodb_tables` and `dynamodb_items` are empty
- `sqs_queues` and `sqs_messages` are empty
- `ssm_parameters` is empty
- `s3_buckets` and `s3_objects` are empty; S3 object files under `{data-dir}/s3/` are removed
- `lambda_functions` and `lambda_event_source_mappings` are empty; Lambda zips under `{data-dir}/lambda/` are removed
- CreateQueue / PutItem / SendMessage / CreateBucket / CreateFunction work on a clean store

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
- [ssm.md](ssm.md) — SSM Parameter Store
- [s3.md](s3.md) — S3 buckets and objects
- [lambda.md](lambda.md) — Lambda functions and event source mappings
- [docker.md](docker.md) — container volumes and healthcheck
- [quickstart.md](quickstart.md) — getting started
