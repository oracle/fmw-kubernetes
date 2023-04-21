#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of Prometheus functions and procedures used by the provisioning and deletion scripts
# 
#
# Dependencies: 
#               
#
# Usage: invoked as needed not directly
#
# Common Environment Variables
#


# Download Prometheus
#
download_prometheus()
{

   ST=`date +%s`
   print_msg "Download Prometheus"

   cd $WORKDIR
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts > $LOGDIR/download.log 2>&1
   helm repo update >> $LOGDIR/download.log 2>&1
   print_status $? $LOGDIR/download.log


   ET=`date +%s`
   print_time STEP "Download Prometheus" $ST $ET >> $LOGDIR/timings.log
}

# Create Override File
#
create_override()
{

   ST=`date +%s`
   print_msg "Creating Helm Override File"

   cp $TEMPLATE_DIR/override_prom.yaml $WORKDIR
   filename=$WORKDIR/override_prom.yaml

   update_variable "<PROM_ALERT_K8>" $PROM_ALERT_K8 $filename
   update_variable "<PROM_K8>" $PROM_K8 $filename
   update_variable "<PROM_GRAF_K8>" $PROM_GRAF_K8 $filename
   update_variable "<OHS_HOST1>" $OHS_HOST1 $filename
   if [ ! "$OHS_HOST2" = "" ]
   then
      update_variable "<OHS_HOST2>" $OHS_HOST2 $filename
   fi
   update_variable "<PROM_ADMIN_PWD>" $PROM_ADMIN_PWD $filename

   print_status $?

   ET=`date +%s`
   print_time STEP "Creating Override File" $ST $ET >> $LOGDIR/timings.log
}

# Deploy Prometheus
#
deploy_prometheus()
{

   ST=`date +%s`
   print_msg "Deploying Prometheus"

   cd $WORKDIR
   helm install -n $PROMNS kube-prometheus  prometheus-community/kube-prometheus-stack -f $WORKDIR/override_prom.yaml > $LOGDIR/deploy.log 2>&1
   print_status $? $LOGDIR/deploy.log

   ET=`date +%s`
   print_time STEP "Deploying Prometheus" $ST $ET >> $LOGDIR/timings.log
}

