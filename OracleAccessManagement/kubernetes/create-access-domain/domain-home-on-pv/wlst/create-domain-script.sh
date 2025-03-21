#!/bin/bash
# Copyright (c) 2020, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

export DOMAIN_HOME=${DOMAIN_HOME_DIR}
if [ -z "${JAVA_HOME}" ]; then
  JAVA_HOME=/usr/java/latest
fi

echo 'datasource type:' $DATASOURCE_TYPE

# Create the domain
wlst.sh -skipWLSModuleScanning \
        ${CREATE_DOMAIN_SCRIPT_DIR}/createOAMDomain.py \
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
        -managedNameBase ${CUSTOM_MANAGED_BASE_NAME} \
        -managedServerPort ${CUSTOM_MANAGEDSERVER_PORT} \
        -prodMode ${CUSTOM_PRODUCTION_MODE} \
        -managedServerCount ${CUSTOM_MANAGED_SERVER_COUNT} \
        -clusterName ${CUSTOM_CLUSTER_NAME} \
        -domainType ${DOMAIN_TYPE} \
        -exposeAdminT3Channel ${EXPOSE_T3_CHANNEL_PREFIX} \
        -t3ChannelPublicAddress ${T3_PUBLIC_ADDRESS} \
        -t3ChannelPort ${T3_CHANNEL_PORT} \
        -datasourceType ${DATASOURCE_TYPE}

sed -i "s/oamk8namespace/${DOMAIN_UID}/g" $DOMAIN_HOME/config/config.xml
