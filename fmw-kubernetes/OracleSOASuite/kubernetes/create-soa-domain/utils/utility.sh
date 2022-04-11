#!/usr/bin/env bash
# Copyright (c) 2020, 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#
# Utility functions for SOA Suite domains
#

#
# Function to generate the properties and yaml files for creating a domain
#
function createFiles_SOA {

  # Make sure the output directory has a copy of the inputs file.
  # The user can either pre-create the output directory, put the inputs
  # file there, and create the domain from it, or the user can put the
  # inputs file some place else and let this script create the output directory
  # (if needed) and copy the inputs file there.
  copyInputsFileToOutputDirectory ${valuesInputFile} "${domainOutputDir}/create-domain-inputs.yaml"

  if [ "${domainHomeInImage}" == "true" ]; then
    if [ -z "${domainHomeImageBase}" ]; then
      fail "Please specify domainHomeImageBase in your input YAML"
    fi
  else
    if [ -z "${image}" ]; then
      fail "Please specify image in your input YAML"
    fi
  fi

  dcrOutput="${domainOutputDir}/domain.yaml"

  domainName=${domainUID}

  enabledPrefix=""     # uncomment the feature
  disabledPrefix="# "  # comment out the feature

  exposeAnyChannelPrefix="${disabledPrefix}"
  if [ "${exposeAdminT3Channel}" = true ]; then
    exposeAdminT3ChannelPrefix="${enabledPrefix}"
    exposeAnyChannelPrefix="${enabledPrefix}"
    # set t3PublicAddress if not set
    if [ -z "${t3PublicAddress}" ]; then
      getKubernetesClusterIP
      t3PublicAddress="${K8S_IP}"
    fi
  else
    exposeAdminT3ChannelPrefix="${disabledPrefix}"
  fi

  if [ "${exposeAdminNodePort}" = true ]; then
    exposeAdminNodePortPrefix="${enabledPrefix}"
    exposeAnyChannelPrefix="${enabledPrefix}"
  else
    exposeAdminNodePortPrefix="${disabledPrefix}"
  fi

  if [ "${istioEnabled}" == "true" ]; then
    istioPrefix="${enabledPrefix}"
  else
    istioPrefix="${disabledPrefix}"
  fi
  
  # The FromModel, MII (model-in-image), and WDT_DOMAIN_TYPE updates in this script
  # must remain even though they are not referenced by a sample. They're used by the 
  # Operator integration test code. If you're interested in MII, 
  # see './kubernetes/samples/scripts/create-weblogic-domain/model-in-image'.

  # MII settings are used for model-in-image integration testing
  if [ "${domainHomeSourceType}" == "FromModel" ]; then
    miiPrefix="${enabledPrefix}"
  else
    miiPrefix="${disabledPrefix}"
  fi

  # MII settings are used for model-in-image integration testing
  if [ -z "${miiConfigMap}" ]; then
    miiConfigMapPrefix="${disabledPrefix}"
  else
    miiConfigMapPrefix="${enabledPrefix}"
  fi

  # For some parameters, use the default value if not defined.
  if [ -z "${domainPVMountPath}" ]; then
    domainPVMountPath="/shared"
  fi

  if [ -z "${logHome}" ]; then
    logHome="${domainPVMountPath}/logs/${domainUID}"
  fi

  if [ -z "${httpAccessLogInLogHome}" ]; then
    httpAccessLogInLogHome="true"
  fi
  
  if [ -z "${dataHome}" ]; then
    dataHome=""
  fi

  if [ -z "${persistentVolumeClaimName}" ]; then
    persistentVolumeClaimName="${domainUID}-weblogic-sample-pvc"
  fi

  if [ -z "${weblogicCredentialsSecretName}" ]; then
    weblogicCredentialsSecretName="${domainUID}-weblogic-credentials"
  fi

  if [ "${domainHomeInImage}" == "true" ]; then
    domainPropertiesOutput="${domainOutputDir}/domain.properties"
    domainHome="/u01/oracle/user_projects/domains/${domainName}"

    if [ -z $domainHomeImageBuildPath ]; then
      domainHomeImageBuildPath="./docker-images/OracleWebLogic/samples/12213-domain-home-in-image"
    fi
 
    # Generate the properties file that will be used when creating the weblogic domain
    echo Generating ${domainPropertiesOutput}

    cp ${domainPropertiesInput} ${domainPropertiesOutput}
    sed -i -e "s:%DOMAIN_NAME%:${domainName}:g" ${domainPropertiesOutput}
    sed -i -e "s:%ADMIN_PORT%:${adminPort}:g" ${domainPropertiesOutput}
    sed -i -e "s:%ADMIN_SERVER_SSL_PORT%:${adminServerSSLPort}:g" ${domainPropertiesOutput}
    sed -i -e "s:%ADMIN_SERVER_NAME%:${adminServerName}:g" ${domainPropertiesOutput}
    sed -i -e "s:%MANAGED_SERVER_PORT%:${managedServerPort}:g" ${domainPropertiesOutput}
    sed -i -e "s:%MANAGED_SERVER_SSL_PORT%:${managedServerSSLPort}:g" ${domainPropertiesOutput}
    sed -i -e "s:%MANAGED_SERVER_NAME_BASE%:${managedServerNameBase}:g" ${domainPropertiesOutput}
    sed -i -e "s:%CONFIGURED_MANAGED_SERVER_COUNT%:${configuredManagedServerCount}:g" ${domainPropertiesOutput}
    sed -i -e "s:%CLUSTER_NAME%:${clusterName}:g" ${domainPropertiesOutput}
    sed -i -e "s:%SSL_ENABLED%:${sslEnabled}:g" ${domainPropertiesOutput}
    sed -i -e "s:%PRODUCTION_MODE_ENABLED%:${productionModeEnabled}:g" ${domainPropertiesOutput}
    sed -i -e "s:%CLUSTER_TYPE%:${clusterType}:g" ${domainPropertiesOutput}
    sed -i -e "s:%JAVA_OPTIONS%:${javaOptions}:g" ${domainPropertiesOutput}
    sed -i -e "s:%T3_CHANNEL_PORT%:${t3ChannelPort}:g" ${domainPropertiesOutput}
    sed -i -e "s:%T3_PUBLIC_ADDRESS%:${t3PublicAddress}:g" ${domainPropertiesOutput}
    sed -i -e "s:%EXPOSE_T3_CHANNEL%:${exposeAdminT3Channel}:g" ${domainPropertiesOutput}
    sed -i -e "s:%FMW_DOMAIN_TYPE%:${fmwDomainType}:g" ${domainPropertiesOutput}
    sed -i -e "s:%WDT_DOMAIN_TYPE%:${wdtDomainType}:g" ${domainPropertiesOutput}

    if [ -z "${image}" ]; then
      # calculate the internal name to tag the generated image
      defaultImageName="`basename ${domainHomeImageBuildPath} | sed 's/^[0-9]*-//'`"
      baseTag=${domainHomeImageBase#*:}
      defaultImageName=${defaultImageName}:${baseTag:-"latest"}
      sed -i -e "s|%IMAGE_NAME%|${defaultImageName}|g" ${domainPropertiesOutput}
    else 
      sed -i -e "s|%IMAGE_NAME%|${image}|g" ${domainPropertiesOutput}
    fi
  else
    # we're in the domain in PV case

    wdtVersion="${WDT_VERSION:-${wdtVersion}}"

    createJobOutput="${domainOutputDir}/create-domain-job.yaml"
    deleteJobOutput="${domainOutputDir}/delete-domain-job.yaml"

    if [ -z "${domainHome}" ]; then
      domainHome="${domainPVMountPath}/domains/${domainUID}"
    fi

    # Use the default value if not defined.
    if [ -z "${createDomainScriptsMountPath}" ]; then
      createDomainScriptsMountPath="/u01/weblogic"
    fi

    if [ -z "${createDomainScriptName}" ]; then
      createDomainScriptName="create-domain-job.sh"
    fi

    # Must escape the ':' value in image for sed to properly parse and replace
    image=$(echo ${image} | sed -e "s/\:/\\\:/g")

    # Generate the yaml to create the kubernetes job that will create the weblogic domain
    echo Generating ${createJobOutput}

    cp ${createJobInput} ${createJobOutput}
    sed -i -e "s:%NAMESPACE%:$namespace:g" ${createJobOutput}
    sed -i -e "s:%WEBLOGIC_CREDENTIALS_SECRET_NAME%:${weblogicCredentialsSecretName}:g" ${createJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE%:${image}:g" ${createJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_POLICY%:${imagePullPolicy}:g" ${createJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_NAME%:${imagePullSecretName}:g" ${createJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_PREFIX%:${imagePullSecretPrefix}:g" ${createJobOutput}
    sed -i -e "s:%DOMAIN_UID%:${domainUID}:g" ${createJobOutput}
    sed -i -e "s:%DOMAIN_NAME%:${domainName}:g" ${createJobOutput}
    sed -i -e "s:%DOMAIN_HOME%:${domainHome}:g" ${createJobOutput}
    sed -i -e "s:%SSL_ENABLED%:${sslEnabled}:g" ${createJobOutput}
    sed -i -e "s:%PRODUCTION_MODE_ENABLED%:${productionModeEnabled}:g" ${createJobOutput}
    sed -i -e "s:%ADMIN_SERVER_NAME%:${adminServerName}:g" ${createJobOutput}
    sed -i -e "s:%ADMIN_SERVER_NAME_SVC%:${adminServerNameSVC}:g" ${createJobOutput}
    sed -i -e "s:%ADMIN_PORT%:${adminPort}:g" ${createJobOutput}
    sed -i -e "s:%ADMIN_SERVER_SSL_PORT%:${adminServerSSLPort}:g" ${createJobOutput}
    sed -i -e "s:%CONFIGURED_MANAGED_SERVER_COUNT%:${configuredManagedServerCount}:g" ${createJobOutput}
    sed -i -e "s:%SOA_MANAGED_SERVER_NAME_BASE%:${soaManagedServerNameBase}:g" ${createJobOutput}
    sed -i -e "s:%OSB_MANAGED_SERVER_NAME_BASE%:${osbManagedServerNameBase}:g" ${createJobOutput}
    sed -i -e "s:%MANAGED_SERVER_NAME_BASE_SVC%:${soaManagedServerNameBaseSVC}:g" ${createJobOutput}
    sed -i -e "s:%SOA_MANAGED_SERVER_PORT%:${soaManagedServerPort}:g" ${createJobOutput}
    sed -i -e "s:%OSB_MANAGED_SERVER_PORT%:${osbManagedServerPort}:g" ${createJobOutput}
    sed -i -e "s:%SOA_MANAGED_SERVER_SSL_PORT%:${soaManagedServerSSLPort}:g" ${createJobOutput}
    sed -i -e "s:%OSB_MANAGED_SERVER_SSL_PORT%:${osbManagedServerSSLPort}:g" ${createJobOutput}
    sed -i -e "s:%T3_CHANNEL_PORT%:${t3ChannelPort}:g" ${createJobOutput}
    sed -i -e "s:%T3_PUBLIC_ADDRESS%:${t3PublicAddress}:g" ${createJobOutput}
    sed -i -e "s:%SOA_CLUSTER_NAME%:${soaClusterName}:g" ${createJobOutput}
    sed -i -e "s:%OSB_CLUSTER_NAME%:${osbClusterName}:g" ${createJobOutput}
    sed -i -e "s:%CLUSTER_TYPE%:${clusterType}:g" ${createJobOutput}
    sed -i -e "s:%DOMAIN_PVC_NAME%:${persistentVolumeClaimName}:g" ${createJobOutput}
    sed -i -e "s:%DOMAIN_ROOT_DIR%:${domainPVMountPath}:g" ${createJobOutput}
    sed -i -e "s:%CREATE_DOMAIN_SCRIPT_DIR%:${createDomainScriptsMountPath}:g" ${createJobOutput}
    sed -i -e "s:%CREATE_DOMAIN_SCRIPT%:${createDomainScriptName}:g" ${createJobOutput}
    sed -i -e "s:%PERSISTENCE_STORE%:${persistentStore}:g" ${createJobOutput}
    # extra entries for FMW Infra domains
    sed -i -e "s:%RCU_CREDENTIALS_SECRET_NAME%:${rcuCredentialsSecret}:g" ${createJobOutput}
    sed -i -e "s:%CUSTOM_RCUPREFIX%:${rcuSchemaPrefix}:g" ${createJobOutput}
    sed -i -e "s|%CUSTOM_CONNECTION_STRING%|${rcuDatabaseURL}|g" ${createJobOutput}
    sed -i -e "s:%EXPOSE_T3_CHANNEL_PREFIX%:${exposeAdminT3Channel}:g" ${createJobOutput}
    sed -i -e "s:%FRONTEND_HOST%:${frontEndHost}:g" ${createJobOutput}
    sed -i -e "s:%FRONTEND_PORT%:${frontEndPort}:g" ${createJobOutput}
    # entries for Istio
    sed -i -e "s:%ISTIO_PREFIX%:${istioPrefix}:g" ${createJobOutput}
    sed -i -e "s:%ISTIO_ENABLED%:${istioEnabled}:g" ${createJobOutput}
    sed -i -e "s:%ISTIO_READINESS_PORT%:${istioReadinessPort}:g" ${createJobOutput}
    sed -i -e "s:%WDT_VERSION%:${wdtVersion}:g" ${createJobOutput}

    # Generate the yaml to create the kubernetes job that will delete the weblogic domain_home folder
    echo Generating ${deleteJobOutput}

    cp ${deleteJobInput} ${deleteJobOutput}
    sed -i -e "s:%NAMESPACE%:$namespace:g" ${deleteJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE%:${image}:g" ${deleteJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_POLICY%:${imagePullPolicy}:g" ${deleteJobOutput}
    sed -i -e "s:%WEBLOGIC_CREDENTIALS_SECRET_NAME%:${weblogicCredentialsSecretName}:g" ${deleteJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_NAME%:${imagePullSecretName}:g" ${deleteJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_PREFIX%:${imagePullSecretPrefix}:g" ${deleteJobOutput}
    sed -i -e "s:%DOMAIN_UID%:${domainUID}:g" ${deleteJobOutput}
    sed -i -e "s:%DOMAIN_NAME%:${domainName}:g" ${deleteJobOutput}
    sed -i -e "s:%DOMAIN_HOME%:${domainHome}:g" ${deleteJobOutput}
    sed -i -e "s:%DOMAIN_PVC_NAME%:${persistentVolumeClaimName}:g" ${deleteJobOutput}
    sed -i -e "s:%DOMAIN_ROOT_DIR%:${domainPVMountPath}:g" ${deleteJobOutput}
  fi
  
  echo Printing domainHomeSourceType
  echo domainHomeSourceType is ${domainHomeSourceType}
  if [ "${domainHomeSourceType}" == "FromModel" ]; then
    echo domainHomeSourceType is FromModel
    # leave domainHomeSourceType to FromModel
    if [ "${logHomeOnPV}" == "true" ]; then
      logHomeOnPVPrefix="${enabledPrefix}"
    else
      logHomeOnPVPrefix="${disabledPrefix}"
    fi
  elif [ "${domainHomeInImage}" == "true" ]; then
    domainHomeSourceType="Image"
	echo domainHomeSourceType is Image
    if [ "${logHomeOnPV}" == "true" ]; then
      logHomeOnPVPrefix="${enabledPrefix}"
    else
      logHomeOnPVPrefix="${disabledPrefix}"
    fi
  else
    domainHomeSourceType="PersistentVolume"
	echo domainHomeSourceType is PV
    logHomeOnPVPrefix="${enabledPrefix}"
    logHomeOnPV=true
  fi

  # Generate the yaml file for creating the domain resource
  echo Generating ${dcrOutput}

  cp ${dcrInput} ${dcrOutput}
  sed -i -e "s:%DOMAIN_UID%:${domainUID}:g" ${dcrOutput}
  sed -i -e "s:%NAMESPACE%:$namespace:g" ${dcrOutput}
  sed -i -e "s:%DOMAIN_HOME%:${domainHome}:g" ${dcrOutput}
  sed -i -e "s:%DOMAIN_HOME_SOURCE_TYPE%:${domainHomeSourceType}:g" ${dcrOutput}
  sed -i -e "s:%WEBLOGIC_IMAGE_PULL_POLICY%:${imagePullPolicy}:g" ${dcrOutput}
  sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_PREFIX%:${imagePullSecretPrefix}:g" ${dcrOutput}
  sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_NAME%:${imagePullSecretName}:g" ${dcrOutput}
  sed -i -e "s:%WEBLOGIC_CREDENTIALS_SECRET_NAME%:${weblogicCredentialsSecretName}:g" ${dcrOutput}
  sed -i -e "s:%INCLUDE_SERVER_OUT_IN_POD_LOG%:${includeServerOutInPodLog}:g" ${dcrOutput}
  sed -i -e "s:%LOG_HOME_ON_PV_PREFIX%:${logHomeOnPVPrefix}:g" ${dcrOutput}
  sed -i -e "s:%LOG_HOME_ENABLED%:${logHomeOnPV}:g" ${dcrOutput}
  sed -i -e "s:%LOG_HOME%:${logHome}:g" ${dcrOutput}
  sed -i -e "s:%HTTP_ACCESS_LOG_IN_LOG_HOME%:${httpAccessLogInLogHome}:g" ${dcrOutput}
  sed -i -e "s:%DATA_HOME%:${dataHome}:g" ${dcrOutput}
  sed -i -e "s:%SERVER_START_POLICY%:${serverStartPolicy}:g" ${dcrOutput}
  sed -i -e "s:%JAVA_OPTIONS%:${javaOptions}:g" ${dcrOutput}
  sed -i -e "s:%DOMAIN_PVC_NAME%:${persistentVolumeClaimName}:g" ${dcrOutput}
  sed -i -e "s:%DOMAIN_ROOT_DIR%:${domainPVMountPath}:g" ${dcrOutput}

  if [ "${istioEnabled}" == "true" ]; then
      exposeAdminNodePortPrefix="${disabledPrefix}"
  fi

  sed -i -e "s:%EXPOSE_T3_CHANNEL_PREFIX%:${exposeAdminT3ChannelPrefix}:g" ${dcrOutput}
  sed -i -e "s:%EXPOSE_ANY_CHANNEL_PREFIX%:${exposeAnyChannelPrefix}:g" ${dcrOutput}
  sed -i -e "s:%EXPOSE_ADMIN_PORT_PREFIX%:${exposeAdminNodePortPrefix}:g" ${dcrOutput}
  sed -i -e "s:%ADMIN_NODE_PORT%:${adminNodePort}:g" ${dcrOutput}
  if [ "${domainType}" = "soa" -o "${domainType}" = "soaosb" -o "${domainType}" = "soab2b" -o "${domainType}" = "soaosbb2b" ]; then
    sed -i -e "s:%CLUSTER_NAME%:${soaClusterName}:g" ${dcrOutput}
  else
    sed -i -e "s:%CLUSTER_NAME%:${osbClusterName}:g" ${dcrOutput}
  fi
  sed -i -e "s:%INITIAL_MANAGED_SERVER_REPLICAS%:${initialManagedServerReplicas}:g" ${dcrOutput}
  sed -i -e "s:%ISTIO_PREFIX%:${istioPrefix}:g" ${dcrOutput}
  sed -i -e "s:%ISTIO_ENABLED%:${istioEnabled}:g" ${dcrOutput}
  sed -i -e "s:%ISTIO_READINESS_PORT%:${istioReadinessPort}:g" ${dcrOutput}
  # MII settings are used for model-in-image integration testing
  sed -i -e "s:%MII_PREFIX%:${miiPrefix}:g" ${dcrOutput}
  sed -i -e "s:%MII_CONFIG_MAP_PREFIX%:${miiConfigMapPrefix}:g" ${dcrOutput}
  sed -i -e "s:%MII_CONFIG_MAP%:${miiConfigMap}:g" ${dcrOutput}
  sed -i -e "s:%WDT_DOMAIN_TYPE%:${wdtDomainType}:g" ${dcrOutput}

  buildServerPodResources
  if [ -z "${serverPodResources}" ]; then
    sed -i -e "/%OPTIONAL_SERVERPOD_RESOURCES%/d" ${dcrOutput}
  else
    if [[ $(uname) -eq "Darwin" ]]; then
      serverPodResources=$(echo "${serverPodResources}" | sed -e 's/\\n/%NEWLINE%/g')
      sed -i -e "s:%OPTIONAL_SERVERPOD_RESOURCES%:${serverPodResources}:g" ${dcrOutput}
      sed -i -e $'s|%NEWLINE%|\\\n|g' ${dcrOutput}
    else
      sed -i -e "s:%OPTIONAL_SERVERPOD_RESOURCES%:${serverPodResources}:g" ${dcrOutput}
    fi
  fi

  if [ "${domainHomeInImage}" == "true" ]; then
 
    # now we know which image to use, update the domain yaml file
    if [ -z $image ]; then
      sed -i -e "s|%WEBLOGIC_IMAGE%|${defaultImageName}|g" ${dcrOutput}
    else
      sed -i -e "s|%WEBLOGIC_IMAGE%|${image}|g" ${dcrOutput}
    fi
  else
    sed -i -e "s:%WEBLOGIC_IMAGE%:${image}:g" ${dcrOutput}
  fi

  # Remove any "...yaml-e" and "...properties-e" files left over from running sed
  rm -f ${domainOutputDir}/*.yaml-e
  rm -f ${domainOutputDir}/*.properties-e
}

#
# Function to create a domain
# $1 - boolean value indicating the location of the domain home
#      true means domain home in image
#      false means domain home on PV
#
function createDomain_SOA {
  if [ "$#" != 1 ]; then
    fail "The function must be called with domainHomeInImage parameter."
  fi

  domainHomeInImage="${1}"
  if [ "true" != "${domainHomeInImage}" ] && [ "false" != "${domainHomeInImage}" ]; then
    fail "The value of domainHomeInImage must be true or false: ${domainHomeInImage}"
  fi

  # Setup the environment for running this script and perform initial validation checks
  initialize

  # Generate files for creating the domain
  createFiles_SOA

  # Check that the domain secret exists and contains the required elements
  validateDomainSecret

  # Validate the domain's persistent volume claim
  if [ "${doValidation}" == true ] && [ "${domainHomeInImage}" == false -o "${logHomeOnPV}" == true ]; then
    validateDomainPVC
  fi

  # Create the WebLogic domain home
  createDomainHome

  if [ "${executeIt}" = true ]; then
    createDomainResource
  fi

  # Print a summary
  printSummary
}
