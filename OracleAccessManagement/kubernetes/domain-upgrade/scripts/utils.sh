#!/bin/bash
# Copyright (c) 2024,2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
#
# Function to exit and print an error message
# $1 - text of message


# timestamp
#   purpose:  echo timestamp in the form yyyy-mm-ddThh:mm:ss.nnnnnnZ
#   example:  2018-10-01T14:00:00.000001Z
timestamp() {
  local timestamp="`date --utc '+%Y-%m-%dT%H:%M:%S.%NZ' 2>&1`"
  if [ ! "${timestamp/illegal/xyz}" = "${timestamp}" ]; then
    # old shell versions don't support %N or --utc
    timestamp="`date -u '+%Y-%m-%dT%H:%M:%S.000000Z' 2>&1`"
  fi
  echo "${timestamp}"
}

# Function to print an error message
printError() {
  echo [`timestamp`][ERROR] $*
}

# Function to print an error message
printInfo() {
  echo [`timestamp`][INFO] $*
}


fail() {
  printError $*
  exit 1
}

# Set default values for inputs
function setDefaultInputValues {

  if [ -z ${namespace} ]; then
    printInfo "Domain namespace is empty, setting to default \"oamns\""
    namespace="oamns"
  fi

  if [ -z ${domainUID} ]; then
    printInfo "domainUID is empty, setting to default \"accessdomain\""
    domainUID="accessdomain"
  fi

  if [ -z ${domainType} ]; then
    printInfo "domainType is empty, setting to default \"oam\""
    domainType="oam"
  fi

  if [ -z ${domainHome} ]; then
    printInfo "domainHome is empty, setting to default \"/u01/oracle/user_projects/domains/accessdomain\""
    domainType="/u01/oracle/user_projects/domains/accessdomain"
  fi

  if [ -z ${domainPVMountPath} ]; then
    printInfo "domainPVMountPath is empty, setting to default \"/u01/oracle/user_projects/domains\""
    domainPVMountPath="/u01/oracle/user_projects/domains"
  fi

  if [ -z ${persistentVolumeClaimName} ]; then
    printInfo "persistentVolumeClaimName is empty, setting to default \"accessdomain-domain-pvc\""
    persistentVolumeClaimName="accessdomain-domain-pvc"
  fi

  if [ -z ${rcuSchemaPrefix} ]; then
    printInfo "rcuSchemaPrefix is empty, setting to default \"OAMPD\""
    rcuSchemaPrefix="OAMPD"
  fi

  if [ -z ${rcuDatabaseURL} ]; then
    printInfo "rcuDatabaseURL is empty, setting to default \"xxxxx.example.com:1521/oampdb1.example.com\""
    rcuDatabaseURL="xxxxx.example.com:1521/oampdb1.example.com"
  fi

  if [ -z ${rcuCredentialsSecret} ]; then
    printInfo "rcuCredentialsSecret is empty, setting to default \"accessdomain-rcu-credentials\""
    rcuCredentialsSecret="accessdomain-rcu-credentials"
  fi

  if [ -z ${secureEnabled} ]; then
    printInfo "secureEnabled is empty, setting to default \"false\""
    secureEnabled="false"
  fi

}


