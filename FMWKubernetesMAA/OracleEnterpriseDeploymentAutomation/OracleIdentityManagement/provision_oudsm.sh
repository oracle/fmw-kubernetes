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
WORKDIR=$LOCAL_WORKDIR/OUD
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

rm $LOGDIR/progressfile
STEPNO=1
PROGRESS=$(get_progress)
if [ $STEPNO -gt $PROGRESS ]
then
     if [ -d $WORKDIR/fmw-kubernetes ]
     then
          echo "IDM FMW Samples already downloaded - Skipping"
     else
        download_samples $WORKDIR
     fi
fi

# Create Helm Override File
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_oudsm_override
fi

# Create OUDSM
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_oudsm
    check_oudsm_started
fi

# Create OUDSM Nodeport
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_oudsm_nodeport
fi

FINISH_TIME=`date +%s`
print_time TOTAL "Create OUDSM" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log
