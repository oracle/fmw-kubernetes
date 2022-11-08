#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which can be used to deploy Oracle Identity Role Intelligence
#
# Dependencies: ./common/functions.sh
#               ./common/oiri_functions.sh
#               ./templates/oiri
#               ./responsefile/idm.rsp
#
# Usage: provision_oiri.sh
#
. common/functions.sh
. common/oiri_functions.sh

. $RSPFILE
TEMPLATE_DIR=$SCRIPTDIR/templates/oiri



START_TIME=`date +%s`

WORKDIR=$LOCAL_WORKDIR/OIRI
LOGDIR=$WORKDIR/logs

if [ "$INSTALL_OIRI" != "true" ] && [ "$INSTALL_OIRI" != "TRUE" ]
then
     echo "You have not requested Oracle Identity Role Intelligence installation"
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
echo -n "Provisioning Oracle Identity Role Intelligence on "
date +"%a %d %b %Y %T"
echo "---------------------------------------------------------------------------"
echo

create_local_workdir
create_logdir

echo -n "Provisioning Oracle Identity Role Intelligence on " >> $LOGDIR/timings.log
date +"%a %d %b %Y %T" >> $LOGDIR/timings.log
echo "---------------------------------------------------------------------------" >> $LOGDIR/timings.log

STEPNO=1
PROGRESS=$(get_progress)

# Create Kubernetes Namespace(s)
#
if [ $STEPNO -gt $PROGRESS ]
then
   create_namespace $OIRINS
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ] && ! [ "$OIRINS" = "$DINGNS" ]
then
   create_namespace $DINGNS
   update_progress
fi

# Create a Container Registry Secret if requested
#
new_step
if [ $STEPNO -gt $PROGRESS ] &&  [ "$CREATE_REGSECRET" = "true" ]
then
   create_registry_secret $REGISTRY $REG_USER $REG_PWD $OIRINS
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ] &&  [ "$CREATE_REGSECRET" = "true" ]
then
   create_registry_secret $REGISTRY $REG_USER $REG_PWD $DINGNS
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ] &&  [ "$CREATE_REGSECRET" = "true" ]
then
   create_registry_secret "https://index.docker.io/v1/" $DH_USER $DH_PWD $OIRINS dockercred
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ] &&  [ "$CREATE_REGSECRET" = "true" ]
then
   create_registry_secret "https://index.docker.io/v1/" $DH_USER $DH_PWD $DINGNS dockercred
   update_progress
fi
# Create a local container for oiri-cli
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_helper 
   update_progress
fi


# Create Service Account
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_rbac 
   update_progress
fi


new_step
if [ $STEPNO -gt $PROGRESS ]
then
   validate_oiricli
   update_progress
fi

# Create files that will be used to deploy OIRI
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   setup_config_files 
   update_progress
fi

# Create Helm override file to deploy OIRI
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   setup_helm_files 
   update_progress
fi

# Create a Keystore
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_keystore 
   update_progress
fi


# Obtain OIG certificate and add to oiri-clie
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   get_oig_certificate
   update_progress
fi

# Store Credentials in a wallet
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_wallet
   update_progress
fi

# Create Database Schemas
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_schemas
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   migrate_schemas
   update_progress
fi

# Create an Service Account, Engineering user and Role in OIG
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_users
   update_progress
fi

# Ensure that OIG is running in Compliance Mode
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   set_compliance_mode
   update_progress
fi

# Having created the wallet ensure that the details inside are correct
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   verify_wallet
   update_progress
fi



# Create OIRI clusters in Kubernetes
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   deploy_oiri
   update_progress
fi

new_step
if [ $STEPNO -gt $PROGRESS ]
then
   check_running $OIRINS oiri-ui
   check_running $DINGNS spark-history-server
   update_progress
fi

# Create NodePort Services
#
if [ "$USE_INGRESS" = "false" ] 
then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
       create_oiri_nodeport
       update_progress
    fi
fi
# Create NodePort Services
#
if [ "$USE_INGRESS" = "false" ] 
then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
       create_oiri_nodeport
       update_progress
    fi
fi


# Create a container for using ding-cli
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   create_ding_helper
   update_progress
fi


# Obtain the Kubernetes certificate and copy to the Ding Container
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   copy_cacert
   update_progress
fi
# Validate the OIG database connection details
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   verify_ding
   update_progress
fi

# Get Ding Token
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   get_ding_token
   update_progress
fi

# Perform and Initial Data Load from the connected OIG database
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   run_ding
   update_progress
fi

# Having performed a full data import, set the Injestion jobs to Incremental for future loads
#
new_step
if [ $STEPNO -gt $PROGRESS ]
then
   set_incremental
   update_progress
fi

# Add OHS entries for OIRI to OIG ohs config files
#
if [ "$USE_INGRESS" = "false" ] || [ "$OIRI_CREATE_OHS" = "true" ]
then
    new_step
    if [ $STEPNO -gt $PROGRESS ]
    then
       create_ohs_entries
       update_progress
    fi
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
print_time TOTAL "Create OIRI" $START_TIME $FINISH_TIME 
print_time TOTAL "Create OIRI" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log

touch $LOCAL_WORKDIR/oiri_installed
