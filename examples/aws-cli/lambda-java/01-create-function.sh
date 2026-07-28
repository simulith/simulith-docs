#!/usr/bin/env bash
# CreateFunction — Java handler (java17, App::handleRequest) — SML-165+ invoke.
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT (e.g. http://127.0.0.1:4566)}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${FUNCTION_NAME:=cli-java-demo-fn}"
: "${JAVA_RUNTIME:=java17}"

if ! command -v java >/dev/null 2>&1 || ! command -v javac >/dev/null 2>&1; then
  echo "java and javac are required on PATH to compile App.class"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BUILD_DIR="${SCRIPT_DIR}/.build"
CLASSES="${BUILD_DIR}/classes"
ZIP="${BUILD_DIR}/function.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$CLASSES"

javac --release 11 -d "$CLASSES" App.java

if command -v zip >/dev/null 2>&1; then
  (cd "$CLASSES" && zip -q -j "$ZIP" ./*.class)
elif command -v python >/dev/null 2>&1; then
  python -c "
import glob, os, sys, zipfile
zip_path, classes_dir = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_path, 'w') as z:
    for path in glob.glob(os.path.join(classes_dir, '*.class')):
        z.write(path, os.path.basename(path))
" "$ZIP" "$CLASSES"
else
  echo "zip or python required to package App.class"
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
  --runtime "$JAVA_RUNTIME" \
  --handler App::handleRequest \
  --role "$ROLE_ARN" \
  --zip-file "fileb://${ZIP_FILE}" \
  --timeout 10 \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

echo "Created $FUNCTION_NAME ($JAVA_RUNTIME)"
