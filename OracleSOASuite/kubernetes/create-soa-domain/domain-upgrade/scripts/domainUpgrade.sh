#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"

SCHEMA_PASSWORD=`cat /weblogic-operator/rcu-secrets/password`
SYS_PASSWORD=`cat /weblogic-operator/rcu-secrets/sys_password`
SYS_USERNAME=`cat /weblogic-operator/rcu-secrets/sys_username`
essSchemaPrefix=""
if [ "${DOMAIN_TYPE}" = "osb" ]; then
  essSchemaPrefix="#"
fi
responseFile=/tmp/domainUpgradeResponse.txt
cp $scriptDir/domainUpgradeResponse.txt ${responseFile}
sed -i -e "s:%DOMAIN_HOME%:${DOMAIN_HOME_DIR}:g" ${responseFile}
sed -i -e "s|%CONNECTION_STRING%|${CONNECTION_STRING}|g" ${responseFile}
sed -i -e "s:%RCUPREFIX%:${RCUPREFIX}:g" ${responseFile}
sed -i -e "s:%SCHEMA_PASSWORD%:${SCHEMA_PASSWORD}:g" ${responseFile}
sed -i -e "s:%SYS_PASSSWORD%:${SYS_PASSWORD}:g" ${responseFile}
sed -i -e "s:%SYS_USERNAME%:${SYS_USERNAME}:g" ${responseFile}
sed -i -e "s:%ESS_SCHEMA_PREFIX%:${essSchemaPrefix}:g" ${responseFile}

echo "SECURE_ENABLED is $SECURE_ENABLED"
sleep 10
echo "Schema upgrade in progress ...."
$ORACLE_HOME/oracle_common/upgrade/bin/ua -response $responseFile -logLevel TRACE

UA_LOGS="${DOMAIN_HOME_DIR}/ua_logs"
mkdir -p ${UA_LOGS}
cp $ORACLE_HOME/oracle_common/upgrade/logs/ua*.log ${UA_LOGS}

echo "Schema upgrade completed. Logs are available for review at ${UA_LOGS}."

echo "Starting domain upgrade ...."
$ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning \
            /u01/scripts/domainUpgrade.py \
            -domainHomeDir ${DOMAIN_HOME_DIR} \
            -domainName ${DOMAIN_NAME} \
            -connectionString ${CONNECTION_STRING} \
            -rcuPrefix ${RCUPREFIX} \
            -schemaPassword `cat /weblogic-operator/rcu-secrets/password`

if [ "$SECURE_ENABLED" == "true" ]; then
   $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning \
           /u01/scripts/secureDomain.py \
           -domainHomeDir ${DOMAIN_HOME_DIR} \
           -domainName ${DOMAIN_NAME}
fi
