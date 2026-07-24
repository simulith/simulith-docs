#!/usr/bin/env bash
# CreateBucket — start object lifecycle demo (skip if bucket exists).
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=cli-demo-bucket}"

if aws s3api head-bucket --bucket "$BUCKET_NAME" --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" >/dev/null 2>&1; then
  echo "Bucket $BUCKET_NAME already exists — continuing"
  exit 0
fi

aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Created bucket $BUCKET_NAME"
