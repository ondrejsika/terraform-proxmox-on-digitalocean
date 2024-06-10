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
  default = {
    size       = "s-4vcpu-8gb"
    node_count = 3
  }
  # See override.tf for live config
  clusters = {
    # "0"  = merge(local.default, { size = "s-4vcpu-8gb", node_count = 3 })
  }
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

resource "digitalocean_droplet" "nfs" {
  image  = "debian-12-x64"
  name   = "pve-nfs-shared"
  region = "nyc3"
  size   = "s-1vcpu-2gb"
  ssh_keys = [
    data.digitalocean_ssh_key.ondrejsika.id,
  ]
  user_data = <<-EOF
  #cloud-config
  ssh_pwauth: yes
  password: asdfasdf2020
  chpasswd:
    expire: false
  runcmd:
  - |
    curl -fsSL https://raw.githubusercontent.com/sikalabs/slu/master/install.sh | sudo sh
    apt-get install -y nfs-kernel-server
    mkdir /nfs
    echo '/nfs *(rw,no_root_squash)' > /etc/exports
    systemctl restart nfs-kernel-server
  EOF
}

resource "cloudflare_record" "nfs" {
  zone_id = var.cloudflare_zone_id
  name    = digitalocean_droplet.nfs.name
  value   = digitalocean_droplet.nfs.ipv4_address
  type    = "A"
  proxied = false
}

module "pve" {
  for_each = local.clusters

  source             = "./do-pve"
  prefix             = each.key
  cloudflare_zone_id = var.cloudflare_zone_id
  vpc_ip_range       = "10.250.${each.key}.0/24"
  ssh_key_id         = data.digitalocean_ssh_key.ondrejsika.id
  size               = each.value.size
  node_count         = each.value.node_count
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
