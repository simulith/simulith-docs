#!/usr/bin/env bash
# PutParameter — write String parameter under a path prefix (SSM path pattern step 1).
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${PARAM_NAME:=/app/cli-demo/log-level}"
: "${PARAM_VALUE:=info}"

aws ssm put-parameter \
  --name "$PARAM_NAME" \
  --type String \
  --value "$PARAM_VALUE" \
  --overwrite \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "PutParameter $PARAM_NAME = $PARAM_VALUE"
