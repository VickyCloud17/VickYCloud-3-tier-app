# =============================================================
#  VickYCloud — Terraform Root
#  File    : terraform/main.tf
#  Target  : Local Minikube cluster
#  Manages : namespaces, configmaps, all K8s resources,
#            Prometheus + Grafana via Helm
# =============================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

# -------------------------------------------------------------
#  Providers
# -------------------------------------------------------------
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}

# -------------------------------------------------------------
#  Module: Namespaces
#  Creates: vickycloud, monitoring, jenkins
# -------------------------------------------------------------
module "namespaces" {
  source     = "./modules/namespace"
  namespaces = var.namespaces
  project    = var.project_name
}

# -------------------------------------------------------------
#  Module: ConfigMaps
#  Creates: nginx default.conf + schema.sql as K8s ConfigMaps
# -------------------------------------------------------------
module "configmaps" {
  source    = "./modules/configmap"
  namespace = var.app_namespace
  project   = var.project_name

  depends_on = [module.namespaces]
}

# -------------------------------------------------------------
#  Module: Kubernetes Core Resources
#  Creates: Secret, PVC, web/app/db Deployments + Services
# -------------------------------------------------------------
module "kubernetes" {
  source = "./modules/k8s"

  project        = var.project_name
  namespace      = var.app_namespace
  web_image      = var.web_image
  app_image      = var.app_image
  db_image       = var.db_image
  web_replicas   = var.web_replicas
  app_replicas   = var.app_replicas
  db_storage     = var.db_storage
  mysql_password = var.mysql_password
  mysql_user     = var.mysql_user
  mysql_database = var.mysql_database

  depends_on = [module.namespaces, module.configmaps]
}

# -------------------------------------------------------------
#  Helm Release: kube-prometheus-stack
#  DISABLED — re-enable when running on a machine with 8GB+ RAM
#  To enable: uncomment this block and run terraform apply again
# -------------------------------------------------------------
# resource "helm_release" "prometheus_stack" {
#   name             = "prometheus-stack"
#   repository       = "https://prometheus-community.github.io/helm-charts"
#   chart            = "kube-prometheus-stack"
#   namespace        = var.monitoring_namespace
#   create_namespace = true
#   version          = "56.6.2"
#   timeout          = 300
#
#   set { name = "grafana.adminPassword"                      value = var.grafana_password }
#   set { name = "grafana.service.type"                       value = "NodePort" }
#   set { name = "grafana.service.nodePort"                   value = "32000" }
#   set { name = "prometheus.prometheusSpec.service.type"     value = "NodePort" }
#   set { name = "prometheus.prometheusSpec.service.nodePort" value = "32001" }
#   set { name = "alertmanager.service.type"                  value = "NodePort" }
#   set { name = "alertmanager.service.nodePort"              value = "32002" }
#
#   depends_on = [module.namespaces]
# }

# -------------------------------------------------------------
#  Outputs
# -------------------------------------------------------------
output "app_url" {
  description = "VickYCloud application URL"
  value       = "http://<minikube-ip>:30080"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://<minikube-ip>:32000  |  user: admin  pass: ${var.grafana_password}"
  sensitive   = true
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://<minikube-ip>:32001"
}

output "app_namespace" {
  description = "Application namespace"
  value       = var.app_namespace
}

output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = var.monitoring_namespace
}
