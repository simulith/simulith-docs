# Go SDK example — Simulith

Runnable smoke test using **AWS SDK for Go v2** against a local Simulith endpoint.

## Prerequisites

- Simulith running on port **4566** — see [quickstart](../../quickstart.md)
- Go 1.22+

## Run

```bash
cd runtime/examples/go
go run .                    # dynamodb + sqs + ssm smoke
go run . -dynamodb          # DynamoDB Music workflow only
go run . -sqs               # SQS message loop only
go run . -ssm               # SSM parameter path workflow only
go run . -seed              # Demo table + demo-queue + SSM (after simulith seed)
```

Optional environment:

```bash
export SIMULITH_ENDPOINT=http://127.0.0.1:4566
export AWS_DEFAULT_REGION=us-east-1
```

Full guide: [sdk-examples.md](../../sdk-examples.md).
