/*
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

resource "oci_file_storage_export_set" "fmw_export_set" {
  # Required
  mount_target_id = oci_file_storage_mount_target.fmw_mount_target.id
}

