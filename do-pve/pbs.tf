resource "digitalocean_droplet" "pbs" {
  image    = "debian-12-x64"
  name     = "pve${var.prefix}pbs"
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
    echo "deb [arch=amd64] http://download.proxmox.com/debian/pbs bookworm pbs-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list
    wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
    apt update
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' full-upgrade
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install pve-kernel-6.2
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install postfix open-iscsi
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install ifupdown2
    rm /tmp/.ifupdown2-first-install
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -f
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install proxmox-backup-server
    apt remove -y os-prober
  EOF
}

resource "digitalocean_volume" "pbs" {
  count = 4

  name   = "pve${var.prefix}pbs-${count.index}"
  region = var.region
  size   = 60
}

resource "digitalocean_volume_attachment" "pbs" {
  count = 4

  droplet_id = digitalocean_droplet.pbs.id
  volume_id  = digitalocean_volume.pbs[count.index].id
}

resource "cloudflare_record" "pbs" {
  zone_id = var.cloudflare_zone_id
  name    = "pve${var.prefix}pbs"
  value   = digitalocean_droplet.pbs.ipv4_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "pbs_wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*.pve${var.prefix}pbs"
  value   = cloudflare_record.pbs.hostname
  type    = "CNAME"
  proxied = false
}
