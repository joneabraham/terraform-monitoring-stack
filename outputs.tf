output "cluster_name" {
  value = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Run this to point kubectl at the new cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "grafana_access" {
  description = "Port-forward command for Grafana (user: admin)"
  value       = "kubectl -n ${module.monitoring.namespace} port-forward svc/${module.monitoring.grafana_service} 3000:80"
}

output "prometheus_access" {
  value = "kubectl -n ${module.monitoring.namespace} port-forward svc/${module.monitoring.prometheus_service} 9090:9090"
}

output "alertmanager_access" {
  value = "kubectl -n ${module.monitoring.namespace} port-forward svc/${module.monitoring.alertmanager_service} 9093:9093"
}

output "argocd_access" {
  description = "Port-forward for the ArgoCD UI, plus how to read the initial admin password"
  value = {
    port_forward = "kubectl -n ${module.argocd.namespace} port-forward svc/argocd-server 8080:443"
    password     = "kubectl -n ${module.argocd.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  }
}
