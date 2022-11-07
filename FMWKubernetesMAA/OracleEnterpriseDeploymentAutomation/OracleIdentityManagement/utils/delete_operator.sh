#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete the WebLogic Operator
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_operator.sh
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $MYDIR/../common/functions.sh
. $RSPFILE

mkdir $LOCAL_WORKDIR/deleteLogs > /dev/null 2>&1

LOG=$LOCAL_WORKDIR/deleteLogs/delete_operator_`date +%F_%T`.log

START_TIME=`date +%s`

ST=`date +%s`

echo "Deleting WebLogic Operator"
echo "--------------------------"
echo
echo Log of Delete Session can be found at: $LOG
echo

echo "Delete Operator"
helm uninstall --namespace $OPERNS weblogic-kubernetes-operator > $LOG 2>&1

echo "Delete Namepace"
kubectl delete namespace $OPERNS >> $LOG 2>&1

echo "Delete Work Directory"
rm -rf $LOCAL_WORKDIR/OPER/* >> $LOG 2>&1

echo "Delete Samples Directory"
rm -rf $LOCAL_WORKDIR/$SAMPLES_DIR $LOCAL_WORKDIR/samples $LOCAL_WORKDIR/operator_installed>> $LOG 2>&1
