#!/bin/sh
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/helper.sh

usage() {

  cat << EOF

  This script collects pod logs from a namespace.
 
  Usage:
 
    $(basename $0) [-n mynamespace] [-m kubecli]
  
    -n <namespace>      : Domain namespace. Default is 'sample-domain1-ns'.

    -m <kubernetes_cli> : Kubernetes command line interface. Default is 'kubectl' if KUBERNETES_CLI env
                          variable is not set. Otherwise default is the value of KUBERNETES_CLI env variable.

    -v <verbose_mode>   : Enables verbose mode. Default is 'false'.

    -h                  : This help.
   
EOF
exit $1
}

kubernetesCli=${KUBERNETES_CLI:-kubectl}
domainNamespace="sample-domain1-ns"
verboseMode=false

while getopts "vn:m:h" opt; do
  case $opt in
    n) domainNamespace="${OPTARG}"
    ;;
    m) kubernetesCli="${OPTARG}"
    ;;
    v) verboseMode=true;
    ;;
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done

set -eu
set -o pipefail

initialize() {

  validateErrors=false

  validateKubernetesCliAvailable
  validateJqAvailable
  failIfValidationErrors
}

getPodLogs() {
  logDir=$1

  for pod in $(${kubernetesCli} get pods --output=jsonpath={.items..metadata.name} -n ${domainNamespace}); 
   do 
      if [ "${verboseMode}" == "true" ]; then
          printInfo "Executing command --> ${kubernetesCli} logs $pod -n ${domainNamespace} >> $logDir/$pod.log"
      fi
      ${kubernetesCli} logs $pod -n ${domainNamespace} >> $logDir/$pod.log ; 
   done
}
initialize

printInfo "Collecting pod logs for namespace ${domainNamespace}...."
tmp_dir="/tmp/$(date +%Y%m%d_%H%M%S)/${domainNamespace}"
mkdir -p ${tmp_dir}
getPodLogs  ${tmp_dir}
printInfo "Successfully collected pod logs for namespace ${domainNamespace} and available at ${tmp_dir}"
