#!/bin/bash
# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/utils.sh
source ${scriptDir}/soainfra-Specific.sh

UA_DIR=${DOMAIN_ROOT_DIR}/upgrade_${DOMAIN_UID}
CHECKPOINT_FILE="${UA_DIR}/checkpoint.txt"

logID=$(date +%Y%m%d-%H%M%S)
UA_LOGS_DIR="${UA_DIR}/logs"


#
# Function to perform initialize to directory and files
#
initialize(){
 printInfo "In initialize"
 mkdir -p "${UA_DIR}"
 mkdir -p "${UA_LOGS_DIR}"
 [ ! -f $CHECKPOINT_FILE ] && touch ${CHECKPOINT_FILE} 
}

#
# Function to verify checkpoint
#
verifyCheckPoint(){
  funcName=${FUNCNAME[1]}
  printInfo "In $funcName"
  if grep -q "${funcName}=done" "$CHECKPOINT_FILE"; then
      printInfo "Already executed ${funcName}. Skipping....";
      return 1
  else
      printInfo "Execute $funcName";
      return 0
  fi
}

#
# Function to add checkpoint
#
addCheckPoint(){
  funcName="${FUNCNAME[1]}"
  msg=$1
  echo "$funcName=$msg" >> "$CHECKPOINT_FILE"
}

#
# Function to perform schema upgrade
#
schemaUpgrade(){
  verifyCheckPoint    
  status=$?
  if [ $status -eq 0 ]; then
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
    sed -i -e "s:%SYS_PASSWORD%:${SYS_PASSWORD}:g" ${responseFile}
    sed -i -e "s:%SYS_USERNAME%:${SYS_USERNAME}:g" ${responseFile}
    sed -i -e "s:%ESS_SCHEMA_PREFIX%:${essSchemaPrefix}:g" ${responseFile}
    
    sleep 10
    printInfo "Schema upgrade started...."
    $ORACLE_HOME/oracle_common/upgrade/bin/ua -response $responseFile -logLevel TRACE
    uaStatus=$?
    rm $responseFile
    cp $ORACLE_HOME/oracle_common/upgrade/logs/ua*.log "${UA_LOGS_DIR}"
    if [ $uaStatus -eq 0 ]; then
        printInfo "Schema upgrade completed. Logs are available for review at ${UA_LOGS_DIR}."
        addCheckPoint "done"
    else
        printError "Schema upgrade failed. Review logs available at ${UA_LOGS_DIR} for details"
        exit $uaStatus
    fi
  else
    printInfo "Schema upgrade is already completed. Review logs available at ${UA_LOGS_DIR}"
  fi
}

  

#
# Function to perform domain home upgrade
#
domainHomeUpgrade(){
  verifyCheckPoint
  status=$?
  if [ $status -eq 0 ]; then
    printInfo "Domain home upgrade started...."
    export WLST_PROPERTIES="-Dwlst.offline.log=domainHomeUpgrade.log"
    $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning \
            /u01/scripts/domainHomeUpgrade.py \
            -domainHomeDir ${DOMAIN_HOME_DIR} \
            -domainName ${DOMAIN_NAME} 
    upStatus=$?
    cp domainHomeUpgrade.log "${UA_LOGS_DIR}/domainHomeUpgrade-${logID}.log"
    if [ $upStatus -eq 0 ]; then
        printInfo "Domain home upgrade completed. Logs are available for review at ${UA_LOGS_DIR}/domainHomeUpgrade-${logID}.log."
        addCheckPoint "done"
    else
        printError "Domain home upgrade failed. Review logs available at ${UA_LOGS_DIR}/domainHomeUpgrade-${logID}.log for details"
        exit $upStatus
    fi
 else
    printInfo "Domain upgrade is already completed. Review logs available at ${UA_LOGS_DIR}/domainHomeUpgrade-${logID}.log" 
 fi  
}

#
# Function to perform post upgrade updates
#
postUpgrade(){
  verifyCheckPoint
  status=$?
  if [ $status -eq 0 ]; then
    printInfo "Post upgrade tasks in progress...."
    export WLST_PROPERTIES="-Dwlst.offline.log=postUpgrade.log"
    $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning \
            /u01/scripts/postUpgrade.py \
            -domainHomeDir ${DOMAIN_HOME_DIR} \
            -domainName ${DOMAIN_NAME} \
            -connectionString ${CONNECTION_STRING} \
            -rcuPrefix ${RCUPREFIX} <<EOF
$(cat /weblogic-operator/rcu-secrets/password)
EOF
    poStatus=$?
    cp postUpgrade.log "${UA_LOGS_DIR}/postUpgrade-${logID}.log"
    if [ $poStatus -eq 0 ]; then
       printInfo "Post upgrade tasks completed. Logs are available for review at ${UA_LOGS_DIR}/postUpgrade-${logID}.log"
       addCheckPoint "done"
    else
       printError "Post upgrade tasks failed. Review logs available at ${UA_LOGS_DIR}/postUpgrade-${logID}.log for details"
       exit $poStatus
    fi
  else
    printInfo "Post upgrade tasks already completed. Review logs available at ${UA_LOGS_DIR}/postUpgrade-${logID}.log"
  fi 
}

#
# Function to enable secure for domain
#
enableSecure(){
  verifyCheckPoint
  status=$?
  if [ $status -eq 0 ]; then
    echo "SECURE_ENABLED is $SECURE_ENABLED"
    export WLST_PROPERTIES="-Dwlst.offline.log=secureEnable.log"
    $ORACLE_HOME/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning \
           /u01/scripts/secureDomain.py \
           -domainHomeDir ${DOMAIN_HOME_DIR} \
           -domainName ${DOMAIN_NAME}
    secureStatus=$?
    cp secureEnable.log "${UA_LOGS_DIR}/secureEnable-${logID}.log"
    if [ $secureStatus -eq 0 ]; then
      printInfo "Secure enable completed. Logs are available for review at ${UA_LOGS_DIR}/secureEnable-${logID}.log"
      addCheckPoint "done"
    else
      printError "Secure enable failed. Review logs available at ${UA_LOGS_DIR}/secureEnable-${logID}.log"
      exit $secureStatus
    fi
  else
    printInfo "Secure enable already completed. Review logs available at ${UA_LOGS_DIR}/secureEnable-${logID}.log"  
  fi
}


initialize
schemaUpgrade
domainHomeUpgrade
postUpgrade
soainfraSpecific

if [ "${SECURE_ENABLED}" == "true" ]; then
  enableSecure
fi

