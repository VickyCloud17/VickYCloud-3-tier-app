# =============================================================
#  VickYCloud — Terraform Variables
#  File: terraform/variables.tf
# =============================================================

# -------------------------------------------------------------
#  Cluster connection
# -------------------------------------------------------------
variable "kubeconfig_path" {
  description = "Absolute path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context name — use 'minikube' for local"
  type        = string
  default     = "minikube"
}

# -------------------------------------------------------------
#  Project metadata
# -------------------------------------------------------------
variable "project_name" {
  description = "Project label applied to all Kubernetes resources"
  type        = string
  default     = "vickycloud"
}

variable "app_namespace" {
  description = "Kubernetes namespace for web + app + db workloads"
  type        = string
  default     = "vickycloud"
}

variable "monitoring_namespace" {
  description = "Kubernetes namespace for Prometheus and Grafana"
  type        = string
  default     = "monitoring"
}

variable "namespaces" {
  description = "List of all namespaces Terraform will create"
  type        = list(string)
  default     = ["vickycloud", "monitoring", "jenkins"]
}

# -------------------------------------------------------------
#  Docker images
# -------------------------------------------------------------
variable "web_image" {
  description = "Docker image for the web tier (nginx)"
  type        = string
  default     = "vickycloud/web-tier:latest"
}

variable "app_image" {
  description = "Docker image for the app tier (PHP + Apache)"
  type        = string
  default     = "vickycloud/app-tier:latest"
}

variable "db_image" {
  description = "Docker image for the database tier"
  type        = string
  default     = "mysql:8.0"
}

# -------------------------------------------------------------
#  Replica counts
# -------------------------------------------------------------
variable "web_replicas" {
  description = "Number of nginx (web tier) pods to run"
  type        = number
  default     = 2
}

variable "app_replicas" {
  description = "Number of PHP Apache (app tier) pods to run"
  type        = number
  default     = 2
}

# -------------------------------------------------------------
#  Database
# -------------------------------------------------------------
variable "mysql_database" {
  description = "MySQL database name"
  type        = string
  default     = "devopsdb"
}

variable "mysql_user" {
  description = "MySQL username"
  type        = string
  default     = "root"
  sensitive   = true
}

variable "mysql_password" {
  description = "MySQL root password — set in terraform.tfvars, never hardcode here"
  type        = string
  sensitive   = true
}

variable "db_storage" {
  description = "PersistentVolumeClaim storage size for MySQL data"
  type        = string
  default     = "5Gi"
}

# -------------------------------------------------------------
#  Monitoring
# -------------------------------------------------------------
variable "grafana_password" {
  description = "Grafana admin password — set in terraform.tfvars"
  type        = string
  sensitive   = true
}
