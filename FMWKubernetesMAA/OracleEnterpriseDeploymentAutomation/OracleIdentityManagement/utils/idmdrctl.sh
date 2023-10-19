#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which controls DR actions
#
#
# Usage: idmdrctl.sh ACTION -p product_type
# Actions: suspend | resume | initial | switch
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $MYDIR/../common/functions.sh
. $MYDIR/../responsefile/dr.rsp

while getopts 'a:p:' OPTION
do
  case "$OPTION" in
    a)
      ACTION=$OPTARG
     ;;
    p)
      product_type=$OPTARG
     ;;
    ?)
     echo "script usage: $(basename $0) ACTION [-p product] " >&2
     exit 1
     ;;
   esac
done

PRODUCT=${product_type^^}

LOGDIR=/tmp

if [ ! "$ACTION" = "switch" ]
then
   if [ "$product_type" = "oud" ]
   then
       . $MYDIR/../common/oud_functions.sh
       NAMESPACE=$OUDNS
   elif [ "$product_type" = "oam" ]
   then
       . $MYDIR/../common/oam_functions.sh
       NAMESPACE=$OAMNS
   elif [ "$product_type" = "oig" ]
   then
       . $MYDIR/../common/oig_functions.sh
       NAMESPACE=$OIGNS
   elif [ "$product_type" = "oiri" ]
   then
       . $MYDIR/../common/oiri_functions.sh
       NAMESPACE=$OIRINS
   elif [ "$product_type" = "oaa" ]
   then
       . $MYDIR/../common/oaa_functions.sh
       NAMESPACE=$OAANS
   else
     echo "Usage: idmdrctl.sh  -a suspend|resume|initial|switch -p oud|oam|oig|oiri|oaa "
     exit
   fi
fi

if [ "$ACTION" = "suspend" ]
then
   suspend_cronjob $DRNS ${product_type}rsyncdr
elif [ "$ACTION" = "resume" ]
then
   resume_cronjob $DRNS ${product_type}rsyncdr
elif [ "$ACTION" = "initial" ]
then
   initialise_dr
elif [ "$ACTION" = "switch" ]
then
   switch_dr_mode
elif [ "$ACTION" = "stop" ]
then
   case "$PRODUCT" in
     OUD)
        WORKDIR=$LOCAL_WORKDIR/OUD
        stop_oud 
     ;;
     OAM)
        stop_domain $OAMNS $OAM_DOMAIN_NAME
     ;;
     OIG)
        stop_domain $OIGNS $OIG_DOMAIN_NAME
     ;;
     OIRI)
        stop_deployment $DINGNS
        stop_deployment $OIRINS
     ;;
     OAA)
        stop_deployment $OAANS
     ;;
   esac
elif [ "$ACTION" = "start" ]
then
   case "$PRODUCT" in
     OUD)
        export WORKDIR=$LOCAL_WORKDIR/OUD
        start_oud 
     ;;
     OAM)
        start_domain $OAMNS $OAM_DOMAIN_NAME
     ;;
     OIG)
        start_domain $OIGNS $OIG_DOMAIN_NAME
     ;;
     OIRI)
        read -p  "How many replicas do you wish to start ? " REPLICAS
        if ! [[ $REPLICAS =~ ^[0-9]+$ ]] 
        then 
           echo "Error: Not a number" 
           exit 1 
        fi
        start_deployment $DINGNS $REPLICAS
        start_deployment $OIRINS $REPLICAS
        if [ "$DR_TYPE" = "PRIMARY" ]
        then 
           PVSERVER=$DR_PRIMARY_PVSERVER
           OIRI_SHARE=$OIRI_PRIMARY_SHARE
           OIRI_DING_SHARE=$OIRI_DING_PRIMARY_SHARE
           OIRI_WORK_SHARE=$OIRI_WORK_PRIMARY_SHARE
        else
           PVSERVER=$DR_STANDBY_PVSERVER
           OIRI_SHARE=$OIRI_STANDBY_SHARE
           OIRI_DING_SHARE=$OIRI_DING_STANDBY_SHARE
           OIRI_WORK_SHARE=$OIRI_WORK_STANDBY_SHARE
        fi
        OIRI_IMAGE=$(kubectl describe deployment -n $OIRINS oiri | grep Image | cut -f2 -d: | sed 's/ //g')
        OIRI_CLI_IMAGE=${OIRI_IMAGE}-cli
        OIRICLI_VER=$(kubectl describe deployment -n $OIRINS oiri | grep Image | cut -f3 -d: | sed 's/ //g')
        OIRI_DING_IMAGE=${OIRI_IMAGE}-ding
        OIRIDING_VER=$OIRICLI_VER
        TEMPLATE_DIR=$MYDIR/../templates/oiri
        WORKDIR=$LOCAL_WORKDIR/OIRI
        create_helper
        create_ding_helper
     ;;
     OAA)
        start_deployment $OAANS $OAA_REPLICAS
     ;;
     ?)
        echo "$PRODUCT is not supported at this time."
        exit 1
        ;;
   esac
else
   echo "Usage: idmdrctl.sh  oud|oam|oig|oiri|oaa suspend|resume|initial|switch|start|stop"
   exit
fi

