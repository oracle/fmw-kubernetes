#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

function setDefaultInputValues {

  if [ -z ${namespace} ]; then
    echo "Domain namespace is empty, setting to default \"soans\""
    namespace="soans"
  fi

  if [ -z ${domainUID} ]; then
    echo "domainUID is empty, setting to default \"soainfra\""
    domainUID="soainfra"
  fi

  if [ -z ${domainType} ]; then
    echo "domainType is empty, setting to default \"soa\""
    domainType="soa"
  fi

  if [ -z ${domainHome} ]; then
    echo "domainHome is empty, setting to default \"/u01/oracle/user_projects/domains/soainfra\""
    domainType="/u01/oracle/user_projects/domains/soainfra"
  fi

  if [ -z ${domainPVMountPath} ]; then
    echo "domainPVMountPath is empty, setting to default \"/u01/oracle/user_projects\""
    domainPVMountPath="/u01/oracle/user_projects"
  fi

  if [ -z ${persistentVolumeClaimName} ]; then
    echo "persistentVolumeClaimName is empty, setting to default \"soainfra-domain-pvc\""
    persistentVolumeClaimName="soainfra-domain-pvc"
  fi

  if [ -z ${rcuSchemaPrefix} ]; then
    echo "rcuSchemaPrefix is empty, setting to default \"SOA1\""
    rcuSchemaPrefix="SOA1"
  fi

  if [ -z ${rcuDatabaseURL} ]; then
    echo "rcuDatabaseURL is empty, setting to default \"oracle-db.default.svc.cluster.local:1521/devpdb.k8s\""
    rcuDatabaseURL="oracle-db.default.svc.cluster.local:1521/devpdb.k8s"
  fi

  if [ -z ${rcuCredentialsSecret} ]; then
    echo "rcuCredentialsSecret is empty, setting to default \"soainfra-rcu-credentials\""
    rcuCredentialsSecret="soainfra-rcu-credentials"
  fi

  if [ -z ${secureEnabled} ]; then
    echo "secureEnabled is empty, setting to default \"false\""
    rcuCredentialsSecret="soainfra-rcu-credentials"
  fi

}


