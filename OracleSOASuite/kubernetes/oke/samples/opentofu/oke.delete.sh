#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This script deletes provisioned OKE Kubernetes cluster using opentofu (https://opentofu.org/)
#

set -o errexit
set -o pipefail

prop() {
  grep "${1}" ${oci_property_file}| grep -v "#" | cut -d'=' -f2
}

cleanupLB() {
  echo 'Clean up left over LB'
  myvcn_id=`oci network vcn list --compartment-id $compartment_ocid  --display-name=${clusterName}_vcn | jq -r '.data[] | .id'`
  declare -a vcnidarray
  vcnidarray=(${myvcn_id// /})
  myip=`oci lb load-balancer list --compartment-id $compartment_ocid |jq -r '.data[] | .id'`
  mysubnets=`oci network subnet list --vcn-id=${vcnidarray[0]} --display-name=${clusterName}-LB-${1} --compartment-id $compartment_ocid | jq -r '.data[] | .id'`

  declare -a iparray
  declare -a mysubnetsidarray
  mysubnetsidarray=(${mysubnets// /})

  iparray=(${myip// /})
  vcn_cidr_prefix=$(prop 'vcn.cidr.prefix')
  for k in "${mysubnetsidarray[@]}"
    do
      for i in "${iparray[@]}"
         do
            lb=`oci lb load-balancer get --load-balancer-id=$i`
            echo "deleting lb with id $i   $lb"
            if [[ (-z "${lb##*$vcn_cidr_prefix*}") || (-z "${lb##*$k*}") ]] ;then
               echo "deleting lb with id $i"
               sleep 60
               oci lb load-balancer delete --load-balancer-id=$i --force || true
            fi
        done
    done
  myip=`oci lb load-balancer list --compartment-id $compartment_ocid |jq -r '.data[] | .id'`
  iparray=(${myip// /})
   for k in "${mysubnetsidarray[@]}"
      do
        for i in "${iparray[@]}"
           do
              lb=`oci lb load-balancer get --load-balancer-id=$i`
              echo "deleting lb with id $i   $lb"
              if [[ (-z "${lb##*$vcn_cidr_prefix*}") || (-z "${lb##*$k*}") ]] ;then
                 echo "deleting lb with id $i"
                 sleep 60
                 oci lb load-balancer delete --load-balancer-id=$i --force || true
              fi
          done
      done
}

deleteOKE() {
  cd ${tofu_script_dir}
  tofu init -var-file=${tofu_script_dir}/${tfvars_filename}.tfvars
  tofu plan -var-file=${tofu_script_dir}/${tfvars_filename}.tfvars
  tofu destroy -auto-approve -var-file=${tofu_script_dir}/${tfvars_filename}.tfvars
}

#MAIN
oci_property_file=${1:-$PWD/oci.props}
tofu_script_dir=${2:-$PWD}
clusterName=$(prop 'okeclustername')
compartment_ocid=$(prop 'compartment.ocid')
vcn_cidr_prefix=$(prop 'vcn.cidr.prefix')
tofu_installdir=$(prop 'tofu.installdir')
tfvars_filename=$(prop 'tfvars.filename')
export KUBECONFIG=${tofu_script_dir}/${clusterName}_kubeconfig
export PATH=${tofu_installdir}:$PATH
echo 'Deleting cluster'
#check and cleanup any left over running Load Balancers
out=$(cleanupLB Subnet01 && :)
echo $out
out=$(cleanupLB Subnet02 && :)
echo $out
deleteOKE || true
