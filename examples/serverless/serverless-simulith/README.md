# serverless-simulith

Serverless Framework v3 plugin that routes **AWS SDK v2** calls (used internally by Serverless deploy) to a **Simulith** runtime on `:4566`.

Use this when `AWS_ENDPOINT_URL` or `[profile simulith]` alone does not reach Simulith during `serverless deploy`. This is **not** LocalStack — no extra container, no autostart.

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
  deploymentMethod: direct   # required for Simulith CFN subset (no ChangeSets yet)
  runtime: nodejs20.x
  region: us-east-1
```

## Credentials

Works with:

- Dummy env vars (`AWS_ACCESS_KEY_ID=test`, `AWS_SECRET_ACCESS_KEY=test`), or
- `--aws-profile simulith` (recommended with `[profile simulith]` in `~/.aws/config`)

The plugin **only** overrides endpoints; it does not replace profile credentials when already configured.

## Simulith prerequisites

- Runtime **≥ v0.157.0** (CFN resource types) on `:4566`
- S3 deployment bucket created before first deploy (see [`hello-serverless`](../hello-serverless/README.md))

## Reference example

[`../hello-serverless/`](../hello-serverless/) — T2 deploy + remove bar.
