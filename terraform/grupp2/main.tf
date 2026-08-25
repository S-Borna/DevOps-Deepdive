terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

# Gruppens delade publika SSH-nyckel, registrerad hos Hetzner en gång.
# (Den privata nyckeln, som bevisar att det är DU, ligger bara på din egen
# maskin i ~/.ssh/grupp2 — den skickas aldrig hit.)
resource "hcloud_ssh_key" "grupp2" {
  name       = "grupp2"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH5KzpRXZ+vPVg+Ideb1FN/YykJrp97+Ogrq5tYOVFCq grupp2"
}

# Själva servern. server_type = minsta i gruppens prioritetsordning (cx23).
resource "hcloud_server" "said" {
  name        = "grupp2-said"
  server_type = "cx23"
  image       = "ubuntu-24.04"
  location    = "nbg1"
  ssh_keys    = [hcloud_ssh_key.grupp2.id]
}

output "ip" {
  value = hcloud_server.said.ipv4_address
}
