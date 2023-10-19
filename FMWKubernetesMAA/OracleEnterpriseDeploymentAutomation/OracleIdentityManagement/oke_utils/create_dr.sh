#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of an Umbrella script that will create all of the OCI infrastructure components
# that are required for setting up a Disaster Recovery configuration between 2 OCI regions. 
#
# Dependencies: ./responsefile/prim_oke.rsp
#               ./responsefile/stby_oke.rsp
#               ./common/oci_util_functions.sh
#               ./common/oci_dr_functions.sh
#
# Usage: create_dr_oci.sh <primary response_tempate_file>  <standby response_tempate_file>
#

export USE_ACTIVE_DATAGUARD=true

if [[ $# -eq 0 ]]; then
  echo "Usage: $0  <primary response_tempate_file>  <standby response_tempate_file>"
  exit 1
fi

DIRNAME=$(dirname $0)
if test -f $DIRNAME/responsefile/$1 ; then
  PRIMARY_RSP=$DIRNAME/responsefile/$1
  PRIMARY_TEMPLATE=$(basename $DIRNAME/responsefile/$1 | sed 's/.rsp//')
else
  echo "Error, Unable to read template file '$DIRNAME/responsefile/$1'"
  exit 1
fi

if test -f $DIRNAME/responsefile/$2 ; then
  STBY_RSP=$DIRNAME/responsefile/$2
  STBY_TEMPLATE=$(basename $DIRNAME/responsefile/$2 | sed 's/.rsp//')
else
  echo "Error, Unable to read template file '$DIRNAME/responsefile/$2'"
  exit 1
fi

source $DIRNAME/common/oci_util_functions.sh
source $DIRNAME/common/oci_dr_functions.sh

WORKDIR=$(get_rsp_value WORKDIR $PRIMARY_RSP )

LOGDIR=$WORKDIR/dr/logs/${PRIMARY_TEMPLATE}_${STBY_TEMPLATE}
LOGFILE="dr_oci.log"
PRIMARY_OUTDIR=$WORKDIR/$PRIMARY_TEMPLATE/output
PRIMARY_RESOURCE_OCID_FILE=$PRIMARY_OUTDIR/$PRIMARY_TEMPLATE.ocid
STBY_OUTDIR=$WORKDIR/$STBY_TEMPLATE/output
STBY_RESOURCE_OCID_FILE=$STBY_OUTDIR/$STBY_TEMPLATE.ocid

COMPARTMENT_NAME=$(get_rsp_value COMPARTMENT_NAME $PRIMARY_RSP )

echo -e "Getting the OCID of the '$COMPARTMENT_NAME' compartment..."
get_compartment_ocid

echo -e "\n============================================================"
echo -e "Compartment Name:             $COMPARTMENT_NAME"
echo -e "Compartment OCID:             $COMPARTMENT_ID"
echo -e "Created Date/Time:            $COMPARTMENT_CREATED"
echo -e "Create Using Primary Template $PRIMARY_TEMPLATE"
echo -e "Create Using Standby Template $STBY_TEMPLATE"
echo -e "============================================================\n"

echo -e "Are you sure you wish to continue and setup Disaster Recovery"
echo -e "components into the above compartment ($COMPARTMENT_NAME) using the specified"
read -r -p "templates named '$PRIMARY_TEMPLATE and $STBY_TEMPLATE' [Y|N]? " confirm
if ! [[ $confirm =~ ^[Yy]$ ]]; then
    echo "Exiting without making any changes"
    exit 1
fi

START_TIME=$(date +%s)

d=$(date +%m-%d-%Y-%H-%M-%S)
mkdir -p $LOGDIR > /dev/null
mv $LOGDIR/$LOGFILE $LOGDIR/$LOGFILE-${d} 2>/dev/null
mv $LOGDIR/timings.log $LOGDIR/timings.log-${d} 2>/dev/null

d1=$(date +"%a %d %b %Y %T")
echo -e "Provisioning the OCI Disaster Recovery Started on $d1" > $LOGDIR/timings.log

STEPNO=0
PROGRESS=$(get_progress)

PRIMARY_REGION=$(get_rsp_value REGION $PRIMARY_RSP )
STBY_REGION=$(get_rsp_value REGION $STBY_RSP )


PRIMARY_VCN_NAME=$(get_rsp_value VCN_DISPLAY_NAME $PRIMARY_RSP )
STBY_VCN_NAME=$(get_rsp_value VCN_DISPLAY_NAME $STBY_RSP )

PRIMARY_VCN_ID=$( grep $PRIMARY_VCN_NAME $PRIMARY_RESOURCE_OCID_FILE | cut -d: -f2)
STBY_VCN_ID=$( grep $STBY_VCN_NAME $STBY_RESOURCE_OCID_FILE | cut -d: -f2)

print_msg screen "Setting up the Dynamic Routing Gateway Resources..."

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   create_drg $PRIMARY_REGION
fi

PRIMARY_DRG_ID=$(grep "DRG-${PRIMARY_REGION}" $PRIMARY_RESOURCE_OCID_FILE | cut -f2 -d:)

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   create_drg_attach $PRIMARY_REGION $PRIMARY_DRG_ID $PRIMARY_VCN_ID
fi

PRIMARY_ATTACH_ID=$(grep "DRG-ATTACHMENT-${PRIMARY_REGION}" $PRIMARY_RESOURCE_OCID_FILE | cut -f2 -d:)

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   create_rpc $PRIMARY_REGION $PRIMARY_DRG_ID 
fi

PRIMARY_RPC_ID=$(grep "RPC-${PRIMARY_REGION}" $PRIMARY_RESOURCE_OCID_FILE | cut -f2 -d:)

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   create_drg $STBY_REGION
fi

STBY_DRG_ID=$(grep "DRG-${STBY_REGION}" $STBY_RESOURCE_OCID_FILE | cut -f2 -d:)

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   create_drg_attach $STBY_REGION $STBY_DRG_ID $STBY_VCN_ID
fi

STBY_ATTACH_ID=$(grep "DRG-ATTACHMENT-${STBY_REGION}" $STBY_RESOURCE_OCID_FILE | cut -f2 -d:)

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   create_rpc $STBY_REGION $STBY_DRG_ID 
fi


STBY_RPC_ID=$(grep "RPC-${STBY_REGION}" $STBY_RESOURCE_OCID_FILE | cut -f2 -d:)

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   connect_rpc $PRIMARY_REGION $PRIMARY_RPC_ID $STBY_REGION $STBY_RPC_ID 
fi


print_msg screen "Setting up the Routing to Gateway ..."
PRIMARY_DB_ROUTE_NAME=$(get_rsp_value DB_ROUTE_TABLE_DISPLAY_NAME $PRIMARY_RSP )
PRIMARY_DB_ROUTE_ID=$(grep "$PRIMARY_DB_ROUTE_NAME" $PRIMARY_RESOURCE_OCID_FILE | cut -f2 -d:)

STBY_DB_CIDR=$(get_rsp_value DB_SUBNET_CIDR $STBY_RSP )
STBY_K8_CIDR=$(get_rsp_value OKE_NODE_SUBNET_CIDR $STBY_RSP )


STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_drg_route $PRIMARY_REGION $PRIMARY_DB_ROUTE_ID $PRIMARY_DRG_ID $STBY_DB_CIDR
fi

PRIMARY_K8_ROUTE_NAME=$(get_rsp_value VCN_PRIVATE_ROUTE_TABLE_DISPLAY_NAME $PRIMARY_RSP )
PRIMARY_K8_ROUTE_ID=$(grep "$PRIMARY_K8_ROUTE_NAME" $PRIMARY_RESOURCE_OCID_FILE | cut -f2 -d:)

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_drg_route $PRIMARY_REGION $PRIMARY_K8_ROUTE_ID $PRIMARY_DRG_ID $STBY_K8_CIDR
fi


STBY_DB_ROUTE_NAME=$(get_rsp_value DB_ROUTE_TABLE_DISPLAY_NAME $STBY_RSP )
STBY_DB_ROUTE_ID=$(grep "$STBY_DB_ROUTE_NAME" $STBY_RESOURCE_OCID_FILE | cut -f2 -d:)

PRIMARY_DB_CIDR=$(get_rsp_value DB_SUBNET_CIDR $PRIMARY_RSP )
PRIMARY_K8_CIDR=$(get_rsp_value OKE_NODE_SUBNET_CIDR $PRIMARY_RSP )


STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_drg_route $STBY_REGION $STBY_DB_ROUTE_ID $STBY_DRG_ID $PRIMARY_DB_CIDR
fi

STBY_K8_ROUTE_NAME=$(get_rsp_value VCN_PRIVATE_ROUTE_TABLE_DISPLAY_NAME $STBY_RSP )
STBY_K8_ROUTE_ID=$(grep "$STBY_K8_ROUTE_NAME" $STBY_RESOURCE_OCID_FILE | cut -f2 -d:)

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_drg_route $STBY_REGION $STBY_K8_ROUTE_ID $STBY_DRG_ID $PRIMARY_K8_CIDR
fi

print_msg screen "Updating Security Lists  ..."
PRIMARY_DB_SECLIST_DISPLAY_NAME=$(get_rsp_value DB_SECLIST_DISPLAY_NAME $PRIMARY_RSP )
PRIMARY_DB_SECLIST=$(grep "$PRIMARY_DB_SECLIST_DISPLAY_NAME" $PRIMARY_RESOURCE_OCID_FILE | cut -f2 -d:)
PRIMARY_DB_LISTENER=$(get_rsp_value DB_SQLNET_PORT $PRIMARY_RSP )
STBY_DB_SECLIST_DISPLAY_NAME=$(get_rsp_value DB_SECLIST_DISPLAY_NAME $STBY_RSP )
STBY_DB_SECLIST=$(grep "$STBY_DB_SECLIST_DISPLAY_NAME" $STBY_RESOURCE_OCID_FILE | cut -f2 -d:)
STBY_DB_LISTENER=$(get_rsp_value DB_SQLNET_PORT $STBY_RSP )

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_ingress $PRIMARY_REGION $PRIMARY_DB_SECLIST $PRIMARY_DB_SECLIST_DISPLAY_NAME TCP $STBY_DB_CIDR $STBY_DB_LISTENER
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_ingress $PRIMARY_REGION $PRIMARY_DB_SECLIST $PRIMARY_DB_SECLIST_DISPLAY_NAME TCP $STBY_DB_CIDR 6200
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_seclist_ingress $STBY_REGION $STBY_DB_SECLIST $STBY_DB_SECLIST_DISPLAY_NAME TCP $PRIMARY_DB_CIDR $PRIMARY_DB_LISTENER
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_seclist_ingress $STBY_REGION $STBY_DB_SECLIST $STBY_DB_SECLIST_DISPLAY_NAME TCP $PRIMARY_DB_CIDR 6200
fi

PRIMARY_OKE_SECLIST_DISPLAY_NAME=$(get_rsp_value PV_SECLIST_DISPLAY_NAME $PRIMARY_RSP )
PRIMARY_OKE_SECLIST=$(grep "$PRIMARY_OKE_SECLIST_DISPLAY_NAME" $PRIMARY_RESOURCE_OCID_FILE | cut -f2 -d:)
PRIMARY_OKE_CIDR=$(get_rsp_value OKE_NODE_SUBNET_CIDR $PRIMARY_RSP )
STBY_OKE_SECLIST_DISPLAY_NAME=$(get_rsp_value PV_SECLIST_DISPLAY_NAME $STBY_RSP )
STBY_OKE_SECLIST=$(grep "$STBY_OKE_SECLIST_DISPLAY_NAME" $STBY_RESOURCE_OCID_FILE | cut -f2 -d:)
STBY_OKE_CIDR=$(get_rsp_value OKE_NODE_SUBNET_CIDR $STBY_RSP )

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_ingress $PRIMARY_REGION $PRIMARY_OKE_SECLIST $PRIMARY_OKE_SECLIST_DISPLAY_NAME TCP $STBY_OKE_CIDR 31444
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_ingress $PRIMARY_REGION $PRIMARY_OKE_SECLIST $PRIMARY_OKE_SECLIST_DISPLAY_NAME TCP $STBY_OKE_CIDR 111
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_ingress $PRIMARY_REGION $PRIMARY_OKE_SECLIST $PRIMARY_OKE_SECLIST_DISPLAY_NAME TCP $STBY_OKE_CIDR 2048 2050
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_ingress $PRIMARY_REGION $PRIMARY_OKE_SECLIST $PRIMARY_OKE_SECLIST_DISPLAY_NAME UDP $STBY_OKE_CIDR 111
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_ingress $PRIMARY_REGION $PRIMARY_OKE_SECLIST $PRIMARY_OKE_SECLIST_DISPLAY_NAME UDP $STBY_OKE_CIDR 2048
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_egress $PRIMARY_REGION $PRIMARY_OKE_SECLIST $PRIMARY_OKE_SECLIST_DISPLAY_NAME TCP $STBY_OKE_CIDR 111
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_egress $PRIMARY_REGION $PRIMARY_OKE_SECLIST $PRIMARY_OKE_SECLIST_DISPLAY_NAME TCP $STBY_OKE_CIDR 2048 2050
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_egress $PRIMARY_REGION $PRIMARY_OKE_SECLIST $PRIMARY_OKE_SECLIST_DISPLAY_NAME UDP $STBY_OKE_CIDR 111
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$PRIMARY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_egress $PRIMARY_REGION $PRIMARY_OKE_SECLIST $PRIMARY_OKE_SECLIST_DISPLAY_NAME UDP $STBY_OKE_CIDR 2048
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_seclist_ingress $STBY_REGION $STBY_OKE_SECLIST $STBY_OKE_SECLIST_DISPLAY_NAME TCP $PRIMARY_OKE_CIDR 31444
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_seclist_ingress $STBY_REGION $STBY_OKE_SECLIST $STBY_OKE_SECLIST_DISPLAY_NAME TCP $PRIMARY_OKE_CIDR 111
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_ingress $STBY_REGION $STBY_OKE_SECLIST $STBY_OKE_SECLIST_DISPLAY_NAME TCP $PRIMARY_OKE_CIDR 2048 2050
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_seclist_ingress $STBY_REGION $STBY_OKE_SECLIST $STBY_OKE_SECLIST_DISPLAY_NAME UDP $PRIMARY_OKE_CIDR 111
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_seclist_ingress $STBY_REGION $STBY_OKE_SECLIST $STBY_OKE_SECLIST_DISPLAY_NAME UDP $PRIMARY_OKE_CIDR 2048
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_seclist_egress $STBY_REGION $STBY_OKE_SECLIST $STBY_OKE_SECLIST_DISPLAY_NAME TCP $PRIMARY_OKE_CIDR 111
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$PRIMARY_OUTDIR
   update_seclist_egress $STBY_REGION $STBY_OKE_SECLIST $STBY_OKE_SECLIST_DISPLAY_NAME TCP $PRIMARY_OKE_CIDR 2048 2050
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_seclist_egress $STBY_REGION $STBY_OKE_SECLIST $STBY_OKE_SECLIST_DISPLAY_NAME UDP $PRIMARY_OKE_CIDR 111
fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   update_seclist_egress $STBY_REGION $STBY_OKE_SECLIST $STBY_OKE_SECLIST_DISPLAY_NAME UDP $PRIMARY_OKE_CIDR 2048
fi

print_msg screen "Setting Up Dataguard  ..."
PRIMARY_DB_NAME=$(get_rsp_value DB_NAME $PRIMARY_RSP )
PRIMARY_DB_SUFFIX=$(get_rsp_value DB_SUFFIX $PRIMARY_RSP )
PRIMARY_DB_SYS_NAME=$(get_rsp_value DB_DISPLAY_NAME $PRIMARY_RSP )
PRIMARY_DB_SYSID=$(grep "$PRIMARY_DB_SYS_NAME" $PRIMARY_RESOURCE_OCID_FILE | cut -f2 -d:)
PRIMARY_DB_PWD=$(get_rsp_value DB_PWD $PRIMARY_RSP )
STBY_DB_SYS_NAME=$(get_rsp_value DB_DISPLAY_NAME $STBY_RSP)
STBY_AD=$(get_rsp_value DB_AD $STBY_RSP)
STBY_DB_SUBNET=$(get_rsp_value DB_SUBNET_DISPLAY_NAME $STBY_RSP)
STBY_DB_SUBNET_ID=$(grep "$STBY_DB_SUBNET" $STBY_RESOURCE_OCID_FILE | cut -f2 -d:)
STBY_DB_SYSID=$(grep "$STBY_DB_SYS_NAME" $STBY_RESOURCE_OCID_FILE | cut -f2 -d:)
STBY_DB_IMAGE=$(get_rsp_value DB_SUBNET_DISPLAY_NAME $STBY_RSP)
STBY_DB_LICENCE=$(get_rsp_value DB_LICENSE $STBY_RSP)
STBY_DB_TIMEZONE=$(get_rsp_value DB_TIMEZONE $STBY_RSP)

get_ad_list $STBY_REGION 
PRIMARY_DB_ID=$(oci db database list --compartment-id $COMPARTMENT_ID --db-system-id $PRIMARY_DB_SYSID --query "data[?contains(\"db-name\", '$PRIMARY_DB_NAME')].{ocid:id}" | jq -r '.[].ocid')

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   create_dataguard $STBY_REGION $PRIMARY_DB_SYSID $PRIMARY_DB_NAME ${!STBY_AD} $STBY_TEMPLATE $STBY_DB_SYS_NAME $STBY_DB_SUBNET_ID $PRIMARY_DB_PWD $STBY_DB_LICENCE $STBY_DB_TIMEZONE
fi

DB_STATE=$(oci db database get --database-id $PRIMARY_DB_ID --query 'data."lifecycle-state"' --raw-output)

echo "   Primary Database  State : " $DB_STATE

if [ "$DB_STATE" = "UPDATING" ]
then
    echo "Database is still Updating - Try again later."
    exit 1
fi

DG_STATE=$(oci db data-guard-association list --database-id $PRIMARY_DB_ID | jq -r '.data[0]["lifecycle-state"]')

echo "   Dataguard Association State : " $DG_STATE
echo ""

if [ "$DG_STATE" != "AVAILABLE" ]
then
   echo "Dataguard is not ready, please try again later."
   exit 1
fi



PRIMARY_SSH_KEYFILE=$(get_rsp_value SSH_ID_KEYFILE $PRIMARY_RSP )
PRIMARY_BASTION_HOSTNAME=$(get_rsp_value BASTION_HOSTNAME $PRIMARY_RSP )
PRIMARY_BASTION_ID=$(grep $PRIMARY_BASTION_HOSTNAME $PRIMARY_RESOURCE_OCID_FILE | cut -f2 -d:)
PRIMARY_BASTION_IP=$(oci compute instance list-vnics --region $PRIMARY_REGION --compartment-id $COMPARTMENT_ID --instance-id $PRIMARY_BASTION_ID --query 'data[0]."public-ip"' --raw-output)
PRIMARY_DB_VNIC=$(oci db system get --db-system-id $PRIMARY_DB_SYSID  --region $PRIMARY_REGION --query 'data."scan-ip-ids"[0]' --raw-output)
PRIMARY_DB_IP=$(oci network private-ip get --region $PRIMARY_REGION --private-ip-id $PRIMARY_DB_VNIC --query 'data."ip-address"' --raw-output)
PRIMARY_DB_DOMAIN=$(oci db system get --db-system-id $PRIMARY_DB_SYSID  --region $PRIMARY_REGION --query 'data."domain"' --raw-output)

STBY_SSH_KEYFILE=$(get_rsp_value SSH_ID_KEYFILE $STBY_RSP )
STBY_BASTION_HOSTNAME=$(get_rsp_value BASTION_HOSTNAME $STBY_RSP )
STBY_BASTION_ID=$(grep $STBY_BASTION_HOSTNAME $STBY_RESOURCE_OCID_FILE | cut -f2 -d:)
STBY_BASTION_IP=$(oci compute instance list-vnics --region $STBY_REGION --compartment-id $COMPARTMENT_ID --instance-id $STBY_BASTION_ID --query 'data[0]."public-ip"' --raw-output)
STBY_DB_SYSID=$(oci db system list --compartment-id $COMPARTMENT_ID --region $STBY_REGION --query "data[?contains(\"display-name\", '$PRIMARY_DB_SYS_NAME-Dataguard')].{ocid:id}" | jq -r '.[].ocid')
STBY_DB_VNIC=$(oci db system get --db-system-id $STBY_DB_SYSID --region $STBY_REGION --query 'data."scan-ip-ids"[0]' --raw-output)
STBY_DB_IP=$(oci network private-ip get --region $STBY_REGION --private-ip-id $STBY_DB_VNIC --query 'data."ip-address"' --raw-output)
STBY_DB_NAME=$(oci db database list --compartment-id $COMPARTMENT_ID --region $STBY_REGION --db-system-id $STBY_DB_SYSID --query 'data[0]."db-unique-name"' --raw-output)

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR

   copy_auth_keys $STBY_SSH_KEYFILE $STBY_BASTION_IP $STBY_DB_IP 

fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR

   set_key_permission $STBY_SSH_KEYFILE $STBY_BASTION_IP $STBY_DB_IP 

fi

STEPNO=$((STEPNO+1))
if [[ $STEPNO -gt $PROGRESS ]]
then
   RESOURCE_OCID_FILE=$STBY_RESOURCE_OCID_FILE
   OUTDIR=$STBY_OUTDIR
   SERVICES=$(get_db_services $PRIMARY_SSH_KEYFILE $PRIMARY_BASTION_IP $PRIMARY_DB_IP $PRIMARY_DB_NAME $PRIMARY_DB_SUFFIX)
   INSTANCES=$(get_db_instances $STBY_SSH_KEYFILE $STBY_BASTION_IP $STBY_DB_IP $STBY_DB_NAME )

   for svc in $SERVICES
   do
     create_dg_service $STBY_SSH_KEYFILE $STBY_BASTION_IP $STBY_DB_IP $STBY_DB_NAME $PRIMARY_DB_DOMAIN $INSTANCES $svc
   done 
fi
