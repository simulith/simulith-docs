# Protocol routing — Simulith runtime

How Simulith routes `POST /` and formats responses per AWS protocol variant.

## Multiplex (POST /)

`internal/protocol/multiplex.go` selects the handler from request shape:

| Signal | Protocol | Services (MVP) |
| --- | --- | --- |
| `Content-Type: application/x-amz-json-*` + `X-Amz-Target` | AWS JSON | DynamoDB, SSM |
| `Content-Type: application/x-www-form-urlencoded` + `Action=` | AWS Query (XML) | SQS |

Non-POST requests to `/` return HTTP 404.

## AWS JSON

How Simulith handles AWS JSON (`awsJson1_0` / `awsJson1_1`) requests and error responses.

### Supported protocols

| Protocol | Content-Type | Services (MVP) |
| --- | --- | --- |
| awsJson1_0 | `application/x-amz-json-1.0` | DynamoDB |
| awsJson1_1 | `application/x-amz-json-1.1` | SSM Parameter Store |

Routing uses `X-Amz-Target` against vendored Smithy models. See `smithy-contracts.md`.

### Request flow

1. `POST /` with AWS JSON headers and body
2. Content-Type parsed (charset parameters ignored)
3. Body buffered and validated as JSON
4. Operation resolved from `X-Amz-Target`
5. Optional SigV4 verification (config, default off)
6. Stub or service handler response

Non-POST requests to `/` return HTTP 404 (not an AWS JSON error envelope).

Unsupported `Content-Type` responses use awsJson1_0 / DynamoDB namespace as a best-effort default.

### Error responses (SML-006)

Protocol-level and service errors use `internal/protocol/awserrors`.

#### Headers

- `Content-Type` — same media type as the request protocol variant
- `x-amzn-errortype` — short Smithy error shape name (e.g. `ValidationException`)

#### Body

```json
{
  "__type": "<shape identifier>",
  "message": "human-readable message"
}
```

#### `__type` formatting

| Protocol | `__type` value |
| --- | --- |
| awsJson1_0 | Full shape ID — e.g. `com.amazonaws.dynamodb#ValidationException` |
| awsJson1_1 | Short shape name — e.g. `ValidationException` |

SDKs accept either form for both protocols; Simulith follows the Smithy recommendation per variant.

#### HTTP status

- Client faults (`@error client`): **400** by default
- SigV4 signature failures: **400** with `SignatureDoesNotMatch` (stable message; no internal verifier details)

Service-specific status codes from Smithy `@httpError` traits (e.g. 404) ship in Phase 3.

#### Phase 3 usage

Service handlers emit errors via:

```go
awserrors.Write(w, protocol, awserrors.ServiceNamespace(op.EndpointPrefix),
    awserrors.ServiceFault("ResourceNotFoundException", "Table not found", 400, nil))
```

## AWS Query (XML)

SQS uses **AWS Query**: form-urlencoded body with `Action=CreateQueue`, XML responses. Implemented in `internal/protocol/aws_query.go` and `queryresp/xml.go`.

- Success: `CreateQueueResponse` with `QueueUrl`
- Errors: `ErrorResponse` with `Code`, `Message`, `Type` (Sender/Receiver fault)

See [sqs.md](sqs.md) for CLI examples and MVP deviations.

## Related

- `smithy-contracts.md` — model vendoring
- `sqs.md` — SQS / AWS Query operations
- `cursor/analysis/features/_core/simulith-error-compatibility/` — SML-006 analysis
