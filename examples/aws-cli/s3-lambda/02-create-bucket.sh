#!/usr/bin/env bash
# CreateBucket — target bucket for object uploads.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=s3-lambda-demo-bucket}"

if aws s3api head-bucket --bucket "$BUCKET_NAME" --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" 2>/dev/null; then
  echo "Bucket $BUCKET_NAME already exists"
  exit 0
fi

aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Created bucket $BUCKET_NAME"
