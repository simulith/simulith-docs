#!/usr/bin/env bash
# SendMessage — enqueue notification referencing DynamoDB item (fan-out step 2).
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${QUEUE_URL:?Set QUEUE_URL (terraform output queue_url)}"
: "${ITEM_ID:=cli-event-1}"

aws sqs send-message \
  --queue-url "$QUEUE_URL" \
  --message-body "{\"itemId\":\"$ITEM_ID\",\"action\":\"process\"}" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Sent fan-out message for item $ITEM_ID"
