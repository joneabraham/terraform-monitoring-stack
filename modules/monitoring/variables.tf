variable "namespace" {
  description = "Namespace for the monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "kube-prometheus-stack chart version"
  type        = string
  default     = "65.1.1"
}

variable "cluster_name" {
  description = "Added as an external label on every metric"
  type        = string
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}

variable "slack_webhook_url" {
  type      = string
  default   = ""
  sensitive = true
}

variable "slack_channel" {
  type    = string
  default = "#alerts"
}

variable "prometheus_retention" {
  type    = string
  default = "7d"
}

variable "prometheus_storage" {
  type    = string
  default = "20Gi"
}
