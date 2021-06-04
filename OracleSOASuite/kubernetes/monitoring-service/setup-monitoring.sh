#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# setup-monitoring.sh

# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
OLD_PWD=`pwd`


function usage {
  echo "usage: ${script} -t <domainType> -n <namespace> -d <domainUID> -u <username> -p <password> -k <SetupMonitoring, yes or no> -l <Prometheus NodePort> -m <Grafana NodePort> -n <Altermanager NodePort> [-h]"
  echo "  -t Domain Type. (required)"
  echo "  -n Domain namespace (optional)"
  echo "      (default: soans)"
  echo "  -d domainUID of Domain. (optional)"
  echo "      (default: soainfra)"
  echo "  -u username. (optional)"
  echo "      (default: weblogic)"
  echo "  -p password. (optional)"
  echo "      (default: Welcome1)"
  echo "  -k Setup Prometheus and Grafana in monitoring namespace? If \"no\", script assumes setup is already available in monitoring namespace. (optional)"
  echo "      (default: yes)"
  echo "  -l Prometheus NodePort. (optional)"
  echo "      (default: 32101)"
  echo "  -m Grafana NodePort. (optional)"
  echo "      (default: 32100)"
  echo "  -n Altermanager NodePort. (optional)"
  echo "      (default: 32102)"
  echo "  -h Help"
  exit $1
}


while getopts ":h:t:n:d:u:p:k:l:m:n:" opt; do
  case $opt in
    t) domainType="${OPTARG}"
    ;;
    n) namespace="${OPTARG}"
    ;;
    d) domainUID="${OPTARG}"
    ;;
    u) username="${OPTARG}"
    ;;
    p) password="${OPTARG}"
    ;;
    k) kubeprometheus=`echo "${OPTARG}" | tr "[:upper:]" "[:lower:]"`
    ;;
    l) prometheusNodePort="${OPTARG}"
    ;;
    m) grafanaNodePort="${OPTARG}"
    ;;
    n) alertmanagerNodePort="${OPTARG}"
    ;;
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done

# Setting default values
if [ -z ${domainType} ]; then
  echo "${script}: -t <domainType> must be specified."
  usage 1
fi

if [ -z ${namespace} ]; then
  namespace="soans"
fi


if [ -z ${domainUID} ]; then
  domainUID="soainfra"
fi

if [ -z ${username} ]; then
  username="weblogic"
fi

if [ -z ${password} ]; then
  password="Welcome1"
fi

if [ -z ${kubeprometheus} ]; then
  kubeprometheus="yes"
fi

if [ -z ${prometheusNodePort} ]; then
  prometheusNodePort="32101"
fi

if [ -z ${grafanaNodePort} ]; then
  grafanaNodePort="32100"
fi

if [ -z ${alertmanagerNodePort} ]; then
  alertmanagerNodePort="32102"
fi
 
adminServerName="AdminServer"
adminServerPort="7001"

#
# Function to exit and print an error message
# $1 - text of message
function fail {
  printError $*
  exit 1
}

# Function to print an error message
function printError {
  echo [ERROR] $*
}

function exitIfError {
  if [ "$1" != "0" ]; then
    echo "$2"
    exit $1
  fi
}

function getKubernetesClusterIP {

  # Get name of the current context
  local CUR_CTX=`kubectl config current-context | awk ' { print $1; } '`

  # Get the name of the current cluster
  local CUR_CLUSTER_CMD="kubectl config view -o jsonpath='{.contexts[?(@.name == \"${CUR_CTX}\")].context.cluster}' | awk ' { print $1; } '"
  local CUR_CLUSTER=`eval ${CUR_CLUSTER_CMD}`

  # Get the server address for the current cluster
  local SVR_ADDR_CMD="kubectl config view -o jsonpath='{.clusters[?(@.name == \"${CUR_CLUSTER}\")].cluster.server}' | awk ' { print $1; } '"
  local SVR_ADDR=`eval ${SVR_ADDR_CMD}`

  # Server address is expected to be of the form http://address:port.  Delimit
  # string on the colon to obtain the address. 
  local array=(${SVR_ADDR//:/ })
  K8S_IP="${array[1]/\/\//}"

}


function setupPrometheusGrafana {

  cd ${scriptDir}
  rm -rf kube-prometheus-0.5.0
  wget -q -c https://github.com/prometheus-operator/kube-prometheus/archive/refs/tags/v0.5.0.tar.gz -O -| tar -zx
  cd kube-prometheus-0.5.0
  sh scripts/monitoring-deploy.sh
}


if [ "${kubeprometheus}" = "yes" ]; then 
   echo -e "Prometheus and Grafana setup in monitoring namespace in progress.......\n"

   # Create the namespace and CRDs, and then wait for them to be availble before creating the remaining resources
   kubectl label nodes --all kubernetes.io/os=linux --overwrite=true

   echo "Seting up Prometheus and grafana started"
   setupPrometheusGrafana
   cd $OLD_PWD

   # Wait for resources to be available
   kubectl -n monitoring rollout status --watch --timeout=600s daemonset.apps/node-exporter  
   kubectl -n monitoring rollout status --watch --timeout=600s deployment.apps/grafana    
   kubectl -n monitoring rollout status --watch --timeout=600s deployment.apps/kube-state-metrics
   kubectl -n monitoring rollout status --watch --timeout=600s deployment.apps/prometheus-adapter
   kubectl -n monitoring rollout status --watch --timeout=600s deployment.apps/prometheus-operator
   kubectl -n monitoring rollout status --watch --timeout=600s statefulset.apps/alertmanager-main
   kubectl -n monitoring rollout status --watch --timeout=600s statefulset.apps/prometheus-k8s

   echo "Seting up Prometheus and grafana completed"

   # Expose the monitoring service using NodePort

   SET_NODEPORT_GRAFANA="kubectl patch svc grafana -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": ${grafanaNodePort} }]'"
   SET_NODEPORT_PROMETHEUS="kubectl patch svc prometheus-k8s -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": ${prometheusNodePort} }]'"
   SET_NODEPORT_ALERTMANAGER="kubectl patch svc alertmanager-main -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": ${alertmanagerNodePort} }]'"
   eval ${SET_NODEPORT_GRAFANA}
   eval ${SET_NODEPORT_PROMETHEUS}
   eval ${SET_NODEPORT_ALERTMANAGER}
else
  if test "$(kubectl get namespace monitoring --ignore-not-found | wc -l)" = 0; then
     fail "The monitoring namespace does not exist. Run ${script} with \"-k yes\" to setup monitoring"
  fi
fi

# Setting up the WebLogic Monitoring Exporter
echo "Deploy WebLogic Monitoring Exporter started"
script=${scriptDir}/scripts/deploy-weblogic-monitoring-exporter.sh
sh ${script} ${domainType} ${namespace} ${domainUID} ${adminServerName} ${adminServerPort} ${username} ${password}
exitIfError $? "ERROR: $script failed."
echo "Deploy WebLogic Monitoring Exporter completed"


# Deploy servicemonitors
serviceMonitor=${scriptDir}/manifests/wls-exporter-ServiceMonitor.yaml
cp ${serviceMonitor}.template ${serviceMonitor}
sed -i -e "s/user:.*/user: `echo -n $username|base64 -w0`/g" ${serviceMonitor}
sed -i -e "s/password: V2VsY29tZTE=/password: `echo -n $password|base64 -w0`/g" ${serviceMonitor}
sed -i -e "s/weblogic.domainName:.*/weblogic.domainName: ${domainUID}/g" ${serviceMonitor}
sed -i -e "$!N;s/matchNames:\n    -.*/matchNames:\n    - ${namespace}/g;P;D" ${serviceMonitor}
kubectl apply -f ${serviceMonitor}

roleBinding=${scriptDir}/manifests/prometheus-roleBinding-domain-namespace.yaml
sed -i -e "s/namespace: soans/namespace: ${namespace}/g" ${roleBinding}
kubectl apply -f ${roleBinding}

roleSpecific=${scriptDir}/manifests/prometheus-roleSpecific-domain-namespace.yaml
sed -i -e "s/namespace: soans/namespace: ${namespace}/g" ${roleSpecific}
kubectl apply -f ${roleSpecific}

# get the Master IP to access Grafana
getKubernetesClusterIP

if [[ ($K8S_IP != "") && ("${kubeprometheus}" = "yes") ]]; then
   # Deploying  WebLogic Server Grafana Dashboard
   echo "Deploying WebLogic Server Grafana Dashboard...."
   curl --noproxy "*" -X POST -H "Content-Type: application/json" -d @config/weblogic-server-dashboard.json http://admin:admin@$K8S_IP:${grafanaNodePort}/api/dashboards/db
   echo "Deployed WebLogic Server Grafana Dashboard successfully"
   echo ""
   echo "Grafana is available at NodePort: ${grafanaNodePort}"
   echo "Prometheus is available at NodePort: ${prometheusNodePort}"
   echo "Altermanager is available at NodePort: ${alertmanagerNodePort}"
   echo ""
   echo "======================================================="
else 
   echo "WARNING !!!! - Could not import WebLogic Server Grafana Dashboard as Grafana details not available"
   echo "WARNING !!!! - Please import config/weblogic-server-dashboard.json manually into Grafana"
fi
