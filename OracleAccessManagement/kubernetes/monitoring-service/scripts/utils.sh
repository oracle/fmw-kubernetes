#!/bin/bash
# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

function initialize {
  if [ -z ${domainNamespace} ]; then
    echo "domainNamespace is empty, setting to default oamns"
    domainNamespace="oamns"
  fi

  if [ -z ${domainUID} ]; then
    echo "domainUID is empty, setting to default accessdomain"
    domainUID="accessdomain"
  fi

  if [ -z ${adminServerName} ]; then
    echo "adminServerName is empty, setting to default \"AdminServer\""
    adminServerName="AdminServer"
  fi


  if [ -z ${weblogicCredentialsSecretName} ]; then
    echo "weblogicCredentialsSecretName is empty, setting to default \"accessdomain-domain-credentials\""
    weblogicCredentialsSecretName="accessdomain-domain-credentials"
  fi

  if [ -z ${monitoringHelmReleaseName} ]; then
    echo "monitoringHelmReleaseName is empty, setting to default \"monitoring\""
    monitoringHelmReleaseName="monitoring"
  fi

  if [ -z ${monitoringNamespace} ]; then
    echo "monitoringNamespace is empty, setting to default \"monitoring\""
    monitoringNamespace="monitoring"
  fi
}

