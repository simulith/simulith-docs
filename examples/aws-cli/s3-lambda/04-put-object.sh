#!/usr/bin/env bash
# PutObject — triggers async Lambda via bucket notification.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=s3-lambda-demo-bucket}"
: "${OBJECT_KEY:=in/demo.txt}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BODY_FILE="${SCRIPT_DIR}/.build/put-object-body.txt"
mkdir -p "${SCRIPT_DIR}/.build"
echo "hello from s3-lambda demo" > "$BODY_FILE"

aws s3 cp "$BODY_FILE" "s3://${BUCKET_NAME}/${OBJECT_KEY}" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

rm -f "$BODY_FILE"

echo "Uploaded s3://${BUCKET_NAME}/${OBJECT_KEY}"
