## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

output "adb_database" {
  value = {
    adb_database_id    = var.provision_adb ? oci_database_autonomous_database.adb_database[0].id : ""
    connection_urls    = var.provision_adb ? oci_database_autonomous_database.adb_database[0].connection_urls : ""
    adb_wallet_content = var.provision_adb ? oci_database_autonomous_database_wallet.adb_database_wallet[0].content : ""
    adb_nsg_id         = (!var.use_existing_vcn && var.adb_private_endpoint) ? oci_core_network_security_group.adb_nsg[0].id : var.adb_nsg_id
  }
}



