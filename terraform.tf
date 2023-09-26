terraform {
  backend "remote" {
    organization = "sikademo"

    workspaces {
      name = "do-pve"
    }
  }
}


variable "do_token" {}
variable "cloudflare_api_token" {}
variable "cloudflare_zone_id" {
  default = "f2c00168a7ecd694bb1ba017b332c019"
}

locals {
  # See override.tf for live config
  clusters = [
    # "0",
  ]
}

provider "digitalocean" {
  token = var.do_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "digitalocean_ssh_key" "ondrejsika" {
  name = "ondrejsika"
}

module "pve" {
  for_each = toset(local.clusters)

  source             = "./do-pve"
  prefix             = each.key
  cloudflare_zone_id = var.cloudflare_zone_id
  vpc_ip_range       = "10.250.${each.key}.0/24"
  ssh_key_id         = data.digitalocean_ssh_key.ondrejsika.id
  size               = "16gb"
}

output "pve" {
  value = module.pve
}

output "price_per_hour" {
  value = format("%.2f", sum([for el in module.pve : el.price_per_hour]))
}

output "price_per_day" {
  value = format("%.2f", sum([for el in module.pve : el.price_per_day]))
}

output "price_per_month" {
  value = format("%.2f", sum([for el in module.pve : el.price_per_month]))
}
