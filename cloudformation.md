# CloudFormation — Simulith

Local **CloudFormation control plane** via the AWS Query API — stack lifecycle plus Serverless v3 resource provisioning.

## Overview

- **SigV4 service name:** `cloudformation`
- **Protocol:** AWS Query (`Action=…`, `application/x-www-form-urlencoded`, XML responses)
- **API version:** `2010-05-15`
- **Persistence:** SQLite (`cfn_stacks`, `cfn_stack_events`, `cfn_stack_resources`)

** / ** — control plane (stack metadata). ** / ** — template parse + Serverless resource types.

## Implemented operations

| Operation | Notes |
| --- | --- |
| CreateStack | Requires `StackName` + `TemplateBody`. Sync `CREATE_COMPLETE` after provisioning. `TemplateURL` not supported |
| UpdateStack | Replace-all: deletes provisioned resources, applies new template |
| DeleteStack | Deletes provisioned resources, then stack and events |
| DescribeStacks | Optional `StackName` filter |
| DescribeStackEvents | Events for one stack, newest first |
| DescribeStackResources | Logical/physical IDs and status for stack resources |

## Supported resource types

| Type | Provisions via |
| --- | --- |
| `AWS::IAM::Role` | IAM store (inline policies subset) |
| `AWS::Lambda::Function` | Lambda store (`Code.ZipFile` or `Code.S3Bucket`+`S3Key`) |
| `AWS::Lambda::Permission` | Lambda permissions |
| `AWS::Lambda::LayerVersion` | Lambda layers |
| `AWS::ApiGateway::RestApi` | API Gateway |
| `AWS::ApiGateway::Resource` | API Gateway |
| `AWS::ApiGateway::Method` | API Gateway (+ `AWS_PROXY` integration) |
| `AWS::ApiGateway::Deployment` | API Gateway |
| `AWS::ApiGateway::Stage` | API Gateway |
| `AWS::Events::Rule` | EventBridge (schedule/event pattern + targets subset) |

**Intrinsics (subset):** `Ref`, `Fn::GetAtt`, `Fn::Sub`, `Fn::Join`. Template `DependsOn` ordering is honored.

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

## Limits

- No change sets, nested stacks, drift detection, or StackSets
- No `TemplateURL` (S3 fetch of template body)
- Create/update/delete are **synchronous** (`*_COMPLETE` immediately)
- Update uses **replace-all** (no resource-level diff yet)
- No `simulith verify cloudformation` yet

## Related

- Serverless / CloudFormation roadmap is documented in the product repository (maintainers).
