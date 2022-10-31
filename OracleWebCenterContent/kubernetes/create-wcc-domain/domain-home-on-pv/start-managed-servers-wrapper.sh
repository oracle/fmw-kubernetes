#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#

function  usage {
  echo usage: ${script} -o path_to_output_dir -p load_balancer_port -n node_port [-m ucm_node_port] [-u ucm_intradocport] [-i ibr_intradocport] [-h]
  echo "  -o output directory which was used during domain creation to generate yaml files, must be specified."
  echo "  -p load balancer port, must be specified."
  echo "  -n node port, to be used for exposing IBR intradoc-port (suggested value should be within a range of 30000-32767) - must be specified."
  echo "  -m ucm node port, to be used for exposing UCM intradoc-port (suggested value should be within a range of 30000-32767) - optional."
  echo "  -u ucm intradocport, optional"
  echo "  -i ibr intradocport, optional"
  echo "  -h Help"
  exit $1
}

while getopts "ho:p:n:m:u:i:" opt; do
  case $opt in
	o) outputDir="${OPTARG}"
	;;
	p) LoadBalancerPort="${OPTARG}"
	;;
        n) NodePort="${OPTARG}"
	;;
        m) UcmNodePort="${OPTARG}"
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

if [ -z ${LoadBalancerPort} ]; then
  echo "${script}: -p(LoadBalancerPort) must be specified."
  usage 1
fi

if [ -z ${NodePort} ]; then
  echo "${script}: -n(NodePort) to be used for exposing IBR intradoc-port (suggested value should be within a range of 30000-32767) must be specified."
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
        echo "Pods timed out, exiting"
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

hostname=`hostname -f`
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

ip_addr=`hostname -i`

echo "Expose the IBR intradoc port using service type NodePort"
kubectl expose  service/$domainUID-cluster-ibr-cluster --name $domainUID-cluster-ibr-cluster-ext --port=$IBRIntradocPort --type=NodePort -n $domainNS --dry-run=client -o yaml > $domainUID-cluster-ibr-cluster-ext.yaml
sed -i -e "/targetPort:*/a\ \ \ \ nodePort: $NodePort" $domainUID-cluster-ibr-cluster-ext.yaml
kubectl -n $domainNS apply -f $domainUID-cluster-ibr-cluster-ext.yaml

wccadfEnabled=$(grep  'adfuiEnabled:' create-domain-inputs.yaml);
wccadfEnabled=${wccadfEnabled//*adfuiEnabled: /};

ipmAppEnabled=$(grep  'ipmEnabled:' create-domain-inputs.yaml);
ipmAppEnabled=${ipmAppEnabled//*ipmEnabled: /};

if [[ true  == "$ipmAppEnabled" || true  == "$wccadfEnabled" ]]; then
  if [ -z ${UcmNodePort} ]; then
    echo "${script}: -m(UcmNodePort) to be used for exposing UCM intradoc-port (suggested value should be within a range of 30000-32767) must be specified if IPM and/or ADFUI is enabled."
    usage 1
  fi

  echo " Expose the UCM intradoc port using service type NodePort"
  kubectl expose service/$domainUID-cluster-ucm-cluster --name $domainUID-cluster-ucm-cluster-ext --port=$UCMIntradocPort --type=NodePort -n $domainNS --dry-run=client -o yaml > $domainUID-cluster-ucm-cluster-ext.yaml
  sed -i -e "/targetPort:*/a\ \ \ \ nodePort: $UcmNodePort" $domainUID-cluster-ucm-cluster-ext.yaml
  kubectl -n $domainNS apply -f $domainUID-cluster-ucm-cluster-ext.yaml
fi

#STOP
kubectl patch domain $domainUID -n $domainNS --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]'

sleep 2m

#START
kubectl patch domain $domainUID -n $domainNS --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IF_NEEDED" }]'

echo "Please monitor server pods status at console using kubectl get pod -n $domainNS"

