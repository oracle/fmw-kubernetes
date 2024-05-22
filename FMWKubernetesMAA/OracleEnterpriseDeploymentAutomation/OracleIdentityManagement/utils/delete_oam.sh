#!/bin/bash
# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OAM deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oam.sh [-r responsefile -p passwordfile]
#

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" 
SCRIPTDIR=$SCRIPTDIR/..

while getopts 'r:p:' OPTION
do
  case "$OPTION" in
    r)
      RSPFILE=$SCRIPTDIR/responsefile/$OPTARG
     ;;
    p)
      PWDFILE=$SCRIPTDIR/responsefile/$OPTARG
     ;;
    ?)
     echo "script usage: $(basename $0) [-r responsefile -p passwordfile] " >&2
     exit 1
     ;;
   esac
done


RSPFILE=${RSPFILE=$SCRIPTDIR/responsefile/idm.rsp}
PWDFILE=${PWDFILE=$SCRIPTDIR/responsefile/.idmpwds}

. $RSPFILE
if [ $? -gt 0 ]
then
    echo "Responsefile : $RSPFILE does not exist."
    exit 1
fi

. $PWDFILE
if [ $? -gt 0 ]
then
    echo "Passwordfile : $PWDFILE does not exist."
    exit 1
fi

. $SCRIPTDIR/common/functions.sh

WORKDIR=$LOCAL_WORKDIR/OAM
LOGDIR=$LOCAL_WORKDIR/delete_logs/OAM
if [ ! -e $LOGDIR ]
then
  mkdir -p $LOGDIR
fi

mkdir $LOCAL_WORKDIR/deleteLogs > /dev/null 2>&1

LOG=$LOCAL_WORKDIR/deleteLogs/delete_oam_`date +%F_%T`.log

START_TIME=`date +%s`

ST=`date +%s`

echo "Deleting Oracle Access Manager"
echo "------------------------------"
echo
echo Log of Delete Session can be found at: $LOG
echo
# Delete Kubernetes Objects
#
echo "Deleting Kubernetes Services"
kubectl delete jobs $OAM_DOMAIN_NAME-create-oam-infra-domain-job -n $OAMNS > $LOG 2>&1

if [ "$USE_INGRESS" = "true" ]
then
     echo "Deleting Ingress Services"
     kubectl delete ingress -n $OAMNS oamadmin-ingress >> $LOG 2>&1
     kubectl delete ingress -n $OAMNS oamruntime-ingress >> $LOG 2>&1
else
     echo "Deleting NodePort Services"
     kubectl delete service -n $OAMNS $OAM_DOMAIN_NAME-policy-nodeport >> $LOG 2>&1
     kubectl delete service -n $OAMNS $OAM_DOMAIN_NAME-oam-nodeport >> $LOG 2>&1
     kubectl delete service -n $OAMNS $OAM_DOMAIN_NAME-oap >> $LOG 2>&1
fi

ELK_DEP=`kubectl get deployment -n $OAMNS | grep logstash | awk '{ print $1 }'`
if [ ! "$ELK_DEP" = "" ]
then
   echo "Deleting Logstash"
   kubectl delete deployment -n $OAMNS oam-logstash >> $LOG 2>&1
   echo "Deleting Logstash configmap"
   kubectl delete cm -n $OAMNS oam-logstash-configmap >> $LOG 2>&1
   kubectl delete cm -n $OAMNS  elk-cert  >> $LOG 2>&1
fi

echo "Deleting OAM Domain"
kubectl delete domain $OAM_DOMAIN_NAME -n $OAMNS >> $LOG 2>&1
echo "Deleting Config Map"
kubectl delete configmaps $OAM_DOMAIN_NAME-create-oam-infra-domain-job-cm -n $OAMNS >> $LOG 2>&1

echo "Check Servers Stopped"
check_stopped $OAMNS adminserver

# Drop OAM Schemas
#
ST=`date +%s`

echo "Recreating Helper Pod."
remove_helper_pod $OAMNS
create_helper_pod $OAMNS $OAM_IMAGE:$OAM_VER

printf "Dropping Schemas - "
drop_schemas  $OAMNS $OAM_DB_SCAN $OAM_DB_LISTENER $OAM_DB_SERVICE $OAM_RCU_PREFIX OAM $OAM_DB_SYS_PWD $OAM_SCHEMA_PWD >> $LOG 2>&1
ET=`date +%s`

grep -q "Prefix validation failed." $LOG
if [ $? -eq 0 ]
then
     echo "Schema Does not exist"
else
     grep -q "ORA-01940" $LOG
     if [ $? -eq 0 ]
     then
          echo "Failed User Connected logfile $LOG"
          exit 1
     fi

     grep -q "Repository Creation Utility - Drop : Operation Completed" $LOG
     if [ $? -eq 0 ]
     then
          echo "Success"
     else
          echo "Failed see logfile $LOG"
          exit 1
     fi
fi

echo "Deleting Namespace $OAMNS"
kubectl delete namespace $OAMNS  >> $LOG 2>&1

# Delete All contents in the Persistent Volumes
# Requires that the PV is mounted locally

# Remove Persistent Volume & Claim from Kubernetes
#
echo "Removing Persistent Volumes"
kubectl delete pv $OAM_DOMAIN_NAME-domain-pv  >> $LOG 2>&1

echo "Deleting Volumes"

if [ ! "$OAM_LOCAL_SHARE" = "" ]
then
  rm -rf  $OAM_LOCAL_SHARE/applications $OAM_LOCAL_SHARE/domains $OAM_LOCAL_SHARE/dr_scripts $OAM_LOCAL_SHARE/keystores $OAM_LOCAL_SHARE/logs $OAM_LOCAL_SHARE/workdir >> $LOG 2>&1
fi


if [ ! "$WORKDIR" = "" ] && [ ! "$LOGDIR" = "" ] && [ ! "$LOCAL_WORKDIR" = "" ]
then
  rm  -rf $WORKDIR/* 
  rm  -rf $LOCAL_WORKDIR/OHS/*/login_vh.conf $LOCAL_WORKDIR/OHS/*/iadadmin_vh.conf $LOCAL_WORKDIR/oam_installed>> $LOG 2>&1
else
  echo "Unable to delete volumes."
fi


FINISH_TIME=`date +%s`
print_time TOTAL "Delete OAM " $START_TIME $FINISH_TIME 
