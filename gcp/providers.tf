terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  # One-time manual setup before first pipeline run:
  #   gsutil mb -l asia-south1 gs://cloudops-ai-tfstate-<your-project-id>
  #   gsutil versioning set on gs://cloudops-ai-tfstate-<your-project-id>
  backend "gcs" {
    bucket = "cloudops-ai-tfstate"   # override at init time with -backend-config if needed
    prefix = "cloudops-ai-gcp"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.cloudops_ai.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.cloudops_ai.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.cloudops_ai.endpoint}"
    cluster_ca_certificate = base64decode(google_container_cluster.cloudops_ai.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}
