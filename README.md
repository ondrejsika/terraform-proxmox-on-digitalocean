# Proxmox (PVE) on Digital Ocean managed by Terraform

    2019 Ondrej Sika <ondrej@ondrejsika.com>
    https://github.com/ondrejsika/terraform-do-proxmox-example

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
