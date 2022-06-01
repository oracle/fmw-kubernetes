#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
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
      -DserverURL=http://${DOMAIN_UID}-cluster-${SOA_CLUSTER_NAME}:${SOA_MANAGED_SERVER_PORT}  \
      -DsarLocation=/u01/sarchives/$1 \
      -Doverwrite=true \
      -Duser=$(cat /weblogic-operator/secrets/username) -Dpassword=$(cat /weblogic-operator/secrets/password)
}

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
