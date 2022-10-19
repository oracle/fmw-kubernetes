#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
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

adminServerPodName="${domainUID}-$(toDNS1123Legal ${adminServerName})"

grafanaEndpointIP=$(kubectl get endpoints ${monitoringNamespace}-grafana -n ${monitoringNamespace}  -o=jsonpath="{.subsets[].addresses[].ip}")
grafanaEndpointPort=$(kubectl get endpoints ${monitoringNamespace}-grafana -n ${monitoringNamespace}  -o=jsonpath="{.subsets[].ports[].port}")
grafanaEndpoint="${grafanaEndpointIP}:${grafanaEndpointPort}"
kubectl cp $scriptDir/../config/weblogic-server-dashboard.json ${domainNamespace}/${adminServerPodName}:/tmp/weblogic-server-dashboard.json
EXEC_DEPLOY="kubectl exec -it -n ${domainNamespace} ${adminServerPodName} -- curl --noproxy \"*\" -X POST -H \"Content-Type: application/json\" -d @/tmp/weblogic-server-dashboard.json http://admin:admin@${grafanaEndpoint}/api/dashboards/db"
echo "Deploying WebLogic Server Grafana Dashboard in progress...."
eval ${EXEC_DEPLOY}

