# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# Gets the OCID of the OS image to use
data "oci_core_images" "OLImageOCID" {
  compartment_id           = var.compartment_id
  operating_system         = var.os
  operating_system_version = var.os_version
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  # filter to avoid Oracle Linux images for GPU
  filter {
    name   = "display_name"
    #https://docs.oracle.com/en-us/iaas/images/oraclelinux-7x/index.htm
    values = ["^${replace(var.os, " ", "-")}-${var.os_version}\\.?[0-9]*-[0-9]{4}\\.[0-9]{2}\\.[0-9]{2}-[0-9]+$"]
    regex  = true
  }
}
