#!/usr/bin/env bash
# CreateFunction — S3 event processor (nodejs20.x).
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${FUNCTION_NAME:=s3-event-fn}"
: "${MARKER_DIR:=/tmp/simulith-s3-lambda-demo}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

mkdir -p "$MARKER_DIR"
rm -f "${MARKER_DIR}"/*.done 2>/dev/null || true

ZIP="${SCRIPT_DIR}/.build/function.zip"
mkdir -p "${SCRIPT_DIR}/.build"
rm -f "$ZIP"
zip -q -j "$ZIP" handler.js

ROLE_ARN="${LAMBDA_ROLE_ARN:-arn:aws:iam::000000000000:role/simulith-cli-demo}"

if aws lambda get-function --function-name "$FUNCTION_NAME" --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" >/dev/null 2>&1; then
  echo "Function $FUNCTION_NAME already exists — delete first or set FUNCTION_NAME"
  exit 1
fi

aws lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime nodejs20.x \
  --handler handler.handler \
  --role "$ROLE_ARN" \
  --zip-file "fileb://${ZIP}" \
  --timeout 5 \
  --environment "Variables={MARKER_DIR=${MARKER_DIR}}" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Created $FUNCTION_NAME (MARKER_DIR=$MARKER_DIR)"
