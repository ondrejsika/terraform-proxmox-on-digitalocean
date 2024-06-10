resource "digitalocean_droplet" "nfs" {
  image  = "debian-12-x64"
  name   = "pve${var.prefix}nfs"
  region = "nyc3"
  size   = "s-1vcpu-2gb"
  ssh_keys = [
    var.ssh_key_id,
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
