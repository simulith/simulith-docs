#!/usr/bin/env bash
# ReceiveMessage — verify queued fan-out notification.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${QUEUE_URL:?Set QUEUE_URL (terraform output queue_url)}"

aws sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --max-number-of-messages 1 \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"
