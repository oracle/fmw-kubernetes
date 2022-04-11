## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

resource "oci_database_db_system" "db_system" {
  count = var.provision_database ? 1 : 0

  #Required
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains.0.name
  compartment_id      = var.compartment_ocid
  db_home {
    #Required
    database {
      #Required
      admin_password = var.admin_password

      #Optional
      db_name     = var.database_name
      db_workload = "OLTP"
      pdb_name = var.pdb_name
    }

    #Optional
    db_version = var.db_version
    display_name = var.database_name
  }
  hostname        = "db"
  shape           = var.db_system_shape
  ssh_public_keys = var.ssh_public_keys
  subnet_id       = var.subnet_id

  #Optional
  cpu_core_count = var.db_system_cpu_core_count
  data_storage_size_in_gb = var.db_system_data_storage_size_in_gb
  database_edition        = var.db_system_database_edition
  db_system_options {

    #Optional
    storage_management = var.db_system_db_system_options_storage_management
  }
  license_model = var.db_system_license_model
  node_count = 1
}
