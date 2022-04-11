#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl
#

# Drop the RCU schema based on schemaPreifix and Database URL

DB_CONNECTSTRING=$CUSTOM_CONNECTION_STRING
DB_USER=`cat /weblogic-operator/rcu-secrets/sys_username`
DB_PASSWORD=`cat /weblogic-operator/rcu-secrets/sys_password`
DB_SCHEMA_PASSWORD=`cat /weblogic-operator/rcu-secrets/password`
RCU_PREFIX=$CUSTOM_RCUPREFIX
rcuType=fmw
SITES_DOMAIN_HOME=$DOMAIN_HOME_DIR
SITES_DOMAIN_LOGS=$DOMAIN_LOGS_DIR
echo "Cleaning direcotry ${SITES_DOMAIN_HOME}"
rm -rf ${SITES_DOMAIN_HOME}
echo "Cleaning direcotry ${SITES_DOMAIN_LOGS}"
rm -rf ${SITES_DOMAIN_LOGS}

echo "${DB_PASSWORD}" > pwd.txt
echo "${DB_SCHEMA_PASSWORD}" >> pwd.txt

echo "dropping RCU schema with following parameters ${DB_CONNECTSTRING} ${RCU_PREFIX} ${rcuType} ${DB_PASSWORD}"
source ${CREATE_DOMAIN_SCRIPT_DIR}/dropRepository.sh ${DB_CONNECTSTRING} ${RCU_PREFIX} ${rcuType} ${DB_PASSWORD}
