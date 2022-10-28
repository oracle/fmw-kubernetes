# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

function  usage {
  echo usage: ${script} -n node_ip -m ucm node port [-h]
  echo "  -n node ip, must be specified."
  echo "  -m ucm node port, which is exposed in the start server script."
  echo "  -h Help"
  exit $1
}

while getopts "h:n:m:" opt; do
  case $opt in
        n) NodeIP="${OPTARG}"
        ;;
        m) UcmNodePort="${OPTARG}"
        ;;
        h) usage 0
        ;;
        *) usage 1
        ;;
  esac
done

if [ -z ${NodeIP} ]; then
  echo "${script}: -n(NodeIP) must be specified."
  usage 1
fi

if [ -z ${UcmNodePort} ]; then
  echo "${script}: -m(UcmNodePort) which is exposed in the start server script must be specified."
  usage 1
fi

# Determine the state of wccadf pod
function wait_wccadf_managed_pod {
counter=0
while true; do
    ready_status=$(kubectl -n $domainNS get pods $domainUID-wccadf-server1 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')
        if [ "True"  == "$ready_status" ]; then
           echo "$domainUID-wccadf-server1 Pod started [OK]"
           break;
        elif [[ "$counter" -gt 15 ]]; then
             echo "Pods timed out, exiting"
             exit 1
        else
           counter=$((counter+1))
           echo "Waiting for $domainUID-wccadf-server1 pod to start."
           sleep 40s
       fi
done
}

echo "Configuring WCCADF servers using WLST..."
domainPort=16225;

domainUID=$(grep  'domainUID:' create-domain-inputs.yaml);
domainUID=${domainUID//*domainUID: /};

domainNS=$(grep  'namespace:' create-domain-inputs.yaml);
domainNS=${domainNS//*namespace: /};

weblogicCredentialsSecretName=$(grep  'weblogicCredentialsSecretName:' create-domain-inputs.yaml);
weblogicCredentialsSecretName=${weblogicCredentialsSecretName//*weblogicCredentialsSecretName: /};

echo "Checking if the $domainUID-wccadf-server pod's are running"
wait_wccadf_managed_pod

username=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNS} -o=jsonpath='{.data.username}'|base64 --decode`
password=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNS} -o=jsonpath='{.data.password}'|base64 --decode`

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"

# Copy the script inside the wccadf pod and execute it using wlst
kubectl cp -n $domainNS ${scriptDir}/common/configureWCCADFDomain.py $domainUID-wccadf-server1:/u01/oracle
kubectl exec -n $domainNS -it $domainUID-wccadf-server1 -- /bin/bash -c "wlst.sh configureWCCADFDomain.py -user $username -password $password -domainUID $domainUID -domainPort $domainPort -hostName $NodeIP -intradocPort $UcmNodePort"

