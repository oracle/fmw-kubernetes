#!/bin/bash
# Copyright (c) 2020, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

export DOMAIN_HOME=${DOMAIN_HOME_DIR}

# Create the domain
if [ -z "${JAVA_HOME}" ]; then
  JAVA_HOME=/usr/java/latest
fi  
wlst.sh -skipWLSModuleScanning \
        ${CREATE_DOMAIN_SCRIPT_DIR}/createSOADomain.py \
        -oh /u01/oracle \
        -jh ${JAVA_HOME} \
        -parent ${DOMAIN_HOME}/.. \
        -name ${CUSTOM_DOMAIN_NAME} \
        -user `cat /weblogic-operator/secrets/username` \
        -password `cat /weblogic-operator/secrets/password` \
        -rcuDb ${CUSTOM_CONNECTION_STRING} \
        -rcuPrefix ${CUSTOM_RCUPREFIX} \
        -rcuSchemaPwd `cat /weblogic-operator/rcu-secrets/password` \
        -adminListenPort ${CUSTOM_ADMIN_LISTEN_PORT} \
        -adminName ${CUSTOM_ADMIN_NAME} \
        -soaManagedNameBase ${CUSTOM_SOA_MANAGED_BASE_NAME} \
        -osbManagedNameBase ${CUSTOM_OSB_MANAGED_BASE_NAME} \
        -soaManagedServerPort ${CUSTOM_SOA_MANAGEDSERVER_PORT} \
        -osbManagedServerPort ${CUSTOM_OSB_MANAGEDSERVER_PORT} \
        -prodMode ${CUSTOM_PRODUCTION_MODE} \
        -secureMode ${CUSTOM_SECURE_MODE} \
        -adminAdministrationPort ${CUSTOM_ADMIN_ADMINISTRATION_PORT} \
        -soaAdministrationPort ${CUSTOM_SOA_ADMINISTRATION_PORT} \
        -osbAdministrationPort ${CUSTOM_OSB_ADMINISTRATION_PORT} \
        -managedServerCount ${CUSTOM_MANAGED_SERVER_COUNT} \
        -soaClusterName ${CUSTOM_SOA_CLUSTER_NAME} \
        -osbClusterName ${CUSTOM_OSB_CLUSTER_NAME} \
        -domainType ${DOMAIN_TYPE} \
        -exposeAdminT3Channel ${EXPOSE_T3_CHANNEL_PREFIX} \
        -t3ChannelPublicAddress ${T3_PUBLIC_ADDRESS} \
        -t3ChannelPort ${T3_CHANNEL_PORT} \
        -sslEnabled ${SSL_ENABLED} \
        -adminServerSSLPort ${ADMIN_SERVER_SSL_PORT} \
        -soaManagedServerSSLPort ${SOA_MANAGED_SERVER_SSL_PORT} \
        -osbManagedServerSSLPort ${OSB_MANAGED_SERVER_SSL_PORT} \
        -persistentStore ${PERSISTENCE_STORE}

wlstCmdVal=$?

if [ $wlstCmdVal -ne 0 ]; then
   echo "ERROR: Domain creation failed. Please check the logs"
   exit 1
else
   #For BUG-37807693
   export OH=/u01/oracle
   JAR_FILE="$OH/oracle_common/modules/oracle.adf.share/adf-share-support.jar"
   SCRIPT_TO_CHECK="DomainConfigGraalLibUpdate.sh"
   if [ -f $JAR_FILE ]; then
	echo "adf-share-support.jar is available, Checking availability of script DomainConfigGraalLibUpdate.sh"
	FILE_PATH=$(jar tf "$JAR_FILE" | grep "$SCRIPT_TO_CHECK")
	if [ -n "$FILE_PATH" ]; then
	   echo "File path of DomainConfigGraalLibUpdate.sh - $FILE_PATH"
	   cd /tmp
           jar xvf $JAR_FILE $FILE_PATH
	   chmod +x $FILE_PATH
	   echo $OH | /tmp/$FILE_PATH
           retVal=$?
           if [ $retVal -ne 0 ]; then
              echo "ERROR: DomainConfigGraalLibUpdate.sh execution failed. Please check the logs"
              exit 1
           else
              echo "DomainConfigGraalLibUpdate.sh script execution completed"
           fi
        else
	   echo "Script DomainConfigGraalLibUpdate.sh not available"
	fi
   else
      echo "$JAR_FILE not available"
   fi
fi
