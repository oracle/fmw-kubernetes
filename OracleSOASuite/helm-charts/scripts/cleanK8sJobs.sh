#!/bin/sh
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/helper.sh

usage() {

  cat << EOF

  This script deletes the Domain creation Jobs from domain namespace.
 
  Usage:
 
    $(basename $0) [-n mynamespace] [-d mydomainuid] [-m kubecli]
    
    -d <domain_uid>     : Domain unique-id. Default is 'sample-domain1'.
  
    -n <namespace>      : Domain namespace. Default is 'sample-domain1-ns'.

    -m <kubernetes_cli> : Kubernetes command line interface. Default is 'kubectl' if KUBERNETES_CLI env
                          variable is not set. Otherwise default is the value of KUBERNETES_CLI env variable.

    -v <verbose_mode>   : Enables verbose mode. Default is 'false'.

    -h                  : This help.
   
EOF
exit $1
}

kubernetesCli=${KUBERNETES_CLI:-kubectl}
domainUid="sample-domain1"
domainNamespace="sample-domain1-ns"
verboseMode=false

while getopts "vn:d:m:h" opt; do
  case $opt in
    n) domainNamespace="${OPTARG}"
    ;;
    d) domainUid="${OPTARG}"
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

deleteJobs() {
      if [ "${verboseMode}" == "true" ]; then
          printInfo "Executing commands --> ${kubernetesCli} delete jobs ${domainUid}-create-soa-infra-domain-job -n ${domainNamespace};"
          printInfo "                   --> ${kubernetesCli} delete jobs ${domainUid}-rcu-create -n ${domainNamespace};"
          printInfo "                   --> ${kubernetesCli} delete jobs ${domainUid}-delete-soa-infra-domain-job -n ${domainNamespace};"
      fi
      ${kubernetesCli} delete jobs ${domainUid}-create-soa-infra-domain-job -n ${domainNamespace} --ignore-not-found=true; 
      ${kubernetesCli} delete jobs ${domainUid}-rcu-create -n ${domainNamespace} --ignore-not-found=true; 
      ${kubernetesCli} delete jobs ${domainUid}-delete-soa-infra-domain-job -n ${domainNamespace} --ignore-not-found=true; 
}

deleteConfigMaps() {
      if [ "${verboseMode}" == "true" ]; then
          printInfo "Executing commands --> ${kubernetesCli} delete configmap ${domainUid}-create-soa-infra-domain-job-cm -n ${domainNamespace};"
          printInfo "                   --> ${kubernetesCli} delete configmap ${domainUid}-create-rcu-job-cm -n ${domainNamespace};"
          printInfo "                   --> ${kubernetesCli} delete configmap ${domainUid}-delete-rcu-job-cm -n ${domainNamespace};"
      fi
      ${kubernetesCli} delete configmap ${domainUid}-create-soa-infra-domain-job-cm -n ${domainNamespace} --ignore-not-found=true;
      ${kubernetesCli} delete configmap ${domainUid}-create-rcu-job-cm -n ${domainNamespace} --ignore-not-found=true;
      ${kubernetesCli} delete configmap ${domainUid}-delete-rcu-job-cm -n ${domainNamespace} --ignore-not-found=true;
      ${kubernetesCli} delete configmap weblogic-scripts-cm -n ${domainNamespace} --ignore-not-found=true;
}

removeOperatorManageLabel(){
      if [ "${verboseMode}" == "true" ]; then
         printInfo "Executing commands --> ${kubernetesCli} label namespace ${domainNamespace} weblogic-operator- 2> /dev/null"
      fi
      ${kubernetesCli} label namespace ${domainNamespace} "weblogic-operator-"  2> /dev/null
}
initialize
removeOperatorManageLabel
sleep 10
deleteJobs  
deleteConfigMaps
