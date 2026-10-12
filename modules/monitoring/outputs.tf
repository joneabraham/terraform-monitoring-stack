output "namespace" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}

# Service names follow fullnameOverride = "kps" set in the chart values.
output "grafana_service" {
  value = "${local.release_name}-grafana"
}

output "prometheus_service" {
  value = "kps-prometheus"
}

output "alertmanager_service" {
  value = "kps-alertmanager"
}
