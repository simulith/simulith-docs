#!/usr/bin/env bash
# CreateSecret — pattern from AWS Secrets Manager user guide.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${SECRET_NAME:=cli-demo-secret}"

if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" >/dev/null 2>&1; then
  echo "Secret $SECRET_NAME already exists — delete first or set SECRET_NAME"
  exit 1
fi

aws secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --description "Simulith CLI demo secret" \
  --secret-string '{"username":"admin","password":"local-dev","managed_by":"cli"}' \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Created secret $SECRET_NAME"
