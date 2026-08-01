variable "project_id" {
  description = "GCP project id, e.g. cloudops-ai-forge"
  type        = string
}

variable "region" {
  default = "asia-south1"
}

variable "cluster_name" {
  default = "cloudops-cluster2"
}
