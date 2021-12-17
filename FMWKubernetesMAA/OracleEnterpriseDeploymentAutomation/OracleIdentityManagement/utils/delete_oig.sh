#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OIG deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oig.sh
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $MYDIR/../common/functions.sh
. $RSPFILE
export WORKDIR=$LOCAL_WORKDIR/OIG

LOGDIR=$WORKDIR/logs

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

echo "Delete NodePort Services"
if [ -f $WORKDIR/oim_nodeport.yaml ]
then
   kubectl delete service -n $OIGNS $OIG_DOMAIN_NAME-oim-nodeport >> $LOG 2>&1
   kubectl delete service -n $OIGNS $OIG_DOMAIN_NAME-soa-nodeport >> $LOG 2>&1
fi
 
if [ -f $WORKDIR/oim_t3_nodeport.yaml ]
then
   kubectl delete service -n $OIGNS $OIG_DOMAIN_NAME-oim-t3-nodeport >> $LOG 2>&1
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
echo "Drop Schemas"

ST=`date +%s`
drop_schemas  $OIGNS $OIG_DB_SCAN $OIG_DB_LISTENER $OIG_DB_SERVICE $OIG_RCU_PREFIX OIG $OIG_DB_SYS_PWD $OIG_SCHEMA_PWD >> $LOG 2>&1
ET=`date +%s`

print_time STEP "Drop Schemas" $ST $ET 



ST=`date +%s`
echo "Deleting Volumes"

# Delete the files in the persistent volumes
rm -rf  $OIG_LOCAL_SHARE/*  >> $LOG 2>&1
rm  -rf $WORKDIR/*  >> $LOG 2>&1
rm  -rf $WORKDIR/* $LOCAL_WORKDIR/OHS/*/prov_vh.conf $LOCAL_WORKDIR/OHS/*/igd*_vh.conf>> $LOG 2>&1

ET=`date +%s`
print_time STEP "Delete Volume" $ST $ET 

# Remove Persistent Volume and Claim
#
echo "Remove Persistent Volumes"
kubectl delete pvc -n $OIGNS $OIG_DOMAIN_NAME-domain-pvc  >> $LOG 2>&1
kubectl delete pv $OIG_DOMAIN_NAME-domain-pv  >> $LOG 2>&1

echo "Delete Namespace"
kubectl delete namespace  $OIGNS  >> $LOG 2>&1

FINISH_TIME=`date +%s`
print_time TOTAL "Delete OIG Domain" $START_TIME $FINISH_TIME 
