# API Gateway — Simulith

Local Amazon API Gateway (REST API) emulation for development and testing.

## Overview

Simulith emulates the API Gateway **management** REST API on the same port as other services (default `:4566`). Management requests use SigV4 service name `apigateway` and path prefix `/restapis`.

**Stage HTTP invoke**: unauthenticated requests to `/restapis/{restapi_id}/{stage}/_user_request_/…` proxy to configured Lambda integrations.

**Lambda request authorizer**: methods with `authorizationType` `CUSTOM` and an `authorizerId` invoke the configured authorizer Lambda before the integration. Deny → `401` with `{"message":"Unauthorized"}`. Allow → authorizer `context` is passed to the proxy event under `requestContext.authorizer`.

Compatible with:

- AWS CLI (`aws apigateway`)
- AWS SDKs (management APIs)
- Terraform (`aws_api_gateway_rest_api`, resource/method/integration, deployment, stage, `aws_lambda_permission`) — green path example

## Implemented operations

| Operation | Method + Path | Status |
| --- | --- | --- |
| CreateRestApi | `POST /restapis` | ✓ |
| GetRestApis | `GET /restapis` | ✓ |
| GetRestApi | `GET /restapis/{restapi_id}` | ✓ |
| DeleteRestApi | `DELETE /restapis/{restapi_id}` | ✓ |
| CreateResource | `POST /restapis/{restapi_id}/resources` | ✓ |
| PutMethod | `PUT /restapis/{restapi_id}/resources/{resource_id}/methods/{http_method}` | ✓ |
| PutIntegration | `PUT .../methods/{http_method}/integration` | ✓ |
| CreateDeployment | `POST /restapis/{restapi_id}/deployments` | ✓ |
| CreateStage | `POST /restapis/{restapi_id}/stages` | ✓ |
| DeleteStage | `DELETE /restapis/{restapi_id}/stages/{stage_name}` | ✓ |
| GetResources | `GET /restapis/{restapi_id}/resources` | ✓ — wire key `item` |
| GetResource | `GET /restapis/{restapi_id}/resources/{resource_id}` | ✓ |
| GetMethod | `GET …/methods/{http_method}` | ✓ |
| GetIntegration | `GET …/methods/{http_method}/integration` | ✓ |
| GetDeployment | `GET /restapis/{restapi_id}/deployments/{id}` | ✓ |
| GetStage | `GET /restapis/{restapi_id}/stages/{stage_name}` | ✓ |
| DeleteDeployment | `DELETE …/deployments/{id}` | ✓ |
| DeleteResource | `DELETE …/resources/{resource_id}` | ✓ |
| DeleteMethod | `DELETE …/methods/{http_method}` | ✓ |
| DeleteIntegration | `DELETE …/integration` | ✓ |
| CreateAuthorizer | `POST /restapis/{restapi_id}/authorizers` | ✓ |
| GetAuthorizer | `GET /restapis/{restapi_id}/authorizers/{authorizer_id}` | ✓ |
| DeleteAuthorizer | `DELETE /restapis/{restapi_id}/authorizers/{authorizer_id}` | ✓ |
| Stage HTTP invoke | `GET/POST …/restapis/{id}/{stage}/_user_request_/…` | ✓ |

`CreateRestApi` creates a root resource automatically and returns `rootResourceId` (required for Terraform `aws_api_gateway_resource`).

## AWS CLI examples

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
ENDPOINT=http://localhost:4566

aws apigateway create-rest-api \
  --endpoint-url "$ENDPOINT" \
  --name my-api \
  --description "local demo"

# … resources, method ANY, AWS_PROXY integration

aws apigateway create-deployment \
  --endpoint-url "$ENDPOINT" \
  --rest-api-id <id>

aws apigateway create-stage \
  --endpoint-url "$ENDPOINT" \
  --rest-api-id <id> \
  --stage-name dev \
  --deployment-id <deploymentId>

# Lambda REQUEST authorizer
aws apigateway create-authorizer \
  --endpoint-url "$ENDPOINT" \
  --rest-api-id <id> \
  --name auth \
  --type REQUEST \
  --authorizer-uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:auth-fn/invocations" \
  --identity-source "method.request.header.Authorization"

aws apigateway put-method \
  --endpoint-url "$ENDPOINT" \
  --rest-api-id <id> \
  --resource-id <resourceId> \
  --http-method GET \
  --authorization-type CUSTOM \
  --authorizer-id <authorizerId>

# HTTP invoke (no SigV4 — local stage URL)
curl -H "Authorization: Bearer token" "http://localhost:4566/restapis/<id>/dev/_user_request_/hello"
```

## Persistence

REST API metadata, resources, methods, integrations, authorizers, deployments, and stages are stored in SQLite (`apigateway_*` tables). `simulith reset` clears API Gateway state with other services. Deleting a Rest API cascades to child rows.

## Verify

```bash
simulith verify apigateway --skip-aws          # Simulith-only smoke (4 scenarios)
simulith verify apigateway                     # AWS parity (requires SIMULITH_VERIFY_LAMBDA_ROLE_ARN)
simulith verify apigateway --filter rest-api   # subset by scenario name prefix
```

Scenarios: `rest-api-crud-lifecycle`, `proxy-integration-lifecycle`, `deployment-stage-lifecycle`, `stage-http-invoke`.

## Terraform

Green path module: [`examples/terraform/apigateway/`](examples/terraform/apigateway/).

```bash
cd runtime/examples/terraform/apigateway
cp terraform.tfvars.native.example terraform.tfvars
terraform init && terraform apply -parallelism=1
curl "$(terraform output -raw invoke_url)"
terraform destroy -parallelism=1
```

Provider routes **apigateway** and **lambda** endpoints to Simulith. Use **`-parallelism=1`** (SQLite). See [terraform-integration.md](terraform-integration.md).

## Out of scope (follow-up stories)

- Cognito user pool authorizer (native) — use Lambda REQUEST authorizer validating Cognito JWT (common production pattern).
- API keys / usage plans, custom domains.

Console panel: **shipped**  /  — [`console/README.md`](console.md), [`runtime/docs/console.md`](console.md).

Seed demo API: **shipped**  /  — [`runtime/docs/seed.md`](seed.md) (`demo-api` → `demo-fn`).
