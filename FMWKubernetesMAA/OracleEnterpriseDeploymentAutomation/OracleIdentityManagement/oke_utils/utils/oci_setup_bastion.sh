#!/bin/bash
# Copyright (c) 2023, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script that will configure a bastion host with the necessary
# configuration to be ready to run the kubectl, helm, and oci commands to setup an integrated 
# OUD-OAM-OIG kubernetes environment as described in the EDG.
#
# Dependencies: ../responsefile/oci-oke.rsp
#
# Usage: invoked automatically as needed, not directly
#
# Common Environment Variables
#

if test -f ../responsefile/$1 ; then
  source ../responsefile/$1
  source ../responsefile/.ocipwd
  TEMPLATE=$(basename ../responsefile/$1 | sed 's/.rsp//')
  LOGDIR=$WORKDIR/$TEMPLATE/logs
  LOGFILE="setup_webhosts.log"
  OUTDIR=$WORKDIR/$TEMPLATE/output
  RESOURCE_OCID_FILE=$OUTDIR/$TEMPLATE.ocid
  INTERIM_PARAM=$OUTDIR/interim_parameters
else
  echo "Error, Unable to read template file '../responsefile/$1'"
  exit 1
fi

CONFIG_LOCATION=../responsefile/$1
source ../common/oci_util_functions.sh
source ../common/oci_setup_functions.sh

if test -f $INTERIM_PARAM ; then
  source $INTERIM_PARAM
else
  touch $INTERIM_PARAM
fi

d=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/$LOGFILE-${d} 2>/dev/null
mv $LOGDIR/timings.log $LOGDIR/timings.log-${d} 2>/dev/null

echo -e "Getting the OCID of the '$COMPARTMENT_NAME' compartment..."
get_compartment_ocid

print_msg screen "Getting the list of availability domains in the region '$REGION'..."
get_ad_list

PROGRESS=0
STEPNO=0

setupBastion
