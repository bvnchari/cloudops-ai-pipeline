# ============================================================
# main.tf — GKE Autopilot + Artifact Registry + monitoring
# Mirrors your working cloudops-cluster2 setup, made reusable.
# ============================================================

resource "google_container_cluster" "cloudops_ai" {
  name             = var.cluster_name
  location         = var.region
  enable_autopilot = true

  # Autopilot manages node pools itself — no separate node pool resource needed
  deletion_protection = false

  release_channel {
    channel = "REGULAR"
  }
}

# Holds whatever app image the pipeline builds — same role as ACR on Azure
resource "google_artifact_registry_repository" "cloudops_ai" {
  location      = var.region
  repository_id = "cloudops-ai"
  format        = "DOCKER"
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
  depends_on = [google_container_cluster.cloudops_ai]
}

resource "kubernetes_namespace" "cloudops_ai" {
  metadata {
    name = "cloudops-ai"
  }
  depends_on = [google_container_cluster.cloudops_ai]
}

# kube-prometheus-stack via Helm — node-exporter disabled (Autopilot blocks
# it via Pod Security Standards, per your earlier runbook notes)
resource "helm_release" "monitoring" {
  name       = "monitoring"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  timeout    = 600

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "prometheus.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "prometheus-node-exporter.enabled"
    value = "false"
  }
}
