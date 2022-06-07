#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
warDir=$PWD
source ${scriptDir}/utils.sh

# Setting default values
initialize
# Function to lowercase a value and make it a legal DNS1123 name
# $1 - value to convert to lowercase
function toDNS1123Legal {
  local val=`echo $1 | tr "[:upper:]" "[:lower:]"`
  val=${val//"_"/"-"}
  echo "$val"
}

# username and password from Kubernetes secret
username=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNamespace} -o=jsonpath='{.data.username}'|base64 --decode`
password=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNamespace} -o=jsonpath='{.data.password}'|base64 --decode`

adminServerPodName="${domainUID}-$(toDNS1123Legal ${adminServerName})"

InputParameterList=" -domainName ${domainUID} -adminServerName ${adminServerName} -adminURL ${adminServerPodName}:${adminServerPort} -username ${username} -password ${password}"
InputParameterList="${InputParameterList} -soaClusterName ${soaClusterName} -wlsMonitoringExporterTosoaCluster ${wlsMonitoringExporterTosoaCluster}"
InputParameterList="${InputParameterList} -osbClusterName ${osbClusterName} -wlsMonitoringExporterToosbCluster ${wlsMonitoringExporterToosbCluster}"

echo "Deploying WebLogic Monitoring Exporter with domainNamespace[$domainNamespace], domainUID[$domainUID], adminServerPodName[$adminServerPodName]"
. $scriptDir/get-wls-exporter.sh 
kubectl cp $scriptDir/wls-exporter-deploy ${domainNamespace}/${adminServerPodName}:/u01/oracle
kubectl cp $scriptDir/deploy-weblogic-monitoring-exporter.py ${domainNamespace}/${adminServerPodName}:/u01/oracle/wls-exporter-deploy
EXEC_DEPLOY="kubectl exec -it -n ${domainNamespace} ${adminServerPodName} -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py ${InputParameterList}"
eval ${EXEC_DEPLOY}

