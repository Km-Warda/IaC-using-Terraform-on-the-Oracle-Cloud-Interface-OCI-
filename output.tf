#Instance outputs
output "instance_id" {
  value = oci_core_instance.compute_instance.id
}
output "instance_public_ip" {
  value = oci_core_instance.compute_instance.public_ip
}
output "instance_private_ip" {
  value = oci_core_instance.compute_instance.private_ip
}


#Storage outputs
output "block_volume_id" {
  value       = oci_core_volume.block_volume.id
}
output "block_volume_display_name" {
  value       = oci_core_volume.block_volume.display_name
}
output "block_volume_size" {
  value       = oci_core_volume.block_volume.size_in_gbs
}