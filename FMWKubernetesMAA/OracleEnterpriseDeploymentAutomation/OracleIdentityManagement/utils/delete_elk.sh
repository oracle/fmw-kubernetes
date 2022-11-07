#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an Elastic Search deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_elk.sh
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $MYDIR/../common/functions.sh
. $RSPFILE

WORKDIR=$LOCAL_WORKDIR/ELK

mkdir $LOCAL_WORKDIR/deleteLogs > /dev/null 2>&1

LOG=$LOCAL_WORKDIR/deleteLogs/delete_elk_`date +%F_%T`.log

START_TIME=`date +%s`

ST=`date +%s`

echo "Deleting ELK and Kibana Controller"
echo "----------------------------------"
echo
echo Log of Delete Session can be found at: $LOG
echo


echo "Delete Kibana"
kubectl delete service -n $ELKNS kibana-nodeport >> $LOG 2>&1
kubectl delete service -n $ELKNS elk-nodeport >> $LOG 2>&1
kubectl delete kibana -n $ELKNS kibana

echo "Delete ELK Cluster"
kubectl delete elasticsearch -n $ELKNS elasticsearch >> $LOG 2>&1

echo "Delete Elastic Search Operator"
helm uninstall -n $ELKNS  elastic-operator >> $LOG 2>&1

echo "Delete Namespace $ELKNS"

kubectl delete namespace $ELKNS  >> $LOG 2>&1

rm  -rf $WORKDIR/logs $LOCAL_WORKDIR/elk_installed
FINISH_TIME=`date +%s`
print_time TOTAL "Delete ELK " $START_TIME $FINISH_TIME
