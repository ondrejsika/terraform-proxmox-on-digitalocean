terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "2.15.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.3.0"
    }
  }
  required_version = ">= 0.13"
}
