#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"

# Set the required environment values
. $ORACLE_HOME/wlserver/server/bin/setWLSEnv.sh

function exitIfError {
  if [ "$1" != "0" ]; then
    echo "$2"
    exit $1
  fi
}
# Deploys Oracle Service Bus archive
function deploy {
    osb_archive=$1
    tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
    cp $scriptDir/import.properties.template $tmp_dir/import.properties
    sed -i -e "s:%DOMAIN_UID%:${DOMAIN_UID}:g" $tmp_dir/import.properties
    sed -i -e "s:%ADMIN_SERVER_NAME_SVC%:${ADMIN_SERVER_NAME_SVC}:g" $tmp_dir/import.properties
    sed -i -e "s:%ADMIN_LISTEN_PORT%:${ADMIN_LISTEN_PORT}:g" $tmp_dir/import.properties
    sed -i -e "s:%USERNAME%:$(cat /weblogic-operator/secrets/username):g" $tmp_dir/import.properties
    sed -i -e "s:%PASSWORD%:$(cat /weblogic-operator/secrets/password):g" $tmp_dir/import.properties
    sed -i -e "s:%OSB_JAR%:$1:g" $tmp_dir/import.properties
    cp /u01/sbarchives/${osb_archive} $tmp_dir
    cd $tmp_dir
    java weblogic.WLST $scriptDir/import.py -p import.properties
}

# Reads the available Oracle Service Bus archives and deploys
cd /u01/sbarchives/
sbars=$(ls *)
for sbar in $sbars
do
   deploy $sbar
done

exitIfError $? "ERROR: $script failed."

# DON'T REMOVE THIS
# This script has to contain this log message.
# It is used to determine if the job is really completed.
echo "Successfully Completed"

