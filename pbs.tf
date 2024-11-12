resource "digitalocean_droplet" "pbs" {
  image  = "debian-12-x64"
  name   = "pbs"
  region = "nyc3"
  size   = "s-4vcpu-8gb"
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
  name   = "pbs"
  region = "nyc3"
  size   = 60
}

resource "digitalocean_volume_attachment" "pbs" {
  droplet_id = digitalocean_droplet.pbs.id
  volume_id  = digitalocean_volume.pbs.id
}

resource "cloudflare_record" "pbs" {
  zone_id = var.cloudflare_zone_id
  name    = "pbs"
  value   = digitalocean_droplet.pbs.ipv4_address
  type    = "A"
  proxied = false
}
