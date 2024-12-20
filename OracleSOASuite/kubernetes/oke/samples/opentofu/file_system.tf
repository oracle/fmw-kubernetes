/*
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

resource "oci_file_storage_file_system" "fmw_fs1" {
  #Required
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[1]["name"]
  compartment_id      = var.compartment_ocid
}

resource "oci_file_storage_file_system" "fmw_fs2" {
  #Required
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[1]["name"]
  compartment_id      = var.compartment_ocid
}

output "fmw1_fs_ocid" {
  value = oci_file_storage_file_system.fmw_fs1.id
}

output "fmw2_fs_ocid" {
  value = oci_file_storage_file_system.fmw_fs2.id
}
