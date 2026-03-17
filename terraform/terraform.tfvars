# =============================================================
#  VickYCloud — Terraform Variable Values
#  File : terraform/terraform.tfvars
#  NOTE : This file is in .gitignore — never commit it
#         It contains passwords and sensitive values
# =============================================================

# -------------------------------------------------------------
#  Cluster
# -------------------------------------------------------------
kubeconfig_path = "~/.kube/config"
kube_context    = "minikube"

# -------------------------------------------------------------
#  Project
# -------------------------------------------------------------
project_name         = "vickycloud"
app_namespace        = "vickycloud"
monitoring_namespace = "monitoring"
namespaces           = ["vickycloud", "monitoring", "jenkins"]

# -------------------------------------------------------------
#  Docker Images
#  For Minikube: build with eval $(minikube docker-env) first
# -------------------------------------------------------------
web_image = "vickycloud/web-tier:latest"
app_image = "vickycloud/app-tier:latest"
db_image  = "mysql:8.0"

# -------------------------------------------------------------
#  Replicas
# -------------------------------------------------------------
web_replicas = 1
app_replicas = 1

# -------------------------------------------------------------
#  Database — change in production
# -------------------------------------------------------------
mysql_database = "devopsdb"
mysql_user     = "root"
mysql_password = "password123"
db_storage     = "5Gi"

# -------------------------------------------------------------
#  Monitoring — change in production
# -------------------------------------------------------------
grafana_password = "Admin@Grafana1"
