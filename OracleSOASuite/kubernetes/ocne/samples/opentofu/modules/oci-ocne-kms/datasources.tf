# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

data "oci_kms_vault" "vault" {
  count    = length(var.vault_ocid) > 0 ? 1 : 0
  vault_id = var.vault_ocid
}
