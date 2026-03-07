variable "tenant_id" {
  description = "Azure tenant ID that owns the target deployment subscription."
  type        = string
}

variable "subscription_id" {
  description = "Optional Azure subscription ID override. If omitted, use the current Azure CLI / ARM subscription context."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Short project name used in generated Azure resource names."
  type        = string
  default     = "legacyedw"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus2"
}

variable "sql_admin_login" {
  description = "SQL administrator login name created on the Azure SQL logical server."
  type        = string
  default     = "sqlbootstrapadmin"
}

variable "sql_admin_password" {
  description = "Optional SQL administrator password. Leave null to auto-generate one."
  type        = string
  default     = null
  sensitive   = true
}

variable "database_name" {
  description = "Name of the imported sample database."
  type        = string
  default     = "AdventureWorksDW"
}

variable "sample_dataset" {
  description = "Named Microsoft sample to stage and import."
  type        = string
  default     = "AdventureWorksDW2022"

  validation {
    condition     = contains(["AdventureWorksDW2022", "WideWorldImportersDW"], var.sample_dataset)
    error_message = "sample_dataset must be AdventureWorksDW2022 or WideWorldImportersDW."
  }
}

variable "sample_bacpac_uri" {
  description = "Optional override for the BACPAC source URI. When set, it overrides sample_dataset."
  type        = string
  default     = null
}

variable "run_sample_import" {
  description = "Whether to run az sql db import during terraform apply."
  type        = bool
  default     = true
}

variable "force_reimport" {
  description = "Whether to delete and recreate the database if it already exists."
  type        = bool
  default     = false
}

variable "import_edition" {
  description = "Edition passed to az sql db import."
  type        = string
  default     = "Standard"
}

variable "import_service_objective_name" {
  description = "Service objective passed to az sql db import."
  type        = string
  default     = "S3"
}

variable "import_max_size_gb" {
  description = "Maximum database size, in GB, passed to az sql db import."
  type        = number
  default     = 20
}

variable "allow_azure_services" {
  description = "Whether to add the standard 0.0.0.0 Azure services firewall rule on the SQL logical server."
  type        = bool
  default     = true
}

variable "extra_firewall_rules" {
  description = "Optional extra SQL firewall rules to allow specific client IP ranges."
  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
  default = []
}

variable "tags" {
  description = "Additional Azure resource tags."
  type        = map(string)
  default     = {}
}
