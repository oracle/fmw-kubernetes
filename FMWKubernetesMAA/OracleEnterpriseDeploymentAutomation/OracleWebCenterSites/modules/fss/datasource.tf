## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_ocid
  ad_number      = var.ad_number
}

# Get the Private IP of the mount target
data "oci_core_private_ip" "private_ip" {
  #Required
  private_ip_id = var.provision_mount_target ? oci_file_storage_mount_target.mount_target.0.private_ip_ids[0] : "na"
}
