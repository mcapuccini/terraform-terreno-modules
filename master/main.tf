variable name_prefix {}
variable image_name {}
variable flavor_name {}
variable keypair_name {}
variable network_name {}
variable floating_ip_pool {}
variable kubeadm_token {}

# Allocate floating IPs
resource "openstack_compute_floatingip_v2" "floating_ip" {
  pool = "${var.floating_ip_pool}"
}

# Bootstrap
resource "template_file" "bootstrap" {
  template = "${file("${path.module}/bootstrap.sh")}"
  vars {
    kubeadm_token = "${var.kubeadm_token}"
  }
}

# Create instances
resource "openstack_compute_instance_v2" "instance" {
  name="${var.name_prefix}-master"
  image_name = "${var.image_name}"
  flavor_name = "${var.flavor_name}"
  floating_ip = "${openstack_compute_floatingip_v2.floating_ip.address}"
  key_pair = "${var.keypair_name}"
  network {
    name = "${var.network_name}"
  }
  user_data = "${template_file.bootstrap.rendered}"
}

output "ip_address" {
  value = "${openstack_compute_instance_v2.instance.0.network.0.fixed_ip_v4}"
}
