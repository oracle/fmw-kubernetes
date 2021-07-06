#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

function  usage {
  echo usage: ${script} -p [-u] [-i] [-h]
  echo "  -p load balancer port, must be specified."
  echo "  -u ucm intradocport, optional"
  echo "  -i ibr intradocport, optional"
  echo "  -h Help"
  exit $1
}

while getopts "hp:u:i:" opt; do
  #echo "-----opt=$opt"
  case $opt in
    p) LoadBalancerPort="${OPTARG}"
    ;;
    u) UCMIntradocPort="${OPTARG}"
    ;;
    i) IBRIntradocPort="${OPTARG}"
    ;;
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done


if [ -z ${LoadBalancerPort} ]; then
  echo "${script}: -p(LoadBalancerPort) must be specified."
  usage 1
fi

if [ -z ${UCMIntradocPort} ]; then
    #echo "inside the if ucm intradoc port is EMPTY"
    UCMIntradocPort=4444
fi

if [ -z ${IBRIntradocPort} ]; then
     #echo "inside the if ibr intradoc port is EMPTY"
     IBRIntradocPort=5555
fi

#Loop determining state of Admin POD
function wait_admin_pod {
# wait untill pods are ready
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

#Loop determining state of MS PODS
function wait_managed_pods {
   #get replicas number
   rep=$(grep  'initialManagedServerReplicas:' create-domain-inputs.yaml);
   rep=${rep//*initialManagedServerReplicas: /};
   echo "replicas=$rep"

for ((i = 1 ; i <= $rep ; i++)); do

  counter=0
while true; do
    ready_status=$(kubectl -n $domainNS get pods $ucmPod$i -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')
    #echo "ready_status=$ready_status"
        if [ "True"  == "$ready_status" ]; then
           echo "$ucmPod$i Pod started [OK]"
           break;
        elif [[ "$counter" -gt 15 ]]; then
             echo "Pods timed out, exiting"
             exit 1
        else
           counter=$((counter+1))
           echo "Waiting for $ucmPod$i Pod to start."
           sleep 40s
       fi
done
done

}

# Get the values from domain-inputs.yaml 

domainUID=$(grep  'domainUID:' create-domain-inputs.yaml);
domainUID=${domainUID//*domainUID: /};

domainNS=$(grep  'namespace:' create-domain-inputs.yaml);
domainNS=${domainNS//*namespace: /};

adminServerName=$(grep  'adminServerName:' create-domain-inputs.yaml);
adminServerName=${adminServerName//*adminServerName: /};

managedServerNameBase=$(grep  'managedServerNameBase:' create-domain-inputs.yaml);
managedServerNameBase=${managedServerNameBase//*managedServerNameBase: /};

adminPod=$domainUID-$adminServerName
ucmPod=$domainUID-$managedServerNameBase

# Enabling Sequential Startup
sed -i '/domainHome:/a \ \ maxClusterConcurrentStartup: 1' output/weblogic-domains/$domainUID/domain.yaml

# Apply the Domain
kubectl apply -f output/weblogic-domains/$domainUID/domain.yaml

wait_admin_pod
wait_managed_pods

hostname=`hostname -f`
UCM_PORT=$LoadBalancerPort
IBR_PORT=$LoadBalancerPort
UCM_INTRADOC_PORT=$UCMIntradocPort
IBR_INTRADOC_PORT=$IBRIntradocPort

# remove the space from hostname
hostname=`echo $hostname | sed  's/^[[:space:]]*//'`

# find & replace '.' from hostname
hostalias=`echo $hostname | sed  's/[.]//g'`
truncatedhostname=${hostalias}

if [ ${#truncatedhostname} -ge "15" ]
then
    truncatedhostname=${truncatedhostname:0:14}
fi

sed -i "s/@UCM_PORT@/$UCM_PORT/g" autoinstall.cfg.cs
sed -i "s/@INSTALL_HOST_FQDN@/$hostname/g" autoinstall.cfg.cs
sed -i "s/@INSTALL_HOST_NAME@/$hostalias/g" autoinstall.cfg.cs
sed -i "s/@HOST_NAME_PREFIX@/$truncatedhostname/g" autoinstall.cfg.cs
sed -i "s/@UCM_INTRADOC_PORT@/$UCM_INTRADOC_PORT/g" autoinstall.cfg.cs

kubectl cp  autoinstall.cfg.cs $domainNS/$domainUID-ucm-server1:/u01/oracle/user_projects/domains/$domainUID/ucm/cs/bin/autoinstall.cfg

# for IBR
sed -i "s/@IBR_PORT@/$IBR_PORT/g" autoinstall.cfg.ibr
sed -i "s/@INSTALL_HOST_FQDN@/$hostname/g" autoinstall.cfg.ibr
sed -i "s/@INSTALL_HOST_NAME@/$hostalias/g" autoinstall.cfg.ibr
sed -i "s/@IBR_INTRADOC_PORT@/$IBR_INTRADOC_PORT/g" autoinstall.cfg.ibr

kubectl cp  autoinstall.cfg.ibr $domainNS/$domainUID-ibr-server1:/u01/oracle/user_projects/domains/$domainUID/ucm/ibr/bin/autoinstall.cfg

#expose service for IBR intradoc port
ip_addr=`hostname -i`

kubectl expose  service/wccinfra-cluster-ibr-cluster --name wccinfra-cluster-ibr-cluster-ext --port=$IBRIntradocPort --target-port=$IBRIntradocPort  --external-ip=$ip_addr -n $domainNS

kubectl get service/wccinfra-cluster-ibr-cluster-ext -n $domainNS -o yaml  > wccinfra-cluster-ibr-cluster-ext.yaml
sed -i "0,/$IBRIntradocPort/s//16250/" wccinfra-cluster-ibr-cluster-ext.yaml
kubectl -n $domainNS apply -f wccinfra-cluster-ibr-cluster-ext.yaml

#STOP
kubectl patch domain $domainUID -n $domainNS --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'

sleep 2m

#START
kubectl patch domain $domainUID -n $domainNS --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IF_NEEDED" }]'

echo "Please monitor server pods status at console using kubectl get pod -n $domainNS"
