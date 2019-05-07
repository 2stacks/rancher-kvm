# Configure the libvirt provider
provider "libvirt" {
  uri = "${var.libvirt_uri}"
}

# Configure the PowerDNS provider
provider "powerdns" {
  api_key    = "${var.pdns_api_key}"
  server_url = "${var.pdns_server_url}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/files/cloud_init.yml")}"

  vars {
    user_name          = "${var.user_name}"
    ssh_authorized-key = "${var.ssh_authorized-key}"
  }
}

data "template_file" "meta_data_svr" {
  template = "${file("${path.module}/files/meta_data.yml")}"

  vars {
    hostname = "${var.svr_name}"
  }
}

data "template_file" "meta_data_agent" {
  count    = "${var.count_agent_all_nodes}"
  template = "${file("${path.module}/files/meta_data.yml")}"

  vars {
    hostname = "${format("${var.prefix}-%02d", count.index + 1)}"
  }
}

data "template_file" "network_config" {
  template = "${file("${path.module}/files/network_config.yml")}"
}

data "template_file" "xslt_config" {
  template = "${file("${path.module}/files/override.xsl")}"

  vars {
    network    = "${var.network}"
    port_group = "${var.port_group}"
  }
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu-qcow2" {
  name   = "${var.prefix}-ubuntu.qcow2"
  pool   = "${var.libvirt_volume_pool}"
  source = "${var.libvirt_volume_source}"
  format = "qcow2"
}

resource "libvirt_volume" "rancher_server" {
  name           = "${var.prefix}-svr.qcow2"
  base_volume_id = "${libvirt_volume.ubuntu-qcow2.id}"
  pool           = "${var.libvirt_volume_pool}"
  size           = "${var.libvirt_volume_svr_size}"
}

resource "libvirt_volume" "rancher_agent" {
  count          = "${var.count_agent_all_nodes}"
  name           = "${format("${var.prefix}-%02d.qcow2", count.index + 1)}"
  base_volume_id = "${libvirt_volume.ubuntu-qcow2.id}"
  pool           = "${var.libvirt_volume_pool}"
  size           = "${var.libvirt_volume_node_size}"
}

# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit_svr" {
  name           = "${var.prefix}-svr-seed.iso"
  pool           = "${var.libvirt_volume_pool}"
  user_data      = "${data.template_file.user_data.rendered}"
  meta_data      = "${data.template_file.meta_data_svr.rendered}"
#  network_config = "${data.template_file.network_config.rendered}"

}

resource "libvirt_cloudinit_disk" "commoninit_agent" {
  count          = "${var.count_agent_all_nodes}"
  name           = "${format("${var.prefix}-seed-%01d.iso", count.index + 1)}"
  pool           = "${var.libvirt_volume_pool}"
  user_data      = "${data.template_file.user_data.rendered}"
  meta_data      = "${data.template_file.meta_data_agent.*.rendered[count.index]}"
#  network_config = "${data.template_file.network_config.rendered}"
}

resource "libvirt_domain" "rancherserver" {
  count      = 1
  name       = "${var.svr_name}"
  memory     = "${var.svr_memory}"
  vcpu       = "${var.svr_vcpu}"
  qemu_agent = true
  cloudinit  = "${libvirt_cloudinit_disk.commoninit_svr.id}"
  disk {
    volume_id = "${libvirt_volume.rancher_server.id}"
  }
  network_interface {
    network_name = "${var.network}"
    wait_for_lease = true
  }
  # used to support features the provider does not allow to set from the schema
  xml {
    xslt = "${data.template_file.xslt_config.rendered}"
  }
  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  connection {
    type        = "ssh"
    private_key = "${file("~/.ssh/do_rsa")}"
    user        = "${var.user_name}"
    timeout     = "2m"
  }

  provisioner "file" {
    content     = "${data.template_file.bootstrap_server.rendered}"
    destination = "/tmp/bootstrap_server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap_server.sh",
      "sudo /tmp/bootstrap_server.sh",
      "rm /tmp/bootstrap_server.sh",
    ]
  }
}

resource "libvirt_domain" "rancheragent" {
  count      = "${var.count_agent_all_nodes}"
  name       = "${format("${var.prefix}-%02d", count.index + 1)}"
  memory     = "${var.node_memory}"
  vcpu       = "${var.node_vcpu}"
  qemu_agent = true
  cloudinit  = "${element(libvirt_cloudinit_disk.commoninit_agent.*.id, count.index)}"
  disk {
    volume_id = "${element(libvirt_volume.rancher_agent.*.id, count.index)}"
  }
  network_interface {
    network_name = "${var.network}"
    wait_for_lease = true
  }
  # used to support features the provider does not allow to set from the schema
  xml {
    xslt = "${data.template_file.xslt_config.rendered}"
  }
  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  connection {
    type        = "ssh"
    private_key = "${file("~/.ssh/do_rsa")}"
    user        = "${var.user_name}"
    timeout     = "2m"
  }

  provisioner "file" {
    content     = "${data.template_file.bootstrap_agent.rendered}"
    destination = "/tmp/bootstrap_agent.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap_agent.sh",
      "sudo /tmp/bootstrap_agent.sh",
      "sudo rm -rf /tmp/bootstrap_server.sh",
    ]
  }

  depends_on = ["powerdns_record.rancher"]
}

data "template_file" "bootstrap_server" {
  template = "${file("${path.module}/files/userdata_server")}"

  vars {
    admin_password        = "${var.admin_password}"
    cluster_name          = "${var.cluster_name}"
    docker_version_server = "${var.docker_version_server}"
    rancher_version       = "${var.rancher_version}"
    svr_fqdn              = "${var.svr_name}.${var.domain}"
    use_letsencyrpt       = "${var.use_letsencyrpt}"
  }
}

data "template_file" "bootstrap_agent" {
  template = "${file("${path.module}/files/userdata_agent")}"

  vars {
    admin_password       = "${var.admin_password}"
    cluster_name         = "${var.cluster_name}"
    docker_version_agent = "${var.docker_version_agent}"
    rancher_version      = "${var.rancher_version}"
    server_address       = "${libvirt_domain.rancherserver.network_interface.0.addresses.0}"
    svr_fqdn             = "${var.svr_name}.${var.domain}"
    use_letsencyrpt      = "${var.use_letsencyrpt}"
  }
}

resource "powerdns_record" "rancher" {
  zone    = "${var.domain}."
  name    = "${var.svr_name}.${var.domain}."
  type    = "A"
  ttl     = 300
  records = ["${element(libvirt_domain.rancherserver.network_interface.0.addresses, 0)}"]
}

locals {
  agent_ips  = "${flatten(libvirt_domain.rancheragent.*.network_interface.0.addresses)}"
}

resource "powerdns_record" "agent" {
  count   = "${var.count_agent_all_nodes}"
  zone    = "${var.domain}."
  name    = "${format("${var.prefix}-%02d", count.index + 1)}.${var.domain}."
  type    = "A"
  ttl     = 300
  records = ["${element(local.agent_ips, count.index)}"]
}

output "rancher-url" {
  value = ["https://${libvirt_domain.rancherserver.network_interface.0.addresses.0}"]
}