#!/bin/bash
# Copyright (c) 2021, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OIG deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oig.sh [-r responsefile -p passwordfile]
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

export WORKDIR=$LOCAL_WORKDIR/OIG
LOGDIR=$LOCAL_WORKDIR/delete_logs/OIG
if [ ! -e $LOGDIR ]
then
  mkdir -p $LOGDIR
fi

START_TIME=`date +%s`

mkdir $LOCAL_WORKDIR/deleteLogs > /dev/null 2>&1

LOG=$LOCAL_WORKDIR/deleteLogs/delete_oig_`date +%F_%T`.log

START_TIME=`date +%s`

ST=`date +%s`

echo "Deleting Oracle Identity Governance"
echo "-----------------------------------"
echo
echo Log of Delete Session can be found at: $LOG
echo

# Delete OIG Kubernetes Objects
#
ST=`date +%s`
echo "Delete Domain Creation Job"
kubectl delete jobs $OIG_DOMAIN_NAME-create-fmw-infra-sample-domain-job -n $OIGNS > $LOG 2>&1

if [ "$USE_INGRESS" = "true" ]
then
   echo "Delete Ingress Services"
   kubectl delete ingress -n $OIGNS oigadmin-ingress >> $LOG 2>&1
   kubectl delete ingress -n $OIGNS oiginternal-ingress >> $LOG 2>&1
   kubectl delete ingress -n $OIGNS oigruntime-ingress >> $LOG 2>&1
else
   echo "Delete NodePort Services"
   kubectl delete service -n $OIGNS $OIG_DOMAIN_NAME-oim-nodeport >> $LOG 2>&1
   kubectl delete service -n $OIGNS $OIG_DOMAIN_NAME-soa-nodeport >> $LOG 2>&1
fi
 
if [ -f $WORKDIR/oim_t3_nodeport.yaml ]
then
   kubectl delete service -n $OIGNS $OIG_DOMAIN_NAME-oim-t3-nodeport >> $LOG 2>&1
fi

ELK_DEP=`kubectl get deployment -n $OIGNS | grep logstash | awk '{ print $1 }'`
if [ ! "$ELK_DEP" = "" ]
then
   echo "Deleting Logstash"
   kubectl delete deployment -n $OIGNS oig-logstash >> $LOG 2>&1
   echo "Deleting Logstash configmap"
   kubectl delete cm -n $OIGNS oig-logstash-configmap >> $LOG 2>&1
   kubectl delete cm -n $OIGNS  elk-cert  >> $LOG 2>&1
fi

echo "Delete OIG Domain"
kubectl delete domain $OIG_DOMAIN_NAME -n $OIGNS >> $LOG 2>&1

ET=`date +%s`
print_time STEP "Delete Domain" $ST $ET 

# Wait for the admin server to be stopped
#
ST=`date +%s`
echo "Check Servers Stopped"
check_stopped $OIGNS adminserver

# Drop the OIG schemas
#

echo "Recreating helper pod."

kubectl delete pod -n $OIGNS helper > /dev/null 2>&1

create_helper_pod $OIGNS $OIG_IMAGE:$OIG_VER


ST=`date +%s`
kubectl get pod -n $OIGNS helper > /dev/null 2>&1

if [ $? -gt 0 ]
then
   create_helper_pod $OIGNS $OIG_IMAGE:$OIG_VER
fi

printf "Drop Schemas - "
drop_schemas  $OIGNS $OIG_DB_SCAN $OIG_DB_LISTENER $OIG_DB_SERVICE $OIG_RCU_PREFIX OIG $OIG_DB_SYS_PWD $OIG_SCHEMA_PWD >> $LOG 2>&1
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

print_time STEP "Drop Schemas" $ST $ET 



echo "Delete Namespace"
kubectl delete namespace  $OIGNS  >> $LOG 2>&1

# Remove Persistent Volume and Claim
#
echo "Remove Persistent Volumes"
kubectl delete pv $OIG_DOMAIN_NAME-domain-pv  >> $LOG 2>&1


ST=`date +%s`
echo "Deleting Volumes"

if [ ! "$OIG_LOCAL_SHARE" = "" ]
then
  rm -rf  $OIG_LOCAL_SHARE/applications $OIG_LOCAL_SHARE/domains $OIG_LOCAL_SHARE/dr_scripts $OIG_LOCAL_SHARE/ConnectorDefaultDirectory $OIG_LOCAL_SHARE/keystores $OIG_LOCAL_SHARE/logs $OIG_LOCAL_SHARE/workdir >> $LOG 2>&1
else
  echo "Unable to Delete Volumes."
fi

if [ ! "$WORKDIR" = "" ] && [ ! "$LOGDIR" = "" ] && [ ! "$LOCAL_WORKDIR" = "" ]
then
   rm -rf $LOGDIR/progressfile $WORKDIR/* $LOCAL_WORKDIR/oaa_installed >> $LOG 2>&1
   rm -rf $LOCAL_WORKDIR/OHS/*/prov_vh.conf $LOCAL_WORKDIR/OHS/*/igd*_vh.conf $LOCAL_WORKDIR/oig_installed>> $LOG 2>&1
else
   echo "Unable to Delete Volumes."
fi


ET=`date +%s`
print_time STEP "Delete Volume" $ST $ET 


FINISH_TIME=`date +%s`
print_time TOTAL "Delete OIG Domain" $START_TIME $FINISH_TIME 
