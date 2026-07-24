# AWS CLI — S3 object lifecycle on Simulith

Seven scripts derived from the [AWS S3 API](https://docs.aws.amazon.com/AmazonS3/latest/API/API_Operations_Amazon_Simple_Storage_Service.html), trimmed to Simulith's documented object subset.

## Prerequisites

- Simulith running ([quickstart](../../../quickstart.md))
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Bash (Git Bash on Windows)

## Environment

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
# Native / :4566
export AWS_ENDPOINT=http://127.0.0.1:4566
# Docker all-in-one
# export AWS_ENDPOINT=http://127.0.0.1:9080/runtime

export BUCKET_NAME=cli-demo-bucket
export OBJECT_KEY=demo/hello.txt
export COPY_KEY=demo/hello-copy.txt
```

Run from this directory:

```bash
cd runtime/examples/aws-cli/s3
```

## Scripts

| Script | AWS operation | Simulith API |
| --- | --- | --- |
| [`01-create-bucket.sh`](01-create-bucket.sh) | `create-bucket` | CreateBucket |
| [`02-put-object.sh`](02-put-object.sh) | `put-object` | PutObject |
| [`03-head-object.sh`](03-head-object.sh) | `head-object` | HeadObject |
| [`04-get-object.sh`](04-get-object.sh) | `get-object` | GetObject |
| [`05-list-objects.sh`](05-list-objects.sh) | `list-objects-v2` | ListObjectsV2 |
| [`06-copy-object.sh`](06-copy-object.sh) | `copy-object` | CopyObject |
| [`07-delete-objects.sh`](07-delete-objects.sh) | `delete-objects` | DeleteObjects |

```bash
./01-create-bucket.sh
./02-put-object.sh
./03-head-object.sh
./04-get-object.sh
./05-list-objects.sh
./06-copy-object.sh
./07-delete-objects.sh
```

Cleanup empty bucket:

```bash
aws s3api delete-bucket \
  --bucket "$BUCKET_NAME" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
```

**Alternative:** use Terraform green path [`../../terraform/s3/`](../../terraform/s3/) for bucket + seed objects, then run scripts `02`–`07` with `BUCKET_NAME` from `terraform output`.

## Limits

- Single-part upload only (no multipart)
- Path-style URLs on Simulith (`s3api` with `--endpoint-url`)
- No versioning, ACL policies, or lifecycle rules
- See [s3.md](../../../s3.md) and [compatibility-matrix.md](../../../compatibility-matrix.md)

## Related

- Terraform green path: [`../../terraform/s3/`](../../terraform/s3/)
- [`terraform-integration.md — Honest integration examples](../../../terraform-integration.md#honest-integration-examples)
