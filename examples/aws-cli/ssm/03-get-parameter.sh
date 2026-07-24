#!/usr/bin/env bash
# GetParameter — read a single parameter by name.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${PARAM_NAME:=/app/cli-demo/log-level}"

aws ssm get-parameter \
  --name "$PARAM_NAME" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "GetParameter $PARAM_NAME"
