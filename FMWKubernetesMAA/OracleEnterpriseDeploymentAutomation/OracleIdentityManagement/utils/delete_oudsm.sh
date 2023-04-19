#!/bin/bash
# Copyright (c) 2021, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OUDSM deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oudsm.sh  [-r responsefile -p passwordfile]
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
else
   echo "Delete Ingress Services"
   kubectl delete ingress -n $OUDNS oudsm-ingress >> $LOG 2>&1
fi

if [ "$USE_ELK" = "true" ]
then
   echo "Deleting Logstash"
   kubectl delete deployment -n $OUDNS oudsm-logstash  >> $LOG 2>&1
   echo "Deleting Logstash configmap"
   kubectl delete cm -n $OUDNS oudsm-logstash-configmap  >> $LOG 2>&1
fi

echo "Delete OUDSM Application"
helm uninstall -n $OUDNS oudsm  >> $LOG 2>&1

check_stopped $OUDNS oudsm-1 

if [ "$USE_ELK" = "true" ]
then
    check_stopped $OUDNS oudsm-es-cluster-0 
fi

echo "Delete Volumes"
if [ ! "$OUDSM_LOCAL_SHARE" = "" ] && [ ! "$LOCAL_WORKDIR" = "" ]
then
   rm -rf $OUDSM_LOCAL_SHARE/* $LOCAL_WORKDIR/OUDSM/* $LOCAL_WORKDIR/oudsm_installed>> $LOG 2>&1
else
   echo "Unable to Delete Volumes."
fi

FINISH_TIME=`date +%s`
print_time TOTAL "Delete OUDSM " $START_TIME $FINISH_TIME
