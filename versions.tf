terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
  }

  # Uncomment and fill in to keep state in S3 with locking (recommended for teams).
  # backend "s3" {
  #   bucket       = "my-tf-state-bucket"
  #   key          = "monitoring-stack/terraform.tfstate"
  #   region       = "ap-south-1"
  #   use_lockfile = true
  #   encrypt      = true
  # }
}
