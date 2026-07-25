#!/usr/bin/env bash
# InvokeFunction sync — Go bootstrap response JSON in output file.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${FUNCTION_NAME:=cli-go-demo-fn}"

OUT="${TMPDIR:-/tmp}/lambda-go-invoke-out.json"
PAYLOAD="${PAYLOAD:-{\"msg\":\"hi\"}}"

aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload "$PAYLOAD" \
  --cli-binary-format raw-in-base64-out \
  "$OUT" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Response:"
cat "$OUT"
echo
