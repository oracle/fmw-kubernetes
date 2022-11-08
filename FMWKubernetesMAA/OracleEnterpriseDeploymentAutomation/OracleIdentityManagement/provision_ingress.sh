#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of deploying an Ingress Controller
#
# Dependencies: ./common/functions.sh
#               ./common/ingress_functions.sh
#               ./responsefile/idm.rsp
#               ./templates/ingress
#
# Usage: provision_ingress.sh
#

. common/functions.sh
. common/ingress_functions.sh

TEMPLATES_DIR=$SCRIPTDIR/templates/ingress/nginx

START_TIME=`date +%s`
WORKDIR=$LOCAL_WORKDIR/INGRESS
LOGDIR=$WORKDIR/logs

if [ "$INSTALL_INGRESS" != "true" ] && [ "$INSTALL_INGRESS" != "TRUE" ]
then
     echo "You have not requested an Ingress installation"
     exit 1
fi

echo 
echo -n "Provisioning Ingress : $INGRES_TYPE on " 
date +"%a %d %b %Y %T" 
echo "------------------------------------------" 
echo 

create_local_workdir
create_logdir

echo -n "Ingress : $INGRES_TYPE on" >> $LOGDIR/timings.log
date +"%a %d %b %Y %T" >> $LOGDIR/timings.log
echo "------------------------------------------------" >> $LOGDIR/timings.log

STEPNO=1
PROGRESS=$(get_progress)



# Create Namespace 
#
if [ $STEPNO -gt $PROGRESS ]
then
    create_namespace $INGRESSNS
    update_progress
fi

# Create Certificate
#
new_step
if [ $STEPNO -gt $PROGRESS ] 
then
    if [ "$INGRESS_SSL" = "true" ]
    then
       create_ingress_cert
       update_progress
    fi
fi

# Create GitHub Secret if requested
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   if [ "$CREATE_GITSECRET" = "true" ]
   then
       create_git_secret $GIT_USER $GIT_TOKEN $INGRESSNS
   fi
   update_progress
fi

# Add Ingress Repository
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_ingress_repo
    update_progress
fi

# Create Ingress Controller
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_ingress_controller
    update_progress
fi


FINISH_TIME=`date +%s`
print_time TOTAL "Create Ingress" $START_TIME $FINISH_TIME 
print_time TOTAL "Create Ingress" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

touch $LOCAL_WORKDIR/ingress_installed
