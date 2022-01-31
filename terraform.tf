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

variable "pve_count" {
  default = 1
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
  count = var.pve_count

  source             = "./do-pve"
  prefix             = count.index
  cloudflare_zone_id = var.cloudflare_zone_id
  vpc_ip_range       = "10.250.${count.index}.0/24"
  ssh_key_id         = data.digitalocean_ssh_key.ondrejsika.id
  size               = "16gb"
}

output "pve" {
  value = module.pve
}
