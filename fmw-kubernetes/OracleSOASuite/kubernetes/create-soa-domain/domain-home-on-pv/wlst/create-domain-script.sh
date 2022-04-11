#!/bin/bash
# Copyright (c) 2020, 2021, Oracle and/or its affiliates.
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
