#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
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
# Usage: create_idm_rsp.sh <response_template_file> 
#

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <response_template_file>"
  exit 1
fi

DIRNAME=$(dirname $0)
if test -f $DIRNAME/responsefile/$1 ; then
  source $DIRNAME/responsefile/$1
  TEMPLATE=$(basename $DIRNAME/responsefile/$1 | sed 's/.rsp//')
  LOGDIR=$WORKDIR/$TEMPLATE/logs
  LOGFILE="provision_oci.log"
  OUTDIR=$WORKDIR/$TEMPLATE/output
  RESOURCE_OCID_FILE=$OUTDIR/$TEMPLATE.ocid
  IDM_TEMPLATE=$DIRNAME/../responsefile/idm.rsp
  IDM_RSP=${OUTDIR}/${TEMPLATE}_idm.rsp
  IDM_SEDFILE=$OUTDIR/idm.sed
else
  echo "Error, Unable to read template file '$DIRNAME/responsefile/$1'"
  exit 1
fi

source $DIRNAME/common/oci_util_functions.sh
source $DIRNAME/common/oci_setup_functions.sh

echo -e "Getting the OCID of the '$COMPARTMENT_NAME' compartment..."
get_compartment_ocid

echo -e "\n============================================================"
echo -e "Compartment Name:             $COMPARTMENT_NAME"
echo -e "Compartment OCID:             $COMPARTMENT_ID"
echo -e "Created Date/Time:            $COMPARTMENT_CREATED"
echo -e "Create Using Template Named:  $TEMPLATE"
echo -e "Create IDM Template        :  $IDM_RSP"
echo -e "============================================================\n"


START_TIME=$(date +%s)

d=$(date +%m-%d-%Y-%H-%M-%S)

echo -e "Setting DOMAIN_NAME to $DNS_DOMAIN_NAME"
echo -e "s/example.com/$DNS_DOMAIN_NAME/" > $IDM_SEDFILE
echo -n "s/dc=example,dc=com/" >> $IDM_SEDFILE
echo -n $DNS_DOMAIN_NAME | sed "s/\./,dc=/g;s/^/dc=/">> $IDM_SEDFILE
echo  "/">> $IDM_SEDFILE


echo -e "Setting SSL Country to $SSL_COUNTRY"
echo "s/SSL_COUNTRY.*/SSL_COUNTRY=\"$SSL_COUNTRY\"/" >> $IDM_SEDFILE
echo -e "Setting SSL Organisation to $SSL_ORG"
echo "s/SSL_ORG.*/SSL_ORG=\"$SSL_ORG\"/" >> $IDM_SEDFILE
echo -e "Setting SSL City to $SSL_LOCALE"
echo "s/SSL_CITY.*/SSL_CITY=\"$SSL_LOCALE\"/" >> $IDM_SEDFILE
echo -e "Setting SSL State to $SSL_STATE"
echo "s/SSL_STATE.*/SSL_STATE=\"$SSL_STATE\"/" >> $IDM_SEDFILE

# Get Worker Node IPs
#
clid=$(cat $RESOURCE_OCID_FILE | grep $OKE_CLUSTER_DISPLAY_NAME | cut -d: -f2)
npid=$(cat $RESOURCE_OCID_FILE | grep $OKE_NODE_POOL_DISPLAY_NAME | cut -d: -f2)
for i in $(oci ce node-pool get --region $REGION --node-pool-id $npid --query \
      'data.nodes[*].id' | jq -r '.[]')
do
      ip=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $i \
           --query 'data[0]."private-ip"' --raw-output)
      workers+=($ip)
done

echo -e "Setting K8_WORKER_HOST1 to $K8_WORKER_HOST1"
echo "s/K8_WORKER_HOST1.*/K8_WORKER_HOST1=${workers[1]}/" >> $IDM_SEDFILE
echo -e "Setting K8_WORKER_HOST2 to $K8_WORKER_HOST2"
echo "s/K8_WORKER_HOST2.*/K8_WORKER_HOST2=${workers[2]}/" >> $IDM_SEDFILE

echo -e "Setting OHS_HOST1 to $WEBHOST1_HOSTNAME"
echo "s/OHS_HOST1.*/OHS_HOST1=$WEBHOST1_HOSTNAME/" >> $IDM_SEDFILE
echo -e "Setting OHS_HOST2 to $WEBHOST2_HOSTNAME"
echo "s/OHS_HOST2.*/OHS_HOST2=$WEBHOST2_HOSTNAME/" >> $IDM_SEDFILE

PVSERVER=$(grep fstab $OUTDIR/bastion_mounts.sh | head -1 | cut -f1 -d : | sed "s/echo \"//")
echo -e "Setting PVSERVER to $PVSERVER"
echo "s/mynfsserver.*/$PVSERVER/" >> $IDM_SEDFILE

PVMOUNT=$(dirname $(grep fstab $OUTDIR/bastion_mounts.sh | head -1 | cut -f2 -d : | sed "s/ .*//") | sed "s/\//\\\\\//g")
echo -e "Setting IAM_PVS to $PVMOUNT"
echo "s/IAM_PVS=.*/IAM_PVS=$PVMOUNT/" >> $IDM_SEDFILE

echo "Setting PV Names"
echo "s/oudpv/$FS_OUDPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/oudconfigpv/$FS_OUDCONFIGPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/oudsmpv/$FS_OUDSMPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/oampv/$FS_OAMPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/oimpv/$FS_OIGPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/oiripv/$FS_OIRIPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/dingpv/$FS_DINGPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/workpv/$FS_WORKPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/oaaconfigpv/$FS_OAACONFIGPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/oaacredpv/$FS_OAACREDPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/oaalogpv/$FS_OAALOGPV_DISPLAY_NAME/"  >> $IDM_SEDFILE
echo "s/oaalogpv/$FS_OAALOGPV_DISPLAY_NAME/"  >> $IDM_SEDFILE

echo "Setting Mount Points"
echo "s/OUD_LOCAL_CONFIG_SHARE.*/OUD_LOCAL_CONFIG_SHARE=$(echo $FS_OUDCONFIGPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OUD_LOCAL_SHARE.*/OUD_LOCAL_SHARE=$(echo $FS_OUDPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OUDSM_LOCAL_SHARE.*/OUDSM_LOCAL_SHARE=$(echo $FS_OUDSMPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OAM_LOCAL_SHARE.*/OAM_LOCAL_SHARE=$(echo $FS_OAMPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OIG_LOCAL_SHARE.*/OIG_LOCAL_SHARE=$(echo $FS_OIGPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OIRI_LOCAL_SHARE.*/OIRI_LOCAL_SHARE=$(echo $FS_OIRIPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OIRI_DING_LOCAL_SHARE.*/OIRI_DING_LOCAL_SHARE=$(echo $FS_DINGPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OIRI_WORK_LOCAL_SHARE.*/OIRI_WORK_LOCAL_SHARE=$(echo $FS_WORKPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OAA_LOCAL_CONFIG_SHARE.*/OAA_LOCAL_CONFIG_SHARE=$(echo $FS_OAACONFIGPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OAA_LOCAL_CRED_SHARE.*/OAA_LOCAL_CRED_SHARE=$(echo $FS_OAACREDPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OAA_LOCAL_LOG_SHARE.*/OAA_LOCAL_LOG_SHARE=$(echo $FS_OAALOGPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE
echo "s/OAA_LOCAL_VAULT_SHARE.*/OAA_LOCAL_VAULT_SHARE=$(echo $FS_OAAVAULTPV_LOCAL_MOUNTPOINT | sed "s/\//\\\\\//g")/" >> $IDM_SEDFILE

DBSYSTEMID=$(cat $RESOURCE_OCID_FILE | grep $DB_DISPLAY_NAME | cut -d: -f2)
dbscan=$(oci db system get --db-system-id $DBSYSTEMID --query 'data."scan-dns-name"' --raw-output)
echo "Setting Database SCAN Address to $dbscan"
echo "s/DB_SCAN=.*/DB_SCAN=$dbscan/" >> $IDM_SEDFILE

dbdomain=$(oci db system get --db-system-id $DBSYSTEMID --query 'data."domain"' --raw-output)

echo "Setting OAM Service Name to $OAM_SERVICE_NAME.$dbdomain"
echo "s/OAM_DB_SERVICE.*/OAM_DB_SERVICE=$OAM_SERVICE_NAME.$dbdomain/" >> $IDM_SEDFILE
echo "Setting OIG Service Name to $OIG_SERVICE_NAME.$dbdomain"
echo "s/OIG_DB_SERVICE.*/OIG_DB_SERVICE=$OIG_SERVICE_NAME.$dbdomain/" >> $IDM_SEDFILE
echo "Setting OIRI Service Name to $OIRI_SERVICE_NAME.$dbdomain"
echo "s/OIRI_DB_SERVICE.*/OIRI_DB_SERVICE=$OIRI_SERVICE_NAME.$dbdomain/" >> $IDM_SEDFILE
echo "Setting OAA Service Name to $OAA_SERVICE_NAME.$dbdomain"
echo "s/OAA_DB_SERVICE.*/OAA_DB_SERVICE=$OAA_SERVICE_NAME.$dbdomain/" >> $IDM_SEDFILE

echo "Setting OAM Admin Virtual Host to $PUBLIC_LBR_IADADMIN_HOSTNAME"
echo "s/OAM_ADMIN_LBR_HOST.*/OAM_ADMIN_LBR_HOST=$PUBLIC_LBR_IADADMIN_HOSTNAME/" >> $IDM_SEDFILE
echo "Setting OAM Login Virtual Host to $PUBLIC_LBR_LOGIN_HOSTNAME"
echo "s/OAM_LOGIN_LBR_HOST.*/OAM_LOGIN_LBR_HOST=$PUBLIC_LBR_LOGIN_HOSTNAME/" >> $IDM_SEDFILE
echo "Setting OIG Admin Virtual Host to $PUBLIC_LBR_IGDADMIN_HOSTNAME"
echo "s/OIG_ADMIN_LBR_HOST.*/OIG_ADMIN_LBR_HOST=$PUBLIC_LBR_IGDADMIN_HOSTNAME/" >> $IDM_SEDFILE
echo "Setting OIG Provisioning Virtual Host to $PUBLIC_LBR_PROV_HOSTNAME"
echo "s/OIG_PROV_LBR_HOST.*/OIG_PROV_LBR_HOST=$PUBLIC_LBR_PROV_HOSTNAME/" >> $IDM_SEDFILE
echo "Setting OIG Internal Virtual Host to $INT_LBR_IGDINTERNAL_HOSTNAME"
echo "s/OIG_LBR_INT_HOST.*/OIG_LBR_INT_HOST=$INT_LBR_IGDINTERNAL_HOSTNAME/" >> $IDM_SEDFILE

echo "Applying Changes"
sed -f $IDM_SEDFILE $IDM_TEMPLATE > $IDM_RSP

echo "File Created Successfully."
