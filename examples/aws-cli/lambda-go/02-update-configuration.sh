#!/usr/bin/env bash
# UpdateFunctionConfiguration — environment patch for Go bootstrap.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${FUNCTION_NAME:=cli-go-demo-fn}"

aws lambda update-function-configuration \
  --function-name "$FUNCTION_NAME" \
  --timeout 10 \
  --environment "Variables={GREETING=hello-from-go-cli}" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Updated configuration for $FUNCTION_NAME"
