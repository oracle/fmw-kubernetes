#!/bin/bash
# Copyright (c) 2021, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of provisioning Oracle Unified Directory Services Manager
#
# Dependencies: ./common/functions.sh
#               ./common/oud_functions.sh
#               ./templates/oudsm
#               ./responsefile/idm.rsp
#
# Usage: provision_oudsm.sh [-r responsefile -p passwordfile]
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

START_TIME=`date +%s`
TEMPLATE_DIR=$SCRIPTDIR/templates/oudsm
WORKDIR=$LOCAL_WORKDIR/OUDSM
OPER_DIR=OracleUnifiedDirectorySM

LOGDIR=$WORKDIR/logs

if [ "$INSTALL_OUDSM" != "true" ] && [ "$INSTALL_OUDSM" != "TRUE" ]
then
     echo "You have not requested OUDSM installation"
     exit 1
fi

if [ "$USE_INGRESS" = "true" ]
then
   INGRESS_HTTP_PORT=`get_k8_port $INGRESS_NAME $INGRESSNS http `
   INGRESS_HTTPS_PORT=`get_k8_port $INGRESS_NAME $INGRESSNS https`
   if [ "$INGRESS_HTTP_PORT" = "" ]
   then
       echo "Unable to get Ingress Ports - Check Ingress is running"
       exit 1
   fi
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
if [ $STEPNO -gt $PROGRESS ] 
then
   if [ "$USE_INGRESS" = "false" ]
   then
       create_oudsm_nodeport
       update_progress
   else 
       create_oudsm_ingress 
       update_progress
   fi
fi

# Create OUDSM OHS Entries
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_oudsm_ohs_entries
    update_progress
fi

if [ "$USE_ELK" = "true" ]
then
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_oudsm_logstash_cm
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
print_time TOTAL "Create OUDSM" $START_TIME $FINISH_TIME 
print_time TOTAL "Create OUDSM" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log
touch $LOCAL_WORKDIR/oudsm_installed
