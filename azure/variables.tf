variable "location" {
  default = "centralindia"
}

variable "rg_name" {
  default = "cloudops-ai-rg"
}

variable "aks_name" {
  default = "cloudops-ai-aks"
}

variable "acr_name" {
  # Must be globally unique, alphanumeric only, 5-50 chars
  default = "cloudopsaiacr"
}

variable "node_count" {
  default = 2
}

variable "node_vm_size" {
  default = "Standard_B2s_v2"
}
