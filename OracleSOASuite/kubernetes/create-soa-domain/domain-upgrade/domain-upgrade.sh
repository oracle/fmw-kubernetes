#!/usr/bin/env bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description
#  This sample script to upgrade SOA Suite domain

# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
runId=$(date +%Y%m%d-%H%M%S)
# source weblogic operator provided common utility scripts
source ${scriptDir}/../../common/utility.sh
source ${scriptDir}/../../common/validate.sh
source ${scriptDir}/scripts/utils.sh

function usage {
  echo usage: ${script} -o dir -i file [-v] [-t] [-h]
  echo "  -i Parameter inputs file, must be specified."
  echo "  -o Output directory for the generated yaml files, must be specified."
  echo "  -v Validate the existence of persistentVolumeClaim, optional."
  echo "  -t Timeout (in seconds) for deploy artifacts job execution, optional."
  echo "  -h Help"
  exit $1
}

#
# Parse the command line options
#
doValidation=false
timeout=600
while getopts "vhi:o:t:" opt; do
  case $opt in
    i) valuesInputFile="${OPTARG}"
    ;;
    o) outputDir="${OPTARG}"
    ;;
    v) doValidation=true
    ;;
    t) timeout="${OPTARG}"
    ;;
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done

if [ -z ${valuesInputFile} ]; then
  echo "${script}: -i must be specified."
  missingRequiredOption="true"
fi

if [ -z ${outputDir} ]; then
  echo "${script}: -o must be specified."
  missingRequiredOption="true"
fi

if [ "${missingRequiredOption}" == "true" ]; then
  usage 1
fi

if [ -z ${timeout} ]; then
  timeout=600
fi

#
# Function to initialize and validate the output directory
# for the generated yaml files for this domain.
#
function initOutputDir {
  domainUpgradeOutputDir="${outputDir}/domain-upgrade/${domainUID}/${runId}"
  # Create a directory for the output files
  mkdir -p ${domainUpgradeOutputDir}

  removeFileIfExists ${domainUpgradeOutputDir}/${valuesInputFile}
  removeFileIfExists ${domainUpgradeOutputDir}/domain-upgrade-inputs.yaml
  removeFileIfExists ${domainUpgradeOutputDir}/domain-upgrade-pod.yaml
}


#
# Function to setup the environment to run the create domain job
#
function initialize {

  parseCommonInputs

  
  # Validate the required files exist
  validateErrors=false

  #validateKubectlAvailable
  validateKubernetesCLIAvailable

  if [ -z "${valuesInputFile}" ]; then
    validationError "You must use the -i option to specify the name of the inputs parameter file (a modified copy of domain-upgrade-inputs.yaml)."
  else
    if [ ! -f ${valuesInputFile} ]; then
      validationError "Unable to locate the input parameters file ${valuesInputFile}"
    fi
  fi

  if [ -z "${outputDir}" ]; then
    validationError "You must use the -o option to specify the name of an existing directory to store the generated yaml files in."
  fi

  createPodInput="${scriptDir}/template/domain-upgrade-pod.yaml.template"
  if [ ! -f ${createPodInput} ]; then
    validationError "The template file ${createPodInput} for domain upgrade was not found"
  fi

  failIfValidationErrors


  initOutputDir

}

function createFiles {

    copyInputsFileToOutputDirectory ${valuesInputFile} "${domainUpgradeOutputDir}/domain-upgrade-inputs.yaml"

    enabledPrefix=""     # uncomment the feature
    disabledPrefix="# "  # comment out the feature

    if [ -z "${weblogicCredentialsSecretName}" ]; then
      weblogicCredentialsSecretName="${domainUID}-weblogic-credentials"
    fi
	
    weblogicImagePullSecretPrefix=${disabledPrefix}    
    
    createPodOutput="${domainUpgradeOutputDir}/domain-upgrade-pod.yaml"
     
    if [ ! -z "${imagePullSecretName}" ]; then
      weblogicImagePullSecretPrefix=${enabledPrefix}
    fi
     # Must escape the ':' value in image for sed to properly parse and replace
    image=$(echo ${image} | sed -e "s/\:/\\\:/g")
     
    # Generate the yaml to create the kubernetes job that will deploy the artifacts
    echo Generating ${createPodOutput}
    
    setDefaultInputValues

    cp ${createPodInput} ${createPodOutput}
    sed -i -e "s:%NAMESPACE%:$namespace:g" ${createPodOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE%:${image}:g" ${createPodOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_POLICY%:${imagePullPolicy}:g" ${createPodOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_NAME%:${imagePullSecretName}:g" ${createPodOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_PREFIX%:${weblogicImagePullSecretPrefix}:g" ${createPodOutput}
    sed -i -e "s:%DOMAIN_UID%:${domainUID}:g" ${createPodOutput}
    sed -i -e "s:%DOMAIN_HOME%:${domainHome}:g" ${createPodOutput}
    sed -i -e "s:%DOMAIN_NAME%:${domainName}:g" ${createPodOutput}
    sed -i -e "s:%DOMAIN_ROOT_DIR%:${domainPVMountPath}:g" ${createPodOutput}
    sed -i -e "s:%DOMAIN_PVC_NAME%:${persistentVolumeClaimName}:g" ${createPodOutput}
    sed -i -e "s:%RCU_CREDENTIALS_SECRET_NAME%:${rcuCredentialsSecret}:g" ${createPodOutput}	
    sed -i -e "s:%RCUPREFIX%:${rcuSchemaPrefix}:g" ${createPodOutput}	
    sed -i -e "s|%CONNECTION_STRING%|${rcuDatabaseURL}|g" ${createPodOutput}	
    sed -i -e "s:%DOMAIN_TYPE%:${domainType}:g" ${createPodOutput}
    sed -i -e "s:%SECURE_ENABLED%:${secureEnabled}:g" ${createPodOutput}
    
      # Remove any "...yaml-e" and "...properties-e" files left over from running sed
  rm -f ${domainUpgradeOutputDir}/*.yaml-e
  rm -f ${domainUpgradeOutputDir}/*.properties-e

}  

# create configmap with scripts required for configuring custom keystores
function createScriptConfigmap {
   ScriptsConfigmapDir=${scriptDir}/scripts
   ScriptsConfigmapTmpDir=$domainUpgradeOutputDir/scripts
   mkdir -p $ScriptsConfigmapTmpDir
   cp ${ScriptsConfigmapDir}/domainUpgrade.sh ${ScriptsConfigmapTmpDir}/
   cp ${ScriptsConfigmapDir}/domainUpgrade.py ${ScriptsConfigmapTmpDir}/
   cp ${ScriptsConfigmapDir}/secureDomain.py ${ScriptsConfigmapTmpDir}/
   cp ${ScriptsConfigmapDir}/domainUpgradeResponse.txt.template ${ScriptsConfigmapTmpDir}/domainUpgradeResponse.txt
   local cmName=${domainUID}-domain-upgrade-pod-cm
   ${KUBERNETES_CLI:-kubectl} create configmap ${cmName} -n $namespace --from-file $ScriptsConfigmapTmpDir --dry-run=client -o yaml | ${KUBERNETES_CLI:-kubectl} apply -f -
   
   echo Checking the configmap $cmName was created
   local num=`${KUBERNETES_CLI:-kubectl} get cm -n $namespace | grep ${cmName} | wc | awk ' { print $1; } '`
   if [ "$num" != "1" ]; then
     fail "The configmap ${cmName} was not created"
   fi
   
   ${KUBERNETES_CLI:-kubectl} label configmap ${cmName} --overwrite=true -n $namespace weblogic.domainUID=$domainUID weblogic.domainName=$domainName
   rm -rf $ScriptsConfigmapTmpDir  
}



function createDomainUpgradePod {
   currPodName=$1
   PodName1=`${KUBERNETES_CLI:-kubectl} get po -n ${namespace} | grep "^domain-upgrade " | cut -f1 -d " " `
   if [ "$podName1" = "$currPodName" ]; then
       echo "[INFO] Pod already exists. Skipping creation."
   else
     createFiles
     createScriptConfigmap
     ${KUBERNETES_CLI:-kubectl} delete po ${podName} -n ${namespace} --ignore-not-found
     ${KUBERNETES_CLI:-kubectl} apply -f ${createPodOutput}
   fi
   checkPod $podName $namespace # exits non zero non error
   checkPodState $podName $namespace "1/1" # exits non zero on error
   sleep 5
   ${KUBERNETES_CLI:-kubectl} get po/${podName} -n $namespace
   echo "[INFO] Pod '${podName}' is running in namespace '$namespace'"
}



initialize
domainName=${domainUID}
imageName=${image}
echo "Stopping the domain before proceeding with upgrade"
${scriptDir}/scripts/stopDomain.sh -d ${domainName} -n ${namespace}
echo "Waiting for ${domainName} to be completely down ...."
${scriptDir}/scripts/waitForDomain.sh -n ${namespace} -d ${domainName} -p 0 -i
sleep 10
echo "Starting with domain uprade for ${domainName}"
podName="${domainUID}-domain-upgrade"
createDomainUpgradePod $podName
${KUBERNETES_CLI:-kubectl} exec -n $namespace -i $podName -- /bin/bash /u01/scripts/domainUpgrade.sh
echo "Removing the temporary pod ${podName} created for configuration."
${KUBERNETES_CLI:-kubectl} delete po ${podName} -n ${namespace} --ignore-not-found
echo "Updating the domain ${domainName} with image ${imageName}...."
sleep 10
${KUBERNETES_CLI:-kubectl} patch domain ${domainName} -n ${namespace} --type=merge -p '{"spec":{"image":"'${imageName}'"}}'
echo "Starting the upgraded domain ...."
${scriptDir}/scripts/startDomain.sh -n ${namespace} -d ${domainName}
${scriptDir}/scripts/waitForDomain.sh -n ${namespace} -d ${domainName} -p Completed -i
echo "Domain upgrade completed. Review the console logs for any errors."
echo "Schema upgrade logs are available for review at domain home - ${domainHome}/ua_logs"

