variable "tenant_id" {
  description = "Azure tenant ID."
  type        = string
}

variable "project_name" {
  description = "Short project name for generated Azure resource names."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sql_admin_login" {
  description = "SQL administrator login name."
  type        = string
}

variable "sql_admin_password" {
  description = "Optional SQL administrator password."
  type        = string
  default     = null
  sensitive   = true
}

variable "database_name" {
  description = "Name of the sample database."
  type        = string
}

variable "sample_dataset" {
  description = "Named Microsoft sample to stage."
  type        = string
}

variable "sample_bacpac_uri" {
  description = "Optional override BACPAC URI."
  type        = string
  default     = null
}

variable "run_sample_import" {
  description = "Whether to execute the sample import workflow."
  type        = bool
}

variable "force_reimport" {
  description = "Whether to delete and recreate the sample database if it already exists."
  type        = bool
}

variable "import_edition" {
  description = "Azure SQL edition used during import."
  type        = string
}

variable "import_service_objective_name" {
  description = "Azure SQL service objective used during import."
  type        = string
}

variable "import_max_size_gb" {
  description = "Max size in GB used during import."
  type        = number
}

variable "allow_azure_services" {
  description = "Whether to create the Azure services firewall rule."
  type        = bool
}

variable "extra_firewall_rules" {
  description = "Additional SQL firewall rules."
  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
}

variable "tags" {
  description = "Azure resource tags."
  type        = map(string)
  default     = {}
}
