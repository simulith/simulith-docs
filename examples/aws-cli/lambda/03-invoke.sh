#!/usr/bin/env bash
# InvokeFunction sync — payload echoed in response body.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${FUNCTION_NAME:=cli-demo-fn}"

OUT="${TMPDIR:-/tmp}/lambda-invoke-out.json"
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  "$OUT" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Response:"
cat "$OUT"
echo
