variable "turbonomic_username" {
  type = string
}
variable "turbonomic_password" {
  type = string
  sensitive = true
}
variable "turbonomic_hostname" {
  type = string
}
variable "turbonomic_skipverify" {
  type = bool
}

variable "prefix" {
  type = string
  default = "turbo-test"
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
  sensitive = true
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}
