# Lambda — Simulith

Local AWS Lambda emulation for development and testing.

## Overview

Simulith emulates the Lambda REST API on the same port as all other services (default `:4566`). Lambda uses the `rest-json` protocol — path-based routing on `/2015-03-31/functions/…` — and is compatible with:

- AWS CLI (`aws lambda`)
- AWS SDK for Go, Node.js, Python, etc.
- Terraform (`aws_lambda_function`)

## Implemented operations

| Operation | Method + Path | Status |
|---|---|---|
| CreateFunction | `POST /2015-03-31/functions` | ✓ |
| ListFunctions | `GET /2015-03-31/functions` | ✓ |
| GetFunction | `GET /2015-03-31/functions/{name}` | ✓ |
| DeleteFunction | `DELETE /2015-03-31/functions/{name}` | ✓ |
| InvokeFunction | `POST /2015-03-31/functions/{name}/invocations` | ✓ |
| UpdateFunctionCode | `PUT /2015-03-31/functions/{name}/code` | ✓ |
| CreateEventSourceMapping | `POST /2015-03-31/event-source-mappings` | ✓ |
| ListEventSourceMappings | `GET /2015-03-31/event-source-mappings` | ✓ |
| GetEventSourceMapping | `GET /2015-03-31/event-source-mappings/{uuid}` | ✓ |
| DeleteEventSourceMapping | `DELETE /2015-03-31/event-source-mappings/{uuid}` | ✓ |
| CreateFunctionUrlConfig | `POST /2021-10-31/functions/{name}/url` | ✓ |
| GetFunctionUrlConfig | `GET /2021-10-31/functions/{name}/url` | ✓ |
| DeleteFunctionUrlConfig | `DELETE /2021-10-31/functions/{name}/url` | ✓ |
| Function URL invoke | `POST /2021-10-31/functions/{name}/url` | ✓ |
| PublishLayerVersion | `POST /2018-10-31/layers/{name}/versions` | ✓ |
| ListLayers | `GET /2018-10-31/layers` | ✓ |
| ListLayerVersions | `GET /2018-10-31/layers/{name}/versions` | ✓ |
| GetLayerVersion | `GET /2018-10-31/layers/{name}/versions/{version}` | ✓ |
| DeleteLayerVersion | `DELETE /2018-10-31/layers/{name}/versions/{version}` | ✓ |

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

Requires **`node`** or **`python3`** on the host PATH for interpreted runtimes (not included in the default Docker runtime image). **Go / custom (`provided*`)** runtimes run a **`bootstrap`** executable from the deployment zip (no host runtime required); build for your host OS when testing locally (Linux binary when deploying to AWS).

```bash
# Invoke (RequestResponse — default)
aws lambda invoke \
  --function-name my-fn \
  --payload '{"key":"value"}' \
  --endpoint-url $ENDPOINT \
  /tmp/out.json

cat /tmp/out.json

# Invoke async (Event) — returns HTTP 202 immediately; handler runs in background
aws lambda invoke \
  --function-name my-fn \
  --invocation-type Event \
  --payload '{"key":"value"}' \
  --endpoint-url $ENDPOINT \
  /tmp/out.json

# UpdateFunctionCode
aws lambda update-function-code \
  --function-name my-fn \
  --zip-file fileb:///tmp/function.zip \
  --endpoint-url $ENDPOINT

# UpdateFunctionConfiguration (env, timeout, memory, layers, handler, runtime)
aws lambda update-function-configuration \
  --function-name my-fn \
  --timeout 30 \
  --environment "Variables={LOG_LEVEL=debug}" \
  --endpoint-url $ENDPOINT
```

Supported runtimes for invoke: `nodejs*` (uses `node`), `python*` (uses `python3`), `provided` / `provided.al2` / `provided.al2023` (runs `bootstrap` binary from zip). `Environment.Variables` from CreateFunction or UpdateFunctionConfiguration are injected into the subprocess. `Timeout` (seconds) kills slow handlers.

### Go (provided.al2023)

Package a compiled **`bootstrap`** binary at the zip root (same contract as AWS custom runtime: event JSON on stdin, response JSON on stdout):

```bash
GOOS=linux GOARCH=amd64 go build -o bootstrap main.go
zip function.zip bootstrap

aws lambda create-function \
  --function-name go-fn \
  --runtime provided.al2023 \
  --handler bootstrap \
  --role arn:aws:iam::000000000000:role/r \
  --zip-file fileb://function.zip \
  --endpoint-url $ENDPOINT
```

For local Simulith on Windows/macOS, build without `GOOS=linux` so the binary matches your dev host.

**Runnable CLI example:** [`examples/aws-cli/lambda-go/`](examples/aws-cli/lambda-go/) — build `bootstrap`, create-function, invoke, update-configuration.

## Function URLs

HTTP invoke without API Gateway. Management API uses `/2021-10-31/functions/{name}/url`; the returned `FunctionUrl` is the same path on `localhost` for local dev.

```bash
# Create Function URL (AuthType NONE — default)
aws lambda create-function-url-config \
  --function-name my-fn \
  --auth-type NONE \
  --endpoint-url $ENDPOINT

# Get / delete config
aws lambda get-function-url-config --function-name my-fn --endpoint-url $ENDPOINT
aws lambda delete-function-url-config --function-name my-fn --endpoint-url $ENDPOINT

# HTTP invoke (no SigV4 when AuthType is NONE)
curl -s -X POST "http://localhost:4566/2021-10-31/functions/my-fn/url" \
  -H "Content-Type: application/json" \
  -d '{"hello":"world"}'
```

**Notes:** POST with `{"AuthType":"..."}` creates the URL; POST with an event payload invokes. Function URL events are passed as raw JSON (not API Gateway HTTP v2 envelope). `AuthType: AWS_IAM` requires SigV4 on invoke.

## Lambda Layers

Share dependencies across functions via layer zips. Layer API uses `/2018-10-31/layers/…`. On invoke, layer zips are extracted **before** the function zip (function code wins on path conflicts).

**Node.js layout:** zip must contain `nodejs/node_modules/<package>/…`. Simulith sets `NODE_PATH` so `require()` resolves from layer modules.

**Python layout:** zip must contain `python/lib/python3.12/site-packages/<module>.py` (or other `python3.*` under `python/lib/…/site-packages`). Simulith sets `PYTHONPATH` so `import` resolves from layer modules.

```bash
# Build a layer zip (nodejs)
mkdir -p /tmp/layer/nodejs/node_modules/my-lib
echo 'module.exports = { ok: true };' > /tmp/layer/nodejs/node_modules/my-lib/index.js
cd /tmp/layer && zip -r layer.zip nodejs

# PublishLayerVersion
aws lambda publish-layer-version \
  --layer-name my-deps \
  --zip-file fileb:///tmp/layer/layer.zip \
  --compatible-runtimes nodejs20.x \
  --endpoint-url $ENDPOINT

# CreateFunction with Layers (use LayerVersionArn from publish output)
aws lambda create-function \
  --function-name my-fn \
  --runtime nodejs20.x \
  --handler index.handler \
  --role arn:aws:iam::000000000000:role/r \
  --zip-file fileb:///tmp/function.zip \
  --layers arn:aws:lambda:us-east-1:000000000000:layer:my-deps:1 \
  --endpoint-url $ENDPOINT

# List / get / delete layer versions
aws lambda list-layers --endpoint-url $ENDPOINT
aws lambda list-layer-versions --layer-name my-deps --endpoint-url $ENDPOINT
aws lambda get-layer-version --layer-name my-deps --version-number 1 --endpoint-url $ENDPOINT
aws lambda delete-layer-version --layer-name my-deps --version-number 1 --endpoint-url $ENDPOINT
```

```bash
# Build a layer zip (python3.12)
mkdir -p /tmp/py-layer/python/lib/python3.12/site-packages
printf 'def ok():\n    return True\n' > /tmp/py-layer/python/lib/python3.12/site-packages/my_lib.py
cd /tmp/py-layer && zip -r layer.zip python

aws lambda publish-layer-version \
  --layer-name py-deps \
  --zip-file fileb:///tmp/py-layer/layer.zip \
  --compatible-runtimes python3.12 \
  --endpoint-url $ENDPOINT
```

**Limits:** `AddLayerVersionPermission` not implemented (open local access).

## SQS event source mapping

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

## Default seed (`demo-fn`)

After `simulith seed` or Console **Seed demo data**, function **`demo-fn`** (Node.js 20.x echo handler) and an SQS event source mapping to `demo-queue` are loaded. Fixture format: [seed.md](seed.md).

```bash
aws lambda get-function --function-name demo-fn \
  --endpoint-url http://127.0.0.1:4566 --region us-east-1

aws lambda list-event-source-mappings --function-name demo-fn \
  --endpoint-url http://127.0.0.1:4566 --region us-east-1
```

Sync invoke of `demo-fn` requires `node` on the runtime host PATH (Docker runtime image does not bundle Node by default).

## Persistence

Function metadata is stored in the SQLite database (`lambda_functions` table). The zip payload is stored on disk at:

```
{data-dir}/lambda/{function-name}/code.zip
```

Both metadata and zip survive runtime restarts. `simulith reset` removes all Lambda state.

Layer version zips are stored at:

```
{data-dir}/lambda/layers/{layer-name}/{version}/code.zip
```

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
| `Timeout` | no | `3` | Seconds; used by  (invoke) |
| `MemorySize` | no | `128` | MB |
| `Environment.Variables` | no | `{}` | Injected into subprocess on invoke |
| `Layers` | no | `[]` | Layer version ARNs; merged into invoke workspace |
| `Description` | no | `""` | Metadata only |

## Known gaps and limits

- **InvocationType: Event** (async HTTP invoke) — **supported** (202 + background run). ESM poller still uses sync invoke internally.
- **Function URLs** — **supported** via `/2021-10-31/functions/<name>/url` (create/get/delete + HTTP invoke on same path; `AuthType: NONE` default).
- **Lambda Layers** — **supported** via `/2018-10-31/layers/…` (publish/list/get/delete; `Layers` on CreateFunction; nodejs `NODE_PATH`, python `PYTHONPATH`).
- **Go / provided runtimes** — **supported** (`provided`, `provided.al2`, `provided.al2023`; `bootstrap` binary in zip). Java and other custom runtimes not supported.
- **Docker runtime image** — does not bundle `node` or `python3`; invoke works when binaries are on PATH (local dev) or image is extended. Provided/Go invoke needs no extra host runtime.
- **Code.S3Bucket / Code.S3Key** — not supported. Use `Code.ZipFile` (base64).
- **Runtime validation** — Simulith accepts any runtime string. AWS enforces a specific list.
- **Zip size limits** — no limit enforced in this version. AWS limits 50 MB compressed / 250 MB uncompressed.
- **ListFunctions pagination** — `Marker` / `MaxItems` query params are ignored; all functions are returned.
- **Tags, aliases, versions** — not implemented.
- **Concurrency** — not applicable for local development.

## Compatibility matrix row

See [`aws-parity-overview.md`](aws-parity-overview.md) for the full matrix. Run **`simulith verify lambda`** for curated parity scenarios.

## Verify

```bash
# Simulith-only smoke (no AWS credentials)
simulith verify lambda --skip-aws --endpoint http://127.0.0.1:4566

# Full parity vs real AWS
export SIMULITH_VERIFY_LAMBDA_ROLE_ARN=arn:aws:iam::<account>:role/<lambda-execution-role>
simulith verify lambda --region us-east-1 --endpoint http://127.0.0.1:4566
```

**Nine scenarios:** function CRUD lifecycle, invoke sync payload, async invoke (`InvocationType: Event`), function URL invoke, **layer-backed invoke**, update function code, SQS ESM lifecycle, list functions after create, get function code location.

**Invoke scenario** requires **`node`** on the **Simulith runtime host** PATH (not only on the verify client). In Docker CI the runtime image has no Node — those scenarios are **skipped** automatically via `/health` → `lambdaInvoke.node`. Typical local dev: install `node` on the host running `simulith start`.

**AWS parity** requires `SIMULITH_VERIFY_LAMBDA_ROLE_ARN` — an IAM role with trust for `lambda.amazonaws.com` and permissions to create/delete functions and event source mappings. ESM scenarios also need SQS create/delete on the same account.

Save JSON report: `simulith verify lambda --skip-aws --save-last` (writes `.simulith/verify-last.json`).

Details: [compatibility.md](compatibility.md) · [compatibility-matrix.md](compatibility-matrix.md)

## Terraform green path

`aws_lambda_function` + `aws_sqs_queue` + `aws_lambda_event_source_mapping` apply and destroy on Simulith:

```bash
cd runtime/examples/terraform/lambda
cp terraform.tfvars.native.example terraform.tfvars
terraform init && terraform apply
terraform destroy
```

Provider endpoints: `lambda` and `sqs` → Simulith base URL. Simulith accepts any `lambda_role_arn` string (default dummy role in examples).

Walkthrough: [examples/terraform/lambda/README.md](examples/terraform/lambda/README.md) · [terraform-integration.md](terraform-integration.md#green-path-iac)
