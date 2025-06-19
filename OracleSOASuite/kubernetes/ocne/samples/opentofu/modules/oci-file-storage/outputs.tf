# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

output "m_mount_target_ip" {
  description = "The private IP of the mount target."
  value       = data.oci_core_private_ip.fmw_mount_target_id.ip_address
}

output "m_file_system1_ocid" {
  description = "The OCID of the file system."
  value       = oci_file_storage_file_system.fmw_fs1.id
}

output "m_file_system2_ocid" {
  description = "The OCID of the file system."
  value       = oci_file_storage_file_system.fmw_fs2.id
}

output "m_export_path1" {
  description = "The export path."
  value       = oci_file_storage_export.fmw_export1.path
}

output "m_export_path2" {
  description = "The export path."
  value       = oci_file_storage_export.fmw_export2.path
}
