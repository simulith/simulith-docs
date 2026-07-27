# AWS CLI — S3 → Lambda on Simulith

Five scripts demonstrating **S3 object-create notification → async Lambda invoke**, using bucket notification configuration and prefix filter.

**Source pattern:** [AWS S3 event notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html) + [Lambda with Amazon S3](https://docs.aws.amazon.com/lambda/latest/dg/with-s3.html) — trimmed to Simulith's documented subset (Lambda targets only; no `aws_lambda_permission` required locally).

## Prerequisites

- Simulith running ([quickstart](../../../quickstart.md)) with **** dispatch
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Bash + `zip` (Git Bash on Windows)
- **Node.js** on PATH (Simulith invokes node subprocess)

## Environment

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT=http://127.0.0.1:4566
# Docker all-in-one: export AWS_ENDPOINT=http://127.0.0.1:9080/runtime

export FUNCTION_NAME=s3-event-fn
export BUCKET_NAME=s3-lambda-demo-bucket
export OBJECT_KEY=in/demo.txt
export MARKER_DIR=/tmp/simulith-s3-lambda-demo
```

Run from this directory:

```bash
cd runtime/examples/aws-cli/s3-lambda
```

## Scripts

| Script | AWS operation | Simulith API |
| --- | --- | --- |
| [`01-create-function.sh`](01-create-function.sh) | `lambda create-function` | CreateFunction |
| [`02-create-bucket.sh`](02-create-bucket.sh) | `s3api create-bucket` | CreateBucket |
| [`03-put-bucket-notification.sh`](03-put-bucket-notification.sh) | `s3api put-bucket-notification-configuration` | PutBucketNotificationConfiguration |
| [`04-put-object.sh`](04-put-object.sh) | `s3api put-object` | PutObject → async Lambda |
| [`05-wait-marker.sh`](05-wait-marker.sh) | — | Poll local marker file from handler |

```bash
./01-create-function.sh
./02-create-bucket.sh
./03-put-bucket-notification.sh
./04-put-object.sh
./05-wait-marker.sh
```

Expected marker JSON includes `eventName` `ObjectCreated:Put` and object key `in/demo.txt`.

Cleanup:

```bash
aws s3 rm "s3://${BUCKET_NAME}" --recursive --endpoint-url "$AWS_ENDPOINT" || true
aws s3api delete-bucket --bucket "$BUCKET_NAME" --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" || true
aws lambda delete-function --function-name "$FUNCTION_NAME" --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION"
rm -rf "$MARKER_DIR"
```

## Limits

- **MARKER_DIR** verification is a **local demo pattern** — production Lambdas typically write to DynamoDB/SQS or another bucket
- Simulith does not model S3→Lambda resource policies (`lambda:InvokeFunction` from S3 service)
- Lambda targets only — no SNS/SQS notifications
- Prefix filter `in/` — keys outside prefix do not invoke
- See [s3.md](../../../s3.md), [lambda.md](../../../lambda.md), [compatibility-matrix.md](../../../compatibility-matrix.md)

## Related

- Terraform module: [`../../terraform/s3-lambda/`](../../terraform/s3-lambda/)
- S3 object lifecycle CLI: [`../s3/`](../s3/)
- Lambda CLI: [`../lambda/`](../lambda/)
- [terraform-integration.md — Honest integration examples](../../../terraform-integration.md#honest-integration-examples)
