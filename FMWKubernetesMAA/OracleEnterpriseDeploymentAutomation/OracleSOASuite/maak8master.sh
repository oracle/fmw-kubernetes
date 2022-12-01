#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Script for Kubernetes Master High Availablility set up
# DEPENDS ON VARIBALES SET AT maak8master.env

basedir=$(dirname "$0")
echo "Running from $basedir"
source $basedir/maak8master.env
source $basedir/common/utils.sh
echo $(dirname "$0")

for host in ${NODE_LIST}; 
do
    echo "*************************   Creating the setup scripts for $host ************************"
    createSetupScripts ${host}
    setupScriptsDir="/tmp/setupscripts/${host}"
    ssh -i $ssh_key $user@$host "mkdir -p /tmp/maa; rm -f /tmp/maa/*; mkdir -p $log_dir"
    scp -i $ssh_key ${setupScriptsDir}/*  $user@$host:/tmp/maa
    echo "************** Installing Docker, Kubernetes and configuring in node $host **************"
    ssh -i $ssh_key $user@$host "sudo sh /tmp/maa/os_configure_$host.sh 2>&1 | tee -a $log_dir/os_configure_$host_$dt.log"
    ssh -i $ssh_key $user@$host "sudo sh /tmp/maa/docker_install_$host.sh 2>&1 | tee -a $log_dir/docker_install_$host_$dt.log"
    ssh -i $ssh_key $user@$host "sudo sh /tmp/maa/docker_configure_$host.sh 2>&1 | tee -a $log_dir/docker_configure_$host_$dt.log"
    ssh -i $ssh_key $user@$host "sudo sh /tmp/maa/k8s_install_$host.sh 2>&1 | tee -a $log_dir/k8s_install_$host_$dt.log"

    echo "Sleeping for possible break..."
    sleep 30

    #   NOTE: When you register the first master node, make sure you don't have in your LBR
    #   any reminiescent members that may be considered alive or certs etc may fail and be uploaded to the wrong member
    if [[ "$host" == "$mnode1" ]]; then
	    echo "Creating master with $k8_version version..."
	    ssh -i $ssh_key $user@$host "sudo kubeadm init --control-plane-endpoint $LBR_HN:$LBR_PORT --pod-network-cidr=$pod_network_cidr --node-name $mnode1 --upload-certs  --v=9 2>&1 | tee -a $log_dir/kubeadm-exec_$host_$dt.log"		
        export token=`ssh -i $ssh_key $user@$host "sudo grep 'kubeadm join $LBR_HN:$LBR_PORT' $log_dir/kubeadm-exec_$host_$dt.log |grep '\-\-token' " | awk '{print $5}' | awk 'NR==1{print $1}'`
        echo "TOKEN= $token"
        export token_ca=`ssh -i $ssh_key $user@$host "sudo grep '\-\-discovery-token-ca-cert-hash' $log_dir/kubeadm-exec_$host_$dt.log" | awk '{print $2}'| awk 'NR==1{print $1}'`
        echo "TOKEN_CA=$token_ca"
        export cp_ca=`ssh -i $ssh_key $user@$host "sudo grep '\-\-certificate-key' $log_dir/kubeadm-exec_$host_$dt.log" | awk '{print $3}'`
        ssh -i $ssh_key $user@$host "mkdir -p $HOME/.kube";
        ssh -i $ssh_key $user@$host "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config";
        ssh -i $ssh_key $user@$host "sudo chown $(id -u):$(id -g) $HOME/.kube/config";
        echo "Giving some time for first node..."
        sleep 20
        echo "Master created."
        echo "Configuring CNI..."
        ssh -i $ssh_key $user@$host "kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts"
        ssh -i $ssh_key $user@$host "kubectl apply -f /tmp/maa/kube-flannel.yml"
        echo "CNI configured."
        while [ $stillnotup == "true" ]
        do
            result=`ssh -i $ssh_key $user@$host "kubectl get nodes| grep 'NotReady' |wc -l"`
            if [ $result -gt 0 ]; then
                stillnotup="true"
                echo "Master not ready, retrying..."
                ((trycount=trycount+1))
                sleep $sleeplapse
                if [ "$trycount" -eq "$max_trycount" ];then
                    echo "Maximum number of retries reached! Master node not ready"
                    exit
                fi
            else
                stillnotup="false"
                echo "Master up, continuing..."
                echo "Installing helm..."
		ssh -i $ssh_key $user@$host "tar -zxvf /tmp/maa/helm-v${helm_version}-linux-amd64.tar.gz"
		ssh -i $ssh_key $user@$host "sudo mv linux-amd64/helm /usr/bin/helm"
		echo "Installed helm."
            fi
        done
    elif [[ "$host" == "$mnode2" ]] || [[ "$host" == "$mnode3" ]]; then
        echo "Creating secondary masters in $k8_version version at $host..."
        ssh -i $ssh_key $user@$host "sudo kubeadm join $LBR_HN:$LBR_PORT --token $token --node-name $host --discovery-token-ca-cert-hash $token_ca  --control-plane --certificate-key $cp_ca --v=9 2>&1 | tee -a $log_dir/kubeadm-exec_$host_$dt.log"
        echo "Secondary master at $host created."
    fi
done

