# CloudFormation — Simulith

Local **CloudFormation control plane** via the AWS Query API — stack lifecycle plus Serverless v3 resource provisioning.

## Overview

- **SigV4 service name:** `cloudformation`
- **Protocol:** AWS Query (`Action=…`, `application/x-www-form-urlencoded`, XML responses)
- **API version:** `2010-05-15`
- **Persistence:** SQLite (`cfn_stacks`, `cfn_stack_events`, `cfn_stack_resources`)

** / ** — control plane (stack metadata). ** / ** — template parse + Serverless resource types. ** / ** — [`hello-serverless` example](examples/serverless/hello-serverless/) green path + deploy hardening. ** / ** — [`serverless-simulith` plugin](examples/serverless/serverless-simulith/) routes Serverless deploy SDK calls to `:4566`. ** / ** — `AWS::S3::Bucket` for Serverless deployment buckets. ** / ** — `AWS::S3::BucketPolicy` for `ServerlessDeploymentBucketPolicy`. ** / ** — `AWS::Lambda::LayerVersion` reads `Content` (not `Code`) for Serverless layer deploys.

## Implemented operations

| Operation | Notes |
| --- | --- |
| CreateStack | `StackName` + `TemplateBody` or `TemplateURL` (S3 fetch). Sync `CREATE_COMPLETE` |
| UpdateStack | Replace-all: deletes provisioned resources, applies new template |
| DeleteStack | Deletes provisioned resources, then stack and events |
| DescribeStacks | Optional `StackName` (name, ARN, or ID); error if filtered stack missing |
| DescribeStackEvents | Events for one stack, newest first |
| DescribeStackResources | Logical/physical IDs and status for stack resources |
| ListStackResources | Same resource rows as Describe (Serverless CLI) |

## Supported resource types

| Type | Provisions via |
| --- | --- |
| `AWS::IAM::Role` | IAM store (inline policies subset) |
| `AWS::Lambda::Function` | Lambda store (`Code.ZipFile` or `Code.S3Bucket`+`S3Key`) |
| `AWS::Lambda::Permission` | Lambda permissions |
| `AWS::Lambda::LayerVersion` | Lambda layers (`Content.ZipFile` or `Content.S3Bucket`+`S3Key` — not `Code`) |
| `AWS::ApiGateway::RestApi` | API Gateway |
| `AWS::ApiGateway::Resource` | API Gateway |
| `AWS::ApiGateway::Method` | API Gateway (+ `AWS_PROXY` integration) |
| `AWS::ApiGateway::Deployment` | API Gateway |
| `AWS::ApiGateway::Stage` | API Gateway |
| `AWS::Events::Rule` | EventBridge (schedule/event pattern + targets subset) |
| `AWS::S3::Bucket` | S3 store (`BucketName`, `PublicAccessBlockConfiguration`, `Tags` subset) |
| `AWS::S3::BucketPolicy` | S3 store (`Bucket` ref, `PolicyDocument` JSON — Serverless deployment bucket policy) |

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

Use the [`serverless-simulith`](examples/serverless/serverless-simulith/) plugin so `serverless deploy` reaches Simulith. Set `provider.deploymentMethod: direct`. Deployment buckets use `AWS::S3::Bucket`. See [`hello-serverless`](examples/serverless/hello-serverless/README.md).

## Limits

- No change sets, nested stacks, drift detection, or StackSets
- Create/update/delete are **synchronous** (`*_COMPLETE` immediately)
- Update uses **replace-all** (no resource-level diff yet)
- No `simulith verify cloudformation` yet

## Related

- Serverless examples: [`examples/serverless/`](examples/serverless/)
- Serverless / CloudFormation roadmap:  (maintainers)
