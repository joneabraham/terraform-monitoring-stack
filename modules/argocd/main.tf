resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  timeout    = 600

  values = [
    yamlencode({
      configs = {
        params = { "server.insecure" = true } # TLS is terminated by port-forward/ingress in this demo
      }
      # Expose ArgoCD's own metrics to Prometheus.
      controller = { metrics = { enabled = true, serviceMonitor = { enabled = true } } }
      server     = { metrics = { enabled = true, serviceMonitor = { enabled = true } } }
      repoServer = { metrics = { enabled = true, serviceMonitor = { enabled = true } } }
    })
  ]
}

# "App of apps": one root Application that syncs everything under gitops/apps.
# After this, adding a workload = committing manifests to Git, not running Terraform.
resource "helm_release" "root_app" {
  name       = "argocd-root-app"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.apps_chart_version

  values = [
    yamlencode({
      applications = {
        root = {
          namespace = kubernetes_namespace.argocd.metadata[0].name
          project   = "default"
          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = var.gitops_target_revision
            path           = var.gitops_repo_path
            directory      = { recurse = true }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "default"
          }
          syncPolicy = {
            automated   = { prune = true, selfHeal = true }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      }
    })
  ]

  depends_on = [helm_release.argocd]
}
