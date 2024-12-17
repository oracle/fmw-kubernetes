#!/bin/bash
# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"

. $ORACLE_HOME/wlserver/server/bin/setWLSEnv.sh

function exitIfError {
  if [ "$1" != "0" ]; then
    echo "$2"
    exit $1
  fi
}

function deploy {
  cd /u01/oracle/soa/bin
  ant -f ant-sca-deploy.xml \
      -DserverURL=${PROTOCOL}://${DOMAIN_UID}-cluster-${SOA_CLUSTER_NAME}:${SOA_MANAGED_SERVER_PORT}  \
      -DsarLocation=/u01/sarchives/$1 \
      -Doverwrite=true \
      -Duser=$(cat /weblogic-operator/secrets/username) -Dpassword=$(cat /weblogic-operator/secrets/password)
}

if [[ $PROTOCOL == "https" ]]; then
   echo | openssl s_client -showcerts  -connect ${DOMAIN_UID}-cluster-${SOA_CLUSTER_NAME}:${SOA_MANAGED_SERVER_PORT} 2>/dev/null |  openssl x509  -trustout > /tmp/ssl_cert.crt
   if [[ -f $JAVA_HOME/lib/security/cacerts ]]; then
       echo yes | keytool -import -v -trustcacerts -alias soadomain -file /tmp/ssl_cert.crt -keystore $JAVA_HOME/lib/security/cacerts -keypass changeit -storepass changeit
   else
       echo yes | keytool -import -v -trustcacerts -alias soadomain -file /tmp/ssl_cert.crt -keystore $JAVA_HOME/jre/lib/security/cacerts -keypass changeit -storepass changeit
   fi
fi

cd /u01/sarchives/
sars=$(ls *)
for sar in $sars
do
   deploy $sar
done

exitIfError $? "ERROR: $script failed."

# DON'T REMOVE THIS
# This script has to contain this log message.
# It is used to determine if the job is really completed.
echo "Successfully Completed"
