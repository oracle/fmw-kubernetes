#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# delete-monitoring.sh

# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
OLD_PWD=`pwd`


#
## Function to exit and print an error message
## $1 - text of message
function fail {
  printError $*
  exit 1
}

# Function to print an error message
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


function deletePrometheusGrafana {
   helm delete ${monitoringNamespace}  --namespace ${monitoringNamespace}
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

# Setting up the WebLogic Monitoring Exporter

echo "Undeploy WebLogic Monitoring Exporter started"
serviceMonitor=${scriptDir}/manifests/wls-exporter-ServiceMonitor.yaml
kubectl delete --ignore-not-found=true -f ${serviceMonitor}
script=${scriptDir}/scripts/undeploy-weblogic-monitoring-exporter.sh
sh ${script}
if [ "$?" != "0" ]; then
  echo "ERROR: $script failed."
  echo "Undeploy WebLogic Monitoring Exporter completed with errors. Review the logs and rerun"
else
  echo "Undeploy WebLogic Monitoring Exporter completed."
fi

if [ "${setupKubePrometheusStack}" = "true" ]; then
  echo "Deleting Prometheus and grafana started"
  deletePrometheusGrafana
  echo "Deleting Prometheus and grafana completed"
fi
cd $OLD_PWD

