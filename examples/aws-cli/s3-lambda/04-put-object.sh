#!/usr/bin/env bash
# PutObject — triggers async Lambda via bucket notification.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=s3-lambda-demo-bucket}"
: "${OBJECT_KEY:=in/demo.txt}"

echo "hello from s3-lambda demo" | aws s3api put-object \
  --bucket "$BUCKET_NAME" \
  --key "$OBJECT_KEY" \
  --body - \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Uploaded s3://${BUCKET_NAME}/${OBJECT_KEY}"
