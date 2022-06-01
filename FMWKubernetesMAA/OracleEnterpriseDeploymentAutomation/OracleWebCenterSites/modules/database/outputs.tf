## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

output "jdbc_connection_url" {
  value = var.provision_database ? "${oci_database_db_system.db_system.0.hostname}.${oci_database_db_system.db_system.0.domain}:1521/${var.pdb_name}.${oci_database_db_system.db_system.0.domain}" : ""
}