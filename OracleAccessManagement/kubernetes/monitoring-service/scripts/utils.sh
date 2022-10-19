#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

function initialize {
  if [ -z ${domainNamespace} ]; then
    echo "domainNamespace is empty, setting to default accessns"
    domainNamespace="accessns"
  fi

  if [ -z ${domainUID} ]; then
    echo "domainUID is empty, setting to default accessinfra"
    domainUID="accessinfra"
  fi

  if [ -z ${weblogicCredentialsSecretName} ]; then
    echo "weblogicCredentialsSecretName is empty, setting to default \"accessinfra-domain-credentials\""
    weblogicCredentialsSecretName="accessinfra-domain-credentials"
  fi

  if [ -z ${adminServerName} ]; then
    echo "adminServerName is empty, setting to default \"AdminServer\""
    adminServerName="AdminServer"
  fi

  if [ -z ${adminServerPort} ]; then
    echo "adminServerPort is empty, setting to default \"7001\""
    adminServerPort="7001"
  fi

  if [ -z ${oamClusterName} ]; then
    echo "oamClusterName is empty, setting to default \"oam_cluster\""
    oamClusterName="oam_cluster"
  fi

  if [ -z ${oamManagedServerPort} ]; then
    echo "oamManagedServerPort is empty, setting to default \"14100\""
    oamManagedServerPort="14100"
  fi

  if [ -z ${wlsMonitoringExporterTooamCluster} ]; then
    echo "wlsMonitoringExporterTooamCluster is empty, setting to default \"false\""
    wlsMonitoringExporterTooamCluster="false"
  fi
  if [ -z ${policyClusterName} ]; then
    echo "policyClusterName is empty, setting to default \"policy_cluster\""
    policyClusterName="policy_cluster"
  fi

  if [ -z ${policyManagedServerPort} ]; then
    echo "policyManagedServerPort is empty, setting to default \"15100\""
    policyManagedServerPort="15100"
  fi

  if [ -z ${wlsMonitoringExporterTopolicyCluster} ]; then
    echo "wlsMonitoringExporterTopolicyCluster is empty, setting to default \"false\""
    wlsMonitoringExporterTopolicyCluster="false"
  fi
}

