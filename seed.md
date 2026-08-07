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
| S3 | bucket `demo-bucket` | `readme.txt`, `config/app.json`; **notification** → `demo-fn` on `uploads/` prefix |
| Lambda | function `demo-fn` | Node.js echo handler; ESM to `demo-queue`; **S3 ObjectCreated** target for `demo-bucket` |
| API Gateway | REST API `demo-api` (`demoapi001`) | Stage `dev` → `{proxy+}` AWS_PROXY to `demo-fn` |
| Secrets Manager | secret `demo-secret` | Plain `SecretString` `hello from seed` |
| EventBridge | rule `demo-rule` | `rate(5 minutes)` → Lambda target `demo-fn` |
| Cognito | pool `demo-pool` | client `demo-client` + group `admin` (JWKS enabled) |
| SES | identity `demo@simulith.local` | template `demo-template` + sample outbox message |
| VPC | `demo-vpc` + `demo-database-subnet` | Postgres SG `demo-postgres-sg` (10.0.0.0/16 → 5432) |
| RDS | instance `demo-db` | Postgres 15 sidecar (`demoapp` / `local-dev-password`; **Docker required** on runtime host) |

When **docker** is not on the Simulith runtime host PATH (e.g. `simulith seed` inside the shipped container image), RDS instances are **skipped with a warning** — other seed fixtures still apply. Same constraint as [`simulith verify rds`](rds.md#verify). seeds/default.json (embedded copy in the runtime).

**Lambda / API Gateway invoke after seed** requires `node` or `python3` on the Simulith runtime host PATH (same as Console panel invoke).

HTTP smoke after seed:

```bash
curl "http://127.0.0.1:4566/restapis/demoapi001/dev/_user_request_/hello"
```

S3 → Lambda after seed (requires `node` on PATH, runtime running):

```bash
echo "trigger" | aws s3api put-object \
  --bucket demo-bucket --key uploads/smoke.txt --body - \
  --endpoint-url http://127.0.0.1:4566 --region us-east-1
# Check Simulith runtime logs for async demo-fn invoke (S3 Records event)
```

## Workflow

```bash
simulith seed
simulith start
aws dynamodb describe-table --table-name Demo --endpoint-url http://127.0.0.1:4566 --region us-east-1
aws sqs receive-message --queue-url http://127.0.0.1:4566/000000000000/demo-queue --endpoint-url http://127.0.0.1:4566 --region us-east-1
aws ssm get-parameter --name /app/demo/api-url --endpoint-url http://127.0.0.1:4566 --region us-east-1
```

On **Git Bash (Windows)**, set `export MSYS2_ARG_CONV_EXCL="*"` before SSM CLI commands, or use [PowerShell](quickstart.md). See [quickstart troubleshooting](quickstart.md#troubleshooting).

Re-running `simulith seed` is **idempotent** (default pre-clear wipes DynamoDB, SQS, SSM, S3, Lambda, API Gateway, Secrets Manager, Cognito, SES, EC2/VPC, RDS, and EventBridge — same scope as `simulith reset` — then re-applies the fixture).

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
  },
  "s3": {
    "buckets": [
      {
        "name": "demo-bucket",
        "notification": {
          "lambdaFunctionConfigurations": [
            {
              "id": "seed-demo-bucket-uploads",
              "functionName": "demo-fn",
              "events": ["s3:ObjectCreated:*"],
              "filterPrefix": "uploads/"
            }
          ]
        },
        "objects": [
          {
            "key": "readme.txt",
            "body": "hello from seed",
            "contentType": "text/plain"
          }
        ]
      }
    ]
  },
  "lambda": {
    "functions": [
      {
        "name": "demo-fn",
        "runtime": "nodejs20.x",
        "handler": "index.handler",
        "handlerSource": "exports.handler = async (event) => ({ ok: true, source: 'seed' });",
        "timeout": 10,
        "memorySize": 128
      }
    ],
    "eventSourceMappings": [
      {
        "uuid": "seed-esm-demo-fn-demo-queue",
        "functionName": "demo-fn",
        "eventSourceArn": "arn:aws:sqs:us-east-1:000000000000:demo-queue",
        "batchSize": 10
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
- **`s3.buckets`** — `name` required; optional `objects` with `key`, `body`, optional `contentType`; optional `notification.lambdaFunctionConfigurations` with `functionName` or `lambdaFunctionArn`, `events` (default `s3:ObjectCreated:*`), optional `filterPrefix` / `filterSuffix`, optional `id`. Notification applied **after** Lambda functions in the fixture (store layer).
- **`lambda.functions`** — `name`, `handlerSource` (Node.js module body) required; zip built at apply time and written under `LambdaDataDir`. Optional `runtime`, `handler`, `role`, `timeout`, `memorySize`, `environment`.
- **`lambda.eventSourceMappings`** — `uuid`, `functionName`, `eventSourceArn` (SQS ARN) required; target queue must exist in fixture (apply after SQS). Optional `batchSize`, `enabled`.
- **`apigateway.restApis`** — `id`, `name` required; optional `description`, `proxyFunction` (default `demo-fn`), `stageName` (default `dev`). Seeds `{proxy+}` AWS_PROXY integration and deployment.
- **`secretsmanager.secrets`** — `name`, `secretString` required; optional `description`, `createdAt`. Applied via store layer with fixed seed suffix/version for idempotent apply.
- **`eventbridge.rules`** — `name`, `scheduleExpression` (`rate(...)` / `cron(...)`) required; optional `state` (default `ENABLED`), `description`, `eventBusName`, `createdAt`. Targets: `id` required; `functionName` (resolved to Lambda ARN; function must exist) or `arn`; optional `input`. Applied **after** Lambda.
- **`cognito.userPools`** — `id`, `name` required; optional `createdAt`. Nested `clients` (`clientId`, `clientName`) and `groups` (`groupName`, optional `description`). JWKS keys generated at apply time. Applied **after** EventBridge.
- **`ses.identities`** — `email` required; optional `createdAt`. Auto-verified (`Success`). Applied **after** Cognito.
- **`ses.templates`** — `name` required; optional `subject`, `htmlPart`, `textPart`, `createdAt`, `updatedAt`. Applied after identities in the SES block.
- **`ses.outboxMessages`** — `source`, `toAddresses` required; optional `templateName` (must exist), `templateData`, `subject`, `htmlBody`, `textBody`, `rawData`, `messageId`, `createdAt`. Captured Send* rows for Console inspect.
- **`vpc.vpcs`** — `cidrBlock` required; optional fixed `id`, `enableDnsSupport` (default true), `enableDnsHostnames` (default false), `tags`. Creates main route table automatically.
- **`vpc.subnets`** — `vpcId`, `cidrBlock` required; optional fixed `id`, `availabilityZone` (default `{region}a`), `mapPublicIpOnLaunch`, `tags`. VPC must exist in fixture (applied first).
- **`vpc.securityGroups`** — `groupName`, `vpcId` required; optional fixed `id`, `description`, `tags`, `ingressRules` / `egressRules` (`ipProtocol`, `fromPort`, `toPort`, `cidrIpv4`, `sourceGroupId`, `description`). Applied after subnets.
- **`rds.*`** — subnet groups, parameter groups, Postgres instances (see [rds.md](rds.md)); applied **after** VPC when subnets are referenced.
- Empty `dynamodb`, `sqs`, `ssm`, `s3`, `lambda`, `apigateway`, `secretsmanager`, `eventbridge`, `cognito`, `ses`, `vpc`, or `rds` sections are allowed

## Out of scope (MVP)
- YAML fixtures — JSON only
- Seeding via live HTTP — store-direct apply only
- Snapshot import — see [snapshot.md](snapshot.md)

## Related

- [persistence.md](persistence.md) — state path, reset
- [dynamodb.md](dynamodb.md) — table/item storage
- [sqs.md](sqs.md) — queue/message storage
- [ssm.md](ssm.md) — Parameter Store Put/Get
- [s3.md](s3.md) — bucket/object storage
- [lambda.md](lambda.md) — function storage and invoke
- [eventbridge.md](eventbridge.md) — schedule rules and targets
- [cognito.md](cognito.md) — User Pool + Admin* + JWKS
