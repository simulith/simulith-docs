#!/usr/bin/env bash
# CopyObject — same-bucket copy via x-amz-copy-source.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=cli-demo-bucket}"
: "${OBJECT_KEY:=demo/hello.txt}"
: "${COPY_KEY:=demo/hello-copy.txt}"

aws s3api copy-object \
  --bucket "$BUCKET_NAME" \
  --key "$COPY_KEY" \
  --copy-source "${BUCKET_NAME}/${OBJECT_KEY}" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Copied s3://$BUCKET_NAME/$OBJECT_KEY → s3://$BUCKET_NAME/$COPY_KEY"
