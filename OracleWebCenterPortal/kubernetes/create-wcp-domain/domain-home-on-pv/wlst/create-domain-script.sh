#!/bin/bash
# Copyright (c) 2020, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

export DOMAIN_HOME=${DOMAIN_HOME_DIR}

if [ -z "${JAVA_HOME}" ]; then
  JAVA_HOME=/usr/java/latest
fi

# Create the domain
wlst.sh -skipWLSModuleScanning \
        ${CREATE_DOMAIN_SCRIPT_DIR}/createWebCenterPortalDomain.py \
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
        -secureMode ${CUSTOM_SECURE_MODE} \
        -managedServerCount ${CUSTOM_MANAGED_SERVER_COUNT} \
        -clusterName ${CUSTOM_CLUSTER_NAME} \
        -exposeAdminT3Channel ${EXPOSE_T3_CHANNEL_PREFIX} \
        -t3ChannelPublicAddress ${T3_PUBLIC_ADDRESS} \
        -sslEnabled ${SSL_ENABLED} \
        -adminServerSSLPort ${ADMIN_SERVER_SSL_PORT} \
        -managedServerSSLPort ${MANAGED_SERVER_SSL_PORT} \
        -configurePortletServer ${CONFIGURE_PORTLET_SERVER}\
        -portletServerPort ${PORTLET_SERVER_PORT}\
        -portletServerSSLPort ${PORTLET_SERVER_SSL_PORT}\
        -portletServerNameBase ${PORTLET_SERVER_NAME_BASE}\
        -portletClusterName ${PORTLET_CLUSTER_NAME}\
        -adminAdministrationPort ${CUSTOM_ADMIN_ADMINISTRATION_PORT} \
        -managedAdministrationPort ${CUSTOM_MANAGED_ADMINISTRATION_PORT} \
        -portletAdministrationPort ${CUSTOM_PORTLET_ADMINISTRATION_PORT} \
        -t3ChannelPort ${T3_CHANNEL_PORT}
