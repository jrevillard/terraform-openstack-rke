resource "openstack_compute_instance_v2" "instance" {
  depends_on  = [var.node_depends_on]
  count       = var.nodes_count
  name        = "${var.name_prefix}-${format("%03d", count.index + 1)}"
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = var.keypair_name

  network {
    name = var.network_name
  }

  security_groups = [var.secgroup_name]
}

resource "openstack_networking_floatingip_v2" "floating_ip" {
  count = var.assign_floating_ip ? var.nodes_count : 0
  pool  = var.floating_ip_pool
}

resource "openstack_compute_floatingip_associate_v2" "associate_floating_ip" {
  count       = var.assign_floating_ip ? var.nodes_count : 0
  floating_ip = openstack_networking_floatingip_v2.floating_ip[count.index].address
  instance_id = openstack_compute_instance_v2.instance[count.index].id
}

data "null_data_source" "nodes" {
  count       = var.nodes_count
  inputs = {
    name        = openstack_compute_instance_v2.instance[count.index].name
    internal_ip = openstack_compute_instance_v2.instance[count.index].access_ip_v4
    floating_ip = openstack_networking_floatingip_v2.floating_ip != [] ? openstack_networking_floatingip_v2.floating_ip[count.index].address : ""
  }
}
