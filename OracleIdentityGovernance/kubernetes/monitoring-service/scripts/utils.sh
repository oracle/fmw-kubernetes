#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

function initialize {
  if [ -z ${domainNamespace} ]; then
    echo "domainNamespace is empty, setting to default oimcluster"
    domainNamespace="oimcluster"
  fi

  if [ -z ${domainUID} ]; then
    echo "domainUID is empty, setting to default oimcluster"
    domainUID="oimcluster"
  fi

  if [ -z ${weblogicCredentialsSecretName} ]; then
    echo "weblogicCredentialsSecretName is empty, setting to default \"oimcluster-domain-credentials\""
    weblogicCredentialsSecretName="oimcluster-domain-credentials"
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
  if [ -z ${oimClusterName} ]; then
    echo "oimClusterName is empty, setting to default \"oim_cluster\""
    oimClusterName="oim_cluster"
  fi

  if [ -z ${oimManagedServerPort} ]; then
    echo "oimManagedServerPort is empty, setting to default \"14000\""
    oimManagedServerPort="14000"
  fi

  if [ -z ${wlsMonitoringExporterTooimCluster} ]; then
    echo "wlsMonitoringExporterTooimCluster is empty, setting to default \"false\""
    wlsMonitoringExporterTooimCluster="false"
  fi
}

