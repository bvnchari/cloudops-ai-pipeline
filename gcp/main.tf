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

# GCP IAM roles (e.g. roles/editor) do NOT automatically grant Kubernetes RBAC
# permissions inside the cluster — GKE authenticates the IAM identity, but
# authorization for cluster-scoped objects (like ClusterRoles, which Helm's
# kube-prometheus-stack needs for its admission webhook) requires an explicit
# Kubernetes RBAC binding. This grants the pipeline's service account
# cluster-admin at the Kubernetes layer.
# NOTE: the GHA service account's cluster-admin RBAC binding is created
# manually, once, as a project-owner bootstrap step — NOT managed here.
# Terraform's own identity can't grant itself permissions it doesn't yet
# have (a ClusterRoleBinding can't create the ClusterRoleBinding that
# grants the right to create ClusterRoleBindings). Run once per cluster:
#   kubectl create clusterrolebinding gha-cluster-admin \
#     --clusterrole=cluster-admin \
#     --user=cloudops-ai-gha@<project-id>.iam.gserviceaccount.com

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
  # GKE Autopilot protects kube-system as a managed namespace — these
  # components try to create Services there to scrape the control plane,
  # which Autopilot blocks outright (Google manages the control plane
  # separately). Standard/documented fix for kube-prometheus-stack on GKE.
  set {
    name  = "kubeControllerManager.enabled"
    value = "false"
  }
  set {
    name  = "kubeScheduler.enabled"
    value = "false"
  }
  set {
    name  = "kubeProxy.enabled"
    value = "false"
  }
  set {
    name  = "kubeEtcd.enabled"
    value = "false"
  }
}
