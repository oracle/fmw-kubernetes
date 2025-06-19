#!/bin/bash
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of an Umbrella script that will create all of the OCI infrastructure components
# as listed in Chapter 9 (Preparing the Oracle Cloud Infrastructure for an Enterprise Deployment) of the 
# document "Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster."
#
# Dependencies: ./responsefile/oci_oke.rsp
#               ./common/oci_util_functions.sh
#               ./common/oci_create_functions.sh
#               ./common/oci_setup_functions.sh
#
# Usage: provision_oci.sh <response_tempate_file>
#

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <response_tempate_file>"
  exit 1
fi

DIRNAME=$(dirname $0)
if test -f $DIRNAME/responsefile/$1 ; then
  source $DIRNAME/responsefile/$1
  source $DIRNAME/responsefile/.ocipwd
  TEMPLATE=$(basename $DIRNAME/responsefile/$1 | sed 's/.rsp//')
  LOGDIR=$WORKDIR/$TEMPLATE/logs
  LOGFILE="provision_oci.log"
  OUTDIR=$WORKDIR/$TEMPLATE/output
  RESOURCE_OCID_FILE=$OUTDIR/$TEMPLATE.ocid
  INTERIM_PARAM=$OUTDIR/interim_parameters
  FREEFORM_TAG=$OUTDIR/freeform_tag.json
else
  echo "Error, Unable to read template file '$DIRNAME/responsefile/$1'"
  exit 1
fi
CONFIG_LOCATION=$DIRNAME/responsefile/$1
source $DIRNAME/common/oci_util_functions.sh
source $DIRNAME/common/oci_create_functions.sh
source $DIRNAME/common/oci_setup_functions.sh

mkdir -p $LOGDIR
mkdir -p $OUTDIR

if test -f $INTERIM_PARAM ; then
  source $INTERIM_PARAM
else
  touch $INTERIM_PARAM
fi

if test -f $FREEFORM_TAG ; then
  rm $FREEFORM_TAG
fi

TAG_NUMBER=$(grep ^OCI_TAG $CONFIG_LOCATION | wc -l)
echo \{ >> $FREEFORM_TAG
for (( i=1; i <= $TAG_NUMBER; ++i ))
do
  TAG=$(grep ^OCI_TAG $CONFIG_LOCATION | head -$i | tail -1 | awk -F\" '{print $2}')
  TAG_KEY=$(echo $TAG | awk -F: '{print $1}')
  TAG_VALUE=$(echo $TAG | awk -F: '{print $2}')
  if [[ "$i" -eq "$TAG_NUMBER" ]]; then
    echo "   \"$TAG_KEY\": \"$TAG_VALUE\"" >> $FREEFORM_TAG
    echo \} >> $FREEFORM_TAG
  else
    echo "   \"$TAG_KEY\": \"$TAG_VALUE\"," >> $FREEFORM_TAG
  fi
done
 
if [[ $TAG_NUMBER -gt 0 ]]; then
  TAG_PARAM=" --freeform-tags file://$FREEFORM_TAG "
else
  TAG_PARAM=""
fi

validateVariables
formatShapeConfig

echo -e "Getting the OCID of the '$COMPARTMENT_NAME' compartment..."
get_compartment_ocid

echo -e "\n============================================================"
echo -e "Compartment Name:             $COMPARTMENT_NAME"
echo -e "Compartment OCID:             $COMPARTMENT_ID"
echo -e "Created Date/Time:            $COMPARTMENT_CREATED"
echo -e "Create Using Template Named:  $TEMPLATE"
echo -e "============================================================\n"

echo -e "Are you sure you wish to continue and install the EDG infrastructure"
echo -e "components into the above compartment ($COMPARTMENT_NAME) using the specified"
read -t 25 -r -p "template named '$TEMPLATE' [Y|N]? " confirm
if ! [[ $confirm =~ ^[Yy]$ ]]; then
    echo "Exiting without making any changes"
    exit 1
fi

START_TIME=`date +%s`

d=`date +%m-%d-%Y-%H-%M-%S`
mkdir -p $LOGDIR
mkdir -p $OUTDIR
mv $LOGDIR/$LOGFILE $LOGDIR/$LOGFILE-${d} 2>/dev/null
mv $LOGDIR/timings.log $LOGDIR/timings.log-${d} 2>/dev/null
touch $RESOURCE_OCID_FILE 2>/dev/null

d1=`date +"%a %d %b %Y %T"`
echo -e "Provisioning the OCI Infrastructure Started on $d1" > $LOGDIR/timings.log

print_msg screen "Getting the list of availability domains in the region '$REGION'..."
get_ad_list

STEPNO=0
PROGRESS=$(get_progress)

print_msg screen "Setting up the VCN Resources..."
createVCN # Steps 1-12
dx=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/createVCN-${dx} 2>/dev/null

print_msg screen "Setting up the Database..."
createDatabase # Steps 13-16
dx=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/createDB-${dx} 2>/dev/null

print_msg screen "Setting up the OKE Cluster..."
createOKE # Steps 17-18
dx=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/createOKE-${dx} 2>/dev/null

print_msg screen "Setting up the Bastion Host Resources..."
createBastion # Steps 19-26
dx=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/createBastion-${dx} 2>/dev/null

print_msg screen "Setting up the Web Host Resources..."
createWebHosts # Steps 27-33
dx=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/createWebHosts-${dx} 2>/dev/null

print_msg screen "Setting up the NFS Resources..."
createNFS # Steps 34-78
dx=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/createNFS-${dx} 2>/dev/null

get_whip

print_msg screen "Setting up the Public Load Balancer..."
createPublicLBR # Steps 79-99
dx=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/createPublicLBR-${dx} 2>/dev/null

print_msg screen "Setting up the Internal Load Balancer..."
createInternalLBR # Steps 100-116
dx=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/createInternalLBR-${dx} 2>/dev/null

print_msg screen "Setting up the Network Load Balancer..."
createNetworkLBR # Steps 117-122
dx=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/createNetworkLBR-${dx} 2>/dev/null

print_msg screen "Setting up the DNS Server..."
createDNS # Steps 123-131
dx=`date +%m-%d-%Y-%H-%M-%S`
mv $LOGDIR/$LOGFILE $LOGDIR/createDNS-${dx} 2>/dev/null

copyBastionSSH # Step 132
CONFIGURE_BASTION=$(tr '[:upper:]' '[:lower:]' <<< $CONFIGURE_BASTION)
if [[ "$CONFIGURE_BASTION" == "true" ]]; then
  print_msg screen "Configuring the Bastion Host..."
  setupBastion # Steps 133-163
  dx=`date +%m-%d-%Y-%H-%M-%S`
  mv $LOGDIR/$LOGFILE $LOGDIR/setupBastion-${dx} 2>/dev/null
else
  print_msg screen "The Bastion Host Can be Configured By Manually Running the $DIRNAME/util/oci_setup_bastion.sh script"
fi
CONFIGURE_WEBHOSTS=$(tr '[:upper:]' '[:lower:]' <<< $CONFIGURE_WEBHOSTS)
if [[ "$CONFIGURE_WEBHOSTS" == "true" ]]; then
  print_msg screen "Configuring the Web hosts..."
  setupWebHosts # Steps 164-207
  dx=`date +%m-%d-%Y-%H-%M-%S`
  mv $LOGDIR/$LOGFILE $LOGDIR/setupWebHosts-${dx} 2>/dev/null
else
  print_msg screen "The Webhosts Host Can be Configured By Manually Running the $DIRNAME/util/oci_setup_webhosts.sh script"
fi
CONFIGURE_DATABASE=$(tr '[:upper:]' '[:lower:]' <<< $CONFIGURE_DATABASE)
if [[ "$CONFIGURE_DATABASE" == "true" ]]; then
  print_msg screen "Configuring the Database..."
  setupDatabase # Steps 208-232
  dx=`date +%m-%d-%Y-%H-%M-%S`
  mv $LOGDIR/$LOGFILE $LOGDIR/setupDB-${dx} 2>/dev/null
else
  print_msg screen "The initial database creation is in progress and may take 1-2 hours to complete."
  print_msg screen "The Database Can be Configured By Manually Running the $DIRNAME/util/oci_setup_database.sh script"
fi

FINISH_TIME=`date +%s`
time_taken=$((FINISH_TIME-START_TIME))
if [[ "$ostype" == "Darwin" ]]; then
  total_time=$(gdate -ud "@$time_taken" +' %H hours %M minutes %S seconds')
else
  total_time=$(date -ud "@$time_taken" +' %H hours %M minutes %S seconds')
fi

d2=`date +"%a %d %b %Y %T"`
echo -e "Provisioning the OCI Infrastructure Completed on $d2" >> $LOGDIR/timings.log

print_msg screen "\n\nCreation of the OCI resources defined in chapter 9 of the EDG has completed"
print_msg screen "in $total_time."
print_msg screen "\nReview the log file at $LOGDIR/$LOGFILE for full details."

id=$(cat $RESOURCE_OCID_FILE | grep $BASTION_INSTANCE_DISPLAY_NAME: | cut -d: -f2)
ip=$(oci compute instance list-vnics --compartment-id $COMPARTMENT_ID --instance-id $id \
       --query 'data[0]."public-ip"' --raw-output) 
print_msg screen "Use the following command to connect to the bastion host:"
print_msg screen "  ssh -i $SSH_ID_KEYFILE opc@$ip"

print_msg screen "\nThe OKE cluster takes 10+ minutes to complete and become available. Once the"
print_msg screen "  cluster is available then the OKE node pool will be created. The node pool takes"
print_msg screen "  5+ minutes to complete once it starts. The OKE cluster will not be available until"
print_msg screen "  both the cluster and node pool show as active within the OCI console."
