#!/usr/bin/env bash
# Publish one custom metric datapoint (PutMetricData) for Terraform green path.
set -euo pipefail

namespace="${1:?namespace}"
metric_name="${2:?metric_name}"
value="${3:?value}"
endpoint="${4:-}"

args=(
  cloudwatch put-metric-data
  --namespace "$namespace"
  --metric-name "$metric_name"
  --value "$value"
  --unit Milliseconds
)

if [[ -n "$endpoint" ]]; then
  args+=(--endpoint-url "$endpoint")
fi

aws "${args[@]}"
