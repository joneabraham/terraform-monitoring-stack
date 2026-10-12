module "network" {
  source = "./modules/network"

  name         = var.cluster_name
  cidr         = var.vpc_cidr
  cluster_name = var.cluster_name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  # Public endpoint so you can reach the API from your laptop; lock down with
  # cluster_endpoint_public_access_cidrs for anything beyond a demo.
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      min_size       = 1
      max_size       = 4
      desired_size   = var.node_desired_size
      capacity_type  = "ON_DEMAND"
    }
  }
}

# EBS CSI driver needs IAM permissions to create volumes for Prometheus/Grafana storage.
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.44"

  role_name             = "${var.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "monitoring" {
  source = "./modules/monitoring"

  grafana_admin_password = var.grafana_admin_password
  slack_webhook_url      = var.slack_webhook_url
  cluster_name           = var.cluster_name

  depends_on = [module.eks]
}

module "argocd" {
  source = "./modules/argocd"

  gitops_repo_url        = var.gitops_repo_url
  gitops_repo_path       = var.gitops_repo_path
  gitops_target_revision = var.gitops_target_revision

  # Apps synced by ArgoCD ship ServiceMonitors, so the Prometheus CRDs must exist first.
  depends_on = [module.monitoring]
}
