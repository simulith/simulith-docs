#!/usr/bin/env bash
set -euo pipefail

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT="${AWS_ENDPOINT:-http://127.0.0.1:4566}"
RUN_ID="${RUN_ID:-$(date +%s)}"
export FUNCTION_NAME="${FUNCTION_NAME:-cli-java-demo-smoke-${RUN_ID}}"

if ! command -v java >/dev/null 2>&1 || ! command -v javac >/dev/null 2>&1; then
  echo "SKIP: java/javac not on PATH"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

./01-create-function.sh
./03-invoke.sh
./02-update-configuration.sh
./03-invoke.sh

aws lambda delete-function \
  --function-name "$FUNCTION_NAME" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "SML-166 CLI smoke PASS"
