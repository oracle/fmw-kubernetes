#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script that will delete all of the infrastructure components that were
# created using the create_infra.sh script.
#
# Dependencies: ./responsefile/oci_oke.rsp
#               ./common/oci_util_functions.sh
#               ./common/oci_delete_functions.sh
#
# Usage: delete_oke.sh <response_tempate_file>
#

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <response_tempate_file>"
  exit 1
fi

DIRNAME=$(dirname $0)
if test -f $DIRNAME/responsefile/$1 ; then
  source $DIRNAME/responsefile/$1
  TEMPLATE=$(basename $DIRNAME/responsefile/$1 | sed 's/.rsp//')
  LOGDIR=$WORKDIR/$TEMPLATE/logs
  LOGFILE=delete_oke.log
  OUTDIR=$WORKDIR/$TEMPLATE/output
  RESOURCE_OCID_FILE=$OUTDIR/$TEMPLATE.ocid
else
  echo "Error, Unable to read template file '$DIRNAME/responsefile/$1'"
  exit 1
fi

if [[ ! -s "$RESOURCE_OCID_FILE" ]]; then
  echo -e "\nThe '$RESOURCE_OCID_FILE' is not present, cannot proceed with automatic resource deletion."
  exit 1
fi

source $DIRNAME/common/oci_util_functions.sh
source $DIRNAME/common/oci_delete_functions.sh

echo -e "Getting the OCID of the '$COMPARTMENT_NAME' compartment..."
get_compartment_ocid

echo -e "\n============================================================"
echo -e "Compartment Name:              $COMPARTMENT_NAME"
echo -e "Compartment OCID:              $COMPARTMENT_ID"
echo -e "Created Date/Time:             $COMPARTMENT_CREATED"
echo -e "Created Using Template Named:  $TEMPLATE"
echo -e "============================================================\n"

echo -e "Are you sure you wish to delete all of the installed OCI infrastructure"
read -r -p "components from the above compartment ($COMPARTMENT_NAME) [Y|N]? " confirm
if ! [[ $confirm =~ ^[Yy]$ ]]; then
  echo "Exiting without making any changes"
  exit 1
fi

START_TIME=`date +%s`

d=`date +%m-%d-%Y-%H-%M-%S`
mkdir -p $LOGDIR
mv $LOGDIR/$LOGFILE $LOGDIR/$LOGFILE-${d} 2>/dev/null 
mv $LOGDIR/timings.log $LOGDIR/timings.log-${d} 2>/dev/null

d1=`date +"%a %d %b %Y %T"`
echo -e "Deletion of the OCI Infrastructure Resources Started on $d1" > $LOGDIR/timings.log

STEPNO=0

print_msg screen "Deleting the DNS Server..."
deleteDNS
print_msg screen "Deleting the Network Load Balancer..."
deleteNetworkLBR
print_msg screen "Deleting the Internal Load Balancer..."
deleteInternalLBR
print_msg screen "Deleting the Public Load Balancer..."
deletePublicLBR
print_msg screen "Deleting the NFS Resources..."
deleteNFS
print_msg screen "Deleting the Web Host Resources..."
deleteWebHosts
print_msg screen "Deleting the Bastion Host Resources..."
deleteBastion
print_msg screen "Deleting the Database..."
deleteDatabase
print_msg screen "Deleting the OKE Cluster..."
deleteOKE
print_msg screen "Deleting the VCN Resources..."
deleteVCN

rm -rf $LOGDIR/progressfile 2>/dev/null
rm -rf $RESOURCE_OCID_FILE 2>/dev/null
rm -rf $LOGDIR/provision_oci* 2>/dev/null
rm -rf $OUTDIR/*_mounts.sh 2>/dev/null

FINISH_TIME=`date +%s`
time_taken=$((FINISH_TIME-START_TIME))
if [[ "$ostype" == "Darwin" ]]; then
  total_time=$(gdate -ud "@$time_taken" +' %H hours %M minutes %S seconds')
else
  total_time=$(date -ud "@$time_taken" +' %H hours %M minutes %S seconds')
fi

d2=`date +"%a %d %b %Y %T"`
echo -e "Deletion of the OCI Infrastructure Resources Completed in $total_time" >> $LOGDIR/timings.log
echo -e "Deletion of the OCI Infrastructure Resources Completed on $d1" > $LOGDIR/timings.log

print_msg screen "Deletion/clean-up of all the OCI resources that were created with the provision_oci.sh"
print_msg screen "script have been completed. Review the log file at $LOGDIR/$LOGFILE for full details."
print_msg screen "The database and may take up to 1 hour before it has been fully deleted."
