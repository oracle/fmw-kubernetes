## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# File Storage Server IP address
output "server_ip" {
  value = var.provision_mount_target ? data.oci_core_private_ip.private_ip.ip_address : var.server_ip
}

output "path" {
  value = length(oci_file_storage_export.export) > 0 ? oci_file_storage_export.export[0].path : null
}

