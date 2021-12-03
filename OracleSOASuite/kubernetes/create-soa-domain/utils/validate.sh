#!/usr/bin/env bash
# Copyright (c) 2020, 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description
#  Validation functions that process inputs properties for SOA domains.
#

#
# Create an instance of clusterName to be used in cases where a legal DNS name is required.
#
function validateClusterName_SOA {
  eval "${1}SVC=$(toDNS1123Legal ${2})"
}

#
# Create an instance of managedServerName to be used in cases where a legal DNS name is required.
#
function validateManagedServerNameBase_SOA {
  eval "${1}SVC=$(toDNS1123Legal ${2})"
}

#
# Function to validate the SOA Suite domainType
#
function validateSOASuiteDomainType {
  if [ ! -z ${domainType} ]; then
    case ${domainType} in
      "soa")
      ;;
      "osb")
      ;;
      "soaosb")
      ;;
      "soab2b")
      ;;
      "soaosbb2b")
      ;;
      *)
        validationError "Invalid domainType: ${domainType}. Valid values are: soa or osb or soaosb or or soab2b or soaosbb2b."
      ;;
    esac
  else
    # Set the default
    domainType="soa"
  fi
  failIfValidationErrors
}

#
# Function to validate the persistent store type for SOA Suite domains
#
function validatePersistentStoreType {
  if [ ! -z ${persistentStore} ]; then
    case ${persistentStore} in
      "jdbc")
      ;;
      "file")
      ;;
      *)
        validationError "Invalid persistentStore: ${persistentStore}. Valid values are: jdbc or file."
      ;;
    esac
  else
    # Set the default
    persistentStore="jdbc"
  fi
  failIfValidationErrors
}

#
# Validate SSL port value is specified ?
#
function validateSSLPortsSpecified {
  if [ "${sslEnabled}" =  "true" ]; then
    validateInputParamsSpecified \
	  ${1}
  fi  
}

#
# Validate ConfiguredManagedServerCount is non zero value
#
function validateConfiguredManagedServerCount {
  if [ "${configuredManagedServerCount}" -le 0 ]; then
    validationError "Invalid configuredManagedServerCount value: ${configuredManagedServerCount}. configuredManagedServerCount value must be greater than 0."
  fi  
}

#
# Validate InitialManagedServerReplicas
#
function validateInitialManagedServerReplicas {
  if [ "${initialManagedServerReplicas}" -lt 0 -o "${initialManagedServerReplicas}" -gt "${configuredManagedServerCount}" ]; then
    validationError "Invalid initialManagedServerReplicas value: ${initialManagedServerReplicas}. initialManagedServerReplicas value must be a positive integer  lesser than configuredManagedServerCount."
  fi  
}

#
# Function to validate the common input parameters
#
function validateCommonInputs_SOA {
  # Parse the commonn inputs file
  parseCommonInputs

  validateInputParamsSpecified \
    adminServerName \
    domainUID \
    namespace \
    includeServerOutInPodLog \
    version

  validateIntegerInputParamsSpecified \
    adminPort \
    configuredManagedServerCount \
    initialManagedServerReplicas \
    t3ChannelPort \
    adminNodePort

  validateBooleanInputParamsSpecified \
    productionModeEnabled \
    exposeAdminT3Channel \
    exposeAdminNodePort \
    includeServerOutInPodLog \
    sslEnabled

  export requiredInputsVersion="create-weblogic-sample-domain-inputs-v1"
  validateVersion

  validateDomainUid
  validateNamespace
  validateAdminServerName

  validateWeblogicCredentialsSecretName
  validateServerStartPolicy
  validateWeblogicImagePullPolicy
  validateWeblogicImagePullSecretName
  validateFmwDomainType

  # Below validations are for SOA Suite domains
  validateSSLPortsSpecified \
	adminServerSSLPort

  validateSOASuiteDomainType
  validatePersistentStoreType

  if [ "${domainType}" = "soa" -o "${domainType}" = "soaosb" -o "${domainType}" = "soab2b" -o "${domainType}" = "soaosbb2b" ]; then
    validateInputParamsSpecified \
      soaClusterName \
      soaManagedServerNameBase

    validateIntegerInputParamsSpecified \
      soaManagedServerPort
 
    validateSSLPortsSpecified \
	  soaManagedServerSSLPort

    validateClusterName_SOA \
      soaClusterName \
      ${soaClusterName}

    validateManagedServerNameBase_SOA \
      soaManagedServerNameBase \
      ${soaManagedServerNameBase}
  fi
  if [ "${domainType}" = "osb" -o "${domainType}" = "soaosb" -o "${domainType}" = "soaosbb2b" ]; then
    validateInputParamsSpecified \
      osbClusterName \
      osbManagedServerNameBase

    validateIntegerInputParamsSpecified \
      osbManagedServerPort

    validateSSLPortsSpecified \
	  osbManagedServerSSLPort

    validateClusterName_SOA \
      osbClusterName \
      ${osbClusterName}

    validateManagedServerNameBase_SOA \
      osbManagedServerNameBase \
      ${osbManagedServerNameBase}
  fi

  validateConfiguredManagedServerCount
  validateInitialManagedServerReplicas
  
  # Below three validate methods are used for MII integration testing
  validateWdtDomainType
  validateWdtModelFile
  validateWdtModelPropertiesFile

  failIfValidationErrors
}

#
# Function to validate the image pull secret name
#
function validateArtifactsImagePullSecretName {
  if [ ! -z ${artifactsImagePullSecretName} ]; then
    validateLowerCase artifactsImagePullSecretName ${artifactsImagePullSecretName}
    artifactsImagePullSecretPrefix=""
  else
    # Set name blank when not specified, and comment out the yaml
    artifactsImagePullSecretName=""
    artifactsImagePullSecretPrefix="#"
  fi
}


function validateArtifactsPVC {
  # Validate the PVC using existing function
  validateDomainPVC
}
