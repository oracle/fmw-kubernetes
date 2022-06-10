#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

function initialize {
  if [ -z ${domainNamespace} ]; then
    echo "domainNamespace is empty, setting to default wcpns"
    domainNamespace="wcpns"
  fi

  if [ -z ${domainUID} ]; then
    echo "domainUID is empty, setting to default wcp-domain"
    domainUID="wcp-domain"
  fi

  if [ -z ${weblogicCredentialsSecretName} ]; then
    echo "weblogicCredentialsSecretName is empty, setting to default \"wcp-domain-domain-credentials\""
    weblogicCredentialsSecretName="wcp-domain-domain-credentials"
  fi

  if [ -z ${adminServerName} ]; then
    echo "adminServerName is empty, setting to default \"AdminServer\""
    adminServerName="AdminServer"
  fi

  if [ -z ${adminServerPort} ]; then
    echo "adminServerPort is empty, setting to default \"7001\""
    adminServerPort="7001"
  fi

  if [ -z ${wcpClusterName} ]; then
    echo "wcpClusterName is empty, setting to default \"wcp-cluster\""
    wcpClusterName="wcp-cluster"
  fi

  if [ -z ${wcpManagedServerPort} ]; then
    echo "wcpManagedServerPort is empty, setting to default \"8888\""
    wcpManagedServerPort="8888"
  fi

  if [ -z ${wlsMonitoringExporterTowcpCluster} ]; then
    echo "wlsMonitoringExporterTowcpCluster is empty, setting to default \"false\""
    wlsMonitoringExporterTowcpCluster="false"
  fi
  if [ -z ${wcpPortletClusterName} ]; then
    echo "wcpPortletClusterName is empty, setting to default \"wcportlet-cluster\""
    wcpPortletClusterName="wcportlet-cluster"
  fi

  if [ -z ${wcpPortletManagedServerPort} ]; then
    echo "wcpPortletManagedServerPort is empty, setting to default \"8889\""
    wcpPortletManagedServerPort="8889"
  fi

  if [ -z ${wlsMonitoringExporterTowcpPortletCluster} ]; then
    echo "wlsMonitoringExporterTowcpPortletCluster is empty, setting to default \"false\""
    wlsMonitoringExporterTowcpPortletCluster="false"
  fi
}

