locals {
  base_tags = {
    workload    = "legacy-edw-bootstrap"
    managed_by  = "terraform"
    sample_data = var.sample_dataset
  }

  tags = merge(local.base_tags, var.tags)
}
