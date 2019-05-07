# Rancher Variables
variable "use_letsencyrpt" {
  description = "Enable Letsencrpt vs self signed cert for rancher server"
  default = "false"
}

variable "rancher_version" {
  description = "rancher/rancher image tag to use"
  default = "latest"
}

variable "count_agent_all_nodes" {
  description = "Count of agent nodes with role all"
  default = 1
}

variable "count_agent_etcd_nodes" {
  description = "Count of agent nodes with role etcd"
  default = 0
}

variable "count_agent_controlplane_nodes" {
  description = "Count of agent nodes with role controlplane"
  default = 0
}

variable "count_agent_worker_nodes" {
  description = "Count of agent nodes with role worker"
  default = 0
}

variable "admin_password" {
  description = "Admin password to access Rancher"
}

variable "cluster_name" {
  description = "Rancher cluster name"
  default = "default"
}

variable "docker_version_server" {
  description = "Docker version of host running `rancher/rancher`"
  default = "17.03"
}

variable "docker_version_agent" {
  description = "Docker version of host being added to a cluster (running `rancher/rancher-agent`)"
  default = "17.03"
}

# Power DNS Variables
variable "pdns_api_key" {
  description = "Power DNS API Key"
}

variable "pdns_server_url" {
  description = "Power DNS API Endpoint"
  default = "http://127.0.0.1:8081/"
}

# Libvirt Variables
variable "libvirt_uri" {
  description = "URI of server running libvirtd"
  default = "qemu:///system"
}

variable "prefix" {
  description = "Resources will be prefixed with this to avoid clashing names"
  default = "k8s"
}

variable "svr_name" {
  description = "hostname for Rancher Server"
  default = "rancher"
}

variable "domain" {
  description = "Domain name for servers"
  default = "xip.io"
}

variable "user_name" {
  description = "OS username"
  default = "ubuntu"
}
variable "ssh_authorized-key" {
  description = "SSH public key used for os login"
}

variable "libvirt_volume_source" {
  description = "Volume Image Source"
  default = "https://cloud-images.ubuntu.com/releases/xenial/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
}

variable "libvirt_volume_pool" {
  description = "Volume Storage Pool"
  default = "default"
}

variable "libvirt_volume_svr_size" {
  description = "Volume Size in Bytes (Default is 10G)"
  default = 10737418240
}

variable "libvirt_volume_node_size" {
  description = "Volume Size in Bytes (Default is 10G)"
  default = 10737418240
}

variable "svr_memory" {
  default = 4096
}

variable "node_memory" {
  default = 4096
}

variable "svr_vcpu" {
  default = 1
}

variable "node_vcpu" {
  default = 2
}

variable "network" {
  description = "Name of Libvirt Network"
  default = "default"
}

variable "port_group" {
  description = "Namve of OVS Port Group"
  default = "default"
}