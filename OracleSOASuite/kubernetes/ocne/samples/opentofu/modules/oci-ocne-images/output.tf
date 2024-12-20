# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

output "image_ocid" {
  value = data.oci_core_images.OLImageOCID.images[0].id
}

output "all_images" {
  value = data.oci_core_images.OLImageOCID.images
}
