#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl
#

function exitIfError {
  if [ "$1" != "0" ]; then
    echo "$2"
    exit $1
  fi
}

# Include common utility functions
source ${CREATE_DOMAIN_SCRIPT_DIR}/utility.sh

export CUSTOM_MANAGED_BASE_NAME=${CUSTOM_MANAGED_BASE_NAME,,}
export CUSTOM_ADMIN_NAME=${CUSTOM_ADMIN_NAME,,}

# Verify the script to create the domain exists
script=${CREATE_DOMAIN_SCRIPT_DIR}/createSitesDomain.sh

checkCreateDomainScript $script

# Execute the script to create the domain
source $script
exitIfError $? "ERROR: $script failed."

# Verify the script to create the domain exists
script=${CREATE_DOMAIN_SCRIPT_DIR}/create-domain-script.sh

checkCreateDomainScript $script
checkDomainSecret
prepareDomainHomeDir

# Execute the script to create the domain
source $script
exitIfError $? "ERROR: $script failed."

echo "Copying ${CREATE_DOMAIN_SCRIPT_DIR}/server-config-update.sh to PV ${DOMAIN_HOME_DIR}"
cp ${CREATE_DOMAIN_SCRIPT_DIR}/server-config-update.sh ${DOMAIN_HOME_DIR}
chmod +x ${DOMAIN_HOME_DIR}/server-config-update.sh

echo "Copying ${CREATE_DOMAIN_SCRIPT_DIR}/unicast.py to PV ${DOMAIN_HOME_DIR}"
cp ${CREATE_DOMAIN_SCRIPT_DIR}/unicast.py ${DOMAIN_HOME_DIR}
chmod +x ${DOMAIN_HOME_DIR}/unicast.py

echo "replacing tokens in ${DOMAIN_HOME_DIR}/server-config-update.sh"
sed -i -e "s:%LOAD_BALANCER_HOSTNAME%:${LB_HOST}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh
sed -i -e "s:%LOAD_BALANCER_PORTNUMBER%:${LB_PORT}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh
sed -i -e "s:%LOAD_BALANCER_PROTOCOL%:${LB_PROTOCOL}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh

sed -i -e "s:%SITES_SAMPLES%:${SITES_SAMPLES}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh

sed -i -e "s:%SITES_CACHE_PORTS%:${SITES_CACHE_PORTS}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh

sed -i -e "s:%MANAGED_SERVER_PORT%:${MANAGED_SERVER_PORT}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh

sed -i -e "s:%SITES_ADMIN_USERNAME%:${SITES_ADMIN_USERNAME}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh
sed -i -e "s:%SITES_ADMIN_PASSWORD%:${SITES_ADMIN_PASSWORD}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh
sed -i -e "s:%SITES_APP_USERNAME%:${SITES_APP_USERNAME}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh
sed -i -e "s:%SITES_APP_PASSWORD%:${SITES_APP_PASSWORD}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh
sed -i -e "s:%SITES_SS_USERNAME%:${SITES_SS_USERNAME}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh
sed -i -e "s:%SITES_SS_PASSWORD%:${SITES_SS_PASSWORD}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh
sed -i -e "s:%DOMAIN_HOME%:${DOMAIN_HOME_DIR}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh
sed -i -e "s:%DOMAIN_ROOT_DIR%:${DOMAIN_ROOT_DIR}:g" ${DOMAIN_HOME_DIR}/server-config-update.sh
																					   

# DON'T REMOVE THIS
# This script has to contain this log message. 
# It is used to determine if the job is really completed.
echo "Successfully Completed"
