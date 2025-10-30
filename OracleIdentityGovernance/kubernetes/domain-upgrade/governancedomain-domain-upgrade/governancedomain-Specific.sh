#!/bin/bash
# Copyright (c) 2024,2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#
# Function to perform OIG specific updates
#

governancedomainSpecific(){
  printInfo "OIG specific tasks in progress...."
  configurationUpgrade
}

##
# Any additional scripts with respect to product specific can be updated here.
# Additional .py files with respect to product specific can be updated here.
##
configurationUpgrade(){
  verifyCheckPoint
  status=$?
  if [ $status -eq 0 ]; then
    responseFile=/tmp/configurationUpgradeResponse.txt
    cp $scriptDir/configurationUpgradeResponse.txt  ${responseFile}
    sed -i -e "s:%DOMAIN_HOME%:${DOMAIN_HOME_DIR}:g" ${responseFile}
    sleep 10
    printInfo "Configuration upgrade started...."
    $ORACLE_HOME/oracle_common/upgrade/bin/ua -configUpgrade -response $responseFile -logLevel TRACE
    uaStatus=$?
    rm $responseFile
    cp $ORACLE_HOME/oracle_common/upgrade/logs/ua*.log "${UA_LOGS_DIR}"
    if [ $uaStatus -eq 0 ]; then
        printInfo "Configuration upgrade completed. Logs are available for review at ${UA_LOGS_DIR}."
        addCheckPoint "done"
    else
        printError "Configuration upgrade failed. Review logs available at ${UA_LOGS_DIR} for details"
        exit $uaStatus
    fi
  else
    printInfo "Configuration upgrade is already completed. Review logs available at ${UA_LOGS_DIR}"
  fi
}
