#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

export DOMAIN_HOME=${DOMAIN_HOME_DIR}

# Create the domain
if [ -z "${JAVA_HOME}" ]; then
  JAVA_HOME=/usr/java/latest
fi
wlst.sh -skipWLSModuleScanning \
        ${CREATE_DOMAIN_SCRIPT_DIR}/createWebCenterContentDomain.py \
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
        -exposeAdminT3Channel ${EXPOSE_T3_CHANNEL_PREFIX} \
        -t3ChannelPublicAddress ${T3_PUBLIC_ADDRESS} \
        -t3ChannelPort ${T3_CHANNEL_PORT} \
        -sslEnabled ${SSL_ENABLED} \
        -adminServerSSLPort ${ADMIN_SERVER_SSL_PORT} \
        -managedServerSSLPort ${MANAGED_SERVER_SSL_PORT}

# call respective Domain creation python file for additional components - ipm, capture and adfui.
if [ "${IPM_ENABLED}" == "true" ]
then
   echo "Call CreateIPMDomain.py file"
   wlst.sh -skipWLSModuleScanning \
        ${CREATE_DOMAIN_SCRIPT_DIR}/createIPMDomain.py \
        -oh /u01/oracle \
        -jh ${JAVA_HOME} \
        -parent ${DOMAIN_HOME}/ \
        -name ${CUSTOM_DOMAIN_NAME} \
        -rcuDb ${CUSTOM_CONNECTION_STRING} \
        -rcuPrefix ${CUSTOM_RCUPREFIX} \
        -rcuSchemaPwd `cat /weblogic-operator/rcu-secrets/password` \
        -prodMode ${CUSTOM_PRODUCTION_MODE} \
        -managedServerCount ${CUSTOM_MANAGED_SERVER_COUNT} \
        -sslEnabled ${SSL_ENABLED} 
fi

if [ "${CAPTURE_ENABLED}" == "true" ]
then
   echo "Building k8 capture domain template jar"
   echo "Extracting the capture template jar oracle.capture_template.jar"
   mkdir -pv /u01/oracle/wccapture/common/templates/wls/template_k8
   cd /u01/oracle/wccapture/common/templates/wls/template_k8
   jar -xf /u01/oracle/wccapture/common/templates/wls/oracle.capture_template.jar
   cd config
   echo "Replacing capture_server1 with CAPTURE_server1 in config.xml"
   sed -i "s/capture_server1/CAPTURE_server1/g" config.xml
   cd ..
   echo "Recreating the domain template jar oracle.capture_template.jar"
   jar -cf oracle.capture_template.jar .
   rm -rf /u01/oracle/wccapture/common/templates/wls/oracle.capture_template.jar
   cp oracle.capture_template.jar /u01/oracle/wccapture/common/templates/wls/    
   echo "Building k8 domain template jar completed"
   echo "Call createCaptureDomain.py file"
   wlst.sh -skipWLSModuleScanning \
        ${CREATE_DOMAIN_SCRIPT_DIR}/createCaptureDomain.py \
        -oh /u01/oracle \
        -jh ${JAVA_HOME} \
        -parent ${DOMAIN_HOME}/ \
        -name ${CUSTOM_DOMAIN_NAME} \
        -rcuDb ${CUSTOM_CONNECTION_STRING} \
        -rcuPrefix ${CUSTOM_RCUPREFIX} \
        -rcuSchemaPwd `cat /weblogic-operator/rcu-secrets/password` \
        -prodMode ${CUSTOM_PRODUCTION_MODE} \
        -managedServerCount ${CUSTOM_MANAGED_SERVER_COUNT} \
        -sslEnabled ${SSL_ENABLED} 
fi

if [ "${ADFUI_ENABLED}" == "true" ]
then
   echo "Call createWCCADFDomain.py file"
   wlst.sh -skipWLSModuleScanning \
        ${CREATE_DOMAIN_SCRIPT_DIR}/createWCCADFDomain.py \
        -oh /u01/oracle \
        -jh ${JAVA_HOME} \
        -parent ${DOMAIN_HOME}/ \
        -name ${CUSTOM_DOMAIN_NAME} \
        -user `cat /weblogic-operator/secrets/username` \
        -password `cat /weblogic-operator/secrets/password` \
        -rcuDb ${CUSTOM_CONNECTION_STRING} \
        -rcuPrefix ${CUSTOM_RCUPREFIX} \
        -rcuSchemaPwd `cat /weblogic-operator/rcu-secrets/password` \
        -prodMode ${CUSTOM_PRODUCTION_MODE} \
        -managedServerCount ${CUSTOM_MANAGED_SERVER_COUNT} \
        -sslEnabled ${SSL_ENABLED} 
fi
