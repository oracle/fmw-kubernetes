#!/bin/bash
# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of deploying the WebLogic Kubernetes Operator
#
# Dependencies: ./common/functions.sh
#               ./responsefile/idm.rsp
#
# Usage: provision_operator.sh [-r responsefile -p passwordfile]
#
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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


WORKDIR=$LOCAL_WORKDIR/OPER
LOGDIR=$WORKDIR/logs
OPER_DIR=OracleAccessManagement

if [ "$INSTALL_OAM" != "true" ] && [ "$INSTALL_OAM" != "TRUE" ] &&  [ "$INSTALL_OIG" != "true" ] && [ "$INSTALL_OIG" != "TRUE" ]
then
     echo "You have not requested OAM or OIG installation"
     exit 1
fi

if [ "$INSTALL_WLSOPER" != "true" ]
then
     echo "You have not requested WebLogic Kubernetes Operator installation"
     exit 1
fi

echo
echo -n "Provisioning WebLogic Kubernetes Operator on "
date +"%a %d %b %Y %T"
echo "---------------------------------------------------------------------"
echo

START_TIME=`date +%s`
create_local_workdir
create_logdir

echo -n "Provisioning WebLogic Kubernetes Operator on " >> $LOGDIR/timings.log
date >> $LOGDIR/timings.log
echo "--------------------------------------------------------------------" >> $LOGDIR/timings.log

STEPNO=1
PROGRESS=$(get_progress)

if [ $STEPNO -gt $PROGRESS ]
then
   download_samples 
   update_progress

fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    copy_samples $OPER_DIR
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
     delete_crd 
     update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
     create_namespace $OPERNS
     update_progress
fi

# Create a Container Registry Secret if requested
#
if [ "$CREATE_REGSECRET" = "true" ] && [ "$OPER_ENABLE_SECRET" = "true" ]
then
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
     create_registry_secret $REGISTRY $REG_USER $REG_PWD $OPERNS
     update_progress
  fi
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
     create_service_account $OPER_ACT $OPERNS
     update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   install_operator
   update_progress
fi


new_step
if [ $STEPNO -gt $PROGRESS ]
then
    check_running $OPERNS weblogic-operator 10 true
    update_progress
fi

if [ "$USE_ELK" = "true" ]
then
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_elk_secret $OPERNS
       update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_cert_secret $OPERNS
       update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       download_oper_cm
       update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       update_oper_cm
       update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       load_oper_cm
       update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       restart_operator
       update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     create_elk_dataview wko
     update_progress
   fi
fi
  
FINISH_TIME=`date +%s`
print_time TOTAL "Install WebLogic Kubernetes Operator " $START_TIME $FINISH_TIME
print_time TOTAL "Install WebLogic Kubernetes Operator" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log
touch $LOCAL_WORKDIR/operator_installed
exit

#
