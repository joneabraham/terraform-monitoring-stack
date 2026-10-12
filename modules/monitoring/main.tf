locals {
  release_name = "kube-prometheus-stack"

  # Alertmanager routing: send to Slack when a webhook is set, otherwise a no-op receiver.
  slack_enabled = var.slack_webhook_url != ""

  alertmanager_config = {
    route = {
      receiver        = local.slack_enabled ? "slack" : "null"
      group_by        = ["alertname", "namespace"]
      group_wait      = "30s"
      group_interval  = "5m"
      repeat_interval = "4h"
      routes = [
        { receiver = "null", matchers = ["alertname = \"Watchdog\""] }
      ]
    }
    receivers = concat(
      [{ name = "null" }],
      local.slack_enabled ? [{
        name = "slack"
        slack_configs = [{
          api_url       = var.slack_webhook_url
          channel       = var.slack_channel
          send_resolved = true
          title         = "[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }}"
          text          = "{{ range .Alerts }}*{{ .Annotations.summary }}*\n{{ .Annotations.description }}\n{{ end }}"
        }]
      }] : []
    )
  }
}

# Encrypted gp3 volumes for Prometheus, Alertmanager and Grafana data.
resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
}

# Prometheus, Alertmanager, Grafana, node-exporter and kube-state-metrics in one chart.
resource "helm_release" "kube_prometheus_stack" {
  name       = local.release_name
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  timeout    = 900

  values = [
    yamlencode({
      fullnameOverride = "kps"

      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention
          # Pick up ServiceMonitors/PrometheusRules from any namespace, not just this release.
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          ruleSelectorNilUsesHelmValues           = false
          externalLabels                          = { cluster = var.cluster_name }
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = kubernetes_storage_class_v1.gp3.metadata[0].name
                accessModes      = ["ReadWriteOnce"]
                resources        = { requests = { storage = var.prometheus_storage } }
              }
            }
          }
        }
      }

      alertmanager = {
        config = local.alertmanager_config
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = kubernetes_storage_class_v1.gp3.metadata[0].name
                accessModes      = ["ReadWriteOnce"]
                resources        = { requests = { storage = "2Gi" } }
              }
            }
          }
        }
      }

      # Custom alert rules on top of the chart's defaults (rendered as a PrometheusRule by the chart).
      additionalPrometheusRulesMap = {
        platform-rules = {
          groups = [{
            name = "platform.rules"
            rules = [
              {
                alert  = "NodeHighCPU"
                expr   = "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 85"
                for    = "10m"
                labels = { severity = "warning" }
                annotations = {
                  summary     = "High CPU on {{ $labels.instance }}"
                  description = "CPU usage has been above 85% for 10 minutes."
                }
              },
              {
                alert  = "NodeDiskAlmostFull"
                expr   = "(node_filesystem_avail_bytes{fstype!~\"tmpfs|overlay\"} / node_filesystem_size_bytes{fstype!~\"tmpfs|overlay\"}) * 100 < 15"
                for    = "15m"
                labels = { severity = "critical" }
                annotations = {
                  summary     = "Disk almost full on {{ $labels.instance }}"
                  description = "Less than 15% disk space left on {{ $labels.mountpoint }}."
                }
              },
              {
                alert  = "PodCrashLooping"
                expr   = "increase(kube_pod_container_status_restarts_total[15m]) > 3"
                for    = "5m"
                labels = { severity = "warning" }
                annotations = {
                  summary     = "{{ $labels.namespace }}/{{ $labels.pod }} is crash looping"
                  description = "Container {{ $labels.container }} restarted more than 3 times in 15 minutes."
                }
              }
            ]
          }]
        }
      }

      grafana = {
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled          = true
          storageClassName = kubernetes_storage_class_v1.gp3.metadata[0].name
          size             = "5Gi"
        }
        defaultDashboardsTimezone = "browser"
        sidecar = {
          dashboards = { enabled = true, searchNamespace = "ALL" }
        }
      }
    })
  ]
}
