#!/bin/bash
# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl

export DOMAIN_HOME=${DOMAIN_HOME_DIR}

echo wlst.sh -skipWLSModuleScanning ${CREATE_DOMAIN_SCRIPT_DIR}/createSitesDomain.py -oh ${ORACLE_HOME} -jh ${JAVA_HOME} -parent ${DOMAIN_HOME}/.. -name ${CUSTOM_DOMAIN_NAME} -user `cat /weblogic-operator/secrets/username` -password `cat /weblogic-operator/secrets/password` -rcuDb ${CUSTOM_CONNECTION_STRING} -rcuPrefix ${CUSTOM_RCUPREFIX} -rcuSchemaPwd `cat /weblogic-operator/rcu-secrets/password` -adminListenPort ${CUSTOM_ADMIN_LISTEN_PORT} -adminName ${CUSTOM_ADMIN_NAME} -managedNameBase ${CUSTOM_MANAGED_BASE_NAME} -managedServerPort ${CUSTOM_MANAGEDSERVER_PORT} -prodMode ${CUSTOM_PRODUCTION_MODE} -secureMode ${CUSTOM_SECURE_MODE} -managedServerCount ${CUSTOM_MANAGED_SERVER_COUNT} -clusterName ${CUSTOM_CLUSTER_NAME} -exposeAdminT3Channel ${EXPOSE_T3_CHANNEL_PREFIX} -t3ChannelPublicAddress ${T3_PUBLIC_ADDRESS} -t3ChannelPort ${T3_CHANNEL_PORT} -sslEnabled ${SSL_ENABLED} -adminServerSSLPort ${ADMIN_SERVER_SSL_PORT} -managedServerSSLPort ${MANAGED_SERVER_SSL_PORT} -domainType wcsites -adminAdministrationPort ${CUSTOM_ADMIN_ADMINISTRATION_PORT} -managedServerAdministrationPort ${CUSTOM_MANAGED_SERVER_ADMINISTRATION_PORT} -machineName wcsites_machine

# Create the domain
wlst.sh -skipWLSModuleScanning \
        ${CREATE_DOMAIN_SCRIPT_DIR}/createSitesDomain.py \
        -oh ${ORACLE_HOME} \
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
        -t3ChannelPort ${T3_CHANNEL_PORT} \
	    -sslEnabled ${SSL_ENABLED} \
        -adminServerSSLPort ${ADMIN_SERVER_SSL_PORT} \
        -managedServerSSLPort ${MANAGED_SERVER_SSL_PORT} \
		-domainType wcsites \
        -adminAdministrationPort ${CUSTOM_ADMIN_ADMINISTRATION_PORT} \
        -managedServerAdministrationPort ${CUSTOM_MANAGED_SERVER_ADMINISTRATION_PORT} \
		-machineName wcsites_machine
