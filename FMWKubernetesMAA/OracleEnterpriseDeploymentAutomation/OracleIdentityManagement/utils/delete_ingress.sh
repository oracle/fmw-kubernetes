#!/bin/bash
# Copyright (c) 2022, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OUD deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_ingress.sh [-r responsefile]
#
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTDIR=$SCRIPTDIR/..

while getopts 'r:' OPTION
do
  case "$OPTION" in
    r)
      RSPFILE=$SCRIPTDIR/responsefile/$OPTARG
     ;;
    p)
      PWDFILE=$SCRIPTDIR/responsefile/$OPTARG
     ;;
    ?)
      echo "script usage: $(basename $0) [-r responsefile] " >&2
      exit 1
      ;;
   esac
done


RSPFILE=${RSPFILE=$SCRIPTDIR/responsefile/idm.rsp}

. $RSPFILE
if [ $? -gt 0 ]
then
    echo "Responsefile : $RSPFILE does not exist."
    exit 1
fi

. $SCRIPTDIR/common/functions.sh

WORKDIR=$LOCAL_WORKDIR/INGRESS

mkdir $LOCAL_WORKDIR/deleteLogs > /dev/null 2>&1

LOG=$LOCAL_WORKDIR/deleteLogs/delete_ingress_`date +%F_%T`.log

START_TIME=`date +%s`

ST=`date +%s`

echo "Deleting Ingress Controller"
echo "---------------------------"
echo
echo Log of Delete Session can be found at: $LOG
echo


echo "Delete Ingress"
helm uninstall -n $INGRESSNS  nginx-ingress >> $LOG 2>&1

echo "Delete Namespace $INGRESSNS"

kubectl delete namespace $INGRESSNS  >> $LOG 2>&1

if [ ! "$WORKDIR" = "" ] && [ ! "$LOCAL_WORKDIR" = "" ]
then
   rm  -rf $WORKDIR/logs $LOCAL_WORKDIR/ingress_installed
fi
FINISH_TIME=`date +%s`
print_time TOTAL "Delete INGRESS " $START_TIME $FINISH_TIME
