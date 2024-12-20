#!/bin/sh
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/helper.sh

usage() {

  cat << EOF

  This script applies 'spec.serverStartPolicy' to the domain resource.
  This change may cause the operator to initiate startup of domain's 
  WebLogic server instance pods based on serverStartPolicy value.
 
  Usage:
 
    $(basename $0) [-n mynamespace] [-d mydomainuid] [-s serverStartPolicy] [-m kubecli]
  
    -d <domain_uid>        : Domain unique-id. Default is 'sample-domain1'.

    -n <namespace>         : Domain namespace. Default is 'sample-domain1-ns'.
  
    -s <serverStartPolicy> : Determines which WebLogic Servers the operator will start up. 
                             Legal values are "Never", "IfNeeded", or "AdminOnly"

    -m <kubernetes_cli>    : Kubernetes command line interface. Default is 'kubectl' if KUBERNETES_CLI env
                             variable is not set. Otherwise default is the value of KUBERNETES_CLI env variable.

    -v <verbose_mode>      : Enables verbose mode. Default is 'false'.

    -h                     : This help.
   
EOF
exit $1
}

kubernetesCli=${KUBERNETES_CLI:-kubectl}
domainUid="sample-domain1"
domainNamespace="sample-domain1-ns"
serverStartPolicy="Never"
verboseMode=false

while getopts "vn:d:s:m:h" opt; do
  case $opt in
    n) domainNamespace="${OPTARG}"
    ;;
    d) domainUid="${OPTARG}"
    ;;
    s) serverStartPolicy="${OPTARG}"
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

initialize

# Check if the Domain creation was success
${kubernetesCli} wait --for=condition=complete  job/${domainUid}-create-soa-infra-domain-job -n ${domainNamespace}

# Get the domain in json format
domainJson=$(${kubernetesCli} get domain ${domainUid} -n ${domainNamespace} -o json --ignore-not-found)

if [ -z "${domainJson}" ]; then
  printError "Domain resource for domain '${domainUid}' not found in namespace '${domainNamespace}'. Exiting."
  exit 1
fi

getDomainPolicy "${domainJson}" currentServerStartPolicy

if [ "${currentServerStartPolicy}" == "${serverStartPolicy}" ]; then
  printInfo "No changes needed, exiting. The domain '${domainUid}' is already having the specified 'spec.serverStartPolicy' of ${serverStartPolicy}."
  exit 0
fi

printInfo "Patching domain '${domainUid}' from serverStartPolicy='${currentServerStartPolicy}' to '${serverStartPolicy}'."

createPatchJsonToUpdateDomainPolicy "${serverStartPolicy}" patchJson

executePatchCommand "${kubernetesCli}" "${domainUid}" "${domainNamespace}" "${patchJson}" "${verboseMode}"

printInfo "Successfully patched domain '${domainUid}' in namespace '${domainNamespace}' with '${serverStartPolicy}' start policy!"
