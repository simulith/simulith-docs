# Serverless Framework integration — Simulith runtime

Deploy **Serverless Framework v3** services to Simulith locally using the **`serverless-simulith`** plugin and the CloudFormation stack API on `:4566`.

> **New to Simulith?** Complete the [Quickstart](quickstart.md) first (runtime on **4566** or Console proxy on **9080/runtime**).

This guide is the **canonical Serverless reference**. Terraform IaC lives in [terraform-integration.md](terraform-integration.md). CloudFormation API details: [cloudformation.md](cloudformation.md).

| Example | Path | Status |
| --- | --- | --- |
| Hello service | [`examples/serverless/hello-serverless/`](examples/serverless/hello-serverless/) | Green (deploy + remove) |
| Plugin source | [`examples/serverless/serverless-simulith/`](examples/serverless/serverless-simulith/) | Published as **`serverless-simulith`** on npm |

---

## Prerequisites

- Simulith running ([quickstart](quickstart.md) — Docker `:4566`, all-in-one Console `:9080`, or native)
- [Node.js](https://nodejs.org/) ≥ 18
- [Serverless Framework v3](https://www.serverless.com/framework/docs/getting-started) (`npm install -g serverless` or `npx serverless@3`)
- Optional: [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to inspect stacks after deploy

---

## Install the plugin

Pin the plugin version to your Simulith runtime release (same semver):

```bash
npm install --save-dev serverless-simulith@latest
```

Package page: [npmjs.com/package/serverless-simulith](https://www.npmjs.com/package/serverless-simulith) · Product: [simulith.dev](https://simulith.dev)

Monorepo contributors can use `"serverless-simulith": "file:../serverless-simulith"` for plugin development.

Add to `serverless.yml` (or shared `serverless.common.yml`):

```yaml
plugins:
  - serverless-simulith

custom:
  simulith:
    stages:
      - dev
    endpoint: http://127.0.0.1.sslip.io:4566  # optional; default uses sslip.io
```

---

## Endpoint matrix

Serverless, the AWS CLI, Terraform, and the **Console** must target the **same** runtime.

| How you run Simulith | Serverless / CLI endpoint | Console |
| --- | --- | --- |
| **Docker all-in-one** | `http://127.0.0.1:9080/runtime` (Console proxy) | http://localhost:9080 |
| **Runtime on `:4566`** | `http://127.0.0.1.sslip.io:4566` (recommended hostname for S3 virtual-host URLs) | Dev overlay on `:9080` if used |
| **`[profile simulith]`** | From `~/.aws/config` — plugin activates with profile + stage | Same SQLite as CLI when endpoints match |

**Activation:** the plugin runs on Simulith only when the stage is listed in `custom.simulith.stages` **and** one of: `AWS_PROFILE=simulith`, `SIMULITH=1`, or `AWS_ENDPOINT_URL` pointing at Simulith. **`prod` on real AWS is unaffected** — the plugin is a no-op without a Simulith signal.

---

## Green path — hello-serverless

From [`examples/serverless/hello-serverless/`](examples/serverless/hello-serverless/):

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://127.0.0.1.sslip.io:4566

cd runtime/examples/serverless/hello-serverless
npm install
npx serverless deploy --stage dev
npx serverless remove --stage dev
```

Expected: CloudFormation stack `CREATE_COMPLETE`, Lambda + API Gateway resources, clean remove.

Browse stacks in Console → **CloudFormation** (read-only panel).

---

## Transparent deploy (existing Serverless projects)

For demoapp-shaped repos (multiple `serverless.yml` roots, layers, domain manager):

1. Install `serverless-simulith` once in the project root `package.json`
2. Add the plugin + `custom.simulith.stages` to each shared `serverless.common.yml`
3. Deploy with the **same entrypoint as AWS**, e.g. `./deploy-backend.sh --stage dev`, with:

```bash
export AWS_PROFILE=simulith AWS_SDK_LOAD_CONFIG=1 AWS_DEFAULT_REGION=us-east-1
```

The plugin applies `deploymentMethod: direct`, `disableLogs`, SSM `${ssm:...}` resolution, injects **`AWS_ENDPOINT_URL` into Lambda environment** (`provider.environment` / `custom.config`) so runtime SDK v3 clients (e.g. Secrets Manager) reach Simulith without per-service code forks, and skips plugins not yet on Simulith — see [plugin README](examples/serverless/serverless-simulith/README.md).

**Terraform first:** unmodified demoapp modules apply with `[profile simulith]` before Serverless backend deploy — see the maintainer checklist under .

---

## Promote to AWS

Keep the same `serverless.yml`. Deploy to AWS with normal credentials and **without** `AWS_PROFILE=simulith` / `AWS_ENDPOINT_URL`. The plugin does not redirect SDK calls when Simulith signals are absent.

---

## Limits

- CloudFormation **subset** — see [cloudformation.md](cloudformation.md) for supported resource types
- No nested stacks, change sets, or StackSets
- Console: **read-only** stack browser — create/update/delete via CLI or Serverless only
- `simulith verify cloudformation` — planned

---

## Related

- [using-simulith.md](using-simulith.md) — mental model and workflow comparison
- [terraform-integration.md](terraform-integration.md) — IaC green paths
- [console.md](console.md) — CloudFormation panel and service browsers
- [docker.md](docker.md) — published images include Node.js for Lambda
