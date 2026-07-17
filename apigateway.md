# API Gateway — Simulith

Local Amazon API Gateway (REST API) emulation for development and testing.

## Overview

Simulith emulates the API Gateway **management** REST API on the same port as other services (default `:4566`). Management requests use SigV4 service name `apigateway` and path prefix `/restapis`.

**Stage HTTP invoke**: unauthenticated requests to `/restapis/{restapi_id}/{stage}/_user_request_/…` proxy to configured Lambda integrations.

Compatible with:

- AWS CLI (`aws apigateway`)
- AWS SDKs (management APIs)
- Terraform (`aws_api_gateway_rest_api`, resource/method/integration, deployment, stage) — through

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

# HTTP invoke (no SigV4 — local stage URL)
curl "http://localhost:4566/restapis/<id>/dev/_user_request_/hello"
```

## Persistence

REST API metadata, resources, methods, integrations, deployments, and stages are stored in SQLite (`apigateway_*` tables). `simulith reset` clears API Gateway state with other services. Deleting a Rest API cascades to child rows.

## Out of scope (follow-up stories)

- `simulith verify apigateway`
- Terraform green path example
- Console panel

See .
