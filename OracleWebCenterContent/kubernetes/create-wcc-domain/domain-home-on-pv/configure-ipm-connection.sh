#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

function  usage {
  echo usage: ${script} -l load_balancer_external_ip -p load_balancer_port [-h]
  echo "  -l load balancer external ip, must be specified."
  echo "  -p load balancer port, must be specified."
  echo "  -h Help"
  exit $1
}

while getopts "h:l:p:" opt; do
  case $opt in
        l) LoadBalancerExternalIP="${OPTARG}"
        ;;
        p) LoadBalancerPort="${OPTARG}"
        ;;
        h) usage 0
        ;;
        *) usage 1
        ;;
  esac
done

if [ -z ${LoadBalancerExternalIP} ]; then
  echo "${script}: -l(LoadBalancerExternalIP) must be specified."
  usage 1
fi

if [ -z ${LoadBalancerPort} ]; then
  echo "${script}: -p(LoadBalancerPort) must be specified."
  usage 1
fi

function wait_admin_pod {
echo "Waiting for $adminPod Pod startup to kick in."
sleep 50s
counter=0
while true; do
    ready_status=$(kubectl -n $domainNS get pods $adminPod -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')
    if [ "True"  == "$ready_status" ]; then
        echo "$adminPod Pod started [OK]"
        break;
    elif [[ "$counter" -gt 8 ]]; then
        echo "Pods timed out, exiting"
        exit 1
    else
        counter=$((counter+1))
        echo "Waiting for $adminPod Pod to start."
        sleep 40s
    fi
done
}

echo "Configuring IPM Frontend Details using WLST..."

domainUID=$(grep  'domainUID:' create-domain-inputs.yaml);
domainUID=${domainUID//*domainUID: /};

domainNS=$(grep  'namespace:' create-domain-inputs.yaml);
domainNS=${domainNS//*namespace: /};

adminServerName=$(grep  'adminServerName:' create-domain-inputs.yaml);
adminServerName=${adminServerName//*adminServerName: /};

adminPort=$(grep  'adminPort:' create-domain-inputs.yaml);
adminPort=${adminPort//*adminPort: /};

adminPod=$domainUID-$adminServerName
adminUrl=$adminPod:$adminPort

weblogicCredentialsSecretName=$(grep  'weblogicCredentialsSecretName:' create-domain-inputs.yaml);
weblogicCredentialsSecretName=${weblogicCredentialsSecretName//*weblogicCredentialsSecretName: /};

sslEnabled=$(grep  'sslEnabled:' create-domain-inputs.yaml);
sslEnabled=${sslEnabled//*sslEnabled: /};

username=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNS} -o=jsonpath='{.data.username}'|base64 --decode`
password=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNS} -o=jsonpath='{.data.password}'|base64 --decode`

echo "Checking if the $adminPod pod is running"
wait_admin_pod

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"

# Copy the script inside the admin server pod and execute it using wlst
kubectl cp -n $domainNS ${scriptDir}/common/configureIPMConnection.py $adminPod:/u01/oracle

kubectl exec -n $domainNS -it $adminPod -- /bin/bash -c "wlst.sh configureIPMConnection.py -user $username -password $password -adminUrl $adminUrl -loadbalancerHost $LoadBalancerExternalIP -loadbalancerPort $LoadBalancerPort -sslEnabled $sslEnabled"


