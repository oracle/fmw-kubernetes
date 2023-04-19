#!/bin/bash
# Copyright (c) 2022, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OHS deployment
#
# Dependencies: ../common/functions.sh
#               ../common/ohs_functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_ohs.sh  [-r responsefile -p passwordfile]
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
. $SCRIPTDIR/common/ohs_functions.sh

WORKDIR=$LOCAL_WORKDIR/OHS
TEMPLATE_DIR=$SCRIPTDIR/templates/ohs

mkdir $LOCAL_WORKDIR/deleteLogs > /dev/null 2>&1

LOG=$LOCAL_WORKDIR/deleteLogs/delete_ohs_`date +%F_%T`.log

START_TIME=`date +%s`

ST=`date +%s`

echo "Deleting Oracle HTTP Server"
echo "---------------------------"
echo
echo Log of Delete Session can be found at: $LOG
echo


if [ ! "$INSTALL_OHS" = "true" ]
then
    echo "OHS Was not installed by the automation scripts.  Delete Manually."
    exit
fi

if [ ! "$OHS_HOST1" = "" ]
then
    echo "Stopping OHS Server on $OHS_HOST1"
    stop_ohs $OHS_HOST1 $OHS1_NAME >> $LOG 2>&1
    echo "Stopping Node Manager on $OHS_HOST1"
    stop_nm $OHS_HOST1 >> $LOG 2>&1

    echo "Deleting OHS Instance $OHS1_NAME"
    delete_instance $OHS_HOST1 $OHS1_NAME >> $LOG 2>&1

    echo "Deleting OHS Instance Files on $OHS1_NAME"
    $SSH ${OHS_USER}@$OHS_HOST1 "rm -rf $OHS_DOMAIN" >> $LOG 2>&1

    echo "Deleting OHS Install on $OHS_HOST1"
    $SSH ${OHS_USER}@$OHS_HOST1 "rm -rf $OHS_ORACLE_HOME" >> $LOG 2>&1

    echo "Deleting Oracle Inventory on $OHS_HOST1"
    $SSH ${OHS_USER}@$OHS_HOST1 "rm -rf $OHS_BASE/oraInventory" >> $LOG 2>&1
fi

if [ ! "$OHS_HOST2" = "" ]
then
    echo "Stopping OHS Server on $OHS_HOST2"
    stop_ohs $OHS_HOST2 $OHS2_NAME >> $LOG 2>&1
    echo "Stopping Node Manager on $OHS_HOST2"
    stop_nm $OHS_HOST2 >> $LOG 2>&1

    echo "Deleting OHS Instance $OHS2_NAME"
    delete_instance $OHS_HOST2 $OHS2_NAME >> $LOG 2>&1

    echo "Deleting OHS Instance files on $OHS2_NAME"
    $SSH ${OHS_USER}@$OHS_HOST2 "rm -rf $OHS_DOMAIN" >> $LOG 2>&1

    echo "Deleting OHS Install on $OHS_HOST2"
    $SSH ${OHS_USER}@$OHS_HOST2 "rm -rf $OHS_ORACLE_HOME" >> $LOG 2>&1

    echo "Deleting Oracle Inventory on $OHS_HOST2"
    $SSH ${OHS_USER}@$OHS_HOST2 "rm -rf $OHS_BASE/oraInventory" >> $LOG 2>&1
fi

echo "Delete Working Directory"
if  [ ! "$LOCAL_WORKDIR" = "" ]
then
  rm -rf $LOCAL_WORKDIR/OHS $LOCAL_WORKDIR/ohs_installed
else
  echo "Unable to Delete Working Directory."
fi


FINISH_TIME=`date +%s`
print_time TOTAL "Delete OHS " $START_TIME $FINISH_TIME
