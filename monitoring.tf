resource "digitalocean_droplet" "monitoring" {
  image  = "debian-12-x64"
  name   = "monitoring"
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
  EOF
}

resource "cloudflare_record" "monitoring" {
  zone_id = var.cloudflare_zone_id
  name    = "monitoring"
  value   = digitalocean_droplet.monitoring.ipv4_address
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "monitoring_wildcard2" {
  zone_id = var.cloudflare_zone_id
  name    = "*.monitoring"
  value   = cloudflare_record.monitoring.hostname
  type    = "CNAME"
  proxied = false
}
