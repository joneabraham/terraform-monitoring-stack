# IaC Monitoring Stack Demo

Terraform that stands up an AWS EKS cluster with a full monitoring stack and GitOps delivery:

- **Network:** VPC across 2 AZs with public and private subnets (`modules/network`)
- **Cluster:** EKS with a managed node group, the EBS CSI driver for persistent volumes, and IRSA
- **Monitoring:** Prometheus, Alertmanager and Grafana via the `kube-prometheus-stack` Helm chart, plus custom alert rules (high CPU, disk almost full, crash-looping pods) and optional Slack alerts (`modules/monitoring`)
- **GitOps:** ArgoCD installed with Helm and an "app of apps" root Application that auto-syncs everything under `gitops/apps` (`modules/argocd`)

```
terraform apply
   ├─ network     VPC, subnets, NAT
   ├─ eks         cluster, node group, add-ons
   ├─ monitoring  Helm: kube-prometheus-stack + PrometheusRules
   └─ argocd      Helm: argo-cd + root Application
                          │
                          ▼  watches Git
                 gitops/apps/sample-app
                 (Deployment, Service, ServiceMonitor, PrometheusRule)
```

After the first apply, new workloads ship by committing to `gitops/apps/`, with no Terraform run needed. The sample app includes a `ServiceMonitor`, so Prometheus starts scraping it the moment ArgoCD syncs it.

## Prerequisites

- Terraform 1.6 or later, AWS CLI v2 (logged in), kubectl
- An AWS account. **This creates billable resources**: the EKS control plane, two t3.large nodes, a NAT gateway and EBS volumes. Destroy the stack when you're done.

## Deploy

```bash
cp terraform.tfvars.example terraform.tfvars   # set grafana_admin_password, your repo URL
terraform init
terraform plan
terraform apply                                # ~15–20 min
```

Then use the commands from `terraform output`:

```bash
aws eks update-kubeconfig --region ap-south-1 --name monitoring-demo
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80   # Grafana: admin / your password
kubectl -n argocd port-forward svc/argocd-server 8080:443                      # ArgoCD UI
```

## Tear down

```bash
terraform destroy
```

## Layout

```
main.tf, providers.tf, variables.tf, outputs.tf, versions.tf
modules/
  network/      VPC
  monitoring/   kube-prometheus-stack + alert rules
  argocd/       ArgoCD + root Application
gitops/apps/    manifests ArgoCD syncs
.github/workflows/terraform.yml   fmt, validate, kubeconform on every PR
```
