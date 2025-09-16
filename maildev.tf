resource "digitalocean_droplet" "maildev" {
  image  = "debian-12-x64"
  name   = "maildev"
  region = "nyc3"
  size   = "s-1vcpu-1gb"
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
  EOF
}

resource "cloudflare_record" "maildev" {
  zone_id = var.cloudflare_zone_id
  name    = "proxmox-maildev"
  value   = digitalocean_droplet.maildev.ipv4_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "maildev_wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*.proxmox-maildev"
  value   = cloudflare_record.maildev.hostname
  type    = "CNAME"
  proxied = false
}
