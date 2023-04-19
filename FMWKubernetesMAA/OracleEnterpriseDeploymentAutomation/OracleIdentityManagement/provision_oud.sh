#!/bin/bash
# Copyright (c) 2021, 2023, Oracle and/or its affiliates.
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
# Usage: provision_oud.sh [-r responsefile -p passwordfile]
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
. $SCRIPTDIR/common/oud_functions.sh

TEMPLATE_DIR=$SCRIPTDIR/templates/oud

START_TIME=`date +%s`
WORKDIR=$LOCAL_WORKDIR/OUD
LOGDIR=$WORKDIR/logs
OPER_DIR=OracleUnifiedDirectory

if [ "$INSTALL_OUD" != "true" ] && [ "$INSTALL_OUD" != "TRUE" ]
then
     echo "You have not requested OUD installation"
     exit 1
fi

echo 
echo -n "Provisioning OUD on " 
date +"%a %d %b %Y %T" 
echo "--------------------------------------------" 
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
     download_samples
     update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    copy_samples $OPER_DIR
    update_progress
fi

# Create Namespace and Helper Pod
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_namespace $OUDNS
    update_progress
fi

# Create a Container Registry Secret if requested
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   if [ "$CREATE_REGSECRET" = "true" ]
   then
       create_registry_secret $REGISTRY $REG_USER $REG_PWD $OUDNS
   fi
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_registry_secret "https://index.docker.io/v1/" $DH_USER $DH_PWD $OUDNS dockercred
   update_progress
fi

# Modify base data template
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    edit_seedfile
    update_progress
fi

# Create Helm override file
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_override
    update_progress
fi


# Copy template files to local share
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    copy_files_to_share
    update_progress
fi


# Use helm to create OUD
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_oud
   update_progress
fi

# Check OUD has Started
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   check_oud_started
   update_progress
fi
    
# Valiate OUD
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   validate_oud
   update_progress
fi

# Setup Ingress if required Otherwise create NodePort Services
#
if [ "$USE_INGRESS" = "false" ] 
then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
        create_oud_nodeport
        update_progress
    fi
fi


# Setup Logstash
#
if [ "$USE_ELK" = "true" ]
then
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_cert_cm $OUDNS
       update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_oud_logstash_cm
       update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_logstash $OUDNS
       update_progress
    fi

fi

FINISH_TIME=`date +%s`
print_time TOTAL "Create OUD" $START_TIME $FINISH_TIME 
print_time TOTAL "Create OUD" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

touch $LOCAL_WORKDIR/oud_installed
