# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

# Work with pki secrets engine
path "pki*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

# OCNE specific capabilities
path "+/ocne*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

path "+/+/ocne*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}

path "+/+/+/ocne*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
