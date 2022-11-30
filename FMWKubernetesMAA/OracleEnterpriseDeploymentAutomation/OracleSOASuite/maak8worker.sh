#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Script for Kubernetes Worker node set up
# Depends on variables set in maak8worker.env

basedir=$(dirname "$0")
echo "Running from $basedir"
source $basedir/maak8worker.env
source $basedir/common/utils.sh
echo $(dirname "$0")

export joincommand=`ssh -i $ssh_key $user@$mnode1 "kubeadm token create  --print-join-command"`

for host in ${NODE_LIST}; 
do
    echo "*************************   Creating the setup scripts for $host ************************"
    createSetupScripts ${host}
    setupScriptsDir="/tmp/setupscripts/${host}"
    ssh -i $ssh_key $user@$host "mkdir -p /tmp/maa; rm -f /tmp/maa/*; mkdir -p $log_dir"
    scp -i $ssh_key ${setupScriptsDir}/*  $user@$host:/tmp/maa

    echo "Setup scripts for $host created"
    echo "************** Installing Docker, Kubernetes and configuring in node $host **************"
    ssh -i $ssh_key $user@$host "sudo sh /tmp/maa/os_configure_$host.sh 2>&1 | tee -a $log_dir/os_configure_$host_$dt.log"
    ssh -i $ssh_key $user@$host "sudo sh /tmp/maa/docker_install_$host.sh 2>&1 | tee -a $log_dir/docker_install_$host_$dt.log"
    ssh -i $ssh_key $user@$host "sudo sh /tmp/maa/docker_configure_$host.sh 2>&1 | tee -a $log_dir/docker_configure_$host_$dt.log"
    ssh -i $ssh_key $user@$host "sudo sh /tmp/maa/k8s_install_$host.sh 2>&1 | tee -a $log_dir/k8s_install_$host_$dt.log"

    echo "Sleeping for possible break..."
    sleep 30
    echo "Creating worker with $k8_version version at $host..."
    ssh -i $ssh_key $user@$host "sudo $joincommand 2>&1 | tee -a $log_dir/kubeadm-worker-join_$host_$dt.log"
    echo "Worker at $host created."
done
