variable "namespace" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  description = "argo-cd Helm chart version"
  type        = string
  default     = "7.6.12"
}

variable "apps_chart_version" {
  description = "argocd-apps Helm chart version"
  type        = string
  default     = "2.0.2"
}

variable "gitops_repo_url" {
  type = string
}

variable "gitops_repo_path" {
  type = string
}

variable "gitops_target_revision" {
  type = string
}
