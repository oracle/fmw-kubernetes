#!/usr/bin/env bash
# Copyright (c) 2020, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description
#  This sample script creates a Kubernetes secret for WebLogic domain admin credentials.
#
#  The following pre-requisites must be handled prior to running this script:
#    * The kubernetes namespace must already be created
#
# Secret name determination
#  1) secretName - if specified
#  2) wccinfra-weblogic-credentials - if secretName and domainUID are both not specified. This is the default out-of-the-box.
#  3) <domainUID>-weblogic-credentials - if secretName is not specified, and domainUID is specified.
#  4) weblogic-credentials - if secretName is not specified, and domainUID is specified as "".
#
# The generated secret will be labeled with 
#       weblogic.domainUID=$domainUID 
# and
#       weblogic.domainName=$domainUID 
# Where the $domainUID is the value of the -d command line option, unless the value supplied is an empty String ""
#

script="${BASH_SOURCE[0]}"

#
# Function to exit and print an error message
# $1 - text of message
fail() {
  echo "[ERROR] $*"
  exit 1
}

# Try to execute ${KUBERNETES_CLI:-kubectl} to see whether ${KUBERNETES_CLI:-kubectl} is available
validateKubectlAvailable() {
  if ! [ -x "$(command -v ${KUBERNETES_CLI:-kubectl})" ]; then
    fail "${KUBERNETES_CLI:-kubectl} is not installed"
  fi
}

usage() {
  echo usage: "${script}" -u username -p password [-d domainUID] [-n namespace] [-s secretName] [-h]
  echo "  -u username, must be specified."
  echo "  -p password, must be provided using the -p argument or user will be prompted to enter a value."
  echo "  -d domainUID, optional. The default value is wccinfra. If specified, the secret will be labeled with the domainUID unless the given value is an empty string."
  echo "  -n namespace, optional. Use the wccns namespace if not specified"
  echo "  -s secretName, optional. If not specified, the secret name will be determined based on the domainUID value"
  echo "  -h Help"
  exit "$1"
}

#
# Parse the command line options
#
domainUID=wccinfra
namespace=wccns
while getopts "hu:p:n:d:s:" opt; do
  case $opt in
    u) username="${OPTARG}"
    ;;
    p) password="${OPTARG}"
    ;;
    n) namespace="${OPTARG}"
    ;;
    d) domainUID="${OPTARG}"
    ;;
    s) secretName="${OPTARG}"
    ;;
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done

if [ -z "$secretName" ]; then
  if [ -z "$domainUID" ]; then
    secretName=weblogic-credentials
  else 
    secretName=$domainUID-weblogic-credentials
  fi
fi

if [ -z "${username}" ]; then
  echo "${script}: -u must be specified."
  missingRequiredOption="true"
fi

if [ "${missingRequiredOption}" != "true" ]; then
  if [ -z "${password}" ]; then
    stty -echo
    printf "Enter password: "
    read -r password
    stty echo
    printf "\n"
  fi
fi

if [ -z "${password}" ]; then
  echo "${script}: -p password must be specified."
  missingRequiredOption="true"
fi

if [ "${missingRequiredOption}" == "true" ]; then
  usage 1
fi

# check and see if the secret already exists
result=$(${KUBERNETES_CLI:-kubectl} get secret "${secretName}" -n "${namespace}" --ignore-not-found=true | grep "${secretName}" | wc | awk ' { print $1; }')
if [ "${result:=Error}" != "0" ]; then
  fail "The secret ${secretName} already exists in namespace ${namespace}."
fi

# create the secret
${KUBERNETES_CLI:-kubectl} -n "$namespace" create secret generic "$secretName" \
  --from-literal=username="$username" \
  --from-literal=password="$password"

# label the secret with domainUID if needed
if [ -n "$domainUID" ]; then
  ${KUBERNETES_CLI:-kubectl} label secret "${secretName}" -n "$namespace" weblogic.domainUID="$domainUID" weblogic.domainName="$domainUID"
fi

# Verify the secret exists
SECRET=$(${KUBERNETES_CLI:-kubectl} get secret "${secretName}" -n "${namespace}" | grep "${secretName}" | wc | awk ' { print $1; }')
if [ "${SECRET}" != "1" ]; then
  fail "The secret ${secretName} was not found in namespace ${namespace}"
fi

echo "The secret ${secretName} has been successfully created in the ${namespace} namespace."

