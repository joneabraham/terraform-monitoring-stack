data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = var.name
  cidr = var.cidr
  azs  = local.azs

  private_subnets = [for i, _ in local.azs : cidrsubnet(var.cidr, 4, i)]
  public_subnets  = [for i, _ in local.azs : cidrsubnet(var.cidr, 8, 48 + i)]

  # One NAT gateway keeps demo costs down; set single_nat_gateway = false for HA.
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Tags the AWS Load Balancer Controller uses to discover subnets.
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}
