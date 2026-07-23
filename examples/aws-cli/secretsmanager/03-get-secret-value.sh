#!/usr/bin/env bash
# GetSecretValue — read current secret string.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${SECRET_NAME:=cli-demo-secret}"

aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
