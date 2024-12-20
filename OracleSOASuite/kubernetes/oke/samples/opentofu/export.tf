/*
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/
resource "oci_file_storage_export" "fmw_export1" {
  #Required
  export_set_id  = oci_file_storage_export_set.fmw_export_set.id
  file_system_id = oci_file_storage_file_system.fmw_fs1.id
  path           = "/fmw1"
}

resource "oci_file_storage_export" "fmw_export2" {
  #Required
  export_set_id  = oci_file_storage_export_set.fmw_export_set.id
  file_system_id = oci_file_storage_file_system.fmw_fs2.id
  path           = "/fmw2"
}

output "fmw1_export_path" {
  value = oci_file_storage_export.fmw_export1.path
}

output "fmw2_export_path" {
  value = oci_file_storage_export.fmw_export2.path
}

