# =============================================================
#  VickYCloud — ConfigMap Module
#  File: terraform/modules/configmap/main.tf
#  Creates:
#    1. nginx-config     — default.conf for web tier
#    2. mysql-initdb-config — schema.sql for DB auto-init
# =============================================================

variable "namespace" {
  description = "Namespace to create ConfigMaps in"
  type        = string
}

variable "project" {
  description = "Project label value"
  type        = string
}

# -------------------------------------------------------------
#  ConfigMap 1 — nginx default.conf
#  Mounted into web-tier pods at /etc/nginx/conf.d/default.conf
# -------------------------------------------------------------
resource "kubernetes_config_map" "nginx_conf" {
  metadata {
    name      = "nginx-config"
    namespace = var.namespace
    labels = {
      project    = var.project
      managed-by = "terraform"
    }
  }

  data = {
    "default.conf" = <<-NGINX
      upstream app_backend {
        server app-service:80;
        keepalive 16;
      }

      server {
        listen 80;
        server_name _;

        root  /usr/share/nginx/html;
        index index.html login.html;

        add_header X-Frame-Options         "SAMEORIGIN"    always;
        add_header X-Content-Type-Options  "nosniff"       always;
        add_header X-XSS-Protection        "1; mode=block" always;
        add_header Referrer-Policy         "strict-origin" always;

        gzip              on;
        gzip_vary         on;
        gzip_min_length   1024;
        gzip_types        text/plain text/css text/javascript
                          application/javascript application/json text/html;

        location / {
          try_files $uri $uri/ /index.html;
          expires 1h;
          add_header Cache-Control "public, must-revalidate";
        }

        location = /login.html {
          root /usr/share/nginx/html;
          expires 1h;
        }

        location ~ \.php$ {
          proxy_pass         http://app_backend;
          proxy_http_version 1.1;
          proxy_set_header   Connection        "";
          proxy_set_header   Host              $host;
          proxy_set_header   X-Real-IP         $remote_addr;
          proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
          proxy_set_header   X-Forwarded-Proto $scheme;
          proxy_connect_timeout 10s;
          proxy_send_timeout    30s;
          proxy_read_timeout    30s;
        }

        location ~ /\. {
          deny all;
          return 404;
        }

        error_page 404 500 502 503 504 /index.html;

        access_log /var/log/nginx/access.log combined;
        error_log  /var/log/nginx/error.log  warn;
      }
    NGINX
  }
}

# -------------------------------------------------------------
#  ConfigMap 2 — MySQL schema.sql
#  Mounted at /docker-entrypoint-initdb.d/ — MySQL runs it
#  automatically on first boot to create all tables
# -------------------------------------------------------------
resource "kubernetes_config_map" "mysql_initdb" {
  metadata {
    name      = "mysql-initdb-config"
    namespace = var.namespace
    labels = {
      project    = var.project
      managed-by = "terraform"
    }
  }

  data = {
    "schema.sql" = <<-SQL
      CREATE DATABASE IF NOT EXISTS devopsdb
          CHARACTER SET utf8mb4
          COLLATE utf8mb4_unicode_ci;

      USE devopsdb;

      CREATE TABLE IF NOT EXISTS users (
          id               INT           AUTO_INCREMENT PRIMARY KEY,
          username         VARCHAR(80)   UNIQUE,
          first_name       VARCHAR(100)  NOT NULL,
          last_name        VARCHAR(100)  NOT NULL,
          email            VARCHAR(255)  NOT NULL UNIQUE,
          password_hash    VARCHAR(255)  NOT NULL,
          company          VARCHAR(150),
          role             ENUM('admin','developer','viewer') DEFAULT 'developer',
          mfa_enabled      TINYINT(1)    DEFAULT 0,
          mfa_secret       VARCHAR(64),
          remember_token   VARCHAR(64),
          login_attempts   TINYINT       DEFAULT 0,
          locked_until     DATETIME,
          last_login       DATETIME,
          created_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
          updated_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS messages (
          id               INT           AUTO_INCREMENT PRIMARY KEY,
          user_id          INT,
          first_name       VARCHAR(100)  NOT NULL,
          last_name        VARCHAR(100)  NOT NULL,
          email            VARCHAR(255)  NOT NULL,
          company          VARCHAR(150),
          cloud            ENUM('AWS','Google Cloud','Azure','Multi-Cloud','On-Premise / Hybrid','') DEFAULT '',
          message          TEXT          NOT NULL,
          status           ENUM('new','read','replied') DEFAULT 'new',
          created_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT fk_messages_user
              FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
      );

      CREATE TABLE IF NOT EXISTS login_logs (
          id               INT           AUTO_INCREMENT PRIMARY KEY,
          user_id          INT,
          ip_address       VARCHAR(45)   NOT NULL,
          user_agent       VARCHAR(255),
          status           ENUM('success','failed','locked') DEFAULT 'failed',
          created_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT fk_loginlogs_user
              FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
      );

      CREATE TABLE IF NOT EXISTS deployments (
          id               INT           AUTO_INCREMENT PRIMARY KEY,
          service_name     VARCHAR(150)  NOT NULL,
          version          VARCHAR(50)   NOT NULL,
          environment      ENUM('dev','staging','production') NOT NULL,
          status           ENUM('pending','running','success','failed') DEFAULT 'pending',
          deployed_by      VARCHAR(100),
          deployed_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
      );

      CREATE INDEX idx_users_email         ON users       (email);
      CREATE INDEX idx_users_username      ON users       (username);
      CREATE INDEX idx_messages_email      ON messages    (email);
      CREATE INDEX idx_messages_status     ON messages    (status);
      CREATE INDEX idx_messages_created    ON messages    (created_at);
      CREATE INDEX idx_loginlogs_user      ON login_logs  (user_id);
      CREATE INDEX idx_loginlogs_ip        ON login_logs  (ip_address);
      CREATE INDEX idx_deployments_env     ON deployments (environment);
      CREATE INDEX idx_deployments_status  ON deployments (status);

      INSERT IGNORE INTO users
          (username, first_name, last_name, email, password_hash, role, mfa_enabled)
      VALUES
          ('vickyadmin', 'Vicky', 'Admin', 'admin@vicky.cloud',
           '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
           'admin', 1);
    SQL
  }
}

# -------------------------------------------------------------
#  Outputs
# -------------------------------------------------------------
output "nginx_configmap_name" {
  description = "Name of the nginx ConfigMap"
  value       = kubernetes_config_map.nginx_conf.metadata[0].name
}

output "mysql_configmap_name" {
  description = "Name of the MySQL init ConfigMap"
  value       = kubernetes_config_map.mysql_initdb.metadata[0].name
}
