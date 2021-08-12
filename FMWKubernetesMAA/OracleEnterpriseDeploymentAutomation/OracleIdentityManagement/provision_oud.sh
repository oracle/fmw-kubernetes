#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of deploying Oracle Unified Directory, configuring it for use with Oracle Access Manager
# and Oracle Identity Governance.   It will also seed users and groups required by those products
#
# Dependencies: ./common/functions.sh
#               ./common/oud_functions.sh
#               ./responsefile/idm.rsp
#               ./templates/oud
#
# Usage: provision_oud.sh
#

. common/functions.sh
. common/oud_functions.sh
. $RSPFILE
TEMPLATES_DIR=$SCRIPTDIR/templates/oud

START_TIME=`date +%s`
WORKDIR=$LOCAL_WORKDIR/OUD
LOGDIR=$WORKDIR/logs

if [ "$INSTALL_OUD" != "true" ] && [ "$INSTALL_OUD" != "TRUE" ]
then
     echo "You have not requested OUD installation"
     exit 1
fi

echo 
echo -n "Provisioning OUD on " 
date +"%a %d %b %Y %T" 
echo "------------------------------------------------" 
echo 

create_local_workdir
create_logdir

echo -n "Provisioning OUD on " >> $LOGDIR/timings.log
date +"%a %d %b %Y %T" >> $LOGDIR/timings.log
echo "------------------------------------------------" >> $LOGDIR/timings.log

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

# Create Namespace and Helper Pod
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_namespace $OUDNS
fi

# Modify base data template
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    edit_seedfile
fi

# Create Helm override file
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_override
fi


# Copy template files to local share
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    copy_files_to_share
fi


# Use helm to create OUD
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_oud
   check_oud_started
fi


# If requested create Nodeport Services
#
if [ "$OUD_CREATE_NODEPORT" = "true" ] || [ "$OUD_CREATE_NODEPORT" = "TRUE" ]
then
    if [ $STEPNO -gt $PROGRESS ]
    then
        create_oud_nodeport
    fi
fi
    
FINISH_TIME=`date +%s`
print_time TOTAL "Create OUD" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

cat $LOGDIR/timings.log
