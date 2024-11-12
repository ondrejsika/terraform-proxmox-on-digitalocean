variable "prefix" {}
variable "ssh_key_id" {}
variable "cloudflare_zone_id" {}
variable "vpc_ip_range" {
  default = "10.10.10.0/24"
}
variable "node_count" {
  default = 3
}
variable "region" {
  default = "nyc3"
}
variable "size" {
  default = "s-4vcpu-8gb"
}

resource "digitalocean_vpc" "vpc" {
  name     = "pve${var.prefix}"
  region   = var.region
  ip_range = var.vpc_ip_range
}

resource "digitalocean_droplet" "pve" {
  count = var.node_count

  image    = "debian-12-x64"
  name     = "pve${var.prefix}node${count.index}"
  region   = var.region
  size     = var.size
  vpc_uuid = digitalocean_vpc.vpc.id
  ssh_keys = [
    var.ssh_key_id
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
    echo $(slu ip) pve${var.prefix}node${count.index} pve${var.prefix}node${count.index}.sikademo.com > /etc/hosts
    echo $(slu ip) pve${var.prefix}node${count.index} pve${var.prefix}node${count.index}.sikademo.com > /etc/cloud/templates/hosts.debian.tmpl
    echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
    apt update
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' full-upgrade
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install pve-kernel-6.2
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install postfix open-iscsi
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install ifupdown2
    rm /tmp/.ifupdown2-first-install
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -f
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install proxmox-ve
    apt remove -y os-prober
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'  install -y nfs-kernel-server
    mkdir /nfs
    echo '/nfs *(rw,no_root_squash)' > /etc/exports
    systemctl restart nfs-kernel-server
  EOF
}

resource "digitalocean_volume" "ceph" {
  count = var.node_count

  name   = "pve${var.prefix}node${count.index}-ceph"
  region = var.region
  size   = 60
}

resource "digitalocean_volume_attachment" "ceph" {
  count = var.node_count

  droplet_id = digitalocean_droplet.pve[count.index].id
  volume_id  = digitalocean_volume.ceph[count.index].id
}

resource "digitalocean_volume" "zfs" {
  count = var.node_count

  name   = "pve${var.prefix}node${count.index}-zfs"
  region = var.region
  size   = 60
}

resource "digitalocean_volume_attachment" "zfs" {
  count = var.node_count

  droplet_id = digitalocean_droplet.pve[count.index].id
  volume_id  = digitalocean_volume.zfs[count.index].id
}

resource "cloudflare_record" "pve" {
  count = var.node_count

  zone_id = var.cloudflare_zone_id
  name    = "pve${var.prefix}node${count.index}"
  value   = digitalocean_droplet.pve[count.index].ipv4_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "droplet_wildcard" {
  count = var.node_count

  zone_id = var.cloudflare_zone_id
  name    = "*.pve${var.prefix}node${count.index}"
  value   = cloudflare_record.pve[count.index].hostname
  type    = "CNAME"
  proxied = false
}

resource "cloudflare_record" "nfs" {
  count = var.node_count

  zone_id = var.cloudflare_zone_id
  name    = "nfs${var.prefix}"
  value   = digitalocean_droplet.pve[0].ipv4_address
  type    = "A"
  proxied = false
}

output "public_ips" {
  value = digitalocean_droplet.pve.*.ipv4_address

}

output "private_ips" {
  value = digitalocean_droplet.pve.*.ipv4_address_private
}

output "domains" {
  value = cloudflare_record.pve.*.hostname

}

output "price_per_hour" {
  value = sum(digitalocean_droplet.pve.*.price_hourly)
}

output "price_per_day" {
  value = sum(digitalocean_droplet.pve.*.price_hourly) * 24
}

output "price_per_month" {
  value = sum(digitalocean_droplet.pve.*.price_monthly)
}
