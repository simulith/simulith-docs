#!/usr/bin/env bash
# PutSecretValue — update secret JSON after create.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${SECRET_NAME:=cli-demo-secret}"

aws secretsmanager put-secret-value \
  --secret-id "$SECRET_NAME" \
  --secret-string '{"username":"admin","password":"rotated-local","managed_by":"cli-put"}' \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Updated secret $SECRET_NAME"
