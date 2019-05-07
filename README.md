# Rancher Kubernetes on KVM 
This repo contains scripts that will allow you to quickly deploy and test Rancher for POC.

Forked from https://github.com/rancher/quickstart

## Summary

The repository contains terraform code to stand up a single Rancher server instance with a 3 node cluster attached to it.

This terraform setup will:

- Create a libvirt guest running `rancher/rancher` version specified in `rancher_version`
- Create a custom cluster called `cluster_name`
- Start `count_agent_all_nodes` amount of droplets and add them to the custom cluster with all roles

Note: This project is customized for KVM servers running Openvswitch.  Installation of these dependencies can be
complex and is outside the scope of this project.

It has also been customized for use with the Terraform PowerDNS provider.
- https://www.terraform.io/docs/providers/powerdns/index.html

### Prereqs
KVM Server running Openvswitch

- https://github.com/mrlesmithjr/ansible-kvm
- https://docs.openvswitch.org/en/latest/intro/install/distributions/

PowerDNS Authoritative Server with API Access
- https://github.com/2stacks/terraform-powerdns

Terraform and the terraform-provider-libvirt

- https://www.terraform.io/downloads.html
- https://github.com/dmacvicar/terraform-provider-libvirt#installing

### How to use

- Clone this repository and go into the rancher-kvm folder
- Move the file `secret.auto.tfvars.example` to `secret.auto.tfvars` and edit.
- Run `terraform init`
- Run `terraform plan`
- Run `terraform apply -parallelism=1`

Note: Adding `-parallelism=1` to `terraform apply` is needed at this time due to an issue with libvirt failing to create 
multiple seed images in parallel.

When provisioning has finished you will be given the url to connect to the Rancher Server

### How to Remove

To remove the VM's that have been deployed run `terraform destroy --force`

### Support for terraform workspace
- Optionally create a new git branch with `git checkout -b dev`
- Create the new Terraform workspace with `terraform workspace new dev`
- Initialize the new environment with `terraform init`

At this point you should change variables as needed.  At a minimum you should probably change the `prefix` and `svr_name` 
variable to prevent resource collisions.  You can add those variables to `dev.tfvars` file and then run;

- `terraform plan -var-file=dev.tfvars`
- `terraform apply -var-file=dev.tfvars -parallelism=1`

### TODO
#### Optional adding nodes per role
- Start `count_agent_etcd_nodes` amount of droplets and add them to the custom cluster with etcd role
- Start `count_agent_controlplane_nodes` amount of droplets and add them to the custom cluster with controlplane role
- Start `count_agent_worker_nodes` amount of droplets and add them to the custom cluster with worker role

Note: Only adding nodes with all roles is currently supported.
