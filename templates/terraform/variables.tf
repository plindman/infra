# templates/terraform/variables.tf

variable "hcloud_token" {
  type        = string
  description = "API token for Hetzner Cloud"
  sensitive   = true
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "servers" {
  type = map(object({
    server_type = string
    image       = string
    location    = string
    labels      = map(string)
  }))
  description = "Map of server configurations"
}