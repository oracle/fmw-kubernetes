#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of deploying Prometheus
#
# Dependencies: ./common/functions.sh
#               ./responsefile/idm.rsp
#
# Usage: provision_prom.sh
#
. common/functions.sh
. common/prom_functions.sh
. $RSPFILE
TEMPLATE_DIR=$SCRIPTDIR/templates/prometheus


WORKDIR=$LOCAL_WORKDIR/PROM
LOGDIR=$WORKDIR/logs


if [ "$INSTALL_PROM" != "true" ]
then
     echo "You have not requested Prometheous/Grafana installation"
     exit 1
fi

echo
echo -n "Provisioning Prometheus on "
date +"%a %d %b %Y %T"
echo "--------------------------------------------------------"
echo

START_TIME=`date +%s`
create_local_workdir
create_logdir

echo -n "Provisioning Prometheus on " >> $LOGDIR/timings.log
date >> $LOGDIR/timings.log
echo "-------------------------------------------------------" >> $LOGDIR/timings.log

STEPNO=1
PROGRESS=$(get_progress)



if [ $STEPNO -gt $PROGRESS ]
then
     download_prometheus
     update_progress
fi

# Create Namespace 
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_namespace $PROMNS
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
     create_override
     update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
     deploy_prometheus
     update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    check_running monitoring alertmanager 5
    check_running monitoring grafana 5
    check_running monitoring node-exporter 5
    update_progress
fi



FINISH_TIME=`date +%s`
print_time TOTAL "Create Prometheus" $START_TIME $FINISH_TIME 
print_time TOTAL "Create Prometheus" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

touch $LOCAL_WORKDIR/prom_installed
exit

#
