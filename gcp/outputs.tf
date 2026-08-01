output "cluster_name" {
  value = google_container_cluster.cloudops_ai.name
}

output "artifact_registry_repo" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.cloudops_ai.repository_id}"
}
