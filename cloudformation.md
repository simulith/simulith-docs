# CloudFormation — Simulith

Local **CloudFormation control plane** via the AWS Query API — stack lifecycle plus Serverless v3 resource provisioning.

## Overview

- **SigV4 service name:** `cloudformation`
- **Protocol:** AWS Query (`Action=…`, `application/x-www-form-urlencoded`, XML responses)
- **API version:** `2010-05-15`
- **Persistence:** SQLite (`cfn_stacks`, `cfn_stack_events`, `cfn_stack_resources`)

**Console:** read-only stack browser at `/cloudformation` in [Simulith Console](console.md) — list stacks, resources, events, and template. Create/update/delete remain CLI, SDK, or Serverless.

** / ** — control plane (stack metadata). ** / ** — template parse + Serverless resource types. ** / ** — [`hello-serverless` example](examples/serverless/hello-serverless/) green path + deploy hardening. ** / ** — [`serverless-simulith` plugin](examples/serverless/serverless-simulith/) routes Serverless deploy SDK calls to `:4566`. ** / ** — `AWS::S3::Bucket` for Serverless deployment buckets. ** / ** — `AWS::S3::BucketPolicy` for `ServerlessDeploymentBucketPolicy`. ** / ** — `AWS::Lambda::LayerVersion` reads `Content` (not `Code`) for Serverless layer deploys. ** / ** — `UpdateStack` preserves S3 deployment buckets (and objects) when the logical bucket ID remains in the template. ** / ** — `GetTemplate` + `AWS::Logs::LogGroup` (no-op) for auth-api Serverless deploy depth. ** / ** — plugin transparent deploy defaults + SSM `${ssm:...}` resolution with `AWS_PROFILE=simulith`. ** / ** — `AWS::Lambda::Version` for Serverless `versionFunctions: true`. ** / ** — auth-api T2 parity (layer ARN lookup, Events Rule without Name, GatewayResponse, plugin skip timing). ** / ** — `AWS::ApiGateway::Authorizer` + method `AuthorizerId` for Serverless Lambda authorizers. ** / ** — `ValidateTemplate` for Serverless pre-deploy validation (no plugin skip).

## What you can do

| Operation | Notes |
| --- | --- |
| CreateStack | `StackName` + `TemplateBody` or `TemplateURL` (S3 fetch). Sync `CREATE_COMPLETE` |
| UpdateStack | Replace-all: deletes provisioned resources, applies new template. **S3 buckets** whose logical IDs remain `AWS::S3::Bucket` in the new template are **preserved** (Serverless deployment bucket + pre-uploaded artifacts) |
| DeleteStack | Deletes provisioned resources, then stack and events |
| DescribeStacks | Optional `StackName` (name, ARN, or ID); error if filtered stack missing |
| DescribeStackEvents | Events for one stack, newest first |
| DescribeStackResources | Logical/physical IDs and status for stack resources |
| DescribeStackResource | Single resource detail (Serverless deploy monitor) |
| GetTemplate | Returns stored `TemplateBody` for a stack (Serverless deploy diff). Same `Action` as SES — disambiguated by `Version=2010-05-15` |
| ValidateTemplate | Validates JSON template without creating a stack; returns `Parameters`, `Capabilities` subset (Serverless pre-deploy) |
| ListStackResources | Same resource rows as Describe (Serverless CLI) |

## What Simulith does not do

These AWS operations (and most resource types) are **not available** locally. Use real AWS if you need them.

| Operation / type | Notes |
| --- | --- |
| `CreateChangeSet` / `ExecuteChangeSet` / `DescribeChangeSet` | No change sets |
| Nested stacks | Not implemented |
| Drift detection | Not implemented |
| `AWS::EC2::*` / `AWS::ECS::*` / `AWS::RDS::*` in templates | Not provisioned |
| Most of the AWS resource catalog | Only the Serverless-oriented types listed below |
| CloudFormation-as-a-service / waiters identical to AWS | Sync local lifecycle |

## Supported resource types

| Type | Provisions via |
| --- | --- |
| `AWS::IAM::Role` | IAM store (inline policies subset) |
| `AWS::Lambda::Function` | Lambda store (`Code.ZipFile` or `Code.S3Bucket`+`S3Key`) |
| `AWS::Lambda::Permission` | Lambda permissions |
| `AWS::Lambda::LayerVersion` | Lambda layers (`Content.ZipFile` or `Content.S3Bucket`+`S3Key` — not `Code`) |
| `AWS::Lambda::Version` | Published function snapshot (`FunctionName` ref or ARN; physical ID = version ARN) |
| `AWS::ApiGateway::RestApi` | API Gateway |
| `AWS::ApiGateway::Resource` | API Gateway |
| `AWS::ApiGateway::Method` | API Gateway (+ `AWS_PROXY` integration; `AuthorizerId` when set) |
| `AWS::ApiGateway::Authorizer` | API Gateway Lambda authorizer (`REQUEST` / `TOKEN`; physical ID = authorizer ID) |
| `AWS::ApiGateway::Deployment` | API Gateway |
| `AWS::ApiGateway::Stage` | API Gateway |
| `AWS::ApiGateway::GatewayResponse` | Metadata-only (physical ID = `{RestApiId}:{ResponseType}`; CORS 4XX/5XX) |
| `AWS::Events::Rule` | EventBridge (schedule/event pattern + targets subset; `Name` optional — defaults to logical ID) |
| `AWS::S3::Bucket` | S3 store (`BucketName`, `PublicAccessBlockConfiguration`, `Tags` subset) |
| `AWS::S3::BucketPolicy` | S3 store (`Bucket` ref, `PolicyDocument` JSON — Serverless deployment bucket policy) |
| `AWS::Logs::LogGroup` | Metadata-only (physical ID = log group name; no CloudWatch Logs API) |

**Intrinsics (subset):** `Ref`, `Fn::GetAtt`, `Fn::Sub`, `Fn::Join`. Template `DependsOn` ordering is honored.

**S3 bucket GetAtt:** `Arn`, `DomainName`, `RegionalDomainName`. Stack delete empties the bucket before `DeleteBucket`.

## AWS CLI

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

aws cloudformation create-stack \
  --endpoint-url http://127.0.0.1:4566 \
  --stack-name hello-dev \
  --template-body file://template.json \
  --capabilities CAPABILITY_IAM

aws cloudformation describe-stack-resources \
  --endpoint-url http://127.0.0.1:4566 \
  --stack-name hello-dev
```

On Windows with sslip.io:

```powershell
aws cloudformation create-stack `
  --endpoint-url http://127.0.0.1.sslip.io:4566 `
  --stack-name hello-dev `
  --template-body file://template.json `
  --capabilities CAPABILITY_IAM
```

## Serverless Framework

Use the [`serverless-simulith`](https://www.npmjs.com/package/serverless-simulith) plugin so `serverless deploy` reaches Simulith. Plugin source: [`examples/serverless/serverless-simulith/`](examples/serverless/serverless-simulith/).

**Canonical guide:** [serverless-integration.md](serverless-integration.md)

**Setup (once per project):**

```bash
npm install --save-dev serverless-simulith@latest
```

Package: [npmjs.com/package/serverless-simulith](https://www.npmjs.com/package/serverless-simulith)

```yaml
plugins:
  - serverless-simulith

custom:
  simulith:
    stages:
      - dev
    endpoint: http://127.0.0.1.sslip.io:4566  # optional
```

**Deploy session** (same `serverless.yml` as AWS):

```bash
export AWS_PROFILE=simulith AWS_SDK_LOAD_CONFIG=1 AWS_DEFAULT_REGION=us-east-1
npx serverless deploy -s dev
```

When the plugin is active it applies `deploymentMethod: direct` and `disableLogs` automatically — no overlay yml required. It resolves `${ssm:...}` in config files against Simulith when using `[profile simulith]`.

Deployment buckets use `AWS::S3::Bucket`. See [`hello-serverless`](examples/serverless/hello-serverless/README.md) and the [plugin README](examples/serverless/serverless-simulith/README.md).

## Limits

- No change sets, nested stacks, drift detection, or StackSets
- Create/update/delete are **synchronous** (`*_COMPLETE` immediately)
- Update uses **replace-all** (no resource-level diff yet)
- No `simulith verify cloudformation` yet

## Related

- Serverless examples: [`examples/serverless/`](examples/serverless/)
- Serverless / CloudFormation roadmap:  (maintainers)
