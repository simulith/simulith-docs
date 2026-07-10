# Lambda — Simulith

Local AWS Lambda emulation for development and testing.

## Overview

Simulith emulates the Lambda REST API on the same port as all other services (default `:4566`). Lambda uses the `rest-json` protocol — path-based routing on `/2015-03-31/functions/…` — and is compatible with:

- AWS CLI (`aws lambda`)
- AWS SDK for Go, Node.js, Python, etc.
- Terraform (`aws_lambda_function`)

## Implemented operations (SML-120–122)

| Operation | Method + Path | Status |
|---|---|---|
| CreateFunction | `POST /2015-03-31/functions` | ✓ |
| ListFunctions | `GET /2015-03-31/functions` | ✓ |
| GetFunction | `GET /2015-03-31/functions/{name}` | ✓ |
| DeleteFunction | `DELETE /2015-03-31/functions/{name}` | ✓ |
| InvokeFunction | `POST /2015-03-31/functions/{name}/invocations` | ✓ (SML-121) |
| UpdateFunctionCode | `PUT /2015-03-31/functions/{name}/code` | ✓ (SML-121) |
| CreateEventSourceMapping | `POST /2015-03-31/event-source-mappings` | ✓ (SML-122) |
| ListEventSourceMappings | `GET /2015-03-31/event-source-mappings` | ✓ (SML-122) |
| GetEventSourceMapping | `GET /2015-03-31/event-source-mappings/{uuid}` | ✓ (SML-122) |
| DeleteEventSourceMapping | `DELETE /2015-03-31/event-source-mappings/{uuid}` | ✓ (SML-122) |

## AWS CLI examples

```bash
# Prerequisites
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
ENDPOINT=http://localhost:4566

# Create a zip from a Node.js handler
cat > /tmp/index.js <<'EOF'
exports.handler = async (event) => ({
  statusCode: 200,
  body: JSON.stringify({ message: 'hello from simulith' })
});
EOF
cd /tmp && zip function.zip index.js

# CreateFunction
aws lambda create-function \
  --function-name my-fn \
  --runtime nodejs20.x \
  --handler index.handler \
  --role arn:aws:iam::000000000000:role/r \
  --zip-file fileb:///tmp/function.zip \
  --endpoint-url $ENDPOINT

# ListFunctions
aws lambda list-functions --endpoint-url $ENDPOINT

# GetFunction
aws lambda get-function --function-name my-fn --endpoint-url $ENDPOINT

# DeleteFunction
aws lambda delete-function --function-name my-fn --endpoint-url $ENDPOINT
```

## InvokeFunction (sync)

Requires **`node`** or **`python3`** on the host PATH (not included in the default Docker runtime image).

```bash
# Invoke (RequestResponse — default)
aws lambda invoke \
  --function-name my-fn \
  --payload '{"key":"value"}' \
  --endpoint-url $ENDPOINT \
  /tmp/out.json

cat /tmp/out.json

# UpdateFunctionCode
aws lambda update-function-code \
  --function-name my-fn \
  --zip-file fileb:///tmp/function.zip \
  --endpoint-url $ENDPOINT
```

Supported runtimes for invoke: `nodejs*` (uses `node`), `python*` (uses `python3`). `Environment.Variables` from CreateFunction are injected into the subprocess. `Timeout` (seconds) kills slow handlers.

## SQS event source mapping (SML-122)

Map a local SQS queue to a Lambda function. The runtime **polls enabled mappings in the background** (~1s interval), batches messages, invokes the function with a standard SQS `Records` event, and deletes messages on success.

```bash
# Queue must exist (e.g. after simulith seed or aws sqs create-queue)
QUEUE_ARN=arn:aws:sqs:us-east-1:000000000000:demo-queue

aws lambda create-event-source-mapping \
  --function-name my-fn \
  --event-source-arn "$QUEUE_ARN" \
  --batch-size 10 \
  --endpoint-url $ENDPOINT

aws lambda list-event-source-mappings --function-name my-fn --endpoint-url $ENDPOINT

# UUID from create/list output
aws lambda delete-event-source-mapping --uuid <uuid> --endpoint-url $ENDPOINT
```

**Limits:** SQS ARNs only; `BatchSize` capped at 10; async `InvocationType: Event` not used (poller invokes synchronously). Requires `node`/`python3` on PATH for the target function.

## Persistence

Function metadata is stored in the SQLite database (`lambda_functions` table). The zip payload is stored on disk at:

```
{data-dir}/lambda/{function-name}/code.zip
```

Both metadata and zip survive runtime restarts. `simulith reset` removes all Lambda state.

## Function ARN format

```
arn:aws:lambda:{region}:{accountId}:function:{functionName}
```

Default values: region `us-east-1`, accountId `000000000000`.

## CreateFunction request fields

| Field | Required | Default | Notes |
|---|---|---|---|
| `FunctionName` | yes | — | Unique identifier |
| `Runtime` | yes | — | Any string accepted; not validated against AWS runtimes in this version |
| `Handler` | yes | — | e.g. `index.handler` |
| `Role` | yes | — | Any ARN string accepted |
| `Code.ZipFile` | yes | — | Base64-encoded zip; `Code.S3Bucket/S3Key` not supported |
| `Timeout` | no | `3` | Seconds; used by SML-121 (invoke) |
| `MemorySize` | no | `128` | MB |
| `Environment.Variables` | no | `{}` | Injected into subprocess on invoke (SML-121) |
| `Description` | no | `""` | Metadata only |

## Known gaps and limits

- **InvocationType: Event** (async HTTP invoke) — not supported; ESM uses sync invoke internally.
- **Go/Java/custom runtimes** — not supported for invoke; Node.js and Python only.
- **Docker runtime image** — does not bundle `node` or `python3`; invoke works when binaries are on PATH (local dev) or image is extended.
- **Code.S3Bucket / Code.S3Key** — not supported. Use `Code.ZipFile` (base64).
- **Runtime validation** — Simulith accepts any runtime string. AWS enforces a specific list.
- **Zip size limits** — no limit enforced in this version. AWS limits 50 MB compressed / 250 MB uncompressed.
- **ListFunctions pagination** — `Marker` / `MaxItems` query params are ignored; all functions are returned.
- **Tags, aliases, versions** — not implemented.
- **Concurrency** — not applicable for local development.

## Compatibility matrix row

See [`aws-parity-overview.md`](aws-parity-overview.md) for the full matrix. Lambda parity tracking begins with SML-123 (`simulith verify lambda`).
