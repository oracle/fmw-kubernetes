## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

variable "provision_database" {}
variable "compartment_ocid" {}
variable "database_name" {}
variable "database_unique_name" {}
variable "db_version" {}
variable "pdb_name" {
  default = "pdb"
}
variable "admin_username" {
  default = "SYS"
}
variable "admin_password" {}
variable "db_system_shape" {
  default = "VM.Standard2.1"
}
variable "db_system_cpu_core_count" {
  default = 1
}
variable "db_system_data_storage_size_in_gb" {
  default = 256
}
variable "db_system_database_edition" {
  default = "ENTERPRISE_EDITION"
}
variable "ssh_public_keys" {}
variable "subnet_id" {}
variable "db_system_license_model" {
  default = "LICENSE_INCLUDED"
}
variable "db_system_db_system_options_storage_management" {
  default = "LVM"
}
