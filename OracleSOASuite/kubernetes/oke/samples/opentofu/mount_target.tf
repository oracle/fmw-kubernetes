/*
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/
resource "oci_file_storage_mount_target" "fmw_mount_target" {
  #Required
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[1]["name"]

  compartment_id = var.compartment_ocid
  subnet_id      = oci_core_subnet.oke-subnet-worker-2.id

  #Optional
  display_name = "${var.cluster_name}-mt"
}

#retrive the private IP of mount target
data "oci_core_private_ip" "fmw_mount_target_id" {
  private_ip_id = oci_file_storage_mount_target.fmw_mount_target.private_ip_ids[0]
}

output "fmw_mount_target_ip" {
  value = data.oci_core_private_ip.fmw_mount_target_id.ip_address
}
