#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of deploying the Oracle WebLogic Operator
#
# Dependencies: ./common/functions.sh
#               ./responsefile/idm.rsp
#
# Usage: provision_operator.sh
#
. common/functions.sh
. $RSPFILE


WORKDIR=$LOCAL_WORKDIR
LOGDIR=$WORKDIR/OPER/logs
OPER_DIR=OracleAccessManagement

if [ "$INSTALL_OAM" != "true" ] && [ "$INSTALL_OAM" != "TRUE" ] &&  [ "$INSTALL_OIG" != "true" ] && [ "$INSTALL_OIG" != "TRUE" ]
then
     echo "You have not requested OAM or OIG installation"
     exit 1
fi

echo
echo -n "Provisioning WLS Operator on "
date +"%a %d %b %Y %T"
echo "-----------------------------------------------------"
echo

START_TIME=`date +%s`
create_local_workdir
create_logdir

echo -n "Provisioning WLS Operator on " >> $LOGDIR/timings.log
date >> $LOGDIR/timings.log
echo "----------------------------------------------------" >> $LOGDIR/timings.log

STEPNO=1
PROGRESS=$(get_progress)


new_step
if [ $STEPNO -gt $PROGRESS ]
then
   download_samples $LOCAL_WORKDIR

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
if [ $STEPNO -gt $PROGRESS ]
then
   if [ "$CREATE_REGSECRET" = "true" ]
   then
      create_registry_secret $REGISTRY $REG_USER $REG_PWD $OPERNS
   fi
   update_progress
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
    print_msg "Check Operator is Running\n"
    check_running $OPERNS weblogic-operator 
    update_progress
fi


exit

#
