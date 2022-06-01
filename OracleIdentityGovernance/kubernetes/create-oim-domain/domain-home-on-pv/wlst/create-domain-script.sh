#!/bin/bash
# Copyright (c) 2020, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

export DOMAIN_HOME=${DOMAIN_HOME_DIR}
export namespace=${NAMESPACE}
export domainName=${CUSTOM_DOMAIN_NAME}
if [ -z "${JAVA_HOME}" ]; then
  JAVA_HOME=/usr/java/latest
fi 


echo 'namespace:' $namespace
echo 'frontEndHost ,frontEndHttpPort :' ${FRONTENDHOST} ${FRONTENDHTTPPORT} 
echo 'domain name:' $domainName

# Create the domain
wlst.sh -skipWLSModuleScanning \
        ${CREATE_DOMAIN_SCRIPT_DIR}/createFMWDomain.py \
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
        -frontEndHost ${FRONTENDHOST} \
        -frontEndHttpPort ${FRONTENDHTTPPORT}

if [ $? -ne 0 ]
then
   # die with unsuccessful shell script termination exit status # 3
   echo "An error occurred while Creating Domain".
   exit 2
fi

# invoke offine config manager
export DOMAIN_HOME=${DOMAIN_HOME_DIR}
export JAVA_HOME=/usr/java/latest
chmod a+rx /u01/oracle/idm/server/bin/offlineConfigManager.sh
cd /u01/oracle/idm/server/bin/
offlineCmd="./offlineConfigManager.sh"
${offlineCmd}
retval=$?
if [ $retval -ne 0 ]; 
 then
   echo "ERROR: Offline config command failed. Please check the logs"
   exit 4
fi

# invoke the command to remove the unnessary templates in the domain config

sed -i 's/<server-template>//g' $DOMAIN_HOME/config/config.xml 
sed -i 's/<listen-port>7100<\/listen-port>//g' $DOMAIN_HOME/config/config.xml
sed -i 's/<\/server-template>//g' $DOMAIN_HOME/config/config.xml
sed -i 's/<name>soa-server-template<\/name>//g' $DOMAIN_HOME/config/config.xml
sed -i 's/<name>oim-server-template<\/name>//g' $DOMAIN_HOME/config/config.xml
sed -i 's/<name>wsm-cache-server-template<\/name>//g' $DOMAIN_HOME/config/config.xml
sed -i 's/<name>wsmpm-server-template<\/name>//g' $DOMAIN_HOME/config/config.xml
sed -i 's/<ssl>/<!--ssl>/g' $DOMAIN_HOME/config/config.xml
sed -i 's/<\/ssl>/<\/ssl-->/g' $DOMAIN_HOME/config/config.xml
sed -i "s/oimk8namespace/$domainName/g" $DOMAIN_HOME/config/config.xml
sed -i "s/applications\/$domainName\/em.ear/domains\/applications\/$domainName\/em.ear/g" $DOMAIN_HOME/config/config.xml

if [ ! -f /u01/oracle/idm/server/ConnectorDefaultDirectory/ConnectorConfigTemplate.xml ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/ConnectorConfigTemplate.xml /u01/oracle/idm/server/ConnectorDefaultDirectory
fi
if [ ! -f /u01/oracle/idm/server/ConnectorDefaultDirectory/ConnectorSchema.xsd ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/ConnectorSchema.xsd /u01/oracle/idm/server/ConnectorDefaultDirectory
fi
if [ ! -f /u01/oracle/idm/server/ConnectorDefaultDirectory/readme.txt ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/readme.txt /u01/oracle/idm/server/ConnectorDefaultDirectory
fi
if [ ! -d /u01/oracle/idm/server/ConnectorDefaultDirectory/targetsystems-lib ] && [ -d /u01/oracle/idm/server/ConnectorDefaultDirectory_orig ]; then
    cp -rf /u01/oracle/idm/server/ConnectorDefaultDirectory_orig/targetsystems-lib /u01/oracle/idm/server/ConnectorDefaultDirectory
fi
