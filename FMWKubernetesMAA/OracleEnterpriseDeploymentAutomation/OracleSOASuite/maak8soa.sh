#!/usr/bin/env bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description
# Script for Oracle SOA Suite deployment on Kubernetes
# Assumes that a Kubernetes cluster is present with an appropriate NFS mount for the PV
# Depends on variables set in maak8soa.env

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/maak8soa.env

read -s -p "Enter WebLogic password: " wlpswd
echo
read -s -p "Enter Database sys password: " syspwd
echo
read -s -p "Enter RCU schema password: " schemapwd
echo

export wlpswd syspwd schemapwd

echo "Sleeping 10 seconds in case you want to break..."
sleep 10
# Labeling nodes for the Oracle SOA Suite domain (may need to parameterize this for larger clusters)
echo "Labeling nodes..."
ssh -i $ssh_key $user@$mnode1 "kubectl  label node $wnode1 name=admin"
ssh -i $ssh_key $user@$mnode1 "kubectl  label node $wnode2 name=wls1"
ssh -i $ssh_key $user@$mnode1 "kubectl  label node $wnode3 name=wls2"
echo "Nodes labeled."

# Steps specific to Oracle SOA Suite
echo "Git cloning fmw-kubernetes repository..."
ssh -i $ssh_key $user@$mnode1 "sudo mkdir -p $soaopdir && sudo chown $user:$user $soaopdir"
ssh -i $ssh_key $user@$mnode1 "sudo yum install -y git-all";
sleep 5


ssh -i $ssh_key $user@$mnode1 "cd $soaopdir && git clone https://github.com/oracle/fmw-kubernetes.git --branch release/$soak8branch"
echo "Set up code repository to deploy Oracle SOA Suite domains done"

echo "Sleeping 10 seconds in case you want to break..."
sleep 10

echo "Creating namespaces..."
ssh -i $ssh_key $user@$mnode1 "kubectl create namespace opns"
ssh -i $ssh_key $user@$mnode1 "kubectl create serviceaccount -n opns  op-sa"
ssh -i $ssh_key $user@$mnode1 "kubectl create namespace soans"
echo "Namespaces created!"

echo "Installing operator $wlsoperator_version..."
# Install operator
ssh -i $ssh_key $user@$mnode1 "cd $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes && helm install weblogic-kubernetes-operator charts/weblogic-operator  --namespace opns  --set image=ghcr.io/oracle/weblogic-kubernetes-operator:$wlsoperator_version --set serviceAccount=op-sa --set 'domainNamespaces={}' --set "javaLoggingLevel=FINE" --wait"
sleep 10

# Configure the operator to manage domains
ssh -i $ssh_key $user@$mnode1 "cd $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes  && helm upgrade --reuse-values --namespace opns --set "domainNamespaces={soans}" --wait weblogic-kubernetes-operator charts/weblogic-operator"
echo "Operator installed!"

echo "Sleeping 10 seconds in case you want to break..."
sleep 10

echo "Creating secrets..."
# Create a Kubernetes secret for the domain
ssh -i $ssh_key $user@$mnode1 "cd $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes/create-weblogic-domain-credentials && ./create-weblogic-credentials.sh -u weblogic -p ${wlpswd} -n soans -d $soaedgdomain -s $soaedgdomain-domain-credentials";
sleep 5

# Create a Kubernetes secret for the RCU
ssh -i $ssh_key $user@$mnode1 "cd $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes/create-rcu-credentials && ./create-rcu-credentials.sh -u $soaedgprefix -p $schemapwd -a sys -q ${syspwd} -d $soaedgdomain -n soans -s $soaedgdomain-rcu-credentials"

echo "Secrets created!"

echo "Creating persistent volume and persistent volume claim..."
ssh -i $ssh_key $user@$mnode1 "mkdir -p $output_dir"
#Create a persistent volume configuration file
ssh -i $ssh_key $user@$mnode1 "cp $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes/create-weblogic-domain-pv-pvc/create-pv-pvc-inputs.yaml $output_dir/create-pv-pvc-inputs.yaml.$dt";

ssh -i $ssh_key $user@$mnode1 "cat <<EOF > $output_dir/create-pv-pvc-inputs.yaml
version: create-weblogic-sample-domain-pv-pvc-inputs-v
baseName: $soaedgdomain
domainUID: $soaedgdomain
namespace: soans
weblogicDomainStorageType: HOST_PATH
weblogicDomainStorageReclaimPolicy: Retain
weblogicDomainStorageSize: 10Gi
weblogicDomainStoragePath: $share_dir
EOF
"
ssh -i $ssh_key $user@$mnode1 "cd $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes/create-weblogic-domain-pv-pvc && ./create-pv-pvc.sh -i $output_dir/create-pv-pvc-inputs.yaml -o $output_dir";
ssh -i $ssh_key $user@$mnode1 "kubectl create -f $output_dir/pv-pvcs/$soaedgdomain-$soaedgdomain-pv.yaml -n soans";
ssh -i $ssh_key $user@$mnode1 "kubectl create -f $output_dir/pv-pvcs/$soaedgdomain-$soaedgdomain-pvc.yaml -n soans";
echo "Persistent volume and persistent volume claim created!"

echo "Sleeping 10 seconds in case you want to break..."
sleep 10

echo "Creating RCU schemas..."
ssh -i $ssh_key $user@$mnode1 "cd $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes/create-rcu-schema && $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes/create-rcu-schema/create-rcu-schema.sh -s $soaedgprefix -t $domain_type -d $db_url -i $soaimage -q $syspwd -r $schemapwd -l LARGE"
echo "RCU schemas created!"
echo "Sleeping 10 seconds in case you want to break..."
sleep 10

echo "Creating domain..."
#Modify domain creation input file
ssh -i $ssh_key $user@$mnode1 "cp $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes/create-soa-domain/domain-home-on-pv/create-domain-inputs.yaml $output_dir/create-domain-inputs.yaml.$dt";

ssh -i $ssh_key $user@$mnode1 "cat <<EOF > $output_dir/create-domain-inputs.yaml
version: create-weblogic-sample-domain-inputs-v1
sslEnabled: false
adminServerSSLPort: 7002
httpAccessLogInLogHome: true
persistentStore: jdbc
soaManagedServerSSLPort: 8002
adminPort: 7001
adminServerName: AdminServer
domainUID: $soaedgdomain
domainType: $domain_type
domainHome: /u01/oracle/user_projects/domains/${soaedgdomain}
serverStartPolicy: IF_NEEDED
soaClusterName: soa_cluster
configuredManagedServerCount: 5
initialManagedServerReplicas: 2
soaManagedServerNameBase: soa_server
soaManagedServerPort: 8001
osbClusterName: osb_cluster
osbManagedServerNameBase: osb_server
osbManagedServerPort: 9001
osbManagedServerSSLPort: 9002
image: $soaimage
imagePullPolicy: IfNotPresent
productionModeEnabled: true
weblogicCredentialsSecretName: ${soaedgdomain}-domain-credentials
includeServerOutInPodLog: true
logHome: /u01/oracle/user_projects/domains/logs/${soaedgdomain}
t3ChannelPort: 30012
t3PublicAddress: ${LBR_HN}
exposeAdminT3Channel: true
adminNodePort: 30701
exposeAdminNodePort: true
namespace: soans
javaOptions: -Dweblogic.StdoutDebugEnabled=false
persistentVolumeClaimName: ${soaedgdomain}-${soaedgdomain}-pvc
domainPVMountPath: /u01/oracle/user_projects
createDomainScriptsMountPath: /u01/weblogic
createDomainScriptName: create-domain-job.sh
createDomainFilesDir: wlst
rcuSchemaPrefix: $soaedgprefix
rcuDatabaseURL: $db_url
rcuCredentialsSecret: ${soaedgdomain}-rcu-credentials
persistentStore: jdbc
serverPodMemoryRequest: 10Gi
serverPodMemoryLimit: 10Gi
serverPodCpuRequest: 1000m
serverPodCpuLimit: 1000m
EOF
"

#Create the SOA EDG domain
ssh -i $ssh_key $user@$mnode1 "cd  $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes/create-soa-domain/domain-home-on-pv && $soaopdir/fmw-kubernetes/OracleSOASuite/kubernetes/create-soa-domain/domain-home-on-pv/create-domain.sh -i $output_dir/create-domain-inputs.yaml -o $output_dir"

ssh -i $ssh_key $user@$mnode1 "kubectl apply -f $output_dir/weblogic-domains/$soaedgdomain/domain.yaml"

stillnotuppod=true
trycountpod=0

#Verify domain start
while [ $stillnotuppod == "true" ]
        do
                resultpod=`ssh -i $ssh_key $user@$host "kubectl get pods -n soans"| grep soa-server |grep Running | wc -l`
                if [ $resultpod -gt 1 ]; then
                        stillnotuppod="true"
                        echo "SOA pod not ready, waiting..."
                        ((trycountpod=trycountpod+1))
                        sleep $sleeplapsepod
                        if [ "$trycountpod" -eq "$max_trycountpod" ];then
                                echo "Maximum number of retries reached! SOA pod not ready. Check status manually."
                                exit
                        fi
                else
                        stillnotuppod="false"
                        echo "SOA pod up, life is good, domain created!"
			ssh -i $ssh_key $user@$mnode1 "kubectl describe domain $soaedgdomain -n soans"
			ssh -i $ssh_key $user@$mnode1 "kubectl get services -n soans"
                fi
        done

echo "Sleeping 10 seconds in case you want to break..."
sleep 10

echo "Creating node port services..."
if [[ "$domain_type" == *"soa"* ]]; then
   # Create node port services
   ssh -i $ssh_key $user@$mnode1 "cat <<EOF > $output_dir/create-nodeport${soaedgdomain}-soa-cluster.yaml
apiVersion: v1
kind: Service
metadata:
  namespace: soans
  labels:
    serviceType: CLUSTER
    weblogic.clusterName: soa_cluster
    weblogic.domainName: ${soaedgdomain}
    weblogic.domainUID: ${soaedgdomain}
  name: ${soaedgdomain}-cluster-soa-cluster-node-port
spec:
  ports:
  - nodePort: 30801
    port: 8001
    protocol: TCP
    targetPort: 8001
  selector:
    weblogic.clusterName: soa_cluster
    weblogic.domainUID: ${soaedgdomain}
  sessionAffinity: ClientIP
  type: NodePort
EOF
"
   ssh -i $ssh_key $user@$mnode1 "kubectl apply -f $output_dir/create-nodeport${soaedgdomain}-soa-cluster.yaml"
   export soaport=`ssh -i $ssh_key $user@$mnode1 "kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services ${soaedgdomain}-cluster-soa-cluster-node-port -n soans"`
   echo "SOA CLUSTER PORT: $soaport"
fi

if [[ "$domain_type" == *"osb"* ]]; then
   ssh -i $ssh_key $user@$mnode1 "cat <<EOF > $output_dir/create-nodeport${soaedgdomain}-osb-cluster.yaml
apiVersion: v1
kind: Service
metadata:
  namespace: soans
  labels:
    serviceType: CLUSTER
    weblogic.clusterName: osb_cluster
    weblogic.domainName: ${soaedgdomain}
    weblogic.domainUID: ${soaedgdomain}
  name: ${soaedgdomain}-cluster-osb-cluster-node-port
spec:
  ports:
  - nodePort: 30901
    port: 9001
    protocol: TCP
    targetPort: 9001
  selector:
    weblogic.clusterName: osb_cluster
    weblogic.domainUID: ${soaedgdomain}
  sessionAffinity: ClientIP
  type: NodePort
EOF
"
   ssh -i $ssh_key $user@$mnode1 "kubectl apply -f $output_dir/create-nodeport${soaedgdomain}-osb-cluster.yaml"
   export osbport=`ssh -i $ssh_key $user@$mnode1 "kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services ${soaedgdomain}-cluster-osb-cluster-node-port -n soans"`
   echo "OSB CLUSTER PORT: $osbport"
fi

export adminport=`ssh -i $ssh_key $user@$mnode1 "kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services ${soaedgdomain}-adminserver-node-port -n soans"`
echo "ADMINISTRATION SERVER PORT: $adminport"
echo "Node port services created!"

echo "ALL DONE!"
