# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

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

weblogicCredentialsSecretName=$(grep  'weblogicCredentialsSecretName:' create-domain-inputs.yaml);
weblogicCredentialsSecretName=${weblogicCredentialsSecretName//*weblogicCredentialsSecretName: /};

sslEnabled=$(grep  'sslEnabled:' create-domain-inputs.yaml);
sslEnabled=${sslEnabled//*sslEnabled: /};

echo "Checking if the $domainUID-wccadf-server pod's are running"
wait_wccadf_managed_pod

domainPort=$(kubectl describe pod $domainUID-wccadf-server1 -n $domainNS | grep LOCAL_ADMIN_PORT| awk '{ print $2 }')
domainProtocol=$(kubectl describe pod $domainUID-wccadf-server1 -n $domainNS | grep LOCAL_ADMIN_PROTOCOL| awk '{ print $2 }')

username=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNS} -o=jsonpath='{.data.username}'|base64 --decode`
password=`kubectl  get secrets ${weblogicCredentialsSecretName} -n ${domainNS} -o=jsonpath='{.data.password}'|base64 --decode`

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
# Copy the script inside the wccadf pod and execute it using wlst
kubectl cp -n $domainNS ${scriptDir}/common/configureWCCADFDomain.py $domainUID-wccadf-server1:/u01/oracle
kubectl exec -n $domainNS -it $domainUID-wccadf-server1 -- /bin/bash -c "wlst.sh configureWCCADFDomain.py -user $username -password $password -domainUID $domainUID -domainPort $domainPort -hostName $hostname -intradocPort $UCMIntradocPort -sslEnabled $sslEnabled -domainProtocol $domainProtocol"

