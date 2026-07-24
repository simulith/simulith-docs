#!/usr/bin/env bash
# GetParametersByPath — list parameters under a path prefix (recursive).
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${PARAM_PATH:=/app/cli-demo}"

aws ssm get-parameters-by-path \
  --path "$PARAM_PATH" \
  --recursive \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "GetParametersByPath $PARAM_PATH (recursive)"
