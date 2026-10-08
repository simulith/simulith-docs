# External benchmarks

Simulith's own `verify` suite lives in this repository. The external benchmark harness clones three pinned public repositories and runs an integration test that already exists in each one, with the client pointed at port 4566.

A failure is a compatibility signal. The runner does not skip a red test and does not edit the checkout.

## Pins

| Id | Repository | Commit | Service | What runs |
| --- | --- | --- | --- | --- |
| `boto3-sqs` | [boto/boto3](https://github.com/boto/boto3) `1.35.99` | `74405eeea71466dd905fedad97d9553f63cf887f` | SQS | `tests.integration.test_sqs.TestSQSResource.test_sqs` |
| `pynamodb-connection` | [pynamodb/PynamoDB](https://github.com/pynamodb/PynamoDB) `5.5.1` | `7b60000164696fa2c668bdd74e3344fa2e9a6970` | DynamoDB | `test_connection_integration__describe_as_needed` (create, put, get, delete) |
| `s3transfer-upload` | [boto/s3transfer](https://github.com/boto/s3transfer) `0.10.4` | `0323658c863654911d385899d4b907ae003d80ff` | S3 | `tests.integration.test_upload.TestUpload.test_upload_below_threshold` |

The catalog is `runtime/benchmarks/external/catalog.json`. Each entry stores a full commit SHA, not a branch. These releases still install on Python 3.8 and 3.12, and their clients follow `AWS_ENDPOINT_URL` (PynamoDB uses `PYNAMODB_INTEGRATION_TEST_DDB_URL`).

`s3transfer` cleanup calls ListObjects (v1). That listing reuses the ListObjectsV2 key order, with `marker` / `NextMarker`. `delimiter` is not applied. The other PynamoDB test in the same file, `test_connection_integration`, builds a GSI and an LSI and then reads `ProvisionedThroughput` from DescribeTable. That test stays out of the pin until DescribeTable returns that block.

## Run locally

Start Simulith, then run the harness from the repository root. Clones and virtualenvs go under `runtime/artifacts/external-benchmarks/` and are not committed.

```bash
cd runtime
go run ./cmd/simulith start
```

```bash
node runtime/scripts/run-external-benchmarks.mjs
```

`node runtime/scripts/run-external-benchmarks.mjs --check` only validates the catalog. It does not clone or call the runtime.

The runner exports `AWS_ENDPOINT_URL`, `AWS_ACCESS_KEY_ID=test`, `AWS_SECRET_ACCESS_KEY=test`, and `AWS_DEFAULT_REGION=us-east-1`. Override the endpoint with `SIMULITH_ENDPOINT`.

## Continuous integration

`.github/workflows/external-benchmarks.yml` builds Simulith from the workflow commit, waits for `GET /health`, and runs the same script. It runs when the catalog, the script, or the workflow changes, on a weekly schedule, and on `workflow_dispatch`.

It is not a required status check. Parity smoke in `ci.yml` remains the check on every pull request. Path filters cannot gate a required check, and this job clones three repositories.

## Adding a pin

Keep the catalog at exactly three repositories, one each for DynamoDB, SQS, and S3, until a later story widens it. A new pin must be a public GitHub repository outside the `simulith` org, a 40-character SHA, and a test command that already exists upstream and does not start LocalStack, DynamoDB Local, or another emulator.

## Top-10 Real-World Benchmark Suite

For broader ecosystem validation covering real Serverless Framework templates, CLI backup tools, and full Conduit RealWorld backends, see [Top-10 benchmarks](top10-benchmarks.md) (`runtime/scripts/run-10-benchmarks.mjs`).
