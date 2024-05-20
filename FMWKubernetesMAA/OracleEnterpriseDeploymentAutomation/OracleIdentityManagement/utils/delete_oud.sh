#!/bin/bash
# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OUD deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oud.sh [-r responsefile -p passwordfile]
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

LOG=$LOCAL_WORKDIR/deleteLogs/delete_oud_`date +%F_%T`.log

START_TIME=`date +%s`

ST=`date +%s`

echo "Deleting Oracle Unified Directory"
echo "---------------------------------"
echo
echo Log of Delete Session can be found at: $LOG
echo

if [ "$OUDNS" = "$OUDSMNS" ]
then
    echo "Check OUDSM is not installed"
    kubectl get svc -n $OUDSMNS | grep oudsm

    if [ $? = 0 ]
    then
       echo "Need to delete OUDSM first."
       exit 1
    fi
fi
if [ "$USE_INGRESS" = "true" ]
then
    echo "Delete Ingress"
    helm uninstall -n $OUDINGNS  $OUD_POD_PREFIX-nginx >> $LOG 2>&1
fi

if [ "$USE_ELK" = "true" ]
then
   echo "Deleting Logstash"
   kubectl delete deployment -n $OUDNS oud-logstash >> $LOG 2>&1
   echo "Deleting Logstash configmap"
   kubectl delete cm -n $OUDNS oud-logstash-configmap >> $LOG 2>&1
   kubectl delete cm -n $OUDNS  elk-cert  >> $LOG 2>&1
fi

echo "Delete OUD Application"
helm uninstall -n $OUDNS $OUD_POD_PREFIX   >> $LOG 2>&1

echo "Check Instances Stopped"
check_stopped $OUDNS $OUD_POD_PREFIX-oud-ds-rs-0
check_stopped $OUDNS $OUD_POD_PREFIX-oud-ds-rs-1

echo "Delete Namespace $OUDNS"
kubectl delete namespace $OUDNS

echo "Delete Volumes"
if [ ! "$LOCAL_WORKDIR" = "" ]
then
  rm -rf $LOCAL_WORKDIR/OUD $LOCAL_WORKDIR/oud_installed
else
  echo "Unable to Delete Volumes."
fi

if [ ! "$OUD_LOCAL_SHARE" = "" ] && [ ! "$OUD_POD_PREFIX" = "" ]
then
  rm -rf $OUD_LOCAL_SHARE/${OUD_POD_PREFIX}*
else
  echo "Unable to Delete Volumes."
fi


FINISH_TIME=`date +%s`
print_time TOTAL "Delete OUD " $START_TIME $FINISH_TIME
