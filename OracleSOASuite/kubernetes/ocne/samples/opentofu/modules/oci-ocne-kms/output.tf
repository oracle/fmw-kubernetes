# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

output "management_endpoint" {
  description = "OCI KMS vault management endpoint."
  value       = local.management_endpoint
}

output "crypto_endpoint" {
  description = "OCI KMS vault crypto endpoint."
  value       = local.crypto_endpoint
}

output "key_id" {
  description = "OCI KMS vault key id."
  value       = local.key_ocid
}
