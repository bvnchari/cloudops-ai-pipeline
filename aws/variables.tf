variable "aws_region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "cloudops-ai-eks"
}

variable "k8s_version" {
  default = "1.31"
}

variable "node_count" {
  default = 2
}

variable "node_instance_type" {
  default = "t3.medium"
}
