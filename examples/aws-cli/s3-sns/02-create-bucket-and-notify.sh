#!/usr/bin/env bash
set -euo pipefail
EP="${EP:-http://127.0.0.1:4566}"
BUCKET="${BUCKET:-s3-sns-demo}"
TOPIC_ARN="${TOPIC_ARN:-arn:aws:sns:us-east-1:000000000000:s3-uploads}"

aws s3api create-bucket --bucket "$BUCKET" --endpoint-url "$EP"

NOTIF=$(mktemp)
cat >"$NOTIF" <<EOF
{
  "TopicConfigurations": [
    {
      "Id": "object-created",
      "TopicArn": "$TOPIC_ARN",
      "Events": ["s3:ObjectCreated:*"]
    }
  ]
}
EOF
aws s3api put-bucket-notification-configuration \
  --bucket "$BUCKET" \
  --notification-configuration "file://$NOTIF" \
  --endpoint-url "$EP"
rm -f "$NOTIF"
