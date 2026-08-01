output "cluster_name" {
  value = aws_eks_cluster.cloudops_ai.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.cloudops_ai.repository_url
}
