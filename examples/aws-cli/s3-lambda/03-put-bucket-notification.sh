#!/usr/bin/env bash
# PutBucketNotificationConfiguration — Lambda on ObjectCreated (prefix in/).
set -euo pipefail

: "${AWS_ENDPOINT:?Set AWS_ENDPOINT}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${BUCKET_NAME:=s3-lambda-demo-bucket}"
: "${FUNCTION_NAME:=s3-event-fn}"

ACCOUNT_ID="${AWS_ACCOUNT_ID:-000000000000}"
LAMBDA_ARN="arn:aws:lambda:${AWS_DEFAULT_REGION}:${ACCOUNT_ID}:function:${FUNCTION_NAME}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "${SCRIPT_DIR}/.build"
NOTIF="${SCRIPT_DIR}/.build/s3-notification-$$.json"
cat > "$NOTIF" <<EOF
{
  "LambdaFunctionConfigurations": [
    {
      "Id": "s3-object-created",
      "LambdaFunctionArn": "${LAMBDA_ARN}",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {"Name": "prefix", "Value": "in/"}
          ]
        }
      }
    }
  ]
}
EOF

NOTIF_FILE="$NOTIF"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if command -v cygpath >/dev/null 2>&1; then
      NOTIF_FILE="$(cygpath -w "$NOTIF" | tr '\\' '/')"
    fi
    ;;
esac

aws s3api put-bucket-notification-configuration \
  --bucket "$BUCKET_NAME" \
  --notification-configuration "file://${NOTIF_FILE}" \
  --endpoint-url "$AWS_ENDPOINT" \
  --region "$AWS_DEFAULT_REGION"

rm -f "$NOTIF"
echo "Notification configured: $FUNCTION_NAME on s3://$BUCKET_NAME/in/*"
