#!/usr/bin/env bash
# PutItem — write event record to DynamoDB (fan-out pattern step 1).
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${TABLE_NAME:?Set TABLE_NAME (terraform output table_name)}"
: "${ITEM_ID:=cli-event-1}"

aws dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item "{\"Id\":{\"S\":\"$ITEM_ID\"},\"Status\":{\"S\":\"pending\"},\"Payload\":{\"S\":\"hello-from-cli\"}}" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "PutItem $ITEM_ID into $TABLE_NAME"
