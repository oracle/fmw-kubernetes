#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl

echo "Executing sample script to update the server configuration"

echo "Printing env"
env

sleep 10
LB_PROTOCOL="%LOAD_BALANCER_PROTOCOL%"
LB_HOST="%LOAD_BALANCER_HOSTNAME%"
LB_PORT="%LOAD_BALANCER_PORTNUMBER%"
SITES_ADMIN_USERNAME="%SITES_ADMIN_USERNAME%"
SITES_ADMIN_PASSWORD="%SITES_ADMIN_PASSWORD%"
SITES_APP_USERNAME="%SITES_APP_USERNAME%"
SITES_APP_PASSWORD="%SITES_APP_PASSWORD%"
SITES_SS_USERNAME="%SITES_SS_USERNAME%"
SITES_SS_PASSWORD="%SITES_SS_PASSWORD%"
SITES_SAMPLES="%SITES_SAMPLES%"
SITES_CACHE_PORTS="%SITES_CACHE_PORTS%"
MANAGED_SERVER_PORT="%MANAGED_SERVER_PORT%"

echo ADMIN_SERVER_NAME : ${ADMIN_SERVER_NAME}
echo DOMAIN_UID : ${DOMAIN_UID}
echo LB_PROTOCOL : ${LB_PROTOCOL}
echo LB_HOST : ${LB_HOST}
echo LB_PORT : ${LB_PORT}
echo HOSTNAME : ${HOSTNAME}
SERVER_NAME="${HOSTNAME/$DOMAIN_UID-/}"
echo SERVER_NAME : ${SERVER_NAME}
#SERVER_NAME=`echo $SERVER_NAME | tr "-" "_"`

echo "Final SERVER_NAME=${SERVER_NAME}"
echo SERVER_NAME : ${SERVER_NAME}

echo MANAGED_SERVER_PORT: ${MANAGED_SERVER_PORT}

SER_HOST_NAME=$(echo ${SERVER_NAME} |  tr '_' '- ')
echo SER_HOST_NAME : ${SER_HOST_NAME}
CONTEXTPATH="sites"

if [[ $SERVER_NAME == *?[0-9] ]];then
  echo "Input ends with  number"
else
  echo "Input does not end with number "
fi

DOMAIN_HOME="%DOMAIN_HOME%"
DOMAIN_ROOT_DIR="%DOMAIN_ROOT_DIR%"

echo DOMAIN_HOME : ${DOMAIN_HOME}

# This check skips the servers for which the configuration was already updated.

  if [ ${SERVER_NAME,,} != ${ADMIN_SERVER_NAME,,} ] && [ ! -f "${DOMAIN_HOME}/config/fmwconfig/servers/${SERVER_NAME}/config/updated.txt" ]; then
	# Logic to update the config file goes here
	
	if [ ! -f "${DOMAIN_HOME}/config/fmwconfig/wcsconfig/updated.txt" ]; then
		echo "--------------------------------------------"
		echo "Updating the configuration at: ${DOMAIN_HOME}/config/fmwconfig/wcsconfig"
		
		SHARED=${DOMAIN_HOME}/config/fmwconfig/wcsconfig
		NODECONFIG=${DOMAIN_HOME}/config/fmwconfig/servers/${SERVER_NAME}/config
		SITES_SHARED=${DOMAIN_ROOT_DIR}/shared		
		
		cd ${SHARED}

		sed -i 's,^\(oracle.wcsites.node.config=\).*,\1'${NODECONFIG}',' wcs_properties_bootstrap.ini
		
		sed -i 's,^\(oracle.wcsites.hostname=\).*,\1'${LB_HOST}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.portnumber=\).*,\1'${LB_PORT}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.cas.hostname=\).*,\1'${LB_HOST}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.cas.portnumber=\).*,\1'${LB_PORT}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.cas.hostnameActual=\).*,\1'${LB_HOST}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.cas.hostnameLocal=\).*,\1'${LB_HOST}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.cas.portnumberLocal=\).*,\1'${LB_PORT}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.system.admin.user=\).*,\1'${SITES_ADMIN_USERNAME}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.system.admin.password=\).*,\1'${SITES_ADMIN_PASSWORD}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.app.user=\).*,\1'${SITES_APP_USERNAME}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.app.password=\).*,\1'${SITES_APP_PASSWORD}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.satellite.user=\).*,\1'${SITES_SS_USERNAME}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.satellite.password=\).*,\1'${SITES_SS_PASSWORD}',' wcs_properties_bootstrap.ini
		
		sed -i 's,^\(oracle.wcsites.database.type=\).*,\1'Oracle',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.database.datasource=\).*,\1'wcsitesDS',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.examples=\).*,\1'true',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.examples.fsii=\).*,\1'${SITES_SAMPLES}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.examples.avisports=\).*,\1'${SITES_SAMPLES}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.examples.Samples=\).*,\1'${SITES_SAMPLES}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.bootstrap.status=\).*,\1'never_done',' wcs_properties_bootstrap.ini
		
		sed -i 's,^\(oracle.wcsites.contextpath=\).*,\1'/${CONTEXTPATH}/',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.shared=\).*,\1'${SITES_SHARED}',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.appserver.type=\).*,\1'wls92',' wcs_properties_bootstrap.ini
		sed -i 's,^\(oracle.wcsites.protocol=\).*,\1'${LB_PROTOCOL}',' wcs_properties_bootstrap.ini		
		
		
		touch ${DOMAIN_HOME}/config/fmwconfig/wcsconfig/updated.txt
		echo "Updated the configuration at: ${DOMAIN_HOME}/config/fmwconfig/wcsconfig"
		echo "--------------------------------------------"
	fi
	
	echo "--------------------------------------------" ${SERVER_NAME} "--------------------------------------------"
	echo "Updating the configuration at: ${DOMAIN_HOME}/config/fmwconfig/servers/${SERVER_NAME}/config"
	cp ${DOMAIN_HOME}/config/fmwconfig/wcsconfig/wcs_properties.json ${SITES_SHARED}/
	
	replaceString="127.0.0.1"
	
	# Print the values 
	replaceWith=${DOMAIN_UID}-${SER_HOST_NAME}
	location=${DOMAIN_HOME}/config/fmwconfig/servers/${SERVER_NAME}/config/
	
	echo replacing for ${SERVER_NAME}  "timeToLive=0 to timeToLive=1"
	grep -rl timeToLive=0 ${location}
	grep -rl timeToLive=0 ${location} | xargs sed -i "s/timeToLive=0/timeToLive=1/g"
	
	echo replacing for ${SERVER_NAME}  "ip_ttl=0 to ip_ttl=1"
	grep -rl ip_ttl=\"0\" ${location}
	grep -rl ip_ttl=\"0\" ${location} | xargs sed -i "s/ip_ttl=\"0\"/ip_ttl=\"1\"/g"
	
	echo replacing for ${SERVER_NAME} ${location}host.properties
	sed -i "s/@unique_id@/${replaceWith}/g" ${location}host.properties
	
	echo replacing for ${SERVER_NAME} ${location}deployerConfigContext.xml
	sed -i "s/@CSConnectPrefix@/${LB_PROTOCOL}/g" ${location}deployerConfigContext.xml
	sed -i "s/@hostname@/${LB_HOST}/g" ${location}deployerConfigContext.xml
	sed -i "s/@portnumber@/${LB_PORT}/g" ${location}deployerConfigContext.xml
	sed -i "s/@context-path@/${CONTEXTPATH}/g" ${location}deployerConfigContext.xml
	
	echo replacing for ${SERVER_NAME} ${location}cas.properties
	sed -i "s/@CSConnectPrefix@/${LB_PROTOCOL}/g" ${location}cas.properties
	sed -i "s/@hostname@/${replaceWith}/g" ${location}cas.properties
	sed -i "s/@portnumber@/${MANAGED_SERVER_PORT}/g" ${location}cas.properties
	
	echo replacing for ${SERVER_NAME} ${location}customBeans.xml
	sed -i "s/@CSConnectPrefix@/${LB_PROTOCOL}/g" ${location}customBeans.xml
	sed -i "s/@hostname@/${LB_HOST}/g" ${location}customBeans.xml
	sed -i "s/@portnumber@/${LB_PORT}/g" ${location}customBeans.xml
	sed -i "s/@context-path@/${CONTEXTPATH}/g" ${location}customBeans.xml
	
	echo "--------------------------------------------"
	
	if [ -z "$SITES_CACHE_PORTS" ]
	then
		echo "\$SITES_CACHE_PORTS is empty"
	else
		echo "\$SITES_CACHE_PORTS is NOT empty"
		python ${DOMAIN_HOME}/unicast.py ${DOMAIN_HOME} ${HOSTNAME::-1} ${SERVER_NAME} ${SITES_CACHE_PORTS}
	fi
	
	
	echo "--------------------------------------------"
	
	rm ${DOMAIN_HOME}/config/fmwconfig/servers/${SERVER_NAME}/config/wcs_properties.json
	rm ${DOMAIN_HOME}/config/fmwconfig/servers/${SERVER_NAME}/config/wcs_properties_bootstrap.ini
	
	#mkdir ${DOMAIN_HOME}/config/fmwconfig/servers/${SERVER_NAME}/config
	touch ${DOMAIN_HOME}/config/fmwconfig/servers/${SERVER_NAME}/config/updated.txt

	

  else
	# Case where the configuration of the server was already updated or not required to udpate.
	echo "Not updating configuration of the server ${SERVER_NAME}."
  fi

echo "--------------------------------------------"
echo "checking the availability of custom extend.sites.webapp-lib.war"

CUSTOM_EXTEND_LIB=${DOMAIN_ROOT_DIR}/sites-home/extend.sites.webapp-lib.war
EXTEND_LIB=/u01/oracle/wcsites/webcentersites/sites-home/extend.sites.webapp-lib.war

if [ -f "$CUSTOM_EXTEND_LIB" ]; then
	EXTEND_LIB=$(echo $EXTEND_LIB | sed 's_/_\\/_g')
	CUSTOM_EXTEND_LIB=$(echo $CUSTOM_EXTEND_LIB | sed 's_/_\\/_g')
	echo "replacing $EXTEND_LIB with custom $CUSTOM_EXTEND_LIB in config.xml"
	sed -i "s/${EXTEND_LIB}/${CUSTOM_EXTEND_LIB}/g" ${DOMAIN_HOME}/config/config.xml
else
	EXTEND_LIB=$(echo $EXTEND_LIB | sed 's_/_\\/_g')
	CUSTOM_EXTEND_LIB=$(echo $CUSTOM_EXTEND_LIB | sed 's_/_\\/_g')
	echo "reverting custom $CUSTOM_EXTEND_LIB to $EXTEND_LIB in config.xml"
	sed -i "s/${CUSTOM_EXTEND_LIB}/${EXTEND_LIB}/g" ${DOMAIN_HOME}/config/config.xml
fi
