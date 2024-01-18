#!/bin/bash
# Copyright (c) 2022,2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of provisioning Oracle HTTP Server
#
# Dependencies: ./common/functions.sh
#               ./common/ohs_functions.sh
#               ./templates/ohs
#               ./responsefile/idm.rsp
#
# Usage: provision_ohs.sh [-r responsefile -p passwordfile]
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
. $SCRIPTDIR/common/ohs_functions.sh


START_TIME=`date +%s`

WORKDIR=$LOCAL_WORKDIR/OHS
LOGDIR=$WORKDIR/logs
TEMPLATE_DIR=$SCRIPTDIR/templates/ohs


if [ "$INSTALL_OHS" != "true" ] && [ "$INSTALL_OHS" != "TRUE" ]
then
     echo "You have not requested OHS installation"
     exit 1
fi

echo
echo -n "Provisioning Oracle HTTP Server on "
date +"%a %d %b %Y %T"
echo "-----------------------------------------------------------"
echo


STEPNO=0
PROGRESS=$(get_progress)

create_logdir
create_local_workdir

echo -n "Provisioning Oracle HTTP Server on " >> $LOGDIR/timings.log
date +"%a %d %b %Y %T" >> $LOGDIR/timings.log
echo "----------------------------------------------------------" >> $LOGDIR/timings.log
echo 

for OHSHOST in $OHS_HOST1 $OHS_HOST2
do
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    mkdir $LOGDIR/$OHSHOST 2>/dev/null
    copy_binary $OHSHOST
    update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    unzip_binary $OHSHOST
    update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    copy_rsp $OHSHOST
    update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    create_home_dir $OHSHOST
    update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    create_orainst $OHSHOST
    update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    install_ohs $OHSHOST
    update_progress
  fi
done

if [ ! "$OHS_HOST1" = "" ] 
then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      create_instance_file $OHS_HOST1 $OHS1_NAME
      update_progress
    fi

    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      create_instance $OHS_HOST1 $OHS1_NAME
      update_progress
    fi

    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      tune_instance $OHS_HOST1 $OHS1_NAME
      update_progress
    fi

    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      create_hc  $OHS_HOST1 $OHS1_NAME
      update_progress
    fi

    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      start_nm $OHS_HOST1 
      update_progress
    fi

    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      start_ohs $OHS_HOST1 $OHS1_NAME
      update_progress
    fi

    if [ "$DEPLOY_WG" = "true" ]
    then
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          deploy_webgate $OHS_HOST1 $OHS1_NAME
          update_progress
        fi

        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          install_webgate $OHS_HOST1 $OHS1_NAME
          update_progress
        fi

        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          update_webgate $OHS_HOST1 $OHS1_NAME
          update_progress
        fi

        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          copy_lbr_cert $OHS_HOST1 $OHS1_NAME
          update_progress
        fi
    fi
fi

if [ ! "$OHS_HOST2" = "" ]
then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      create_instance_file $OHS_HOST2 $OHS2_NAME
      update_progress
    fi

    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      create_instance $OHS_HOST2 $OHS2_NAME
      update_progress
    fi

    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      tune_instance  $OHS_HOST2 $OHS2_NAME
      update_progress
    fi

    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      create_hc  $OHS_HOST2 $OHS2_NAME
      update_progress
    fi


    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      start_nm $OHS_HOST2 
      update_progress
    fi

    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      start_ohs $OHS_HOST2 $OHS2_NAME
      update_progress
    fi

    if [ "$DEPLOY_WG" = "true" ]
    then
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          deploy_webgate $OHS_HOST2 $OHS2_NAME
          update_progress
        fi

        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          install_webgate $OHS_HOST2 $OHS2_NAME
          update_progress
        fi

        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          update_webgate $OHS_HOST2 $OHS2_NAME
          update_progress
        fi

        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          copy_lbr_cert $OHS_HOST2 $OHS2_NAME
          update_progress
        fi
    fi
fi

FINISH_TIME=`date +%s`
print_time TOTAL "Create Oracle HTTP Server" $START_TIME $FINISH_TIME 
print_time TOTAL "Create Oracle HTTP Server" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

touch $LOCAL_WORKDIR/ohs_installed
