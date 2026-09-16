# CloudWatch Metrics — green path on Simulith.
#
# Custom metrics have no Terraform managed resource; apply publishes one datapoint
# via AWS CLI (PutMetricData). Destroy removes the terraform_data hook only — datapoints
# remain in Simulith SQLite until reset (same as real AWS custom metrics).
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

resource "terraform_data" "custom_metric" {
  input = {
    namespace   = var.metric_namespace
    metric_name = var.metric_name
    value       = var.metric_value
    endpoint    = var.use_simulith_endpoint ? var.simulith_endpoint : ""
  }

  provisioner "local-exec" {
    when = create
    command = join(" ", [
      "bash",
      "${path.module}/scripts/put-metric.sh",
      var.metric_namespace,
      var.metric_name,
      tostring(var.metric_value),
      var.use_simulith_endpoint ? var.simulith_endpoint : "",
    ])
    environment = {
      AWS_ACCESS_KEY_ID     = var.use_simulith_endpoint ? "test" : ""
      AWS_SECRET_ACCESS_KEY = var.use_simulith_endpoint ? "secret" : ""
      AWS_DEFAULT_REGION    = var.aws_region
    }
  }
}
