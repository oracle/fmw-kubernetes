#!/bin/bash
# Copyright (c) 2021, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete the WebLogic Operator
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_operator.sh  [-r responsefile ]
#
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTDIR=$SCRIPTDIR/..

while getopts 'r:' OPTION
do
  case "$OPTION" in
    r)
      RSPFILE=$SCRIPTDIR/responsefile/$OPTARG
     ;;
    ?)
     echo "script usage: $(basename $0) [-r responsefile ] " >&2
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
if [ ! "$LOCAL_WORKDIR" = "" ]
then
  rm -rf $LOCAL_WORKDIR/OPER/*  $LOCAL_WORKDIR/operator_installed >> $LOG 2>&1

  if [ ! "$DELETE_SAMPLES" = "false" ]
  then
    echo "Delete Samples Directory"
    rm -rf $LOCAL_WORKDIR/$SAMPLES_DIR $LOCAL_WORKDIR/samples >> $LOG 2>&1
  else
    echo "Samples not deleted."
  fi
else
  echo "Unable to Delete Work Directory."
fi

