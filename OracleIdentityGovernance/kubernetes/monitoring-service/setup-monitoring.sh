#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# setup-monitoring.sh

# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
OLD_PWD=`pwd`



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


#
# Function to remove a file if it exists 
#
function removeFileIfExists {
  echo "input is $1"
  if [ -f $1 ]; then
    rm -f $1
  fi
}

function exitIfError {
  if [ "$1" != "0" ]; then
    echo "$2"
    exit $1
  fi
}

#
# Function to parse a yaml file and generate the bash exports
# $1 - Input filename
# $2 - Output filename
function parseYaml {
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\):|\1|" \
     -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
     -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
  awk -F$fs '{
    if (length($3) > 0) {
      # javaOptions may contain tokens that are not allowed in export command
      # we need to handle it differently. 
      if ($2=="javaOptions") {
        printf("%s=%s\n", $2, $3);
      } else {
        printf("export %s=\"%s\"\n", $2, $3);
      }
    }
  }' > $2
}

function usage {
  echo usage: ${script} -i file [-v] [-h]
  echo "  -i Parameter inputs file, must be specified."
  echo "  -h Help"
  exit $1
}

function installKubePrometheusStack {
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update
  echo "Setup prometheus-community/kube-prometheus-stack in progress"   
  if [ ${exposeMonitoringNodePort} == "true" ]; then
   
     helm install ${monitoringNamespace} prometheus-community/kube-prometheus-stack \
       --namespace ${monitoringNamespace} ${additionalParamForKubePrometheusStack} \
       --set prometheus.service.type=NodePort --set prometheus.service.nodePort=${prometheusNodePort} \
       --set alertmanager.service.type=NodePort --set alertmanager.service.nodePort=${alertmanagerNodePort} \
       --set grafana.adminPassword=admin --set grafana.service.type=NodePort  --set grafana.service.nodePort=${grafanaNodePort} \
       --version "16.5.0" --values ${scriptDir}/values.yaml \
       --atomic --wait
  else
     helm install ${monitoringNamespace}  prometheus-community/kube-prometheus-stack \
       --namespace ${monitoringNamespace} ${additionalParamForKubePrometheusStack} \
       --set grafana.adminPassword=admin \
       --version "16.5.0" --values ${scriptDir}/values.yaml \
       --atomic --wait
  fi
  exitIfError $? "ERROR: prometheus-community/kube-prometheus-stack install failed."
}

#Parse the inputs
while getopts "hi:" opt; do
  case $opt in
    i) valuesInputFile="${OPTARG}"
    ;;
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done

if [ -z ${valuesInputFile} ]; then
  echo "${script}: -i must be specified."
  missingRequiredOption="true"
fi

if [ "${missingRequiredOption}" == "true" ]; then
  usage 1
fi

if [ ! -f ${valuesInputFile} ]; then
  echo "Unable to locate the input parameters file ${valuesInputFile}"
  fail 'The error listed above must be resolved before the script can continue'
fi


exportValuesFile=$(mktemp /tmp/export-values-XXXXXXXXX.sh)  
parseYaml ${valuesInputFile} ${exportValuesFile}


source ${exportValuesFile}
rm ${exportValuesFile}


if [ "${setupKubePrometheusStack}" = "true" ]; then 
   if test "$(kubectl get namespace ${monitoringNamespace} --ignore-not-found | wc -l)" = 0; then
     echo "The namespace ${monitoringNamespace} for install prometheus-community/kube-prometheus-stack does not exist. Creating the namespace ${monitoringNamespace}"
     kubectl create namespace ${monitoringNamespace} 
   fi
   echo -e "Monitoring setup in  ${monitoringNamespace} in progress.......\n"

   # Create the namespace and CRDs, and then wait for them to be availble before creating the remaining resources
   kubectl label nodes --all kubernetes.io/os=linux --overwrite=true

   echo "Setup prometheus-community/kube-prometheus-stack started"
   installKubePrometheusStack
   cd $OLD_PWD

   echo "Setup prometheus-community/kube-prometheus-stack completed"
fi

export username=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNamespace} -o=jsonpath='{.data.username}'|base64 --decode`
export password=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNamespace} -o=jsonpath='{.data.password}'|base64 --decode`

# Setting up the WebLogic Monitoring Exporter
echo "Deploy WebLogic Monitoring Exporter started"
script=${scriptDir}/scripts/deploy-weblogic-monitoring-exporter.sh
sh ${script} 
exitIfError $? "ERROR: $script failed."
echo "Deploy WebLogic Monitoring Exporter completed"


# Deploy servicemonitors
serviceMonitor=${scriptDir}/manifests/wls-exporter-ServiceMonitor.yaml
cp "${serviceMonitor}.template" "${serviceMonitor}"
sed -i -e "s/release: monitoring/release: ${monitoringNamespace}/g" ${serviceMonitor}
sed -i -e "s/user: %USERNAME%/user: `echo -n $username|base64 -w0`/g" ${serviceMonitor}
sed -i -e "s/password: %PASSWORD%/password: `echo -n $password|base64 -w0`/g" ${serviceMonitor}
sed -i -e "s/namespace:.*/namespace: ${domainNamespace}/g" ${serviceMonitor}
sed -i -e "s/weblogic.domainName:.*/weblogic.domainName: ${domainUID}/g" ${serviceMonitor}
sed -i -e "$!N;s/matchNames:\n    -.*/matchNames:\n    - ${domainNamespace}/g;P;D" ${serviceMonitor}

kubectl apply -f ${serviceMonitor}


if [ "${setupKubePrometheusStack}" = "true" ]; then
   # Deploying  WebLogic Server Grafana Dashboard
   echo "Deploying WebLogic Server Grafana Dashboard...."
   sh ${scriptDir}/scripts/deploy-weblogic-server-grafana-dashboard.sh
   echo ""
   echo "Deployed WebLogic Server Grafana Dashboard successfully"
   echo ""
   if [ ${exposeMonitoringNodePort} == "true" ]; then
     echo "Grafana is available at NodePort: ${grafanaNodePort}"
     echo "Prometheus is available at NodePort: ${prometheusNodePort}"
     echo "Altermanager is available at NodePort: ${alertmanagerNodePort}"
     echo "=============================================================="
   fi
else 
   echo "Please import config/weblogic-server-dashboard.json manually into Grafana"
fi
   
echo ""

