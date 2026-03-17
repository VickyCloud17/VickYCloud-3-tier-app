# =============================================================
#  VickYCloud — Namespace Module
#  File: terraform/modules/namespace/main.tf
#  Creates all Kubernetes namespaces for the project
# =============================================================

variable "namespaces" {
  description = "List of namespace names to create"
  type        = list(string)
}

variable "project" {
  description = "Project label value"
  type        = string
}

# -------------------------------------------------------------
#  Create each namespace from the list
# -------------------------------------------------------------
resource "kubernetes_namespace" "this" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value
    labels = {
      project    = var.project
      managed-by = "terraform"
    }
  }
}

# -------------------------------------------------------------
#  Outputs
# -------------------------------------------------------------
output "namespace_names" {
  description = "List of created namespace names"
  value       = [for ns in kubernetes_namespace.this : ns.metadata[0].name]
}
