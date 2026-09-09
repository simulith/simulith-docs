# serverless-simulith

Serverless Framework v3 plugin that routes **AWS SDK v2** calls (used internally by Serverless deploy) to a **[Simulith](https://simulith.dev)** runtime on `:4566`.

Use this when `AWS_ENDPOINT_URL` or `[profile simulith]` alone does not reach Simulith during `serverless deploy`. This is **not** LocalStack — no extra container, no autostart.

---

## What is Simulith?

**Simulith** is a local AWS-compatible runtime for development and testing. Same AWS CLI, SDKs, Terraform, and Serverless workflows — pointed at a local endpoint instead of the cloud.

| Surface | Link | What you get |
| --- | --- | --- |
| **Website** | [simulith.dev](https://simulith.dev) | Product overview, services, compatibility |
| **Documentation** | [simulith-docs](https://github.com/simulith/simulith-docs) | [Quickstart](https://github.com/simulith/simulith-docs/blob/main/quickstart.md) · [Using Simulith](https://github.com/simulith/simulith-docs/blob/main/using-simulith.md) · [Serverless guide](https://github.com/simulith/simulith-docs/blob/main/serverless-integration.md) |
| **Console** | [Console guide](https://github.com/simulith/simulith-docs/blob/main/console.md) | Web UI at `:9080` — browse Lambda, S3, DynamoDB, CloudFormation stacks, and more |
| **Docker** | [simulith/simulith](https://hub.docker.com/r/simulith/simulith) · [simulith/console](https://hub.docker.com/r/simulith/console) | Runtime + optional UI in one compose stack |

**Typical flow:** run Simulith (Docker) → apply Terraform or deploy Serverless locally → inspect resources in **Console** → promote the same code/IaC to AWS by switching credentials and endpoint.

Pin this plugin to the **same semver as your Simulith runtime** (e.g. runtime `0.174.0` → `serverless-simulith@0.174.0`).

---

## Install

```bash
npm install --save-dev serverless-simulith@latest
```

Monorepo / plugin development:

```json
"serverless-simulith": "file:../../simulith/runtime/examples/serverless/serverless-simulith"
```

Add to each `serverless.common.yml` (or layer `serverless.yml`):

```yaml
plugins:
  - serverless-simulith

custom:
  simulith:
    stages:
      - dev
    endpoint: http://127.0.0.1.sslip.io:4566
```

---

## Why this plugin?

Serverless deploy uses AWS SDK v2 internally. Environment variables and AWS profiles alone do not always redirect every call to Simulith. This plugin:

- Routes deploy-time SDK calls to Simulith (`:4566` or Console proxy `:9080/runtime`)
- Applies Simulith-friendly defaults (`deploymentMethod: direct`, `disableLogs`, SSM `${ssm:...}` resolution)
- Stays **inactive on real AWS** when no Simulith signal is present (same `serverless.yml` for local and cloud)

Full guide: [serverless-integration.md](https://github.com/simulith/simulith-docs/blob/main/serverless-integration.md) · CloudFormation API: [cloudformation.md](https://github.com/simulith/simulith-docs/blob/main/cloudformation.md)

---

## Transparent deploy (existing Serverless projects)

When `custom.simulith.stages` includes the active stage (typically `dev`), the plugin:

- Routes all AWS SDK calls to Simulith
- Sets `deploymentMethod: direct`
- Enables `disableLogs` on functions (CloudWatch LogGroup parity gap)
- Uses native CloudFormation `ValidateTemplate` on Simulith
- Skips `serverless-add-api-key` (not on Simulith yet) — filtered in plugin **constructor** before other plugins load
- Runs **`serverless-domain-manager`** on Simulith when custom domain APIs are available

**No overlay yml required.** Use the project's normal deploy entrypoint:

```bash
export AWS_PROFILE=simulith AWS_SDK_LOAD_CONFIG=1 AWS_DEFAULT_REGION=us-east-1
./deploy-backend.sh --stage dev
```

Stage `prod` on **real AWS** is unaffected — the plugin is inactive unless `AWS_PROFILE=simulith`, `SIMULITH=1`, or `AWS_ENDPOINT_URL` is set (see below).

---

## Deploying to real AWS (same `serverless.yml`)

`serverless-simulith` stays in `plugins` permanently. On a normal AWS deploy it is a **no-op**:

- No SDK redirect to `:4566`
- No `deploymentMethod: direct` / `disableLogs` overrides
- Other plugins (`serverless-domain-manager`, etc.) call **real** AWS

Activation requires **both** (1) stage listed in `custom.simulith.stages` (defaults: `dev`, `local`) **and** (2) an explicit Simulith signal:

| Signal | Example |
| --- | --- |
| `AWS_PROFILE=simulith` | `export AWS_PROFILE=simulith` before `sls deploy` |
| `SIMULITH=1` | CI/local script |
| `AWS_ENDPOINT_URL` | Already pointing at Simulith |

```bash
# AWS dev (default credentials / prod profile)
sls deploy --stage dev

# Simulith dev (same yml, same stage)
AWS_PROFILE=simulith sls deploy --stage dev
```

---

## Minimal `serverless.yml`

```yaml
plugins:
  - serverless-simulith

custom:
  simulith:
    stages:
      - dev
    endpoint: http://127.0.0.1.sslip.io:4566

provider:
  name: aws
  runtime: nodejs20.x
  region: us-east-1
```

`deploymentMethod: direct` is applied automatically when the plugin is active.

---

## Credentials

When the plugin is active for the stage, it **overrides credentials to `test`/`test`** (unless `custom.simulith.preserveProfileCredentials: true`) so Serverless deploy calls succeed against Simulith SigV4.

**Activation** (stage must be listed in `custom.simulith.stages`):

- `AWS_PROFILE=simulith` (recommended — same session as Terraform), or
- `AWS_ENDPOINT_URL=http://127.0.0.1.sslip.io:4566`, or
- `SIMULITH=1`

---

## Simulith prerequisites

- Runtime **≥ v0.163.0** recommended (CFN GetTemplate, LogGroup no-op, S3 bucket preservation)
- [Docker quickstart](https://github.com/simulith/simulith-docs/blob/main/docker.md) — runtime on `:4566`, optional Console on `:9080`
- **Windows + large layers:** use WSL/Git Bash if packaging hits `EMFILE` (OS file-handle limit)

---

## Reference example

[hello-serverless](https://github.com/simulith/simulith-docs/tree/main/examples/serverless/hello-serverless) — minimal deploy + remove green path (see [Serverless integration guide](https://github.com/simulith/simulith-docs/blob/main/serverless-integration.md#green-path---hello-serverless)).

---

## Links

- **npm:** https://www.npmjs.com/package/serverless-simulith (maintained by the [**simulith**](https://www.npmjs.com/org/simulith) org)
- **Source:** https://github.com/simulith/simulith-docs/tree/main/examples/serverless/serverless-simulith
- **Issues / feedback:** https://github.com/simulith/simulith-docs/issues
