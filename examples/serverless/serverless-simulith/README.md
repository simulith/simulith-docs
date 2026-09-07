# serverless-simulith

Serverless Framework v3 plugin that routes **AWS SDK v2** calls (used internally by Serverless deploy) to a **Simulith** runtime on `:4566`.

Use this when `AWS_ENDPOINT_URL` or `[profile simulith]` alone does not reach Simulith during `serverless deploy`. This is **not** LocalStack — no extra container, no autostart.

## Transparent deploy (demoapp-shaped projects)

When `custom.simulith.stages` includes the active stage (typically `dev`), the plugin:

- Routes all AWS SDK calls to Simulith
- Sets `deploymentMethod: direct`
- Enables `disableLogs` on functions (CloudWatch LogGroup parity gap)
- Skips `serverless-domain-manager` and `serverless-add-api-key` (not on Simulith yet) — applied in plugin **constructor** so `${file():plugins}` lists are filtered before other plugins load

**No overlay yml or maintainer scripts required.** Use the project's normal deploy entrypoint, e.g.:

```bash
# Terraform (profile simulith) — unmodified modules + backend.simulith.hcl
export AWS_PROFILE=simulith AWS_SDK_LOAD_CONFIG=1 AWS_DEFAULT_REGION=us-east-1

# Serverless — same order as AWS (plugin activates via AWS_PROFILE=simulith)
./deploy-backend.sh --stage dev
```

Install the plugin once in the project root `package.json`:

```json
"serverless-simulith": "file:../../simulith/runtime/examples/serverless/serverless-simulith"
```

Add to each `serverless.common.yml` (or layer `serverless.yml`):

```yaml
plugins:
  - serverless-simulith
  # ...existing plugins

custom:
  simulith:
    stages:
      - dev
    endpoint: http://127.0.0.1.sslip.io:4566
```

Stage `prod` is unaffected — the plugin skips when the stage is not listed.

## Install

From your Serverless project:

```bash
npm install --save-dev serverless@^3 file:../serverless-simulith
# or, from monorepo: file:../../runtime/examples/serverless/serverless-simulith
```

## Minimal `serverless.yml`

```yaml
plugins:
  - serverless-simulith

custom:
  simulith:
    stages:
      - dev
    # optional; defaults to AWS_ENDPOINT_URL or http://127.0.0.1.sslip.io:4566
    endpoint: http://127.0.0.1.sslip.io:4566

provider:
  name: aws
  runtime: nodejs20.x
  region: us-east-1
```

`deploymentMethod: direct` is applied automatically when the plugin is active.

## Credentials

When the plugin is active for the stage, it **overrides credentials to `test`/`test`** (unless `custom.simulith.preserveProfileCredentials: true`) so Serverless deploy calls like `Lambda.getFunction` succeed against Simulith SigV4. Endpoints always route to Simulith.

**Activation** (stage must be listed in `custom.simulith.stages`, typically `dev`):

- `AWS_PROFILE=simulith` (recommended — same session as Terraform), or
- `AWS_ENDPOINT_URL=http://127.0.0.1.sslip.io:4566`, or
- `SIMULITH=1`

Deploying to real AWS with the same `serverless.yml` is unchanged when none of the above is set.

## Simulith prerequisites

- Runtime **≥ v0.163.0** recommended (CFN GetTemplate, LogGroup no-op, S3 bucket preservation)
- Docker image on `:4566`, S3 deployment bucket from Terraform
- **Windows + layer-engine:** use WSL/Git Bash for `deploy-backend.sh --only-layer-engine` if packaging hits `EMFILE` (Windows file-handle limit, not Simulith-specific)

## Reference example

[`../hello-serverless/`](../hello-serverless/) — T2 deploy + remove bar.

## Maintainer validation

Internal demoapp T2 uses the **external checkout** with `./deploy-backend.sh` — not scripts under `simulith/runtime/tmp/`. See `validation-process.md`.
