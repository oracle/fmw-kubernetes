#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

function initialize {
  if [ -z ${domainNamespace} ]; then
    echo "domainNamespace is empty, setting to default wccns"
    domainNamespace="wccns"
  fi

  if [ -z ${domainUID} ]; then
    echo "domainUID is empty, setting to default wccinfra"
    domainUID="wccinfra"
  fi

  if [ -z ${weblogicCredentialsSecretName} ]; then
    echo "weblogicCredentialsSecretName is empty, setting to default \"wccinfra-domain-credentials\""
    weblogicCredentialsSecretName="wccinfra-domain-credentials"
  fi

  if [ -z ${adminServerName} ]; then
    echo "adminServerName is empty, setting to default \"adminserver\""
    adminServerName="adminserver"
  fi

  if [ -z ${adminServerPort} ]; then
    echo "adminServerPort is empty, setting to default \"7001\""
    adminServerPort="7001"
  fi

  if [ -z ${ibrClusterName} ]; then
    echo "ibrClusterName is empty, setting to default \"ibr_cluster\""
    ibrClusterName="ibr_cluster"
  fi

  if [ -z ${ibrManagedServerPort} ]; then
    echo "ibrManagedServerPort is empty, setting to default \"16250\""
    ibrManagedServerPort="16250"
  fi

  if [ -z ${wlsMonitoringExporterToibrCluster} ]; then
    echo "wlsMonitoringExporterToibrCluster is empty, setting to default \"false\""
    wlsMonitoringExporterToibrCluster="false"
  fi
  if [ -z ${ucmClusterName} ]; then
    echo "ucmClusterName is empty, setting to default \"ucm_cluster\""
    ucmClusterName="ucm_cluster"
  fi

  if [ -z ${ucmManagedServerPort} ]; then
    echo "ucmManagedServerPort is empty, setting to default \"16200\""
    ucmManagedServerPort="16200"
  fi

  if [ -z ${wlsMonitoringExporterToucmCluster} ]; then
    echo "wlsMonitoringExporterToucmCluster is empty, setting to default \"false\""
    wlsMonitoringExporterToucmCluster="false"
  fi
  if [ -z ${ipmClusterName} ]; then
    echo "ipmClusterName is empty, setting to default \"ipm_cluster\""
    ipmClusterName="ipm_cluster"
  fi

  if [ -z ${ipmManagedServerPort} ]; then
    echo "ipmManagedServerPort is empty, setting to default \"16000\""
    ipmManagedServerPort="16000"
  fi

  if [ -z ${wlsMonitoringExporterToipmCluster} ]; then
    echo "wlsMonitoringExporterToipmCluster is empty, setting to default \"false\""
    wlsMonitoringExporterToipmCluster="false"
  fi
  if [ -z ${captureClusterName} ]; then
    echo "captureClusterName is empty, setting to default \"capture_cluster\""
    captureClusterName="capture_cluster"
  fi

  if [ -z ${captureManagedServerPort} ]; then
    echo "captureManagedServerPort is empty, setting to default \"16400\""
    captureManagedServerPort="16400"
  fi

  if [ -z ${wlsMonitoringExporterTocaptureCluster} ]; then
    echo "wlsMonitoringExporterTocaptureCluster is empty, setting to default \"false\""
    wlsMonitoringExporterTocaptureCluster="false"
  fi
  if [ -z ${wccadfClusterName} ]; then
    echo "wccadfClusterName is empty, setting to default \"wccadf_cluster\""
    wccadfClusterName="wccadf_cluster"
  fi

  if [ -z ${wccadfManagedServerPort} ]; then
    echo "wccadfManagedServerPort is empty, setting to default \"16225\""
    wccadfManagedServerPort="16225"
  fi

  if [ -z ${wlsMonitoringExporterTowccadfCluster} ]; then
    echo "wlsMonitoringExporterTowccadfCluster is empty, setting to default \"false\""
    wlsMonitoringExporterTowccadfCluster="false"
  fi
}

