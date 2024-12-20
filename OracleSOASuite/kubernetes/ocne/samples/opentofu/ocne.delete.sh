#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#
# This script deletes provisioned OCNE environment using tofu (https://opentofu.org/)
#

set -o errexit
set -o pipefail

prop() {
  grep "${1}" ${oci_property_file}| grep -v "#" | cut -d'=' -f2
}

deleteOCNECluster() {
  cd ${opentofuVarDir}
  tofu init -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
  tofu plan -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
  tofu destroy -auto-approve -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
}


#MAIN
oci_property_file=${1:-$PWD/oci.props}
opentofuVarDir=${2:-$PWD}

clusterTFVarsFile=$(prop 'tfvars.filename')
opentofuDir=$(prop 'tofu.installdir')
export PATH=${opentofuDir}:$PATH

echo 'Deleting cluster'
deleteOCNECluster || true
