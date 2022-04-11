#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of provisioning Oracle Unified Directory Services Manager
#
# Dependencies: ./common/functions.sh
#               ./common/oud_functions.sh
#               ./templates/oudsm
#               ./responsefile/idm.rsp
#
# Usage: provision_oudsm.sh
#
. common/functions.sh
. common/oud_functions.sh
. $RSPFILE
TEMPLATE_DIR=$SCRIPTDIR/templates/oudsm

START_TIME=`date +%s`
WORKDIR=$LOCAL_WORKDIR/OUDSM
OPER_DIR=OracleUnifiedDirectorySM

LOGDIR=$WORKDIR/logs

if [ "$INSTALL_OUDSM" != "true" ] && [ "$INSTALL_OUDSM" != "TRUE" ]
then
     echo "You have not requested OUDSM installation"
     exit 1
fi

echo
echo -n "Provisioning OUDSM on "
date +"%a %d %b %Y %T"
echo "--------------------------------------------------"
echo

create_local_workdir
create_logdir

echo -n "Provisioning OUDSM on " >> $LOGDIR/timings.log
date +"%a %d %b %Y %T" >> $LOGDIR/timings.log
echo "-------------------------------------------------" >> $LOGDIR/timings.log

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

# Create Helm Override File
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_oudsm_override
    update_progress
fi

# Create OUDSM
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_oudsm
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    check_oudsm_started
    update_progress
fi

# Create NodePort for OUDSM
#
new_step
if [ $STEPNO -gt $PROGRESS ] && [ "$USE_INGRESS" = "false" ]
then
    create_oudsm_nodeport
    update_progress
fi

# Create OUDSM OHS Entries
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_oudsm_ohs_entries
    update_progress
fi

FINISH_TIME=`date +%s`
print_time TOTAL "Create OUDSM" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log
