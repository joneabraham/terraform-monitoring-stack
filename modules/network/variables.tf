variable "name" {
  description = "Name prefix for the VPC"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name, used for subnet discovery tags"
  type        = string
}
