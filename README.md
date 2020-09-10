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
ssh root@pve1-do.sikademo.com
ssh root@pve2-do.sikademo.com
ssh root@pve3-do.sikademo.com
```

## Destroy Infrastructure

```
terraform destroy -auto-approve
```
