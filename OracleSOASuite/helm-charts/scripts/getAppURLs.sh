#!/bin/sh
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/helper.sh

usage() {

  cat << EOF

  This script gets the application URL details for the Domain.
 
  Usage:
 
    $(basename $0) [-d domainType] [-n lbNamespace] [-t lbType] [-r lbReleasename] [-i lbHostname] [-s sslType] [-m kubecli]
  
    -d <domain_type>     : Type of domain, values are soa, osb, soaosb. Default is 'soaosb'.

    -n <loadbalancer_namespace>     : LoadBalancer (Ingress Controller) namespace. Default is 'soalbns'.

    -t <loadbalancer_type>      : Loadbalancer type, TRAEFIK or NGINX. Default is 'TRAEFIK'.

    -r <loadbalancer_releasename>      : Loadbalancer helm install releasename. Default is 'soalb'.

    -l <loadbalancer_hostname>      : Loadbalancer hostname, Default is www.example.org.

    -y <ssl_type>      : Type of Configuration. values are NONSSL , SSL and E2ESSL. Default is NONSSL.

    -a <admin_hostname>      : Administration server hostname for E2E URL access.  Default is admin.org.

    -s <soa_hostname>      : SOA Cluster hostname for E2E URL access.  Default is soa.org.

    -o <osb_hostname>      : OSB Cluster hostname for E2E URL access.  Default is osb.org.

    -m <kubernetes_cli> : Kubernetes command line interface. Default is 'kubectl' if KUBERNETES_CLI env
                          variable is not set. Otherwise default is the value of KUBERNETES_CLI env variable.

    -v <verbose_mode>   : Enables verbose mode. Default is 'false'.

    -h                  : This help.
   
EOF
exit $1
}

kubernetesCli=${KUBERNETES_CLI:-kubectl}
domainType="soaosb"
lbNamespace="soalbns"
lbReleasename="soalb"
lbType="TRAEFIK"
lbHostname="www.example.org"
sslType="NONSSL"
adminhostName="admin.org"
soahostName="soa.org"
osbhostName="osb.org"
verboseMode=false

while getopts "vd:n:t:r:l:y:a:s:o:m:h" opt; do
  case $opt in
    d) domainType="${OPTARG}"
    ;;
    n) lbNamespace="${OPTARG}"
    ;;
    t) lbType="${OPTARG}"
    ;;
    r) lbReleasename="${OPTARG}"
    ;;
    l) lbHostname="${OPTARG}"
    ;;
    y) sslType="${OPTARG}"
    ;;
    a) adminhostName="${OPTARG}"
    ;;
    s) soahostName="${OPTARG}"
    ;;
    o) osbhostName="${OPTARG}"
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

# Get the domain in json format

if [ ${lbType} == "NGINX" ]; then
  lbsvcName="ingress-nginx-controller"
elif [ ${lbType} == "TRAEFIK" ]; then
  lbsvcName="traefik"
else
  echo "Not supported load balancer type ${lbType}"
  exit
fi

if [ ${sslType} == "NONSSL" ]; then
   port=$(kubectl --namespace ${lbNamespace} get services -o jsonpath="{.spec.ports[0].nodePort}" "${lbReleasename}-${lbsvcName}")
   protocol="http"
   adminurl="${protocol}://${lbHostname}:${port}"
   soaurl="${protocol}://${lbHostname}:${port}"
   osburl="${protocol}://${lbHostname}:${port}"
elif [ ${sslType} == "SSL" ]; then
   port=$(kubectl --namespace ${lbNamespace} get services -o jsonpath="{.spec.ports[1].nodePort}" "${lbReleasename}-${lbsvcName}")
   protocol="https"
   adminurl="${protocol}://${lbHostname}:${port}"
   soaurl="${protocol}://${lbHostname}:${port}"
   osburl="${protocol}://${lbHostname}:${port}"
else
   port=$(kubectl --namespace ${lbNamespace} get services -o jsonpath="{.spec.ports[1].nodePort}" "${lbReleasename}-${lbsvcName}")
   protocol="https"
   adminurl="${protocol}://${adminhostName}:${port}"
   soaurl="${protocol}://${soahostName}:${port}"
   osburl="${protocol}://${osbhostName}:${port}"
  
fi

url="${protocol}://${lbHostname}:${port}"

echo "========================================================================================="
echo "       Visit the following URLs for Oracle SOA Suite domain of type ${domainType}"
echo "========================================================================================="

echo "${adminurl}/em"
if [[ ${domainType} == *"osb"* ]]; then
  echo "${adminurl}/servicebus"
fi
if [[ ${domainType} == *"soa"* ]]; then
  echo "${soaurl}/soa-infra"
  echo "${soaurl}/soa/composer"
  echo "${soaurl}/integration/worklistapp"
  echo "${soaurl}/ess"
  echo "${soaurl}/EssHealthCheck"
fi
echo "========================================================================================="
