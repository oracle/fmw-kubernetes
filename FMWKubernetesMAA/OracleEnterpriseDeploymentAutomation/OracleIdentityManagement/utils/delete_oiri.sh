#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OIRI deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oiri.sh
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $MYDIR/../common/functions.sh
. $MYDIR/../common/oiri_functions.sh
. $RSPFILE
WORKDIR=$LOCAL_WORKDIR/OIRI
LOGDIR=$WORKDIR/logs
PROGRESS=$(get_progress)
START_TIME=`date +%s`

mkdir $LOCAL_WORKDIR/deleteLogs > /dev/null 2>&1

LOG=$LOCAL_WORKDIR/deleteLogs/delete_oiri_`date +%F_%T`.log

START_TIME=`date +%s`

ST=`date +%s`

echo "Deleting Oracle Identity Role Intelligence"
echo "------------------------------------------"
echo
echo Log of Delete Session can be found at: $LOG
echo

if [ "$USE_ELK" = "true" ]
then
   echo "Deleting Logstash"
   kubectl delete deployment -n $OIRINS oiri-logstash >> $LOG 2>&1
   echo "Deleting Logstash configmap"
   kubectl delete cm -n $OIRINS oiri-logstash-configmap >> $LOG 2>&1
fi

echo "Deleting OIRI Application"
oiri_cli "helm delete oiri" > $LOG 2>&1


ST=`date +%s`
echo "Drop Schemas"
if [ $PROGRESS -gt 13 ]
then
   delete_schemas
fi
ET=`date +%s`

print_time STEP "Drop Schemas" $ST $ET

echo "Delete Role Bindings and Service Account"
kubectl delete rolebinding -n $OIRINS oiri-rolebinding >> $LOG 2>&1
kubectl delete clusterrolebinding oiri-clusterrolebinding >> $LOG 2>&1
kubectl delete role ding-ns-role -n $DINGNS >> $LOG 2>&1
kubectl delete role oiri-ns-role-ns-role -n $OIRINS >> $LOG 2>&1
kubectl delete serviceaccount -n $OIRINS oiri-service-account >> $LOG 2>&1

echo "Delete OIRI-CLI pod"
kubectl delete pod -n $OIRINS oiri-cli >> $LOG 2>&1
echo "Delete DING-CLI pod"
kubectl delete pod -n $DINGNS oiri-ding-cli >> $LOG 2>&1

echo "Delete Namespaces"
kubectl delete namespace $OIRINS >> $LOG 2>&1
kubectl delete namespace $DINGNS >> $LOG 2>&1

echo "Deleting Volumes"
ST=`date +%s`
rm -rf $LOGDIR/progressfile $WORKDIR/* $LOCAL_WORKDIR/oiri_installed >> $LOG 2>&1
rm -rf $OIRI_LOCAL_SHARE/* $OIRI_DING_LOCAL_SHARE/*  >> $LOG 2>&1
ET=`date +%s`
print_time STEP "Delete Volumes" $ST $ET

FINISH_TIME=`date +%s`
print_time TOTAL "Delete OIRI " $START_TIME $FINISH_TIME
