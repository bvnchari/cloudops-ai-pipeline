# ============================================================
# backend.tf — Remote state in Azure Storage
# One-time manual setup (run these BEFORE first pipeline run):
#
#   az group create -n cloudops-ai-tfstate-rg -l centralindia
#   az storage account create -n cloudopsaitfstate -g cloudops-ai-tfstate-rg \
#       -l centralindia --sku Standard_LRS
#   az storage container create -n tfstate --account-name cloudopsaitfstate
#
# This keeps state OUTSIDE the AKS cluster you're about to destroy,
# so "terraform destroy" always knows what it created last time —
# even across GitHub Actions runs on different runners.
# ============================================================

terraform {
  backend "azurerm" {
    resource_group_name = "cloudops-ai-tfstate-rg"
    storage_account_name = "cloudopsaitfstate"
    container_name       = "tfstate"
    key                   = "cloudops-ai-azure.tfstate"
  }
}
