#!/usr/bin/env bash
set -euo pipefail
EP="${EP:-http://127.0.0.1:4566}"
aws sns create-topic --name s3-uploads --endpoint-url "$EP"
echo "TOPIC_ARN=arn:aws:sns:us-east-1:000000000000:s3-uploads"
