## Copyright (c) 2022, Oracle and/or its affiliates.
## Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# Variables passed into vcn module

variable "compartment_ocid" {}

variable "vcn_cidr" {
  default = "10.0.0.0/16"
}
variable "oke_cluster" {}
variable "provision_database" {}