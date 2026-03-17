# =============================================================
#  VickYCloud — Kubernetes Resources Module
#  File: terraform/modules/k8s/main.tf
#  Creates:
#    - mysql-secret        (credentials)
#    - mysql-pvc           (persistent storage 5Gi)
#    - web-deployment      (nginx, 2 replicas)
#    - web-service         (NodePort :30080)
#    - app-deployment      (PHP Apache, 2 replicas)
#    - app-service         (ClusterIP)
#    - db-deployment       (MySQL 8.0)
#    - mysql-service       (ClusterIP :3306)
# =============================================================

variable "project" {
  description = "Project label"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for all resources"
  type        = string
}

variable "web_image" {
  description = "Web tier Docker image"
  type        = string
}

variable "app_image" {
  description = "App tier Docker image"
  type        = string
}

variable "db_image" {
  description = "MySQL Docker image"
  type        = string
}

variable "web_replicas" {
  description = "Number of web tier replicas"
  type        = number
}

variable "app_replicas" {
  description = "Number of app tier replicas"
  type        = number
}

variable "db_storage" {
  description = "MySQL PVC storage size"
  type        = string
}

variable "mysql_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

variable "mysql_user" {
  description = "MySQL username"
  type        = string
  sensitive   = true
}

variable "mysql_database" {
  description = "MySQL database name"
  type        = string
}

# -------------------------------------------------------------
#  Local values — shared labels
# -------------------------------------------------------------
locals {
  common_labels = {
    project    = var.project
    managed-by = "terraform"
  }
}

# =============================================================
#  SECRET — MySQL credentials
#  Referenced by app-deployment env vars and db-deployment
# =============================================================
resource "kubernetes_secret" "mysql" {
  metadata {
    name      = "mysql-secret"
    namespace = var.namespace
    labels    = local.common_labels
  }

  type = "Opaque"

  data = {
    mysql-root-password = var.mysql_password
    mysql-user          = var.mysql_user
    mysql-password      = var.mysql_password
  }
}

# =============================================================
#  PVC — MySQL persistent data volume
# =============================================================
resource "kubernetes_persistent_volume_claim" "mysql" {
  metadata {
    name      = "mysql-pvc"
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.db_storage
      }
    }
  }
}

# =============================================================
#  WEB TIER — Deployment
#  nginx serves index.html + login.html
#  proxies *.php to app-service
# =============================================================
resource "kubernetes_deployment" "web" {
  timeouts {
    create = "10m"
    update = "10m"
    delete = "5m"
  }

  metadata {
    name      = "web-deployment"
    namespace = var.namespace
    labels    = merge(local.common_labels, { app = "web", tier = "presentation" })
  }

  spec {
    replicas = var.web_replicas

    selector {
      match_labels = { app = "web" }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    template {
      metadata {
        labels = { app = "web", tier = "presentation" }
      }

      spec {
        container {
          name              = "web"
          image             = var.web_image
          image_pull_policy = "Never"

          port {
            container_port = 80
            name           = "http"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 15
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            failure_threshold     = 3
          }
        }

        restart_policy = "Always"
      }
    }
  }
}

# =============================================================
#  WEB TIER — Service (NodePort — public facing)
# =============================================================
resource "kubernetes_service" "web" {
  metadata {
    name      = "web-service"
    namespace = var.namespace
    labels    = merge(local.common_labels, { app = "web" })
  }

  spec {
    type     = "NodePort"
    selector = { app = "web" }

    port {
      name        = "http"
      port        = 80
      target_port = 80
      node_port   = 30080
    }
  }
}

# =============================================================
#  APP TIER — Deployment
#  PHP 8.2 + Apache runs submit.php and login.php
# =============================================================
resource "kubernetes_deployment" "app" {
  timeouts {
    create = "10m"
    update = "10m"
    delete = "5m"
  }

  metadata {
    name      = "app-deployment"
    namespace = var.namespace
    labels    = merge(local.common_labels, { app = "app", tier = "application" })
  }

  spec {
    replicas = var.app_replicas

    selector {
      match_labels = { app = "app" }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = 1
        max_unavailable = 0
      }
    }

    template {
      metadata {
        labels = { app = "app", tier = "application" }
      }

      spec {
        container {
          name              = "app"
          image             = var.app_image
          image_pull_policy = "Never"

          port {
            container_port = 80
            name           = "http"
          }

          # DB connection pulled from Secret — never hardcoded
          env {
            name  = "DB_HOST"
            value = "mysql-service"
          }
          env {
            name  = "DB_NAME"
            value = var.mysql_database
          }
          env {
            name = "DB_USER"
            value_from {
              secret_key_ref {
                name = "mysql-secret"
                key  = "mysql-user"
              }
            }
          }
          env {
            name = "DB_PASS"
            value_from {
              secret_key_ref {
                name = "mysql-secret"
                key  = "mysql-password"
              }
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            tcp_socket {
              port = 80
            }
            initial_delay_seconds = 15
            period_seconds        = 20
            failure_threshold     = 3
          }

          readiness_probe {
            tcp_socket {
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            failure_threshold     = 3
          }
        }

        restart_policy = "Always"
      }
    }
  }

  depends_on = [kubernetes_secret.mysql]
}

# =============================================================
#  APP TIER — Service (ClusterIP — internal only)
#  Name must match nginx proxy_pass: http://app-service
# =============================================================
resource "kubernetes_service" "app" {
  metadata {
    name      = "app-service"
    namespace = var.namespace
    labels    = merge(local.common_labels, { app = "app" })
  }

  spec {
    type     = "ClusterIP"
    selector = { app = "app" }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}

# =============================================================
#  DB TIER — Deployment
#  MySQL 8.0 with PVC for data + ConfigMap for schema init
# =============================================================
resource "kubernetes_deployment" "db" {
  timeouts {
    create = "10m"
    update = "10m"
    delete = "5m"
  }

  metadata {
    name      = "db-deployment"
    namespace = var.namespace
    labels    = merge(local.common_labels, { app = "mysql", tier = "data" })
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "mysql" }
    }

    # Recreate — MySQL cannot run two writers simultaneously
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = { app = "mysql", tier = "data" }
      }

      spec {
        container {
          name              = "mysql"
          image             = var.db_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 3306
            name           = "mysql"
          }

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = "mysql-secret"
                key  = "mysql-root-password"
              }
            }
          }
          env {
            name  = "MYSQL_DATABASE"
            value = var.mysql_database
          }
          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = "mysql-secret"
                key  = "mysql-user"
              }
            }
          }
          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = "mysql-secret"
                key  = "mysql-password"
              }
            }
          }

          # MySQL data directory
          volume_mount {
            name       = "mysql-data"
            mount_path = "/var/lib/mysql"
          }

          # schema.sql auto-runs on first boot
          volume_mount {
            name       = "mysql-initdb"
            mount_path = "/docker-entrypoint-initdb.d"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            exec {
              command = ["mysqladmin", "ping", "-h", "localhost"]
            }
            initial_delay_seconds = 30
            period_seconds        = 20
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["mysqladmin", "ping", "-h", "localhost"]
            }
            initial_delay_seconds = 20
            period_seconds        = 10
            failure_threshold     = 3
          }
        }

        volume {
          name = "mysql-data"
          persistent_volume_claim {
            claim_name = "mysql-pvc"
          }
        }

        volume {
          name = "mysql-initdb"
          config_map {
            name = "mysql-initdb-config"
          }
        }

        restart_policy = "Always"
      }
    }
  }

  depends_on = [
    kubernetes_secret.mysql,
    kubernetes_persistent_volume_claim.mysql
  ]
}

# =============================================================
#  DB TIER — Service (ClusterIP — internal only)
#  Name must match DB_HOST in submit.php and login.php
# =============================================================
resource "kubernetes_service" "db" {
  metadata {
    name      = "mysql-service"
    namespace = var.namespace
    labels    = merge(local.common_labels, { app = "mysql" })
  }

  spec {
    type     = "ClusterIP"
    selector = { app = "mysql" }

    port {
      name        = "mysql"
      port        = 3306
      target_port = 3306
    }
  }
}

# =============================================================
#  Outputs
# =============================================================
output "web_nodeport" {
  description = "NodePort for accessing the web tier"
  value       = 30080
}

output "mysql_service_name" {
  description = "MySQL service name (used as DB_HOST in PHP)"
  value       = kubernetes_service.db.metadata[0].name
}

output "app_service_name" {
  description = "App service name (used in nginx proxy_pass)"
  value       = kubernetes_service.app.metadata[0].name
}
