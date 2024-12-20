# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "oci_file_storage_mount_target" "fmw_mount_target" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
  subnet_id           = var.subnet_id

  display_name = "${var.cluster_name}-mt"
}

data "oci_core_private_ip" "fmw_mount_target_id" {
  private_ip_id = oci_file_storage_mount_target.fmw_mount_target.private_ip_ids[0]
}

resource "oci_file_storage_file_system" "fmw_fs1" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
}

resource "oci_file_storage_file_system" "fmw_fs2" {
  #Required
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
}

resource "oci_file_storage_export_set" "fmw_export_set" {
  mount_target_id = oci_file_storage_mount_target.fmw_mount_target.id
}

resource "oci_file_storage_export" "fmw_export1" {
  export_set_id  = oci_file_storage_export_set.fmw_export_set.id
  file_system_id = oci_file_storage_file_system.fmw_fs1.id
  path           = var.export_path1
}

resource "oci_file_storage_export" "fmw_export2" {
  #Required
  export_set_id  = oci_file_storage_export_set.fmw_export_set.id
  file_system_id = oci_file_storage_file_system.fmw_fs2.id
  path           = var.export_path2
}

