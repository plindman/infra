# templates/terraform/main.tf

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.0"
    }
  }
  required_version = "~> 1.0"
}

provider "hcloud" {
  token = var.hcloud_token
}

# Create SSH keys for each server
resource "hcloud_ssh_key" "ssh_key" {
  for_each   = var.servers
  name       = "${each.key}-key"
  public_key = file("~/.ssh/${each.key}-key.pub")
}

# Create servers based on configuration
resource "hcloud_server" "servers" {
  for_each    = var.servers
  name        = each.key
  image       = each.value.image
  server_type = each.value.server_type
  location    = each.value.location
  ssh_keys    = [hcloud_ssh_key.ssh_key[each.key].name]

  labels = merge(
    each.value.labels,
    {
      "managed-by" = "terraform"
      "project"    = var.project_name
    }
  )
}

# Output the server IPs
output "server_ips" {
  description = "IP addresses of all servers"
  value       = { for name, server in hcloud_server.servers : name => server.ipv4_address }
}