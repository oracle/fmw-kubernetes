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
. ../common/functions.sh
. $RSPFILE
export WORKDIR=$LOCAL_WORKDIR/OIG

LOGDIR=$WORKDIR/logs

START_TIME=`date +%s`

# Delete OIG Kubernetes Objects
#
ST=`date +%s`
kubectl delete jobs $OIG_DOMAIN_NAME-create-fmw-infra-sample-domain-job -n $OIGNS
if [ -f $WORKDIR/oim_nodeport.yaml ]
then
   kubectl delete -n $OIGNS -f $WORKDIR/oim_nodeport.yaml
   kubectl delete -n $OIGNS -f $WORKDIR/soa_nodeport.yaml
fi
 
if [ -f $WORKDIR/oim_t3_nodeport.yaml ]
then
   kubectl delete -n $OIGNS -f $WORKDIR/oim_t3_nodeport.yaml
fi

kubectl delete domain $OIG_DOMAIN_NAME -n $OIGNS

ET=`date +%s`
print_time STEP "Delete Domain" $ST $ET 

# Wait for the admin server to be stopped
#
ST=`date +%s`
check_stopped $OIGNS adminserver

ET=`date +%s`
print_time STEP "Stop Servers" $ST $ET 

# Drop the OIG schemas
#
ST=`date +%s`
drop_schemas  $OIGNS $OIG_DB_SCAN $OIG_DB_LISTENER $OIG_DB_SERVICE $OIG_RCU_PREFIX OIG $OIG_DB_SYS_PWD $OIG_SCHEMA_PWD
ET=`date +%s`

print_time STEP "Drop Schemas" $ST $ET 



ST=`date +%s`
echo "Deleting Volumes"

# Delete the files in the persistent volumes
rm -rf $OIG_LOCAL_SHARE/*
rm  -rf $WORKDIR/* > /dev/null

ET=`date +%s`
print_time STEP "Delete Volume" $ST $ET 

# Remove Persistent Volume and Claim
#
kubectl delete pvc -n $OIGNS $OIG_DOMAIN_NAME-domain-pvc
kubectl delete pv $OIG_DOMAIN_NAME-domain-pv
kubectl delete namespace  $OIGNS

FINISH_TIME=`date +%s`
print_time TOTAL "Delete OIG Domain" $START_TIME $FINISH_TIME 
