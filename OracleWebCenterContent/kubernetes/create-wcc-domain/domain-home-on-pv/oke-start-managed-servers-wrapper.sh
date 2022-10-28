#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

function  usage {
  echo usage: ${script} -o path_to_output_dir -l load_balancer_external_ip -p load_balancer_port [-u ucm_intradocport] [-i ibr_intradocport] [-h]
  echo "  -o output directory which was used during domain creation to generate yaml files, must be specified."
  echo "  -l load balancer external ip, must be specified."
  echo "  -p load balancer port, must be specified."
  echo "  -u ucm intradocport, optional"
  echo "  -i ibr intradocport, optional"
  echo "  -h Help"
  exit $1
}

while getopts "ho:l:p:u:i:" opt; do
  case $opt in
	o) outputDir="${OPTARG}"
	;;
	l) LoadBalancerExternalIP="${OPTARG}"
	;;
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

if [ -z ${outputDir} ]; then
  echo "${script}: -o(outputDir) must be specified."
  usage 1
fi

if [ -z ${LoadBalancerExternalIP} ]; then
  echo "${script}: -l(LoadBalancerExternalIP) must be specified."
  usage 1
fi

if [ -z ${LoadBalancerPort} ]; then
  echo "${script}: -p(LoadBalancerPort) must be specified."
  usage 1
fi

if [ -z ${UCMIntradocPort} ]; then
    UCMIntradocPort=4444
fi

if [ -z ${IBRIntradocPort} ]; then
     IBRIntradocPort=5555
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
        echo "Admin Pod timed out, exiting"
        exit 1
    else
        counter=$((counter+1))
        echo "Waiting for $adminPod Pod to start."
        sleep 40s
    fi
done
}

function wait_managed_pods {
   rep=$(grep  'initialManagedServerReplicas:' create-domain-inputs.yaml);
   rep=${rep//*initialManagedServerReplicas: /};
   echo "replicas=$rep"

for ((i = 1 ; i <= $rep ; i++)); do

  counter=0
while true; do
    ready_status=$(kubectl -n $domainNS get pods $ucmPod$i -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}')
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

sed -i '/domainHome:/a \ \ maxClusterConcurrentStartup: 1' ${outputDir}/weblogic-domains/$domainUID/domain.yaml

kubectl apply -f ${outputDir}/weblogic-domains/$domainUID/domain.yaml

wait_admin_pod
wait_managed_pods

hostname=$LoadBalancerExternalIP
UCM_PORT=$LoadBalancerPort
IBR_PORT=$LoadBalancerPort
UCM_INTRADOC_PORT=$UCMIntradocPort
IBR_INTRADOC_PORT=$IBRIntradocPort

hostname=`echo $hostname | sed  's/^[[:space:]]*//'`

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

sed -i "s/@IBR_PORT@/$IBR_PORT/g" autoinstall.cfg.ibr
sed -i "s/@INSTALL_HOST_FQDN@/$hostname/g" autoinstall.cfg.ibr
sed -i "s/@INSTALL_HOST_NAME@/$hostalias/g" autoinstall.cfg.ibr
sed -i "s/@IBR_INTRADOC_PORT@/$IBR_INTRADOC_PORT/g" autoinstall.cfg.ibr

kubectl cp  autoinstall.cfg.ibr $domainNS/$domainUID-ibr-server1:/u01/oracle/user_projects/domains/$domainUID/ucm/ibr/bin/autoinstall.cfg

kubectl patch domain $domainUID -n $domainNS --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'

sleep 2m

kubectl patch domain $domainUID -n $domainNS --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IF_NEEDED" }]'

echo "Please monitor server pods status at console using kubectl get pod -n $domainNS"
