#!/usr/bin/env bash
set -euo pipefail
EP="${EP:-http://127.0.0.1:4566}"
BUCKET="${BUCKET:-s3-sns-demo}"
TOPIC_ARN="${TOPIC_ARN:-arn:aws:sns:us-east-1:000000000000:s3-uploads}"

echo "hello" | aws s3 cp - "s3://$BUCKET/in/demo.txt" --endpoint-url "$EP"
echo "Published to bucket; check SNS topic $TOPIC_ARN (ListTopics / console / sqlite sns_messages)"
