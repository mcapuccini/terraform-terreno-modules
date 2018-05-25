resource "openstack_compute_keypair_v2" "main" {
  name       = "${var.name_prefix}-keypair"
  public_key = "${file(var.public_key)}"
}
