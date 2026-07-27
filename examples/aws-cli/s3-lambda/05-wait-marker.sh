#!/usr/bin/env bash
# Wait for Lambda marker file written by async S3 dispatch.
set -euo pipefail

: "${MARKER_DIR:=/tmp/simulith-s3-lambda-demo}"
: "${OBJECT_KEY:=in/demo.txt}"

SAFE_KEY="${OBJECT_KEY//\//_}"
MARKER="${MARKER_DIR}/${SAFE_KEY}.done"
DEADLINE=$((SECONDS + 15))

echo "Waiting for marker: $MARKER"
while [ ! -f "$MARKER" ]; do
  if [ "$SECONDS" -ge "$DEADLINE" ]; then
    echo "Timeout — marker not found. Is node on PATH? Check Simulith runtime logs."
    exit 1
  fi
  sleep 0.25
done

echo "Lambda processed event:"
cat "$MARKER"
echo ""
