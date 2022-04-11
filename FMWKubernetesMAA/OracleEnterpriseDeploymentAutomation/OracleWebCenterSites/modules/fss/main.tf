## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "oci_file_storage_file_system" "fss" {
  count = var.provision_filesystem ? 1 : 0

  #Required
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid

  #Optional
  display_name = "Oracle WebCenter Sites File System"
  kms_key_id   = var.encryption_key_id
}

resource "oci_file_storage_mount_target" "mount_target" {
  count = var.provision_mount_target ? 1 : 0

  #Required
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  subnet_id           = var.subnet_id

  #Optional
  display_name = "Oracle WebCenter Sites Mount Target"
}

resource "oci_file_storage_export_set" "export_set" {
  count = var.provision_export ? 1 : 0

  #Required
  mount_target_id = var.provision_mount_target ? oci_file_storage_mount_target.mount_target.0.id : var.mount_target_ocid

  #Optional
  display_name = "Oracle WebCenter Sites Export Set"
}

resource "oci_file_storage_export" "export" {
  #Required
  count = var.provision_export ? 1 : 0
  export_set_id  = oci_file_storage_export_set.export_set.0.id
  file_system_id = var.provision_filesystem ? oci_file_storage_file_system.fss.0.id : var.filesystem_ocid
  path           = var.mount_path

  #Optional
  export_options {
    #Required
    source = var.source_cidr

    #Optional
    access                         = "READ_WRITE"
    anonymous_gid                  = null
    anonymous_uid                  = null
    identity_squash                = "NONE"
    require_privileged_source_port = false
  }
}
