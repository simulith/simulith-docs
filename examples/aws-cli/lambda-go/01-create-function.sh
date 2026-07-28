#!/usr/bin/env bash
# CreateFunction — Go provided.al2023 bootstrap (SML-157+ invoke).
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${FUNCTION_NAME:=cli-go-demo-fn}"

if ! command -v go >/dev/null 2>&1; then
  echo "go is required on PATH to build bootstrap"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_DIR="${SCRIPT_DIR}/.build"
mkdir -p "$BUILD_DIR"

BOOTSTRAP_NAME=bootstrap
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*|Windows*)
    BOOTSTRAP_NAME=bootstrap.exe
    ;;
esac

BOOTSTRAP="${BUILD_DIR}/${BOOTSTRAP_NAME}"
ZIP="${BUILD_DIR}/function.zip"

rm -f "$BOOTSTRAP" "$ZIP"
go build -o "$BOOTSTRAP" .
if command -v zip >/dev/null 2>&1; then
  zip -q -j "$ZIP" "$BOOTSTRAP"
elif command -v python >/dev/null 2>&1; then
  python -c "import zipfile, sys; z=zipfile.ZipFile(sys.argv[1], 'w'); z.write(sys.argv[2], sys.argv[3]); z.close()" "$ZIP" "$BOOTSTRAP" "$BOOTSTRAP_NAME"
else
  echo "zip or python required to package bootstrap"
  exit 1
fi

ZIP_FILE="$ZIP"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if command -v cygpath >/dev/null 2>&1; then
      ZIP_FILE="$(cygpath -w "$ZIP" | tr '\\' '/')"
    fi
    ;;
esac

ROLE_ARN="${LAMBDA_ROLE_ARN:-arn:aws:iam::000000000000:role/simulith-cli-demo}"

if aws lambda get-function --function-name "$FUNCTION_NAME" --endpoint-url "$AWS_ENDPOINT" --region "$AWS_DEFAULT_REGION" >/dev/null 2>&1; then
  echo "Function $FUNCTION_NAME already exists — delete first or set FUNCTION_NAME"
  exit 1
fi

aws lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime provided.al2023 \
  --handler bootstrap \
  --role "$ROLE_ARN" \
  --zip-file "fileb://${ZIP_FILE}" \
  --timeout 3 \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Created $FUNCTION_NAME (provided.al2023)"
