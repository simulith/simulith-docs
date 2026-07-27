#!/usr/bin/env bash
set -euo pipefail

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT="${AWS_ENDPOINT:-http://127.0.0.1:4566}"
RUN_ID="${RUN_ID:-$(date +%s)}"
export FUNCTION_NAME="${FUNCTION_NAME:-s3-event-fn-smoke-${RUN_ID}}"
export BUCKET_NAME="${BUCKET_NAME:-s3-lambda-demo-smoke-${RUN_ID}}"
export OBJECT_KEY=in/demo.txt
_marker_base="${TMPDIR:-${TEMP:-${TMP:-/tmp}}}/simulith-s3-lambda-demo"
if [[ -n "${LOCALAPPDATA:-}" ]]; then
  _marker_base="${LOCALAPPDATA}/Temp/simulith-s3-lambda-demo"
fi
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if command -v cygpath >/dev/null 2>&1; then
      export MARKER_DIR="$(cygpath -m "$_marker_base")"
    else
      export MARKER_DIR="${_marker_base//\\//}"
    fi
    ;;
  *)
    export MARKER_DIR="$_marker_base"
    ;;
esac
unset _marker_base

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

rm -rf "$MARKER_DIR"
mkdir -p "$MARKER_DIR"

./01-create-function.sh
./02-create-bucket.sh
./03-put-bucket-notification.sh
./04-put-object.sh
./05-wait-marker.sh

echo "SML-163 CLI smoke PASS"
