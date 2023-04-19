#!/usr/bin/env bash
# Copyright (c) 2020, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description
#  Validation functions that process inputs properties for OIG domains.
#

#
# Function to validate datasource input parameters type
#
function validateOIGDatasourceType {
  if [ ! -z ${datasourceType} ]; then
    case ${datasourceType} in
      "generic")
      ;;
      "agl")
      ;;
      *)
        validationError "Invalid datasourceType: ${datasourceType}. Valid values are: agl or generic"
      ;;
    esac
  else
    validationError "datasourceType cannot be empty or null, valid values are: agl or generic"
  fi
  failIfValidationErrors
}

#
# Function to validate the common input parameters for OIG
#
function validateCommonInputs_OIG {
  sample_name=${1:-"other"}

  # Parse the common inputs file
  parseCommonInputs

  validateInputParamsSpecified \
    adminServerName \
    domainUID \
    clusterName \
    managedServerNameBase \
    namespace \
    includeServerOutInPodLog \
    version \
    datasourceType

  validateIntegerInputParamsSpecified \
    adminPort \
    initialManagedServerReplicas \
    managedServerPort \
    t3ChannelPort \
    adminNodePort

  if [ ! "${sample_name}" == "fmw-domain-home-in-image" ]; then
    validateIntegerInputParamsSpecified configuredManagedServerCount
  fi

  validateBooleanInputParamsSpecified \
    productionModeEnabled \
    exposeAdminT3Channel \
    exposeAdminNodePort \
    includeServerOutInPodLog

  export requiredInputsVersion="create-weblogic-sample-domain-inputs-v1"
  validateVersion

  validateDomainUid
  validateNamespace
  validateAdminServerName
  validateManagedServerNameBase
  validateClusterName
  validateWeblogicCredentialsSecretName
  validateServerStartPolicy
  validateWeblogicImagePullPolicy
  validateWeblogicImagePullSecretName
  validateFmwDomainType
  validateDomainFilesDir

  #validate datasourceType inputs
  validateLowerCase datasourceType
  validateOIGDatasourceType

  # Below three validate methods are used for MII integration testing
  validateWdtDomainType
  validateWdtModelFile
  validateWdtModelPropertiesFile

  failIfValidationErrors
}