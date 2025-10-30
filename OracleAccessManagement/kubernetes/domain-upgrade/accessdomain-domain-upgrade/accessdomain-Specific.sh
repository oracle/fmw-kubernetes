#!/bin/bash
# Copyright (c) 2024,2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#
# Function to perform OAM specific updates
#

accessdomainSpecific(){
  printInfo "OAM Product specific tasks in progress..."
  #sampleFunction
}

sampleFunction(){
  verifyCheckPoint
  status=$?
  if [ $status -eq 0 ]; then
    printInfo "OAM specific tasks in progress...."
    export WLST_PROPERTIES="-Dwlst.offline.log=accessdomainSpecific.log"
    $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning \
            /u01/scripts/accessdomainSpecific.py \
            -domainHomeDir ${DOMAIN_HOME_DIR} \
            -domainName ${DOMAIN_NAME}
    psStatus=$?
    cp accessdomainSpecific.log "${UA_LOGS_DIR}/accessdomainSpecific-${logID}.log"
    if [ $psStatus -eq 0 ]; then
       printInfo "OAM specific tasks completed. Logs are available for review at ${UA_LOGS_DIR}/accessdomainSpecific-${logID}.log"
       addCheckPoint "done"
    else
       printError "OAM specific tasks failed. Review logs available at ${UA_LOGS_DIR}/accessdomainSpecific-${logID}.log for details"
       exit $psStatus
    fi
  else
    printInfo "OAM specific tasks already completed. Review logs available at ${UA_LOGS_DIR}/accessdomainSpecific-${logID}.log"
  fi

}

##
# Any additional scripts with respect to product specific can be updated here.
# Additional .py files with respect to product specific can be updated here.
##
