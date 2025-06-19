#!/bin/bash
# Copyright (c) 2022, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which can be used to deploy Oracle Advanced Authentication
#
# Dependencies: ./common/functions.sh
#               ./common/oaa_functions.sh
#               ./templates/oaa
#               ./responsefile/idm.rsp
#
# Usage: provision_oaa.sh
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
. $SCRIPTDIR/common/oaa_functions.sh
. $SCRIPTDIR/common/ohs_functions.sh

START_TIME=`date +%s`

TEMPLATE_DIR=$SCRIPTDIR/templates/oaa
WORKDIR=$LOCAL_WORKDIR/OAA
LOGDIR=$WORKDIR/logs

if [ "$INSTALL_OAA" != "true" ] && [ "$INSTALL_OAA" != "TRUE" ]
then
     echo "You have not requested Oracle Advanced Authentication"
     exit 1
fi

if [ "$INSTALL_OUA" = "true" ] && [ "$INSTALL_OAA" != "true" ]
then
     echo "You have not requested Oracle Advanced Authentication"
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
echo -n "Provisioning Oracle Advanced Authentication on "
date +"%a %d %b %Y %T"
echo "-----------------------------------------------------------------------"
echo

create_local_workdir
create_logdir
printf "Using Image:"
printf "\n\t$OAA_MGT_IMAGE:$OAAMGT_VER\n\n"

echo -n "Provisioning Oracle Advanced Authentication on " >> $LOGDIR/timings.log
date +"%a %d %b %Y %T" >> $LOGDIR/timings.log
echo "----------------------------------------------------------------------" >> $LOGDIR/timings.log

STEPNO=1
PROGRESS=$(get_progress)


# Create Kubernetes Namespace(s)
#
if [ $STEPNO -gt $PROGRESS ]
then
   create_namespace $OAANS
   update_progress
fi


# Create a Container Registry Secret if requested
#
if  [ "$CREATE_REGSECRET" = "true" ]
then
  new_step
  if [ $STEPNO -gt $PROGRESS ] 
  then
     create_registry_secret $REGISTRY $REG_USER $REG_PWD $OAANS
     update_progress
  fi
fi


# Create GitHub Secret if requested
#
if [ "$CREATE_GITSECRET" = "true" ]
then
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
       create_git_secret $GIT_USER $GIT_TOKEN $OAANS
       update_progress       
   fi
fi

if [ "$CREATE_REGSECRET" = "true" ] 
then
  new_step
  if [ $STEPNO -gt $PROGRESS ] 
  then
     create_registry_secret "https://index.docker.io/v1/" $DH_USER $DH_PWD $OAANS dockercred
     update_progress
  fi
fi

# Create a Management Container
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_helper 
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   copy_settings_file
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_rbac 
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   validate_oaamgmt
   update_progress
fi

# Register TAP
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    register_tap
    update_progress
fi

# Register TAP for OUA
#
if [ "$INSTALL_OUA" = "true" ]
then
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    register_tap_oua
    update_progress
  fi
fi

if [ "$OAA_CREATE_OHS" = "true" ]
then

   # Create OHS rewrite Rules
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       if [ "$UPDATE_OHS" = "true" ]
       then
          add_ohs_rewrite_rules
          update_progress
       fi
   fi

   # Add OHS entries for OAA to OAM ohs config files if Ingress is being used
   #
   if [ "$USE_INGRESS" = "true" ] 
   then
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
        create_ohs_entries
        update_progress
     fi
   fi

   # Copy OHS config to OHS servers if required
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       if [ "$UPDATE_OHS" = "true" ] && [ "$OAA_CREATE_OHS" = "true" ]
       then
          copy_ohs_config
          update_progress
       fi
   fi
fi

# Update Property File
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   prepare_property_file
   update_progress
fi

# Edit properties file for OUA
#
if [ "$INSTALL_OUA" = "true" ]
then
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    edit_properties_oua
    update_progress
  fi
fi

# Deploy OAA
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   deploy_oaa
   update_progress
fi

# Add OHS entries for OAA to OAM ohs config files if Ingress is not being used
#
if [ "$USE_INGRESS" = "false" ]
then
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
     create_ohs_entries
     update_progress
  fi

  # Copy OHS config to OHS servers if required
  #
  if [ "$UPDATE_OHS" = "true" ]
  then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
       copy_ohs_config
       update_progress
    fi
    # Create OHS Wallet
    #
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
       create_ohs_wallet
       update_progress
    fi
  fi
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   check_running $OAANS email 0 true
   check_running $OAANS yotp 0 
   check_running $OAANS totp 0 
   check_running $OAANS fido 0 
   check_running $OAANS kba 0 
   check_running $OAANS sms 0 
   check_running $OAANS push 0 
   check_running $OAANS spui 0 
   check_running $OAANS policy 0 
   check_running $OAANS oaa-admin 0 
   check_running $OAANS oaa 0 
   if [ "$INSTALL_OUA" = "true" ]
   then
     check_running $OAANS drss 0 
   fi
   if [ "$INSTALL_RISK" = "true" ]
   then
     check_running $OAANS risk-cc 0 
     check_running $OAANS risk 0 
   fi
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   check_running $OAMNS adminserver 0 true
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   update_urls
   update_progress
fi

# Configure UMS
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    configure_ums
    update_progress
fi



# Create Test User
#
new_step
if [ $STEPNO -gt $PROGRESS ] && [ "$OAA_CREATE_TESTUSER" = "true" ]
then
    create_test_user oud
    update_progress
fi


# Configure OUA Parameters
#
if [ "$INSTALL_OUA" = "true" ]
then
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    configure_oua
    update_progress
  fi
fi      

# Restart Domain
#
if [ "$INSTALL_OUA" = "true" ]
then
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    stop_domain $OAMNS $OAM_DOMAIN_NAME
    update_progress
  fi
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    start_domain $OAMNS $OAM_DOMAIN_NAME
    update_progress
  fi
fi      

FINISH_TIME=`date +%s`
print_time TOTAL "Create OAA" $START_TIME $FINISH_TIME 
print_time TOTAL "Create OAA" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

touch $LOCAL_WORKDIR/oaa_installed
