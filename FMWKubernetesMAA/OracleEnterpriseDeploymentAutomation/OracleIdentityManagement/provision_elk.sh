#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of deploying the Oracle WebLogic Operator
#
# Dependencies: ./common/functions.sh
#               ./responsefile/idm.rsp
#
# Usage: provision_elk.sh
#
. common/functions.sh
. $RSPFILE
TEMPLATE_DIR=$SCRIPTDIR/templates/elk


WORKDIR=$LOCAL_WORKDIR/ELK
LOGDIR=$WORKDIR/logs


if [ "$INSTALL_ELK" != "true" ]
then
     echo "You have not requested Elastic Search/Kibana installation"
     exit 1
fi

echo
echo -n "Provisioning Elastic Search on "
date +"%a %d %b %Y %T"
echo "--------------------------------------------------------"
echo

START_TIME=`date +%s`
create_local_workdir
create_logdir

echo -n "Provisioning Elastic Search on " >> $LOGDIR/timings.log
date >> $LOGDIR/timings.log
echo "-------------------------------------------------------" >> $LOGDIR/timings.log

PROGRESS=$(get_progress)


new_step
if [ $STEPNO -gt $PROGRESS ]
then
     create_namespace $ELKNS
     update_progress
fi

# Create a Container Registry Secret if requested
#
new_step
if [ $STEPNO -gt $PROGRESS ] &&  [ "$CREATE_REGSECRET" = "true" ]
then
   create_registry_secret "https://index.docker.io/v1/" $DH_USER $DH_PWD $ELKNS dockercred
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
     install_elk_operator
     update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
     deploy_elk
     update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    check_running $ELKNS elasticsearch-es-default-0 30
    check_running $ELKNS elasticsearch-es-default-1 10
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
     deploy_kibana
     update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    check_running $ELKNS kibana 10
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_elk_nodeport
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    update_elk_password
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    get_elk_cert
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_elk_role
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_elk_user
    update_progress
fi


FINISH_TIME=`date +%s`
print_time TOTAL "Create Elastic Search" $START_TIME $FINISH_TIME 
print_time TOTAL "Create Elastic Search" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

touch $LOCAL_WORKDIR/elk_installed
exit

