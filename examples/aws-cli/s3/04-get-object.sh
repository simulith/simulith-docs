#!/usr/bin/env bash
# GetObject — download object body.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=cli-demo-bucket}"
: "${OBJECT_KEY:=demo/hello.txt}"

OUT="${TMPDIR:-/tmp}/s3-cli-get-object.out"
aws s3api get-object \
  --bucket "$BUCKET_NAME" \
  --key "$OBJECT_KEY" \
  "$OUT" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Saved to $OUT:"
cat "$OUT"
