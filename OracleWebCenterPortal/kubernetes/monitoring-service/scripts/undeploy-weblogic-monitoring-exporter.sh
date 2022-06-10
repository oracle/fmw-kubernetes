#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/utils.sh

# Function to lowercase a value and make it a legal DNS1123 name
# $1 - value to convert to lowercase
function toDNS1123Legal {
  local val=`echo $1 | tr "[:upper:]" "[:lower:]"`
  val=${val//"_"/"-"}
  echo "$val"
}

initialize

# username and password from Kubernetes secret
username=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNamespace} -o=jsonpath='{.data.username}'|base64 --decode`
password=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNamespace} -o=jsonpath='{.data.password}'|base64 --decode`

adminServerPodName="${domainUID}-$(toDNS1123Legal ${adminServerName})"

InputParameterList="-domainName ${domainUID} -adminServerName ${adminServerName} -adminURL ${adminServerPodName}:${adminServerPort} -username ${username} -password ${password}"
InputParameterList="${InputParameterList} -wcpClusterName ${wcpClusterName} -wlsMonitoringExporterTowcpCluster ${wlsMonitoringExporterTowcpCluster}"
InputParameterList="${InputParameterList} -wcpPortletClusterName ${wcpPortletClusterName} -wlsMonitoringExporterTowcpPortletCluster ${wlsMonitoringExporterTowcpPortletCluster}"

# Copy weblogic monitoring exporter jars for deployment
echo "Undeploying WebLogic Monitoring Exporter: domainNamespace[$domainNamespace], domainUID[$domainUID], adminServerPodName[$adminServerPodName]"

kubectl cp $scriptDir/undeploy-weblogic-monitoring-exporter.py ${domainNamespace}/${adminServerPodName}:/u01/oracle/undeploy-weblogic-monitoring-exporter.py
EXEC_UNDEPLOY="kubectl exec -it -n ${domainNamespace} ${adminServerPodName} -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/undeploy-weblogic-monitoring-exporter.py ${InputParameterList}"
eval ${EXEC_UNDEPLOY}

# Cleanup the local wars
rm -rf ${scriptDir}/wls-exporter-deploy

