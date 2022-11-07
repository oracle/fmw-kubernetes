#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete a Prometheus deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_prom.sh
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $MYDIR/../common/functions.sh
. $RSPFILE

WORKDIR=$LOCAL_WORKDIR/PROM

mkdir $LOCAL_WORKDIR/deleteLogs > /dev/null 2>&1

LOG=$LOCAL_WORKDIR/deleteLogs/delete_prom_`date +%F_%T`.log

START_TIME=`date +%s`

ST=`date +%s`

echo "Deleting Prometheus"
echo "-------------------"
echo
echo Log of Delete Session can be found at: $LOG
echo



echo "Delete Prometheus"
helm uninstall kube-prometheus -n $PROMNS >> $LOG 2>&1

echo "Delete CRDs"
kubectl delete crd -n $PROMNS alertmanagerconfigs.monitoring.coreos.com >> $LOG 2>&1
kubectl delete crd -n $PROMNS alertmanagers.monitoring.coreos.com >> $LOG 2>&1
kubectl delete crd -n $PROMNS podmonitors.monitoring.coreos.com >> $LOG 2>&1
kubectl delete crd -n $PROMNS probes.monitoring.coreos.com >> $LOG 2>&1
kubectl delete crd -n $PROMNS prometheuses.monitoring.coreos.com >> $LOG 2>&1
kubectl delete crd -n $PROMNS prometheusrules.monitoring.coreos.com >> $LOG 2>&1
kubectl delete crd -n $PROMNS servicemonitors.monitoring.coreos.com >> $LOG 2>&1
kubectl delete crd -n $PROMNS thanosrulers.monitoring.coreos.com >> $LOG 2>&1

echo "Delete Namespace"
kubectl delete namespace $PROMNS >> $LOG 2>&1

echo "Delete Working Directory"
rm  -rf $WORKDIR/* $LOCAL_WORKDIR/prom_installed

FINISH_TIME=`date +%s`
print_time TOTAL "Delete Prometheus " $START_TIME $FINISH_TIME
