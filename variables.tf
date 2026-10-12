variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "owner" {
  description = "Value for the Owner tag on every resource"
  type        = string
  default     = "jone-abraham"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "monitoring-demo"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "grafana_admin_password" {
  description = "Initial Grafana admin password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.grafana_admin_password) >= 12
    error_message = "Use at least 12 characters for the Grafana admin password."
  }
}

variable "slack_webhook_url" {
  description = "Optional Slack incoming-webhook URL for Alertmanager notifications. Leave empty to disable."
  type        = string
  default     = ""
  sensitive   = true
}

variable "gitops_repo_url" {
  description = "Git repository ArgoCD watches for application manifests"
  type        = string
  default     = "https://github.com/joneabraham/terraform-monitoring-stack.git"
}

variable "gitops_repo_path" {
  description = "Path inside the GitOps repo that holds the app manifests"
  type        = string
  default     = "gitops/apps"
}

variable "gitops_target_revision" {
  description = "Branch, tag or commit ArgoCD tracks"
  type        = string
  default     = "main"
}
