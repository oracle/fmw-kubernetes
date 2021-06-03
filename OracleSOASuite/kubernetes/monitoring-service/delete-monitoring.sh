#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# delete-monitoring.sh

# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
OLD_PWD=`pwd`


function usage {
  echo "usage: ${script} -t <domainType> -n <namespace> -d <domainUID> -u <username> -p <password>  -k <Delete kubeprometheus, yes or no> [-h]"
  echo "  -t Domain Type. (required)"
  echo "  -n Domain namespace (optional)"
  echo "      (default: soans)"
  echo "  -d domainUID of Domain. (optional)"
  echo "      (default: soainfra)"
  echo "  -u username. (optional)"
  echo "      (default: weblogic)"
  echo "  -p password. {optional)"
  echo "      (default: Welcome1)"
  echo "  -k Delete kubeprometheus yes/no. (optional)"
  echo "      (default: no)"
  echo "  -h Help"
  exit $1
}


while getopts ":h:t:n:d:u:p:k:" opt; do
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
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done

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
  kubeprometheus="no"
fi


adminServerName="AdminServer"
adminServerPort="7001"

function deletePrometheusGrafana {

  cd ${scriptDir}/kube-prometheus-0.5.0
  kubectl delete --ignore-not-found=true  -f manifests/
  kubectl delete --ignore-not-found=true  -f manifests/setup/
}

# Setting up the WebLogic Monitoring Exporter

echo "Undeploy WebLogic Monitoring Exporter started"
kubectl delete --ignore-not-found=true -f ${scriptDir}/manifests/
script=${scriptDir}/scripts/undeploy-weblogic-monitoring-exporter.sh
sh ${script} ${domainType} ${namespace} ${domainUID} ${adminServerName} ${adminServerPort} ${username} ${password}

echo "Undeploy WebLogic Monitoring Exporter completed"

if [ "${kubeprometheus}" = "yes" ]; then
  echo "Deleting Prometheus and grafana started"
  deletePrometheusGrafana
  echo "Deleting Prometheus and grafana completed"
fi
cd $OLD_PWD

