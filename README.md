# terraform-proxmox-on-digitalocean

    2019 Ondrej Sika <ondrej@ondrejsika.com>
    https://github.com/ondrejsika/terraform-proxmox-on-digitalocean

## Run Server

```
terraform init
terraform plan
terraform apply -auto-approve
```

## Connect

```
ssh root@pve0node0.sikademo.com
ssh root@pve0node1.sikademo.com
ssh root@pve0node2.sikademo.com
```

or

- https://pve0node0.sikademo.com:8006
- https://pve0node1.sikademo.com:8006
- https://pve0node2.sikademo.com:8006

## Destroy Infrastructure

```
terraform destroy -auto-approve
```
