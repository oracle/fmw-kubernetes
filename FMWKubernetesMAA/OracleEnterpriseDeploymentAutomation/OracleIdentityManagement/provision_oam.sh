#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
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
# Usage: provision_oam.sh
#
. common/functions.sh
. common/oam_functions.sh
. $RSPFILE
TEMPLATE_DIR=$SCRIPTDIR/templates/oam



START_TIME=`date +%s`

WORKDIR=$LOCAL_WORKDIR/OAM
LOGDIR=$WORKDIR/logs
OPER_DIR=OracleAccessManagement

if [ "$INSTALL_OAM" != "true" ] && [ "$INSTALL_OAM" != "TRUE" ]
then
     echo "You have not requested OAM installation"
     exit 1
fi

echo
echo -n "Provisioning OAM on "
date +"%a %d %b %Y %T"
echo "------------------------------------------------"
echo

create_local_workdir
create_logdir

echo -n "Provisioning OAM on " >> $LOGDIR/timings.log
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

# Ensure Weblogic Operator has been created
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


# Create Kubernetes Secrets
#

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_domain_secret $OAMNS $OAM_DOMAIN_NAME $OAM_WEBLOGIC_USER $OAM_WEBLOGIC_PWD
    update_progress
fi


new_step
if [ $STEPNO -gt $PROGRESS ]
then
    create_rcu_secret $OAMNS $OAM_DOMAIN_NAME $OAM_RCU_PREFIX $OAM_SCHEMA_PWD $OAM_DB_SYS_PWD
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
    create_oam_domain
    update_progress
fi

# Create Node Port Services
#

if [ ! "$USE_INGRESS" = "true" ]
then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
       create_oam_nodeport
       update_progress
    fi
fi

# Set memory params and disable derby db
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   copy_to_k8 $TEMPLATE_DIR/oamSetUserOverrides.sh domains/$OAM_DOMAIN_NAME/bin/setUserOverrides.sh $OAMNS $OAM_DOMAIN_NAME
   update_progress
fi

# Update default OAM config using OAM APIs

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
# Add Weblogic Plugin
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   set_weblogic_plugin
   update_progress
fi

# Add ADF logout
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   config_adf_logout
   update_progress
fi

# Update OAM Datasouce
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   update_oamds
   update_progress
fi

# Enable DB Fan
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   fix_gridlink
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

new_step
if [ $STEPNO -gt $PROGRESS ]
then
    update_replica_count oam $OAM_SERVER_INITIAL
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


FINISH_TIME=`date +%s`
print_time TOTAL "Create OAM" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

cat $LOGDIR/timings.log
