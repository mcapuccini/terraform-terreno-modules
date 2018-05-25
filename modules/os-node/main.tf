resource "openstack_compute_instance_v2" "instance" {
  count       = "${var.count}"
  name        = "${var.name_prefix}-${format("%03d", count.index)}"
  image_name  = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  flavor_id   = "${var.flavor_id}"
  key_pair    = "${var.keypair_name}"

  network {
    name = "${var.network_name}"
  }

  security_groups = ["${var.secgroup_name}"]
  user_data       = "${file(var.bootstrap_script)}"
}

# Allocate floating IPs (optional)
resource "openstack_compute_floatingip_v2" "floating_ip" {
  count = "${var.assign_floating_ip ? var.count : 0}"
  pool  = "${var.floating_ip_pool}"
}

# Associate floating IPs (if created)
resource "openstack_compute_floatingip_associate_v2" "floating_ip" {
  count       = "${var.assign_floating_ip ? var.count : 0}"
  floating_ip = "${element(openstack_compute_floatingip_v2.floating_ip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.instance.*.id, count.index)}"
}

# Create extra disk (optional)
resource "openstack_blockstorage_volume_v2" "extra_disk" {
  count = "${var.extra_disk_size > 0 ? var.count : 0}"
  name  = "${var.name_prefix}-extra-${format("%03d", count.index)}"
  size  = "${var.extra_disk_size}"
}

# Attach extra disk (if created) Disk attaches as /dev/...
resource "openstack_compute_volume_attach_v2" "attach_extra_disk" {
  count       = "${var.extra_disk_size > 0 ? var.count : 0}"
  instance_id = "${element(openstack_compute_instance_v2.instance.*.id, count.index)}"
  volume_id   = "${element(openstack_blockstorage_volume_v2.extra_disk.*.id, count.index)}"
}

# Generate a list of IP numbers with public IP first if available
data "null_data_source" "access_ip" {
  count = "${var.count}"

  inputs = {
    # Need to attach empty element to list since it can be empty (terraform workaround issues/11210)
    ip = "${ var.assign_floating_ip == true ?  element(concat(openstack_compute_floatingip_v2.floating_ip.*.address, list("")), count.index) : element(openstack_compute_instance_v2.instance.*.network.0.fixed_ip_v4, count.index) }"
  }
}
