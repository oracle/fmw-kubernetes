#!/bin/bash
# Copyright (c) 2024,2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#
# Script to perform SOA specific updates
#

soainfraSpecific(){
    b2bTargetsRemoval    # Function call for b2bUI Targets removal
    configurationUpgrade # Function call for configuration upgrade
}


b2bTargetsRemoval(){
   verifyCheckPoint
   status=$?
   if [ $status -eq 0 ]; then
      printInfo "Removing the b2bui targets if exists...."
      export WLST_PROPERTIES="-Dwlst.offline.log=b2bTargetsRemoval.log"

      $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning \
	      /u01/scripts/b2bTargetsRemoval.py \
	      -domainHomeDir ${DOMAIN_HOME_DIR} \
	      -domainName ${DOMAIN_NAME}

      psStatus=$?
      cp b2bTargetsRemoval.log "${UA_LOGS_DIR}/b2bTargetsRemoval-${logID}.log"

      if [ $psStatus -eq 0 ]; then
	 printInfo "Removal of b2bui targets completed. Logs are available for review at ${UA_LOGS_DIR}/b2bTargetsRemoval-${logID}.log"
	 addCheckPoint "done"
      else
	 printError "Removal of b2bui targets failed. Review logs available at ${UA_LOGS_DIR}/b2bTargetsRemoval-${logID}.log for details"
	 exit $psStatus
      fi
   else
      printInfo "Removal of b2bui targets completed. Review logs available at ${UA_LOGS_DIR}/b2bTargetsRemoval-${logID}.log"
   fi
}

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
