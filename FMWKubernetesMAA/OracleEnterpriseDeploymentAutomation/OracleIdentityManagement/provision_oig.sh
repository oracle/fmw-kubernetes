#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of provisioning Oracle Identity Governance and wiring it to Oracle Unified Directory
# and Oracle Access Manager
#
# Dependencies: ./common/functions.sh
#               ./common/oig_functions.sh
#               ./templates/oig
#               ./responsefile/idm.rsp
#
# Usage: provision_oig.sh
#

. common/functions.sh
. common/oig_functions.sh
. $RSPFILE
TEMPLATE_DIR=$SCRIPTDIR/templates/oig



START_TIME=`date +%s`

WORKDIR=$LOCAL_WORKDIR/OIG
LOGDIR=$WORKDIR/logs
OPER_DIR=OracleIdentityGovernance

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

if [ "$INSTALL_OIG" != "true" ] && [ "$INSTALL_OIG" != "TRUE" ]
then
     echo "You have not requested OIG installation"
     exit 1
fi

echo
echo -n "Provisioning OIG on "
date +"%a %d %b %Y %T"
echo "------------------------------------------------"
echo

create_local_workdir
create_logdir

echo -n "Provisioning OIG on " >> $LOGDIR/timings.log
date +"%a %d %b %Y %T" >> $LOGDIR/timings.log
echo "-----------------------------------------------" >> $LOGDIR/timings.log

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
    create_namespace $OIGNS WLS
    update_progress
fi

new_step

if [ $STEPNO -gt $PROGRESS ]
then
    create_registry_secret $REGISTRY $REG_USER $REG_PWD $OIGNS
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ] &&  [ "$CREATE_REGSECRET" = "true" ]
then
   create_registry_secret "https://index.docker.io/v1/" $DH_USER $DH_PWD $OIGNS dockercred
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    check_ldap_user $LDAP_OIGLDAP_USER
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_helper_pod $OIGNS $OIG_IMAGE:$OIG_VER
    update_progress
fi

# Create RCU Schema Objects
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_schemas  $OIGNS  $OIG_DB_SCAN $OIG_DB_LISTENER $OIG_DB_SERVICE $OIG_RCU_PREFIX OIG $OIG_DB_SYS_PWD $OIG_SCHEMA_PWD
    update_progress
fi


# Create Kubernetes Secrets
#

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_domain_secret $OIGNS $OIG_DOMAIN_NAME $OIG_WEBLOGIC_USER $OIG_WEBLOGIC_PWD 
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_rcu_secret $OIGNS $OIG_DOMAIN_NAME $OIG_RCU_PREFIX $OIG_SCHEMA_PWD $OIG_DB_SYS_PWD
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
    check_pv_ok $OIG_DOMAIN_NAME
    update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    check_pvc_ok $OIG_DOMAIN_NAME $OIGNS
    update_progress
fi

# Create Domain Configuration File
#

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    edit_domain_creation_file $WORKDIR/create-domain-inputs.yaml
    update_progress
fi

# Initialise Domain
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_oig_domain
    update_progress
fi

# Perform Initial Domain Start
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    perform_initial_start
    update_progress
fi

# Create Services
#

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   if [ "$USE_INGRESS" = "true" ]
   then
       create_oig_ingress
   else
       create_oig_nodeport
   fi
   update_progress
fi


# Create Working Directory inside container
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_workdir $OIGNS $OIG_DOMAIN_NAME
   update_progress
fi


# Set memory params and disable derby db
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   copy_to_k8 $TEMPLATE_DIR/oigSetUserOverrides.sh domains/$OIG_DOMAIN_NAME/bin/setUserOverrides.sh $OIGNS $OIG_DOMAIN_NAME
   update_progress
fi


# Update MDS Datasource
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    update_mds
    update_progress
fi

# Enable DB FAN
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    fix_gridlink
    update_progress
fi

# Set Weblogic Plugin
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   set_weblogic_plugin
   update_progress
fi

if  [ "$INSTALL_OAM" = "true" ] && [ "$OAM_OIG_INTEG" = "true" ]
then
    # Copy Connector to Container
    #
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
       copy_connector
       update_progress
    fi

   # Create Integration sedfiles
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      create_connector_files
      update_progress
   fi

    # Create WLS Authenticators
    #
    new_step
    if [ $STEPNO -gt $PROGRESS ] 
    then
       create_wlsauthenticators
       update_progress
    fi

    # Create OUD Authenticator
    #
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
       create_oud_authenticator
       update_progress
    fi

   # Restart Domain
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      stop_domain $OIGNS $OIG_DOMAIN_NAME
      update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      start_domain $OIGNS $OIG_DOMAIN_NAME
       update_progress
   fi


   # Create WLS Admin Roles
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      create_admin_roles
      update_progress
   fi

   # Genarate OIGOAMIntegration Parameter Files
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      generate_parameter_files
      update_progress
   fi

   # Configure LDAP Connector
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      configure_connector
      update_progress
   fi

   # Add Missing Object Classes to LDAP
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      add_object_classes
      update_progress
   fi

   # Configure SSO
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      configure_sso
       update_progress
   fi

   # Enable OAM Notifications
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      enable_oam_notifications
       update_progress
   fi

   # Update Match Attribute
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      update_match_attr >> $LOGDIR/update_match_attr.log
      update_progress
   fi

fi
# Get Loadbalancer Certificates
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
     if  [ "$INSTALL_OAM" = "true" ] && [ "$OAM_OIG_INTEG" = "true" ]
     then
          get_lbr_certificate $OAM_LOGIN_LBR_HOST $OAM_LOGIN_LBR_PORT
     fi
     if [ "$OIG_BI_INTEG" = "true" ] || [ "$OIG_BI_INTEG" = "TRUE" ]
     then 
       if [ "$OIG_BI_PROTOCOL" = "https" ]  ||  [ "$OIG_BI_PROTOCOL" = "HTTPS" ]
       then
          get_lbr_certificate $OIG_BI_HOST $OIG_BI_PORT
       fi
     fi
    update_progress
fi

# Add certificates to Oracle Keystore Service
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
    add_certs_to_kss
    update_progress
fi

if  [ "$INSTALL_OAM" = "true" ] && [ "$OAM_OIG_INTEG" = "true" ]
then
   # Restart Domain
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      stop_domain $OIGNS $OIG_DOMAIN_NAME
      update_progress
   fi

   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      start_domain $OIGNS $OIG_DOMAIN_NAME
      update_progress
   fi


   # Run Recon jobs to Pull LDAP users/Groups into OIG
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      run_recon_jobs
      update_progress
   fi

   # Assign WSM Roles
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      assign_wsmroles
      update_progress
   fi

fi

# Update SOA URLS
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   update_soa_urls
   update_progress
fi


if [ "$OIG_ENABLE_T3" = "true" ] || [ "$OIG_ENABLE_T3" = "TRUE" ]
then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      enable_oim_T3
      update_progress
    fi
fi

#
# Create an Email Driver
#
if [ "$OIG_EMAIL_CREATE" = "true" ] || [ "$OIG_EMAIL_CREATE" = "TRUE" ] 
then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      create_email_driver
      update_progress
    fi

    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      set_email_notifications
      update_progress
    fi
fi

# Integrate OIG and BI
#
if [ "$OIG_BI_INTEG" = "true" ] || [ "$OIG_BI_INTEG" = "TRUE" ]
then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
      update_biconfig
      update_progress
    fi
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_oig_ohs_config
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

# Restart All Domain
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   stop_domain $OIGNS $OIG_DOMAIN_NAME
   update_progress
fi

if  [ "$INSTALL_OAM" = "true" ] && [ "$OAM_OIG_INTEG" = "true" ]
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

#
# Set the initial server count
# 
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   update_replica_count oig $OIG_SERVER_INITIAL
   sleep 90
   check_running $OIGNS adminserver
   check_running $OIGNS soa-server1
   update_progress
fi

if [ "$USE_ELK" = "true" ]
then
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
       create_cert_cm $OIGNS
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
       create_logstash $OIGNS
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
FINISH_TIME=`date +%s`
print_time TOTAL "Create OIG" $START_TIME $FINISH_TIME 
print_time TOTAL "Create OIG" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

touch $LOCAL_WORKDIR/oig_installed
