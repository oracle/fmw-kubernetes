#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
warDir=$PWD

domainType=${1:-soa}
namespace=${2:-soans}
domainUID=${3:-soainfra}
adminServerName=${4:-AdminServer}
adminServerPort=${5:-7001}
username=${6:-weblogic}
password=${7:Welcome1}

# Function to lowercase a value and make it a legal DNS1123 name
# $1 - value to convert to lowercase
function toDNS1123Legal {
  local val=`echo $1 | tr "[:upper:]" "[:lower:]"`
  val=${val//"_"/"-"}
  echo "$val"
}

adminServerPodName="${domainUID}-$(toDNS1123Legal ${adminServerName})"

echo "Deploying WebLogic Monitoring Exporter with namespace[$namespace], domainUID[$domainUID], domainType[$domainType]"
. $scriptDir/get-wls-exporter.sh $domainType
kubectl cp $scriptDir/wls-exporter-deploy ${namespace}/${adminServerPodName}:/u01/oracle
kubectl cp $scriptDir/deploy-weblogic-monitoring-exporter.py ${namespace}/${adminServerPodName}:/u01/oracle/wls-exporter-deploy
EXEC_DEPLOY="kubectl exec -it -n ${namespace} ${adminServerPodName} -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py -domainType ${domainType} -domainName ${domainUID} -adminServerName ${adminServerName} -adminURL ${adminServerPodName}:${adminServerPort} -username ${username} -password ${password}"
eval ${EXEC_DEPLOY}


