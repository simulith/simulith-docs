# Compatibility matrix — Simulith MVP

Public reference for **local API support** vs **`simulith verify` coverage** on DynamoDB, SQS, SSM, S3, Lambda, and API Gateway (REST API management).

**Public mirror (prospects, sales, Hub):** [simulith-docs/compatibility-matrix.md](https://github.com/simulith/simulith-docs/blob/main/compatibility-matrix.md)

**Consolidated summary (percentages, Terraform, Console):** [`aws-parity-overview.md`](aws-parity-overview.md).

**Important:** **available** means the operation is implemented in the local runtime (often with MVP limits — see the service guide). **Verify** means a curated scenario in [`simulith verify`](compatibility.md) compares Simulith to real AWS (or smoke-only with `--skip-aws`). Shipped locally ≠ verified against AWS.

Last updated: 2026-08-03..

## Summary

| Metric | Count |
| --- | --- |
| Services in matrix | 14 (DynamoDB, SQS, SSM, S3, Lambda, API Gateway, Secrets Manager, Cognito, SES, EventBridge, VPC, RDS, IAM, KMS) |
| Operations **available** locally | 106 |
| Default verify scenarios | DynamoDB 6, SQS 10, SSM 10, S3 6, Lambda 9 |
| DynamoDB extended verify scenarios | 13 (`--filter extended`) |

Run verification: [`compatibility.md`](compatibility.md).

**Trust bundle:** packaged matrix + verify smoke reports for enterprise POCs — [`trust-bundle.md`](trust-bundle.md) · sales guide: .

## Legend

### API status

| Status | Meaning |
| --- | --- |
| **available** | HTTP handler shipped; see service doc for MVP limits |
| **partial** | Implemented with documented gaps vs AWS |
| **gap** | Not implemented |

### Verify

| Value | Meaning |
| --- | --- |
| **yes** (`scenario`) | Default `simulith verify <service>` (no filter) |
| **extended** (`scenario`) | DynamoDB only: `simulith verify dynamodb --filter <name>` |
| **no** | Not in verify subset |

---

## DynamoDB

Guide: [dynamodb.md](dynamodb.md) · Verify: `simulith verify dynamodb` (6 default + 13 extended)

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateTable | available | yes (`create-describe-table`) | |
| DescribeTable | available | yes (`create-describe-table`) | |
| PutItem | available | yes (`put-get-item`); extended (`conditional-put`) | ConditionExpression covered by extended scenario |
| BatchWriteItem | available | extended (`batch-write-item`) | Up to 25 put/delete requests |
| BatchGetItem | available | extended (`batch-get-item`, `projection-expression`) | Up to 100 keys; projection optional |
| TransactWriteItems | available | extended (`transact-write-get-items`) | Put/Delete/Update/ConditionCheck |
| TransactGetItems | available | extended (`transact-write-get-items`, `projection-expression`) | Ordered reads; projection optional |
| GetItem | available | yes (`put-get-item`); extended (`projection-expression`) | ProjectionExpression MVP subset |
| Query (base table) | available | yes (`query`); extended (`projection-expression`, `query-scan-1mb-pagination`) | KeyCondition MVP subset; 1 MB page cap |
| Query (GSI / LSI) | available | extended (`query-gsi`) | Requires `IndexName` |
| Scan | available | yes (`scan`); extended (`projection-expression`, `query-scan-1mb-pagination`, `parallel-scan`) | Parallel `Segment`/`TotalSegments` |
| UpdateItem | available | yes (`update-item`); extended (`update-expression-add-delete`) | ADD/DELETE on numbers and sets |
| DeleteItem | available | yes (`delete-item`) | |
| DeleteTable | available | extended (`delete-table`) | Also used by verify cleanup |
| ListTables | available | extended (`list-tables`) | |
| UpdateTable | available | extended (`update-table`) | Stream metadata — see dynamodb.md |
| TagResource / UntagResource / ListTagsOfResource | available | extended (`table-tags`) | Table tags in metadata |

**Not in matrix (gap):** streams API, export/import, etc.

---

## SQS

Guide: [sqs.md](sqs.md) · Verify: `simulith verify sqs` (10 scenarios) · Standard queues only

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateQueue | available | yes (`create-get-queue-url`) | Standard queues; idempotent create |
| GetQueueUrl | available | yes (`create-get-queue-url`) | |
| SendMessage | available | yes (`send-receive-delete`) | |
| ReceiveMessage | available | yes (`send-receive-delete`) | Short poll in verify |
| DeleteMessage | available | yes (`send-receive-delete`) | |
| GetQueueAttributes | available | yes (`get-queue-attributes`) | Subset of attributes in scenario |
| ListQueues | available | yes (`list-queues`) | |
| DeleteQueue | available | yes (`delete-queue`) | Also used by verify cleanup |
| SetQueueAttributes | available | yes (`set-queue-attributes`) | |
| SendMessageBatch | available | yes (`send-message-batch`) | |
| DeleteMessageBatch | available | yes (`delete-message-batch`) | |
| PurgeQueue | available | yes (`purge-queue`) | 60s throttle between purges |
| ChangeMessageVisibility | available | yes (`change-message-visibility`) | Invalid handle → error |
| ChangeMessageVisibilityBatch | available | yes (`change-message-visibility`) | Same scenario as single |

**Not in matrix (gap):** FIFO queues, etc.

---

## SSM Parameter Store

Guide: [ssm.md](ssm.md) · Verify: `simulith verify ssm` (10 scenarios)

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| PutParameter | available | yes (`put-get-parameter`, `put-overwrite`, `secure-string`, `parameter-tier`) | Standard tier + 4 KB limit |
| GetParameter | available | yes (`put-get-parameter`, `secure-string`, `parameter-tier`) | `WithDecryption` for SecureString |
| DeleteParameter | available | yes (`delete-parameter`) | |
| DeleteParameters | available | yes (`delete-parameters`) | Batch delete up to 10 names |
| GetParameters | available | yes (`get-parameters-batch`) | Up to 10 names |
| GetParametersByPath | available | yes (`get-parameters-by-path`) | |
| DescribeParameters | available | yes (`describe-parameters`, `parameter-tier`) | Terraform refresh; MVP filters only |
| AddTagsToResource | available | yes (`parameter-tags`) | Parameter resources only |
| RemoveTagsFromResource | available | yes (`parameter-tags`) | Parameter resources only |
| ListTagsForResource | available | yes (`parameter-tags`) | Parameter resources only |

**Not in matrix (gap):** full ParameterFilters, labels, Advanced tier, parameter policies, real AWS KMS, etc.

---

## S3

Guide: [s3.md](s3.md) · Verify: `simulith verify s3` (6 scenarios)

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateBucket | available | yes (`create-list-delete-bucket`, `put-get-object`, `head-object`, `delete-object`, `list-objects-v2-prefix`, `object-round-trip`) | Idempotent; names 3–63 chars |
| ListBuckets | available | yes (`create-list-delete-bucket`) | |
| DeleteBucket | available | yes (`create-list-delete-bucket`) | Empty bucket only |
| PutObject | available | yes (`put-get-object`, `object-round-trip`, `list-objects-v2-prefix`) | Single-part; Content-Type from header |
| GetObject | available | yes (`put-get-object`, `object-round-trip`) | Body + Content-Type, Content-Length, ETag |
| HeadObject | available | yes (`head-object`) | Existence check; Content-Length |
| DeleteObject | available | yes (`delete-object`) | Idempotent (204) |
| CopyObject | available | — | Same/cross-bucket via `x-amz-copy-source` |
| DeleteObjects | available | — | Batch up to 1000 keys (`POST ?delete`) |
| CreateMultipartUpload | available | — | POST `?uploads` |
| UploadPart | available | — | `partNumber` 1–10000 |
| CompleteMultipartUpload | available | — | Assembles parts; multipart ETag |
| AbortMultipartUpload | available | — | Cleans in-progress upload |
| GetBucketNotificationConfiguration | available | — | GET `?notification` |
| PutBucketNotificationConfiguration | available | — | LambdaFunctionConfiguration only |
| ListObjectsV2 | available | yes (`list-objects-v2-prefix`) | prefix, max-keys, continuation-token |

**Not in matrix (gap):** SNS/SQS notification targets, versioning, CORS, SSE-KMS, S3 Select, ListParts.

---

## Lambda

Guide: [lambda.md](lambda.md) · Verify: `simulith verify lambda` (9 scenarios)

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateFunction | available | yes (`function-crud-lifecycle`) | Code.ZipFile (base64); runtime string not validated |
| ListFunctions | available | yes (`list-functions-after-create`) | Returns all functions; no pagination |
| GetFunction | available | yes (`get-function-code-location`) | Returns Configuration + Code.Location |
| DeleteFunction | available | yes (`function-crud-lifecycle`) | 204; removes metadata + zip from disk |
| InvokeFunction | available | yes (`invoke-sync-payload`) | Sync subprocess; skips if `node` not on PATH; `java*` uses host `java`; `provided*` runs zip `bootstrap` |
| UpdateFunctionCode | available | yes (`update-function-code`) | Replaces zip on disk; updates CodeSize / CodeSha256 |
| UpdateFunctionConfiguration | available | — | Partial JSON patch: Environment, Timeout, MemorySize, Handler, Runtime, Role, Description, Layers, **VpcConfig** |
| CreateEventSourceMapping | available | yes (`esm-sqs-lifecycle`) | SQS ARNs only; BatchSize capped at 10 |
| ListEventSourceMappings | available | yes (`esm-sqs-lifecycle`) | Filter by FunctionName |
| GetEventSourceMapping | available | yes (`esm-sqs-lifecycle`) | UUID path |
| DeleteEventSourceMapping | available | yes (`esm-sqs-lifecycle`) | 202 Accepted |
| CreateFunctionUrlConfig | available | yes (`function-url-invoke`) | `/2021-10-31/functions/{name}/url` |
| GetFunctionUrlConfig | available | yes (`function-url-invoke`) | |
| DeleteFunctionUrlConfig | available | yes (`function-url-invoke`) | |
| Function URL HTTP invoke | available | yes (`function-url-invoke`) | Same path; raw JSON event |
| InvokeFunction (Event) | available | yes (`invoke-async-event`) | HTTP 202 + background run |
| PublishLayerVersion | available | yes (`layer-invoke`) | `/2018-10-31/layers/{name}/versions` |
| ListLayers | available | — | All layer names |
| ListLayerVersions | available | — | Per layer name |
| GetLayerVersion | available | — | By version number |
| DeleteLayerVersion | available | — | Removes metadata + zip |
| CreateFunction (`Layers`) | available | yes (`layer-invoke`) | Layer ARNs on configuration |

**Not in matrix (gap):** aliases, versions.

---

## API Gateway

Guide: [apigateway.md](apigateway.md) · Verify: `simulith verify apigateway`

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateRestApi | available | yes (`rest-api-crud-lifecycle`) | `POST /restapis`; metadata in SQLite; auto root resource |
| GetRestApis | available | yes (`rest-api-crud-lifecycle`) | `{ "item": [ ... ] }` (AWS REST JSON) |
| GetRestApi | available | yes (`rest-api-crud-lifecycle`) | 404 `NotFoundException` when missing; includes `rootResourceId` |
| DeleteRestApi | available | yes (`rest-api-crud-lifecycle`) | 202 Accepted; cascades resources/methods/integrations |
| CreateResource | available | yes (`proxy-integration-lifecycle`) | `POST /restapis/{id}/resources` or `…/resources/{parentId}` |
| PutMethod | available | yes (`proxy-integration-lifecycle`) | `PUT .../resources/{id}/methods/{http_method}` |
| PutIntegration | available | yes (`proxy-integration-lifecycle`) | `AWS_PROXY` → Lambda invoke URI |
| CreateDeployment | available | yes (`deployment-stage-lifecycle`) | `POST /restapis/{id}/deployments` |
| CreateStage | available | yes (`deployment-stage-lifecycle`) | `POST /restapis/{id}/stages` |
| Stage HTTP invoke | available | yes (`stage-http-invoke`) | `…/{stage}/_user_request_/…` → Lambda proxy (no SigV4) |
| GetResources / GetResource / GetMethod / GetIntegration | available | — | Terraform refresh; GetResources wire key `item` |
| GetDeployment / GetStage | available | — | Terraform read after create |
| DeleteStage / DeleteDeployment / DeleteResource / DeleteMethod / DeleteIntegration | available | — | Terraform destroy |
| Lambda AddPermission / RemovePermission / GetPolicy | available | — | `POST/DELETE/GET …/functions/{name}/policy` |

**Terraform:** [`examples/terraform/apigateway/`](examples/terraform/apigateway/) — green apply + HTTP invoke + destroy.

**Not in matrix (gap):** Console panel.

---

## Secrets Manager

Guide: [secretsmanager.md](secretsmanager.md) · Verify: `simulith verify secretsmanager`

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateSecret | available | yes (`secret-crud-lifecycle`) | Plain `SecretString`; optional `KmsKeyId` |
| GetSecretValue | available | yes (`secret-crud-lifecycle`, `get-secret-value`) | By name or ARN |
| ListSecrets | available | yes (`secret-crud-lifecycle`) | Full list (no pagination) |
| DeleteSecret | available | yes (`secret-crud-lifecycle`) | Immediate delete with `ForceDeleteWithoutRecovery` |

---

## KMS

Guide: [kms.md](kms.md) · Verify: `simulith verify kms`

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateKey | available | yes (`cmk-alias-lifecycle`, `encrypt-decrypt-roundtrip`) |  — symmetric CMK |
| DescribeKey | available | yes (`cmk-alias-lifecycle`) | Key ID, ARN, or alias |
| CreateAlias | available | yes (`cmk-alias-lifecycle`) | `alias/...` |
| ListAliases | available | yes (`cmk-alias-lifecycle`) | Optional `KeyId` filter |
| Encrypt | available | yes (`encrypt-decrypt-roundtrip`) | Mock envelope ciphertext |
| Decrypt | available | yes (`encrypt-decrypt-roundtrip`) | Round-trip with Encrypt |

---

## Cognito (Identity Provider)

Guide: [cognito.md](cognito.md) · Verify: `simulith verify cognito`

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateUserPool | available | yes (`user-pool-client-lifecycle`) |  |
| DescribeUserPool | available | yes (`user-pool-client-lifecycle`) | |
| ListUserPools | available | no | |
| DeleteUserPool | available | yes (`user-pool-client-lifecycle`) | Cascades clients/groups/domain |
| UpdateUserPool | available | no | Config merge |
| CreateUserPoolClient | available | yes (`user-pool-client-lifecycle`) | |
| DescribeUserPoolClient | available | no | |
| ListUserPoolClients | available | yes (`user-pool-client-lifecycle`) | |
| DeleteUserPoolClient | available | yes (`user-pool-client-lifecycle`) | |
| CreateGroup / GetGroup / ListGroups / DeleteGroup | available | no | |
| CreateUserPoolDomain / Describe / Delete | available | no | Metadata only |
| JWKS GET `/{poolId}/.well-known/jwks.json` | available | yes (`admin-auth-jwks`) | RSA per pool |
| AdminCreateUser / AdminGetUser | available | yes (`admin-auth-jwks`) |  |
| AdminSetUserPassword / AdminConfirmSignUp | available | yes (`admin-auth-jwks`) | AdminSetUserPassword |
| AdminEnableUser / AdminDisableUser | available | no | |
| AdminInitiateAuth | available | yes (`admin-auth-jwks`) | ADMIN_USER_PASSWORD_AUTH → RS256 JWT |

---

## SES (Simple Email Service)

Guide: [ses.md](ses.md) · Verify: `simulith verify ses`

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| VerifyEmailIdentity / DeleteIdentity / ListIdentities | available | yes (`identity-template-lifecycle`) | Auto-verified locally |
| GetIdentityVerificationAttributes | available | yes (`identity-template-lifecycle`) | |
| CreateTemplate / Get / Update / Delete / ListTemplates | available | yes (`identity-template-lifecycle`) | Update/List not in default scenarios |
| SendEmail / SendTemplatedEmail / SendRawEmail | available | yes (`send-templated-email`) | Outbox; AWS send skipped (sandbox) |

---

## EventBridge (CloudWatch Events)

Guide: [eventbridge.md](eventbridge.md) · Verify: `simulith verify eventbridge`

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| PutRule / DeleteRule / DescribeRule / ListRules | available | yes (`rule-target-lifecycle`) | Default bus; schedule only |
| EnableRule / DisableRule | available | yes (`rule-target-lifecycle`) | |
| PutTargets / RemoveTargets / ListTargetsByRule | available | yes (`rule-target-lifecycle`) | Lambda ARN targets |
| Schedule → Lambda Invoke | available | yes (`schedule-lambda-invoke`) | `rate(...)`; `cron(...)` ≈ 1m; needs `node` |
| PutEvents (default bus) | available | no | ; verify deferred |

---

## VPC (EC2 networking)

Guide: [vpc.md](vpc.md) · Verify: `simulith verify vpc`

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateVpc / DescribeVpcs / DeleteVpc | available | yes |  |
| CreateSubnet / DescribeSubnets / DeleteSubnet | available | yes | |
| CreateSecurityGroup + ingress/egress | available | yes | |
| IGW / route tables / gateway endpoints | available | no | Metadata routing |
| Lambda VpcConfig | available | yes | ; invoke scenario in verify vpc |

---

## RDS (Postgres sidecar)

Guide: [rds.md](rds.md) · Verify: `simulith verify rds`

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateDBSubnetGroup / Describe / Delete | available | yes |  |
| CreateDBParameterGroup / Describe / Delete | available | yes | Minimal stub |
| CreateDBInstance / Describe / Delete | available | yes | Postgres 15 Docker sidecar |
| CreateDBProxy / Describe / Delete | available | yes |  |
| RegisterDBProxyTargets / DeregisterDBProxyTargets | available | yes | TCP relay to instance |
| ModifyDBProxyTargetGroup | available | no | Stub (pool config ignored) |

---

## IAM

Guide: [iam.md](iam.md) · Verify: `simulith verify iam`

| Operation | API status | Verify | Notes |
| --- | --- | --- | --- |
| CreateRole / GetRole / DeleteRole | available | yes |  /  |
| CreatePolicy / GetPolicy / DeletePolicy | available | yes | Managed policy subset |
| AttachRolePolicy / DetachRolePolicy / ListAttachedRolePolicies | available | yes | RDS Proxy role attach |

---

## Verify scenario index

Quick reference — full runbook in [compatibility.md](compatibility.md).

| Service | Default scenarios | Extended (DynamoDB only) |
| --- | --- | --- |
| DynamoDB | `create-describe-table`, `put-get-item`, `query`, `scan`, `update-item`, `delete-item` | `list-tables`, `delete-table`, `query-gsi`, `conditional-put`, `update-table`, `table-tags`, `batch-write-item`, `batch-get-item` |
| SQS | `create-get-queue-url`, `send-receive-delete`, `get-queue-attributes`, `list-queues`, `delete-queue`, `set-queue-attributes`, `send-message-batch`, `delete-message-batch`, `purge-queue`, `change-message-visibility` | — |
| SSM | `put-get-parameter`, `put-overwrite`, `get-parameters-batch`, `get-parameters-by-path`, `delete-parameter`, `delete-parameters`, `describe-parameters`, `secure-string`, `parameter-tags`, `parameter-tier` | — |
| S3 | `create-list-delete-bucket`, `put-get-object`, `head-object`, `delete-object`, `list-objects-v2-prefix`, `object-round-trip` | — |
| Lambda | `function-crud-lifecycle`, `invoke-sync-payload`, `invoke-async-event`, `function-url-invoke`, `layer-invoke`, `update-function-code`, `esm-sqs-lifecycle`, `list-functions-after-create`, `get-function-code-location` | — |
| API Gateway | `rest-api-crud-lifecycle`, `proxy-integration-lifecycle`, `deployment-stage-lifecycle`, `stage-http-invoke` | — |
| Secrets Manager | `secret-crud-lifecycle`, `get-secret-value` | — |
| Cognito | `user-pool-client-lifecycle`, `admin-auth-jwks` | — |
| SES | `identity-template-lifecycle`, `send-templated-email` | — |
| EventBridge | `rule-target-lifecycle`, `schedule-lambda-invoke` | — |
| RDS | `db-instance-lifecycle`, `db-proxy-tcp-connect` | — |
| VPC | `vpc-subnet-sg-lifecycle`, `lambda-vpc-proxy-reachability` | — |
| IAM | `rds-proxy-role-lifecycle`, `managed-policy-get` | — |

```bash
simulith verify dynamodb --skip-aws
simulith verify dynamodb --skip-aws --filter extended
simulith verify sqs --skip-aws
simulith verify ssm --skip-aws
simulith verify s3 --skip-aws
simulith verify lambda --skip-aws
simulith verify apigateway --skip-aws
simulith verify secretsmanager --skip-aws
simulith verify cognito --skip-aws
simulith verify ses --skip-aws
simulith verify eventbridge --skip-aws
simulith verify rds --skip-aws
simulith verify vpc --skip-aws
simulith verify iam --skip-aws
simulith verify kms --skip-aws
```

---

## Related

- [compatibility.md](compatibility.md) — running verify and reports
- [quickstart.md](quickstart.md) — onboarding
- [README.md](README.md) — doc index
- Product backlog:
