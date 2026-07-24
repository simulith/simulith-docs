#!/usr/bin/env bash
# DeleteObjects — batch delete (up to 1000 keys).
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=cli-demo-bucket}"
: "${OBJECT_KEY:=demo/hello.txt}"
: "${COPY_KEY:=demo/hello-copy.txt}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DELETE_JSON="${SCRIPT_DIR}/.build/delete-keys.json"
mkdir -p "${SCRIPT_DIR}/.build"
cat >"$DELETE_JSON" <<EOF
{
  "Objects": [
    {"Key": "$OBJECT_KEY"},
    {"Key": "$COPY_KEY"}
  ],
  "Quiet": false
}
EOF

aws s3api delete-objects \
  --bucket "$BUCKET_NAME" \
  --delete "file://${DELETE_JSON}" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Deleted $OBJECT_KEY and $COPY_KEY"
