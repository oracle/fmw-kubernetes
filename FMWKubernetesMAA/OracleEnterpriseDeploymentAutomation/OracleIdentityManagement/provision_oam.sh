#!/bin/bash
# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which can be used to deploy Oracle Access Manager and wire it to 
# Oracle Unified Directory
#
# Dependencies: ./common/functions.sh
#               ./common/oam_functions.sh
#               ./templates/oam
#               ./responsefile/idm.rsp
#
# Usage: provision_oam.sh  [-r responsefile -p passwordfile]
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
. $SCRIPTDIR/common/oam_functions.sh
. $SCRIPTDIR/common/ohs_functions.sh

START_TIME=`date +%s`

TEMPLATE_DIR=$SCRIPTDIR/templates/oam
WORKDIR=$LOCAL_WORKDIR/OAM
LOGDIR=$WORKDIR/logs
OPER_DIR=OracleAccessManagement

if [ "$USE_INGRESS" = "true" ]
then
   if [ "$INGRESS_SERVICE_TYPE" = "NodePort" ]
   then
      INGRESS_HTTP_PORT=`get_k8_port $INGRESS_NAME $INGRESSNS http `
      INGRESS_HTTPS_PORT=`get_k8_port $INGRESS_NAME $INGRESSNS https`
      INGRESS_HOST=""
   else
      INGRESS_HTTP_PORT=$INGRESS_HTTP
      INGRESS_HTTPS_PORT=$INGRESS_HTTPS
      INGRESS_HOST=`kubectl get svc -n $INGRESSNS | awk '{print $4}' | grep -v EXTERNAL`
   fi

   if [ "$INGRESS_HTTP_PORT" = "" ]
   then
       echo "Unable to get Ingress Ports - Check Ingress is running"
       exit 1
   fi
fi

if [ "$INSTALL_OAM" != "true" ] 
then
     echo "You have not requested OAM installation"
     exit 1
fi

echo
echo -n "Provisioning OAM on "
date +"%a %d %b %Y %T"
echo "--------------------------------------------"

create_local_workdir
create_logdir
printf "Using Image:"
printf "\n\t$OAM_IMAGE:$OAM_VER\n\n"

echo -n "Provisioning OAM on " >> $LOGDIR/timings.log
date +"%a %d %b %Y %T" >> $LOGDIR/timings.log
echo "-------------------------------------------" >> $LOGDIR/timings.log

STEPNO=1
PROGRESS=$(get_progress)


if [ $STEPNO -gt $PROGRESS ]
then
    download_samples $WORKDIR
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    copy_samples $OPER_DIR
    update_progress
fi

# Ensure Weblogic Kubernetes Operator has been created
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   check_oper_exists
   update_progress
fi

# Create Namespace and Helper Pod
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_namespace $OAMNS WLS
    update_progress
fi

# Create a Container Registry Secret if requested
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   if [ "$CREATE_REGSECRET" = "true" ]
   then
      create_registry_secret $REGISTRY $REG_USER $REG_PWD $OAMNS
   fi
   update_progress
fi

if [ "$WLS_CREATION_TYPE" = "WDT" ] && [ ! "$REGISTRY" = "$WDT_IMAGE_REGISTRY" ] 
then
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      if [ "$CREATE_REGSECRET" = "true" ]
      then
         create_registry_secret $WDT_IMAGE_REGISTRY $WDT_IMAGE_REG_USER $WDT_IMAGE_REG_PWD $OAMNS regcred2
      fi
      update_progress
   fi
fi

new_step
if [ $STEPNO -gt $PROGRESS ] &&  [ "$CREATE_REGSECRET" = "true" ]
then
   create_registry_secret "https://index.docker.io/v1/" $DH_USER $DH_PWD $OAMNS dockercred
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   if [ "$EXTERNAL_LDAP_HOST" = "" ]
   then
      check_ldap_user $LDAP_OAMLDAP_USER
   else
      check_ldap_user_ext ${EXTERNAL_LDAP_HOST} ${EXTERNAL_LDAP_PORT} $LDAP_OAMLDAP_USER
   fi
   update_progress
fi

# Create Kubernetes Secrets
#

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    if [ "$WLS_CREATION_TYPE" = "WDT" ]
    then
       create_domain_secret_wdt $OAMNS $OAM_DOMAIN_NAME $OAM_WEBLOGIC_USER $OAM_WEBLOGIC_PWD
    else
       create_domain_secret $OAMNS $OAM_DOMAIN_NAME $OAM_WEBLOGIC_USER $OAM_WEBLOGIC_PWD
    fi
    update_progress
fi


new_step
if [ $STEPNO -gt $PROGRESS ]
then
    if [ "$WLS_CREATION_TYPE" = "WDT" ]
    then
      create_rcu_secret_wdt $OAMNS $OAM_DOMAIN_NAME $OAM_RCU_PREFIX $OAM_SCHEMA_PWD $OAM_DB_SYS_PWD $OAM_DB_SCAN $OAM_DB_LISTENER $OAM_DB_SERVICE
    else
      create_rcu_secret $OAMNS $OAM_DOMAIN_NAME $OAM_RCU_PREFIX $OAM_SCHEMA_PWD $OAM_DB_SYS_PWD
    fi
    update_progress
fi

if [ "$WLS_CREATION_TYPE" = "WLST" ]
then
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    create_helper_pod $OAMNS $OAM_IMAGE:$OAM_VER
    update_progress
  fi

  # Create RCU Schema Objects
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    create_schemas  $OAMNS  $OAM_DB_SCAN $OAM_DB_LISTENER $OAM_DB_SERVICE $OAM_RCU_PREFIX OAM $OAM_DB_SYS_PWD $OAM_SCHEMA_PWD
    update_progress
  fi


  # Create Persistent Volumes
  #

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    create_persistent_volumes
    update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
     check_pv_ok $OAM_DOMAIN_NAME
     update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    check_pvc_ok $OAM_DOMAIN_NAME $OAMNS
    update_progress
  fi
 
fi

# Create Domain Configuration File
#

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    edit_domain_creation_file 
    update_progress
fi

if [ "$WLS_CREATION_TYPE" = "WDT" ]
then
  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
     generate_wdt_model_files
     update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    build_wdt_image
    update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
    add_image_wdt
    update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
     create_oam_domain_wdt
     update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
     check_running $OAMNS introspector true
     update_progress
   fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
     check_introspector $OAMNS
     update_progress
  fi

  new_step
  if [ $STEPNO -gt $PROGRESS ]
  then
     check_domain_ok $OAMNS $OAM_DOMAIN_NAME
     update_progress
  fi
else

  # Initialise Domain
  #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      create_oam_domain
      update_progress
   fi

   # Start Domain
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       perform_first_start
       update_progress
   fi
fi


# Check that the domain is started
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    check_running $OAMNS adminserver true
    check_running $OAMNS oam-server1
    update_progress
fi

# Create Services
#

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   if [ "$USE_INGRESS" = "true" ]
   then
       create_oam_ingress
   else
       create_oam_nodeport
   fi
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   if [ "$USE_INGRESS" = "true" ]
   then
       check_ingress $OAMNS oam-runtime
   fi
   update_progress
fi

# Set memory params and disable derby db
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   copy_to_k8 $TEMPLATE_DIR/oamSetUserOverrides.sh domains/$OAM_DOMAIN_NAME/bin/setUserOverrides.sh $OAMNS $OAM_DOMAIN_NAME
   update_progress
fi

# Update default OAM config using OAM APIs
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   update_default_oam_domain http://$K8_WORKER_HOST1:$OAM_ADMIN_K8 $OAM_WEBLOGIC_USER:$OAM_WEBLOGIC_PWD
   update_progress
fi

# Update OAM HostIds
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   update_oam_hostids http://$K8_WORKER_HOST1:$OAM_ADMIN_K8 $OAM_WEBLOGIC_USER:$OAM_WEBLOGIC_PWD 
   update_progress
fi


# Add missing out of the box OAM Resources
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    add_oam_resources  http://$K8_WORKER_HOST1:$OAM_ADMIN_K8 $OAM_WEBLOGIC_USER:$OAM_WEBLOGIC_PWD
    update_progress
fi


# Restart Domain
#
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

# Create Working Directory inside container
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_workdir $OAMNS $OAM_DOMAIN_NAME
   update_progress
fi

# run idmConfigTool to wire to OUD
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   run_idmConfigTool $OAMNS $OAM_DOMAIN_NAME
   update_progress
fi


# Add WLS Admin Roles
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   add_admin_roles
   update_progress
fi


# Create wg agent if idmconfigtool wasnt able to
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_wg_agent
   update_progress
fi


if [ "$WLS_CREATION_TYPE" = "WLST" ]
then
   new_step
   # Add Weblogic Plugin
   #
   if [ $STEPNO -gt $PROGRESS ]
   then
      set_weblogic_plugin
      update_progress

      # Update OAM Datasouce
      #
      new_step
      if [ $STEPNO -gt $PROGRESS ]
      then
         update_oamds
         update_progress
      fi
   fi
fi

# Add ADF logout
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   config_adf_logout
   update_progress
fi


# Enable DB Fan
#

# Restart Domain
#
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

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    scale_cluster $OAMNS $OAM_DOMAIN_NAME oam-cluster $OAM_SERVER_INITIAL
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    scale_cluster $OAMNS $OAM_DOMAIN_NAME policy-cluster $OAM_SERVER_INITIAL
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_oam_ohs_config
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    copy_wg_files
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    if [ "$UPDATE_OHS" = "true" ]
    then
       copy_ohs_config
       update_progress
    fi
fi

if [ "$USE_ELK" = "true" ]
then
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_elk_secret $OAMNS
       update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_cert_cm $OAMNS
       update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_logstash_cm
       update_progress
    fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_logstash $OAMNS
       update_progress
    fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     create_elk_dataview oam
     update_progress
   fi
fi

if [ "$USE_PROM" = "true" ]
then
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     generate_wls_monitor
     update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     deploy_wls_monitor
     update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     enable_monitor
     update_progress
   fi

fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   check_healthcheck_ok
   update_progress
fi

FINISH_TIME=`date +%s`
print_time TOTAL "Create OAM" $START_TIME $FINISH_TIME 
print_time TOTAL "Create OAM" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

touch $LOCAL_WORKDIR/oam_installed
