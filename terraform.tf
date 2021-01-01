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

variable "vm_count" {
  default = 3
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

resource "digitalocean_vpc" "vpc" {
  name     = "pve"
  region   = "nyc3"
  ip_range = "10.10.10.0/24"
}

resource "digitalocean_droplet" "pve" {
  count = var.vm_count

  image    = "debian-10-x64"
  name     = "pve${count.index}"
  region   = "nyc3"
  size     = "s-6vcpu-16gb"
  vpc_uuid = digitalocean_vpc.vpc.id
  ssh_keys = [
    data.digitalocean_ssh_key.ondrejsika.id
  ]
  connection {
    type = "ssh"
    user = "root"
    host = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${self.ipv4_address} ${self.name} ${self.name}-do.sikademo.com > /etc/hosts",
      "echo ${self.ipv4_address} ${self.name} ${self.name}-do.sikademo.com > /etc/cloud/templates/hosts.debian.tmpl",
      "echo 'deb http://download.proxmox.com/debian/pve buster pve-no-subscription' > /etc/apt/sources.list.d/pve-install-repo.list",
      "wget http://download.proxmox.com/debian/proxmox-ve-release-6.x.gpg -O /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg",
      "chmod +r /etc/apt/trusted.gpg.d/proxmox-ve-release-6.x.gpg",
      "apt update && DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' full-upgrade",
      "DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install proxmox-ve postfix open-iscsi",
      "apt remove -y os-prober",
    ]
  }
}

resource "digitalocean_volume" "ceph" {
  count = var.vm_count

  name   = "pve-ceph-${count.index}"
  region = "nyc3"
  size   = 60
}

resource "digitalocean_volume_attachment" "ceph" {
  count = var.vm_count

  droplet_id = digitalocean_droplet.pve[count.index].id
  volume_id  = digitalocean_volume.ceph[count.index].id
}

resource "cloudflare_record" "pve" {
  count = var.vm_count

  zone_id = var.cloudflare_zone_id
  name    = "pve${count.index}-do"
  value   = digitalocean_droplet.pve[count.index].ipv4_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "droplet_wildcard" {
  count = var.vm_count

  zone_id = var.cloudflare_zone_id
  name    = "*.pve${count.index}-do"
  value   = "pve${count.index}-do.sikademo.com"
  type    = "CNAME"
  proxied = false
}

output "ips" {
  value = [
    digitalocean_droplet.pve[0].ipv4_address,
    digitalocean_droplet.pve[1].ipv4_address,
    digitalocean_droplet.pve[2].ipv4_address,
  ]
}

output "domains" {
  value = [
    cloudflare_record.pve[0].hostname,
    cloudflare_record.pve[1].hostname,
    cloudflare_record.pve[2].hostname,
  ]
}
