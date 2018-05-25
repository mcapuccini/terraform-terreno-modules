output "extra_disk_device" {
  description = "List of attached block storage device paths (one per node)"
  value       = ["${openstack_compute_volume_attach_v2.attach_extra_disk.*.device}"]
}

output "local_ip_v4" {
  description = "List of local IPv4 addresses (one per node)"
  value       = ["${openstack_compute_instance_v2.instance.*.network.0.fixed_ip_v4}"]
}

output "public_ip" {
  description = "List of floating IP addresses (one per node)"
  value       = ["${data.null_data_source.access_ip.*.inputs.ip}"]
}

output "hostnames" {
  description = "List of hostnames (one per node)"
  value       = ["${openstack_compute_instance_v2.instance.*.name}"]
}
