#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

function initialize {
  if [ -z ${domainNamespace} ]; then
    echo "domainNamespace is empty, setting to default soans"
    domainNamespace="soans"
  fi

  if [ -z ${domainUID} ]; then
    echo "domainUID is empty, setting to default soainfra"
    domainUID="soainfra"
  fi

  if [ -z ${weblogicCredentialsSecretName} ]; then
    echo "weblogicCredentialsSecretName is empty, setting to default \"soainfra-domain-credentials\""
    weblogicCredentialsSecretName="soainfra-domain-credentials"
  fi

  if [ -z ${adminServerName} ]; then
    echo "adminServerName is empty, setting to default \"AdminServer\""
    adminServerName="AdminServer"
  fi

  if [ -z ${adminServerPort} ]; then
    echo "adminServerPort is empty, setting to default \"7001\""
    adminServerPort="7001"
  fi

  if [ -z ${soaClusterName} ]; then
    echo "soaClusterName is empty, setting to default \"soa_cluster\""
    soaClusterName="soa_cluster"
  fi

  if [ -z ${soaManagedServerPort} ]; then
    echo "soaManagedServerPort is empty, setting to default \"8001\""
    soaManagedServerPort="8001"
  fi

  if [ -z ${wlsMonitoringExporterTosoaCluster} ]; then
    echo "wlsMonitoringExporterTosoaCluster is empty, setting to default \"false\""
    wlsMonitoringExporterTosoaCluster="false"
  fi
  if [ -z ${osbClusterName} ]; then
    echo "osbClusterName is empty, setting to default \"osb_cluster\""
    osbClusterName="osb_cluster"
  fi

  if [ -z ${osbManagedServerPort} ]; then
    echo "osbManagedServerPort is empty, setting to default \"9001\""
    osbManagedServerPort="9001"
  fi

  if [ -z ${wlsMonitoringExporterToosbCluster} ]; then
    echo "wlsMonitoringExporterToosbCluster is empty, setting to default \"false\""
    wlsMonitoringExporterToosbCluster="false"
  fi
}

