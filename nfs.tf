resource "digitalocean_droplet" "nfs" {
  image  = "debian-12-x64"
  name   = "nfs"
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
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'  install -y nfs-kernel-server
    mkdir /nfs
    mkdir /nfs0
    mkdir /nfs1
    mkdir /nfs2
    mkdir /nfs3
    mkdir /nfs4
    mkdir /nfs5
    mkdir /nfs6
    mkdir /nfs7
    mkdir /nfs8
    mkdir /nfs9
    echo '/nfs *(rw,no_root_squash)' > /etc/exports
    echo '/nfs0 *(rw,no_root_squash)' >> /etc/exports
    echo '/nfs1 *(rw,no_root_squash)' >> /etc/exports
    echo '/nfs2 *(rw,no_root_squash)' >> /etc/exports
    echo '/nfs3 *(rw,no_root_squash)' >> /etc/exports
    echo '/nfs4 *(rw,no_root_squash)' >> /etc/exports
    echo '/nfs5 *(rw,no_root_squash)' >> /etc/exports
    echo '/nfs6 *(rw,no_root_squash)' >> /etc/exports
    echo '/nfs7 *(rw,no_root_squash)' >> /etc/exports
    echo '/nfs8 *(rw,no_root_squash)' >> /etc/exports
    echo '/nfs9 *(rw,no_root_squash)' >> /etc/exports
    systemctl restart nfs-kernel-server
  EOF
}

resource "cloudflare_record" "mfs" {
  zone_id = var.cloudflare_zone_id
  name    = "nfs"
  value   = digitalocean_droplet.nfs.ipv4_address
  type    = "A"
  proxied = false
}
