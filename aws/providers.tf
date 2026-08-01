terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
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
  #   aws s3api create-bucket --bucket cloudops-ai-tfstate-aws --region ap-south-1 \
  #       --create-bucket-configuration LocationConstraint=ap-south-1
  #   aws s3api put-bucket-versioning --bucket cloudops-ai-tfstate-aws --versioning-configuration Status=Enabled
  backend "s3" {
    bucket = "cloudops-ai-tfstate-aws"
    key    = "cloudops-ai-aws.tfstate"
    region = "ap-south-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.cloudops_ai.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.cloudops_ai.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cloudops_ai.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cloudops_ai.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cloudops_ai.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}
