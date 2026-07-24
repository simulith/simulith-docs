#!/usr/bin/env bash
# HeadObject — metadata / existence check.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=cli-demo-bucket}"
: "${OBJECT_KEY:=demo/hello.txt}"

aws s3api head-object \
  --bucket "$BUCKET_NAME" \
  --key "$OBJECT_KEY" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
