# API Gateway — Simulith

Local Amazon API Gateway (REST API management) emulation for development and testing.

## Overview

Simulith emulates the API Gateway **management** REST API on the same port as other services (default `:4566`). Requests use SigV4 service name `apigateway` and path prefix `/restapis`.

Compatible with:

- AWS CLI (`aws apigateway`)
- AWS SDKs (management APIs)
- Terraform (`aws_api_gateway_rest_api`, `aws_api_gateway_resource`, `aws_api_gateway_method`, `aws_api_gateway_integration`) — management subset through

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

aws apigateway get-rest-apis --endpoint-url "$ENDPOINT"

aws apigateway get-rest-api --endpoint-url "$ENDPOINT" --rest-api-id <id>

# Lambda proxy resource (use rootResourceId from create-rest-api)
aws apigateway create-resource \
  --endpoint-url "$ENDPOINT" \
  --rest-api-id <id> \
  --parent-id <rootResourceId> \
  --path-part "{proxy+}"

aws apigateway put-method \
  --endpoint-url "$ENDPOINT" \
  --rest-api-id <id> \
  --resource-id <resourceId> \
  --http-method ANY \
  --authorization-type NONE

aws apigateway put-integration \
  --endpoint-url "$ENDPOINT" \
  --rest-api-id <id> \
  --resource-id <resourceId> \
  --http-method ANY \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:demo/invocations"

aws apigateway delete-rest-api --endpoint-url "$ENDPOINT" --rest-api-id <id>
```

## Persistence

REST API metadata, resources, methods, and integrations are stored in SQLite (`apigateway_*` tables). `simulith reset` clears API Gateway state with other services. Deleting a Rest API cascades to child resources.

## Out of scope (follow-up stories)

- Deployments, stages, HTTP invoke
- `simulith verify apigateway`
- Console panel

See .
