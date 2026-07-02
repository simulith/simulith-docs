# Seed — Simulith runtime

Load **curated fixtures** into the local SQLite state store for repeatable dev setups.

> **New to Simulith?** Start with the [Quickstart](quickstart.md) (seed + AWS CLI smoke in under five minutes).

## Command

```bash
simulith seed [--config path] [--file path] [--no-reset]
```

- **`--file`** — JSON fixture path (default: built-in demo profile)
- **`--no-reset`** — skip pre-clear of DynamoDB + SQS before apply (advanced)
- **`--config`** — same config resolution as `start` / `reset`

**Stop a running server first** if it holds the database open (same guidance as [persistence.md](persistence.md#reset)).

## Default profile

`simulith seed` loads:

| Service | Resource | Content |
| --- | --- | --- |
| DynamoDB | table `Demo` | Hash key `Id`; items `1/Alice`, `2/Bob` |
| SQS | queue `demo-queue` | One message `hello from seed` |
| SSM | `/app/demo/api-url`, `/app/demo/env` | String parameters for local app config |

Example fixture source: [seeds/default.json](../seeds/default.json) (embedded copy in `internal/seed/default.json`).

## Workflow

```bash
simulith seed
simulith start
aws dynamodb describe-table --table-name Demo --endpoint-url http://127.0.0.1:4566 --region us-east-1
aws sqs receive-message --queue-url http://127.0.0.1:4566/000000000000/demo-queue --endpoint-url http://127.0.0.1:4566 --region us-east-1
aws ssm get-parameter --name /app/demo/api-url --endpoint-url http://127.0.0.1:4566 --region us-east-1
```

On **Git Bash (Windows)**, set `export MSYS2_ARG_CONV_EXCL="*"` before SSM CLI commands, or use [PowerShell](quickstart.md). See [quickstart troubleshooting](quickstart.md#troubleshooting).

Re-running `simulith seed` is **idempotent** (default pre-clear wipes DynamoDB, SQS, and SSM — same scope as `simulith reset` — then re-applies the fixture).

More CLI examples: [aws-cli-examples.md](aws-cli-examples.md#seeded-data). SDK: [sdk-examples.md](sdk-examples.md#seeded-data).

## Fixture schema (v1)

```json
{
  "version": 1,
  "dynamodb": {
    "tables": [
      {
        "name": "Demo",
        "definition": {
          "TableName": "Demo",
          "KeySchema": [{ "AttributeName": "Id", "KeyType": "HASH" }],
          "AttributeDefinitions": [{ "AttributeName": "Id", "AttributeType": "S" }],
          "BillingMode": "PAY_PER_REQUEST"
        },
        "items": [
          { "Id": { "S": "1" }, "Name": { "S": "Alice" } }
        ]
      }
    ]
  },
  "sqs": {
    "queues": [
      {
        "name": "demo-queue",
        "queueUrl": "http://127.0.0.1:4566/000000000000/demo-queue",
        "attributes": {},
        "messages": [
          { "body": "hello from seed", "delaySeconds": 0 }
        ]
      }
    ]
  },
  "ssm": {
    "parameters": [
      {
        "name": "/app/demo/api-url",
        "type": "String",
        "value": "http://localhost:8080",
        "version": 1,
        "lastModified": "2026-01-01T00:00:00Z"
      }
    ]
  }
}
```

Notes:

- **`definition`** — CreateTable-shaped JSON (or stored `{ "description": ... }` wrapper)
- **`items`** — DynamoDB AttributeMap JSON; keys derived same as runtime PutItem
- **`queueUrl`** — optional; defaults to `http://{host}:{port}/000000000000/{name}` from config
- **`messages`** — `messageId` and `md5_body` generated at apply time
- **`ssm.parameters`** — `name`, `type`, `value` required; `version` (default 1), `lastModified` (default now UTC), `tags`, `dataType` optional. Applied via store layer (not HTTP PutParameter).
- Empty `dynamodb`, `sqs`, or `ssm` sections are allowed

## Out of scope (MVP)
- YAML fixtures — JSON only
- Seeding via live HTTP — store-direct apply only
- Snapshot import — see [snapshot.md](snapshot.md) (SML-020)

## Related

- [persistence.md](persistence.md) — state path, reset
- [dynamodb.md](dynamodb.md) — table/item storage
- [sqs.md](sqs.md) — queue/message storage
- [ssm.md](ssm.md) — Parameter Store Put/Get
