#!/usr/bin/env bash
# ListObjectsV2 — list keys under prefix.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=cli-demo-bucket}"
: "${LIST_PREFIX:=demo/}"

aws s3api list-objects-v2 \
  --bucket "$BUCKET_NAME" \
  --prefix "$LIST_PREFIX" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
