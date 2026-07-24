#!/usr/bin/env bash
# PutObject — upload object body.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=cli-demo-bucket}"
: "${OBJECT_KEY:=demo/hello.txt}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BODY="${SCRIPT_DIR}/.build/hello.txt"
mkdir -p "${SCRIPT_DIR}/.build"
echo "hello from simulith cli demo" >"$BODY"

aws s3api put-object \
  --bucket "$BUCKET_NAME" \
  --key "$OBJECT_KEY" \
  --body "$BODY" \
  --content-type "text/plain" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "PutObject s3://$BUCKET_NAME/$OBJECT_KEY"
