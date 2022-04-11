#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OUDSM deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oudsm.sh
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $MYDIR/../common/functions.sh
. $RSPFILE

mkdir $LOCAL_WORKDIR/deleteLogs > /dev/null 2>&1

LOG=$LOCAL_WORKDIR/deleteLogs/delete_oudsm_`date +%F_%T`.log

START_TIME=`date +%s`

ST=`date +%s`

echo "Deleting Oracle Unified Directory Service Manager"
echo "-------------------------------------------------"
echo
echo Log of Delete Session can be found at: $LOG
echo

if [ "$USE_INGRESS" = "false" ]
then
   echo "Delete NodePort Services"
   kubectl delete service -n $OUDNS oudsm-nodeport >> $LOG 2>&1
fi

echo "Delete OUDSM Application"
helm uninstall -n $OUDNS oudsm  >> $LOG 2>&1

echo "Check Server Stopped"
check_stopped $OUDNS oudsm-1 >> $LOG 2>&1

echo "Delete Volumes"
rm -rf $OUDSM_LOCAL_SHARE/* $LOCAL_WORKDIR/OUDSM/* >> $LOG 2>&1

FINISH_TIME=`date +%s`
print_time TOTAL "Delete OUDSM " $START_TIME $FINISH_TIME
