#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OAM deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oam.sh
#
. ../common/functions.sh
. $RSPFILE
WORKDIR=$LOCAL_WORKDIR/OAM
LOGDIR=$WORKDIR/logs


START_TIME=`date +%s`

ST=`date +%s`

# Delete Kubernetes Objects
#
kubectl delete jobs $OAM_DOMAIN_NAME-create-oam-infra-domain-job -n $OAMNS
if [ -f $WORKDIR/policy_nodeport.yaml ]
then
    kubectl delete -n $OAMNS -f $WORKDIR/policy_nodeport.yaml
    kubectl delete -n $OAMNS -f $WORKDIR/oam_nodeport.yaml
    kubectl delete -n $OAMNS -f $WORKDIR/oap_nodeport.yaml
fi
kubectl delete domain $OAM_DOMAIN_NAME -n $OAMNS
kubectl delete configmaps $OAM_DOMAIN_NAME-create-oam-infra-domain-job-cm -n $OAMNS

ET=`date +%s`
print_time STEP "Delete Domain" $ST $ET 

ST=`date +%s`
check_stopped $OAMNS adminserver

ET=`date +%s`
print_time STEP "Stop Servers" $ST $ET 

# Drop OAM Schemas
#
ST=`date +%s`
drop_schemas  $OAMNS $OAM_DB_SCAN $OAM_DB_LISTENER $OAM_DB_SERVICE $OAM_RCU_PREFIX OAM $OAM_DB_SYS_PWD $OAM_SCHEMA_PWD
ET=`date +%s`

print_time STEP "Drop Schemas" $ST $ET 


# Delete All contents in the Persistent Volumes
# Requires that the PV is mounted locally

ST=`date +%s`
echo "Deleting Volumes"
rm -rf $OAM_LOCAL_SHARE/*
rm  -rf $WORKDIR/* > /dev/null

# Remove Persistent Volume & Claim from Kubernetes
#
kubectl delete pvc -n $OAMNS $OAM_DOMAIN_NAME-domain-pvc
kubectl delete pv $OAM_DOMAIN_NAME-domain-pv

ET=`date +%s`
print_time STEP "Delete Volume" $ST $ET 
kubectl delete namespace $OAMNS

FINISH_TIME=`date +%s`
print_time TOTAL "Delete OAM Domain" $START_TIME $FINISH_TIME 
