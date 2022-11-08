#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
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
. common/functions.sh
. common/oaa_functions.sh

. $RSPFILE
TEMPLATE_DIR=$SCRIPTDIR/templates/oaa



START_TIME=`date +%s`

WORKDIR=$LOCAL_WORKDIR/OAA
LOGDIR=$WORKDIR/logs

if [ "$INSTALL_OAA" != "true" ] && [ "$INSTALL_OAA" != "TRUE" ]
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

echo -n "Provisioning Oracle Advanced Authentication on " >> $LOGDIR/timings.log
date +"%a %d %b %Y %T" >> $LOGDIR/timings.log
echo "----------------------------------------------------------------------" >> $LOGDIR/timings.log

STEPNO=1
PROGRESS=$(get_progress)

# Create LDAP Users
#
if [ $STEPNO -gt $PROGRESS ]
then
   create_ldap_entries oud
   update_progress
fi

# Add Existig Users to OAA Group
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   add_existing_users oud
   update_progress
fi

# Create Kubernetes Namespace(s)
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_namespace $OAANS
   update_progress
fi


# Create a Container Registry Secret if requested
#
new_step
if [ $STEPNO -gt $PROGRESS ] &&  [ "$CREATE_REGSECRET" = "true" ]
then
   create_registry_secret $REGISTRY $REG_USER $REG_PWD $OAANS
   update_progress
fi



# Create GitHub Secret if requested
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   if [ "$CREATE_GITSECRET" = "true" ]
   then
       create_git_secret $GIT_USER $GIT_TOKEN $OAANS
   fi
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ] &&  [ "$CREATE_REGSECRET" = "true" ]
then
   create_registry_secret "https://index.docker.io/v1/" $DH_USER $DH_PWD $OAANS dockercred
   update_progress
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
   create_rbac 
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   validate_oaamgmt
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_helm_file
   update_progress
fi

# Get OAM Certificate
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   get_lbr_certificate $OAM_LOGIN_LBR_HOST $OAM_LOGIN_LBR_PORT
   update_progress
fi

# Create OAA Server Certificates
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_server_certs
   update_progress
fi


# Update Property File
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   prepare_property_file
   update_progress
fi


# Enable OAM Auth

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   enable_oauth http://$K8_WORKER_HOST1:$OAM_ADMIN_K8 $OAM_OAMADMIN_USER:$OAM_OAMADMIN_PWD
   update_progress
fi


# Validate OAM Auth

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   validate_oauth 
   update_progress
fi

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
if [ "$USE_INGRESS" = "true" ] && [ "$OAA_CREATE_OHS" = "true" ]
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
   check_running $OAANS email 0
   check_running $OAANS yotp 0
   check_running $OAANS totp 0
   check_running $OAANS fido 0
   check_running $OAANS kba 0
   check_running $OAANS sms 0
   check_running $OAANS push 0
   check_running $OAANS spui 0
   check_running $OAANS policy 0
   check_running $OAANS fido 0
   update_progress
fi

# Import Snapshot
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   import_snapshot
   update_progress
fi
# Update URLs
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   check_running $OAMNS adminserver 0
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

# Register TAP
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    register_tap
    update_progress
fi


# Create OAA Agent
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_oaa_agent
    update_progress
fi



# Install OAA Plugin
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    install_plugin
    update_progress
fi


# Create OAM Authentication Module
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_auth_module
    update_progress
fi

# Create OAM Authentication Scheme
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_auth_scheme
    update_progress
fi

# Create OAM Authentication Policy
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_auth_policy
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

FINISH_TIME=`date +%s`
print_time TOTAL "Create OAA" $START_TIME $FINISH_TIME 
print_time TOTAL "Create OAA" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

touch $LOCAL_WORKDIR/oaa_installed
