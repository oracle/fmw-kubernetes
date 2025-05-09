#!/bin/bash
# Copyright (c) 2020, 2025, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#
# Report an error and fail the job
# $1 - text of error
function fail {
  echo ERROR: $1
  exit 1
}

#
# Create a folder
# $1 - path of folder to create
function createFolder {
  mkdir -m 777 -p $1
  if [ ! -d $1 ]; then
    fail "Unable to create folder $1"
  fi
}

function checkCreateDomainScript {
  if [ -f $1 ]; then
    echo The domain will be created using the script $1
  else
    fail "Could not locate the domain creation script ${1}"
  fi
}
 
function checkDomainSecret { 

  # Validate the domain secrets exist before proceeding.
  if [ ! -f /weblogic-operator/secrets/username ]; then
    fail "The domain secret /weblogic-operator/secrets/username was not found"
  fi
  if [ ! -f /weblogic-operator/secrets/password ]; then
    fail "The domain secret /weblogic-operator/secrets/password was not found"
  fi
}

function prepareDomainHomeDir { 
  # Do not proceed if the domain already exists
  local domainFolder=${DOMAIN_HOME_DIR}
  if [ -d ${domainFolder} ]; then
    fail "The create domain job will not overwrite an existing domain. The domain folder ${domainFolder} already exists"
  fi

  # Create the base folders
  createFolder ${DOMAIN_ROOT_DIR}/domains
  createFolder ${DOMAIN_LOGS_DIR}
  createFolder ${DOMAIN_ROOT_DIR}/applications
  createFolder ${DOMAIN_ROOT_DIR}/stores
}

#
# Function to generate the properties and yaml files for creating a OAM domain
#

createFiles_OAM() {

  update=false
  if [ "$#" == 1 ]; then
    echo Trying to update the domain
    update=true
  fi

  # Make sure the output directory has a copy of the inputs file.
  # The user can either pre-create the output directory, put the inputs
  # file there, and create the domain from it, or the user can put the
  # inputs file some place else and let this script create the output directory
  # (if needed) and copy the inputs file there.
  echo createFiles - valuesInputFile is ${valuesInputFile}
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
    domainHome="${domainHome:-/u01/oracle/user_projects/domains/${domainName}}"

    # Generate the properties file that will be used when creating the weblogic domain
    echo Generating ${domainPropertiesOutput} from ${domainPropertiesInput}

    cp ${domainPropertiesInput} ${domainPropertiesOutput}
    sed -i -e "s:%DOMAIN_NAME%:${domainName}:g" ${domainPropertiesOutput}
    sed -i -e "s:%DOMAIN_HOME%:${domainHome}:g" ${domainPropertiesOutput}
    sed -i -e "s:%ADMIN_PORT%:${adminPort}:g" ${domainPropertiesOutput}
    sed -i -e "s:%ADMIN_SERVER_NAME%:${adminServerName}:g" ${domainPropertiesOutput}
    sed -i -e "s:%MANAGED_SERVER_PORT%:${managedServerPort}:g" ${domainPropertiesOutput}
    sed -i -e "s:%MANAGED_SERVER_SSL_PORT%:${managedServerSSLPort}:g" ${domainPropertiesOutput}
    sed -i -e "s:%MANAGED_SERVER_NAME_BASE%:${managedServerNameBase}:g" ${domainPropertiesOutput}
    sed -i -e "s:%CONFIGURED_MANAGED_SERVER_COUNT%:${configuredManagedServerCount}:g" ${domainPropertiesOutput}
    sed -i -e "s:%CLUSTER_NAME%:${clusterName}:g" ${domainPropertiesOutput}
    sed -i -e "s:%PRODUCTION_MODE_ENABLED%:${productionModeEnabled}:g" ${domainPropertiesOutput}
    sed -i -e "s:%CLUSTER_TYPE%:${clusterType}:g" ${domainPropertiesOutput}
    sed -i -e "s;%JAVA_OPTIONS%;${javaOptions};g" ${domainPropertiesOutput}
    sed -i -e "s:%T3_CHANNEL_PORT%:${t3ChannelPort}:g" ${domainPropertiesOutput}
    sed -i -e "s:%T3_PUBLIC_ADDRESS%:${t3PublicAddress}:g" ${domainPropertiesOutput}
    sed -i -e "s:%EXPOSE_T3_CHANNEL%:${exposeAdminT3Channel}:g" ${domainPropertiesOutput}
    sed -i -e "s:%FMW_DOMAIN_TYPE%:${fmwDomainType}:g" ${domainPropertiesOutput}
    sed -i -e "s:%WDT_DOMAIN_TYPE%:${wdtDomainType}:g" ${domainPropertiesOutput}
    sed -i -e "s:%ADMIN_USER_NAME%:${username}:g" ${domainPropertiesOutput}
    sed -i -e "s:%ADMIN_USER_PASS%:${password}:g" ${domainPropertiesOutput}
    sed -i -e "s:%RCU_SCHEMA_PREFIX%:${rcuSchemaPrefix}:g" ${domainPropertiesOutput}
    sed -i -e "s:%RCU_SCHEMA_PASSWORD%:${rcuSchemaPassword}:g" ${domainPropertiesOutput}
    sed -i -e "s|%RCU_DB_CONN_STRING%|${rcuDatabaseURL}|g" ${domainPropertiesOutput}

    if [ -z "${image}" ]; then
      # calculate the internal name to tag the generated image
      defaultImageName="domain-home-in-image"
      baseTag=${domainHomeImageBase#*:}
      defaultImageName=${defaultImageName}:${baseTag:-"latest"}
      sed -i -e "s|%IMAGE_NAME%|${defaultImageName}|g" ${domainPropertiesOutput}
      export BUILD_IMAGE_TAG=${defaultImageName}
    else
      sed -i -e "s|%IMAGE_NAME%|${image}|g" ${domainPropertiesOutput}
      export BUILD_IMAGE_TAG=${image}
    fi
  else
    # we're in the domain in PV case

    wdtVersion="${WDT_VERSION:-${wdtVersion}}"
    httpsProxy="${https_proxy}"

    createJobOutput="${domainOutputDir}/create-domain-job.yaml"
    deleteJobOutput="${domainOutputDir}/delete-domain-job.yaml"

    if [ -z "${domainHome}" ]; then
      domainHome="${domainPVMountPath}/domains/${domainUID}"
    fi

    # Use the default value if not defined.
    if [ -z "${createDomainScriptsMountPath}" ]; then
      createDomainScriptsMountPath="/u01/weblogic"
    fi

    if [ "${update}" == "true" ]; then
      createDomainScriptName="update-domain-job.sh"
    elif [ -z "${createDomainScriptName}" ]; then
      createDomainScriptName="create-domain-job.sh"
    fi
    echo createDomainScriptName is ${createDomainScriptName}

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
    sed -i -e "s:%PRODUCTION_MODE_ENABLED%:${productionModeEnabled}:g" ${createJobOutput}
    sed -i -e "s:%ADMIN_SERVER_NAME%:${adminServerName}:g" ${createJobOutput}
    sed -i -e "s:%ADMIN_SERVER_NAME_SVC%:${adminServerNameSVC}:g" ${createJobOutput}
    sed -i -e "s:%ADMIN_PORT%:${adminPort}:g" ${createJobOutput}
    sed -i -e "s:%CONFIGURED_MANAGED_SERVER_COUNT%:${configuredManagedServerCount}:g" ${createJobOutput}
    sed -i -e "s:%MANAGED_SERVER_NAME_BASE%:${managedServerNameBase}:g" ${createJobOutput}
    sed -i -e "s:%MANAGED_SERVER_NAME_BASE_SVC%:${managedServerNameBaseSVC}:g" ${createJobOutput}
    sed -i -e "s:%MANAGED_SERVER_PORT%:${managedServerPort}:g" ${createJobOutput}
    sed -i -e "s:%MANAGED_SERVER_SSL_PORT%:${managedServerSSLPort}:g" ${createJobOutput}
    sed -i -e "s:%T3_CHANNEL_PORT%:${t3ChannelPort}:g" ${createJobOutput}
    sed -i -e "s:%T3_PUBLIC_ADDRESS%:${t3PublicAddress}:g" ${createJobOutput}
    sed -i -e "s:%CLUSTER_NAME%:${clusterName}:g" ${createJobOutput}
    sed -i -e "s:%CLUSTER_TYPE%:${clusterType}:g" ${createJobOutput}
    sed -i -e "s:%DOMAIN_PVC_NAME%:${persistentVolumeClaimName}:g" ${createJobOutput}
    sed -i -e "s:%DOMAIN_ROOT_DIR%:${domainPVMountPath}:g" ${createJobOutput}
    sed -i -e "s:%CREATE_DOMAIN_SCRIPT_DIR%:${createDomainScriptsMountPath}:g" ${createJobOutput}
    sed -i -e "s:%CREATE_DOMAIN_SCRIPT%:${createDomainScriptName}:g" ${createJobOutput}
    # extra entries for FMW Infra domains
    sed -i -e "s:%RCU_CREDENTIALS_SECRET_NAME%:${rcuCredentialsSecret}:g" ${createJobOutput}
    sed -i -e "s:%CUSTOM_RCUPREFIX%:${rcuSchemaPrefix}:g" ${createJobOutput}
    sed -i -e "s|%CUSTOM_CONNECTION_STRING%|${rcuDatabaseURL}|g" ${createJobOutput}
    sed -i -e "s:%EXPOSE_T3_CHANNEL_PREFIX%:${exposeAdminT3Channel}:g" ${createJobOutput}
    sed -i -e "s:%FRONTEND_HOST%:${frontEndHost}:g" ${createJobOutput}
    sed -i -e "s:%FRONTEND_PORT%:${frontEndPort}:g" ${createJobOutput}
    # entries for Istio
    sed -i -e "s:%WDT_VERSION%:${wdtVersion}:g" ${createJobOutput}
    #sed -i -e "s|%DOMAIN_TYPE%|${domain_type}|g" ${createJobOutput}
    sed -i -e "s|%PROXY_VAL%|${httpsProxy}|g" ${createJobOutput}

    # entries for AGL Datasource
    sed -i -e "s:%DATASOURCE_TYPE%:${datasourceType}:g" ${createJobOutput}

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
    if [ "${logHomeOnPV}" == "true" ]; then
      logHomeOnPVPrefix="${enabledPrefix}"
    else
      logHomeOnPVPrefix="${disabledPrefix}"
    fi
  else
    domainHomeSourceType="PersistentVolume"
    logHomeOnPVPrefix="${enabledPrefix}"
    logHomeOnPV=true
  fi

  # Generate the yaml file for creating the domain resource
  # We want to use wdt's extractDomainResource.sh to get the domain resource
  # for domain on pv use case. For others, generate domain resource here

  if [ "${domainHomeSourceType}" != "PersistentVolume" ] || [ "${wdtDomainType}" != "WLS" ] ||
         [ "${useWdt}" != true ]; then
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
    sed -i -e "s;%JAVA_OPTIONS%;${javaOptions};g" ${dcrOutput}
    sed -i -e "s:%DOMAIN_PVC_NAME%:${persistentVolumeClaimName}:g" ${dcrOutput}
    sed -i -e "s:%DOMAIN_ROOT_DIR%:${domainPVMountPath}:g" ${dcrOutput}

    if [ "${istioEnabled}" == "true" ]; then
      exposeAdminNodePortPrefix="${disabledPrefix}"
    fi

    sed -i -e "s:%EXPOSE_T3_CHANNEL_PREFIX%:${exposeAdminT3ChannelPrefix}:g" ${dcrOutput}
    sed -i -e "s:%EXPOSE_ANY_CHANNEL_PREFIX%:${exposeAnyChannelPrefix}:g" ${dcrOutput}
    sed -i -e "s:%EXPOSE_ADMIN_PORT_PREFIX%:${exposeAdminNodePortPrefix}:g" ${dcrOutput}
    sed -i -e "s:%ADMIN_NODE_PORT%:${adminNodePort}:g" ${dcrOutput}
    sed -i -e "s:%CLUSTER_NAME%:${clusterName}:g" ${dcrOutput}
    sed -i -e "s:%INITIAL_MANAGED_SERVER_REPLICAS%:${initialManagedServerReplicas}:g" ${dcrOutput}
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
  fi

  # Remove any "...yaml-e" and "...properties-e" files left over from running sed
  rm -f ${domainOutputDir}/*.yaml-e
  rm -f ${domainOutputDir}/*.properties-e

}

# Function to create a OAM domain
# $1 - boolean value indicating the location of the domain home
#      true means domain home in image
#      false means domain home on PV
#
createDomain_OAM() {
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
  createFiles_OAM

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
