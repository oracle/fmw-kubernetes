#!/usr/bin/env bash
# Copyright (c) 2021, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description
#  This sample script Deploys SOA Suite and Serivce Bus artifacts available in an existing PV/PVC into SOA Suite domain.

#  The deploy artifacts inputs can be customized by editing deploy-artifcts-inputs.yaml
#
#  The following pre-requisites must be handled prior to running this script:
#    * The SOA Suite domain must already be created and servers must be up and running.
#    * The Kubernetes secrets 'username' and 'password' of the admin account have been available in the namespace
#    * The host directory that will be used as the persistent volume must already exist
#      and have the appropriate file permissions set.
#    * The Kubernetes persistent volume must already be created
#    * The Kubernetes persistent volume claim must already be created
#

# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
runId=$(date +%Y%m%d-%H%M%S)
# source weblogic operator provided common utility scripts
source ${scriptDir}/../../common/utility.sh
source ${scriptDir}/../../common/validate.sh
# source SOA specific utility scripts
source ${scriptDir}/../utils/utility.sh
source ${scriptDir}/../utils/validate.sh

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
  deployOutputDir="${outputDir}/deploy-artifacts/${domainUID}/${runId}"
  # Create a directory for the output files
  mkdir -p ${deployOutputDir}

  removeFileIfExists ${deployOutputDir}/${valuesInputFile}
  removeFileIfExists ${deployOutputDir}/deploy-artifacts-inputs.yaml
  removeFileIfExists ${deployOutputDir}/deploy-artifacts-job.yaml
}


#
# Function to setup the environment to run the create domain job
#
function initialize {

  parseCommonInputs
  adminServerNameSVC=$(toDNS1123Legal $adminServerName)
  soaClusterNameSVC=$(toDNS1123Legal $soaClusterName)
  # Validate the required files exist
  validateErrors=false

  #validateKubectlAvailable
  validateKubernetesCLIAvailable

  if [ -z "${valuesInputFile}" ]; then
    validationError "You must use the -i option to specify the name of the inputs parameter file (a modified copy of kubernetes/create-soa-domain/domain-home-on-pv/deploy-artifacts-inputs.yaml)."
  else
    if [ ! -f ${valuesInputFile} ]; then
      validationError "Unable to locate the input parameters file ${valuesInputFile}"
    fi
  fi

  if [ -z "${outputDir}" ]; then
    validationError "You must use the -o option to specify the name of an existing directory to store the generated yaml files in."
  fi

  createJobInput="${scriptDir}/deploy-artifacts-job-template.yaml"
  if [ ! -f ${createJobInput} ]; then
    validationError "The template file ${createJobInput} for deploying artifacts to SOA domain was not found"
  fi

  failIfValidationErrors


  initOutputDir

}


function createFiles {

    copyInputsFileToOutputDirectory ${valuesInputFile} "${deployOutputDir}/deploy-artifacts-inputs.yaml"
    domainName=${domainUID}

    enabledPrefix=""     # uncomment the feature
    disabledPrefix="# "  # comment out the feature

    if [ -z "${artifactsSourceType}" ]; then
      artifactsSourceType="PersistentVolume"
    fi

    if [ -z "${weblogicCredentialsSecretName}" ]; then
      weblogicCredentialsSecretName="${domainUID}-weblogic-credentials"
    fi
    soaDeployPrefix=${disabledPrefix}
    osbDeployPrefix=${disabledPrefix}
    artifactsInPvPrefix=${disabledPrefix}
    artifactsInImagePrefix=${disabledPrefix}
    artifactsImagePullSecretPrefix=${disabledPrefix}
    weblogicImagePullSecretPrefix=${disabledPrefix}
    imagePullSecretPrefix=${disabledPrefix}
    
    if [[ $artifactsSourceType == "PersistentVolume" ]]; then
      artifactsImage=""
      artifactsInPvPrefix=${enabledPrefix}
      if [ -z "${persistentVolumeClaimName}" ]; then
        persistentVolumeClaimName="${domainUID}-deploy-artifacts-pvc"
      fi
    fi

    if [[ $artifactsSourceType == "Image" ]]; then
      validateArtifactsImagePullSecretName
      artifactsInImagePrefix=${enabledPrefix}
      if [ -z "${artifactsImage}" ]; then
        artifactsImage="artifacts:12.2.1.4"
      fi
      artifactsImage=$(echo ${artifactsImage} | sed -e "s/\:/\\\:/g")
      if [ ! -z ${artifactsImagePullSecretName} ]; then
        artifactsImagePullSecretPrefix=${enabledPrefix}    
        imagePullSecretPrefix=${enabledPrefix}
      fi
    fi

    if [[ $domainType =~ "soa" ]]; then
      soaDeployPrefix=${enabledPrefix}
    fi
    if [[ $domainType =~ "osb" ]]; then
      osbDeployPrefix=${enabledPrefix}
    fi
    createJobOutput="${deployOutputDir}/deploy-artifacts-job.yaml"
     # Use the default value if not defined.
    if [ -z "${deployScriptsMountPath}" ]; then
      deployScriptsMountPath="/u01/weblogic"
    fi
    
    if [ ! -z "${imagePullSecretName}" ]; then
      weblogicImagePullSecretPrefix=${enabledPrefix}
      imagePullSecretPrefix=${enabledPrefix}
    fi
     # Must escape the ':' value in image for sed to properly parse and replace
    image=$(echo ${image} | sed -e "s/\:/\\\:/g")
    
    # Generate the yaml to create the kubernetes job that will deploy the artifacts
    echo Generating ${createJobOutput}

    cp ${createJobInput} ${createJobOutput}
    sed -i -e "s:%NAMESPACE%:$namespace:g" ${createJobOutput}
    sed -i -e "s:%RUN_UID%:$runId:g" ${createJobOutput}
    sed -i -e "s:%WEBLOGIC_CREDENTIALS_SECRET_NAME%:${weblogicCredentialsSecretName}:g" ${createJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE%:${image}:g" ${createJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_POLICY%:${imagePullPolicy}:g" ${createJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_NAME%:${imagePullSecretName}:g" ${createJobOutput}
    sed -i -e "s:%IMAGE_PULL_SECRET_PREFIX%:${imagePullSecretPrefix}:g" ${createJobOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_PREFIX%:${weblogicImagePullSecretPrefix}:g" ${createJobOutput}
    sed -i -e "s:%DOMAIN_UID%:${domainUID}:g" ${createJobOutput}
    sed -i -e "s:%DOMAIN_NAME%:${domainName}:g" ${createJobOutput}
    sed -i -e "s:%ADMIN_SERVER_NAME_SVC%:${adminServerNameSVC}:g" ${createJobOutput}
    sed -i -e "s:%ADMIN_PORT%:${adminPort}:g" ${createJobOutput}
    sed -i -e "s:%SOA_DEPLOY_PREFIX%:${soaDeployPrefix}:g" ${createJobOutput}
    sed -i -e "s:%SOA_MANAGED_SERVER_PORT%:${soaManagedServerPort}:g" ${createJobOutput}
    sed -i -e "s:%OSB_DEPLOY_PREFIX%:${osbDeployPrefix}:g" ${createJobOutput}
    sed -i -e "s:%SOA_CLUSTER_NAME%:${soaClusterNameSVC}:g" ${createJobOutput}
    sed -i -e "s:%OSB_CLUSTER_NAME%:${osbClusterName}:g" ${createJobOutput}
    sed -i -e "s:%ARCHIVES_PVC_NAME%:${persistentVolumeClaimName}:g" ${createJobOutput}
    sed -i -e "s:%DEPLOY_ARTIFACTS_SCRIPT_DIR%:${deployScriptsMountPath}:g" ${createJobOutput}
    sed -i -e "s:%DEPLOY_SCRIPT%:${deployScriptName}:g" ${createJobOutput}
    sed -i -e "s:%ARTIFACTS_IN_IMAGE_PREFIX%:${artifactsInImagePrefix}:g" ${createJobOutput}
    sed -i -e "s:%ARTIFACTS_IN_PV_PREFIX%:${artifactsInPvPrefix}:g" ${createJobOutput}
    sed -i -e "s:%ARTIFACTS_IMAGE%:${artifactsImage}:g" ${createJobOutput}
    sed -i -e "s:%ARTIFACTS_IMAGE_PULL_POLICY%:${artifactsImagePullPolicy}:g" ${createJobOutput}
    sed -i -e "s:%ARTIFACTS_IMAGE_PULL_SECRET_NAME%:${artifactsImagePullSecretName}:g" ${createJobOutput}
    sed -i -e "s:%ARTIFACTS_IMAGE_PULL_SECRET_PREFIX%:${artifactsImagePullSecretPrefix}:g" ${createJobOutput}
    sed -i -e "s:%SOA_ARTIFACTS_ARCHIVE_PATH%:${soaArtifactsArchivePath}:g" ${createJobOutput}
    sed -i -e "s:%OSB_ARTIFACTS_ARCHIVE_PATH%:${osbArtifactsArchivePath}:g" ${createJobOutput}
      # Remove any "...yaml-e" and "...properties-e" files left over from running sed
  rm -f ${deployOutputDir}/*.yaml-e
  rm -f ${deployOutputDir}/*.properties-e


}  

# create configmap using what is in the deployScriptFilesDir
function deployConfigmap {
  # Use the default files if deployScriptFilesDir is not specified
  if [ -z "${deployScriptFilesDir}" ]; then
    deployFilesDir=${scriptDir}/deploy
  elif [[ ! ${deployScriptFilesDir} == /* ]]; then
    deployFilesDir=${scriptDir}/${deployScriptFilesDir}
  fi

   
  if [[ "$domainType" =~ "soa" ]]; then
     # customize the files with domain information
     soaExternalFilesTmpDir=$deployOutputDir/soa
     mkdir -p $soaExternalFilesTmpDir
     cp ${deployScriptFilesDir}/soa/* ${soaExternalFilesTmpDir}/
     cp ${deployOutputDir}/deploy-artifacts-inputs.yaml ${soaExternalFilesTmpDir}/
     local cmName=${domainUID}-deploy-scripts-soa-job-cm
     ${KUBERNETES_CLI:-kubectl} create configmap ${cmName} -n $namespace --from-file $soaExternalFilesTmpDir --dry-run=client -o yaml | ${KUBERNETES_CLI:-kubectl} apply -f -
     echo Checking the configmap $cmName was created
     local num=`${KUBERNETES_CLI:-kubectl} get cm -n $namespace | grep ${cmName} | wc | awk ' { print $1; } '`
     if [ "$num" != "1" ]; then
       fail "The configmap ${cmName} was not created"
     fi

     ${KUBERNETES_CLI:-kubectl} label configmap ${cmName} --overwrite=true -n $namespace weblogic.domainUID=$domainUID weblogic.domainName=$domainName
     rm -rf $soaExternalFilesTmpDir
  fi
 
  if [[ "$domainType" =~ "osb" ]]; then
     # customize the files with domain information
     osbExternalFilesTmpDir=$deployOutputDir/osb
     mkdir -p $osbExternalFilesTmpDir
     cp ${deployScriptFilesDir}/osb/* ${osbExternalFilesTmpDir}/
     cp ${deployOutputDir}/deploy-artifacts-inputs.yaml ${osbExternalFilesTmpDir}/
     local cmName=${domainUID}-deploy-scripts-osb-job-cm
     ${KUBERNETES_CLI:-kubectl} create configmap ${cmName} -n $namespace --from-file $osbExternalFilesTmpDir --dry-run=client -o yaml | ${KUBERNETES_CLI:-kubectl} apply -f -
     echo Checking the configmap $cmName was created
     local num=`${KUBERNETES_CLI:-kubectl} get cm -n $namespace | grep ${cmName} | wc | awk ' { print $1; } '`
     if [ "$num" != "1" ]; then
       fail "The configmap ${cmName} was not created"
     fi

     ${KUBERNETES_CLI:-kubectl} label configmap ${cmName} --overwrite=true -n $namespace weblogic.domainUID=$domainUID weblogic.domainName=$domainName
     rm -rf $osbExternalFilesTmpDir
  fi
}


# Clean up the configmaps after deployments
function cleanUpConfigMaps {
 
 if [[ "$domainType" =~ "soa" ]]; then
     local cmName=${domainUID}-deploy-scripts-soa-job-cm
     ${KUBERNETES_CLI:-kubectl} delete configmap ${cmName} -n $namespace
 fi

 if [[ "$domainType" =~ "osb" ]]; then
     local cmName=${domainUID}-deploy-scripts-osb-job-cm
     ${KUBERNETES_CLI:-kubectl} delete configmap ${cmName} -n $namespace
 fi

}

function startDeployArtifacts {
  # Setup the environment for running this script and perform initial validation checks
  initialize

  # Generate files for creating the domain
  createFiles

  # Check that the domain secret exists and contains the required elements
  validateDomainSecret

  # Validate the persistent volume claim
  if [ "${doValidation}" == true ] && [ "${artifactsSourceType}" == "PersistentVolume" ]; then
    validateArtifactsPVC
  fi

  # Deploy the artifacts
  deployArtifacts

  # cleanup the configmaps which holds the deployment scripts
  cleanUpConfigMaps

  # Print a summary
  printSummary

}

function checkForErrors {
  
  domain=$1
  CONTAINER_NAME_SUFFIX="deploy-artifacts-job"
  JOB_NAME="${domainUID}-${CONTAINER_NAME_SUFFIX}-${runId}"
  CONTAINER_NAME="${domain}-${CONTAINER_NAME_SUFFIX}"
  CONTAINER_ERRORS=`${KUBERNETES_CLI:-kubectl} logs jobs/${JOB_NAME} ${CONTAINER_NAME} -n ${namespace} | grep "ERROR:" `
  CONTAINER_ERR_COUNT=`echo ${CONTAINER_ERRORS} | grep "ERROR:" | wc | awk ' {print $1; }'`
      if [ "$CONTAINER_ERR_COUNT" != "0" ]; then
        echo "A failure was detected in the log file for job ${JOB_NAME}."
        echo "$CONTAINER_ERRORS"
        echo "Check the log output for additional information."
        fail "Exiting due to failure - the job has failed!"
      fi

}
#
# Function to run the job that deploy the artifacts
#
function deployArtifacts {

  # create the config map for the job
  deployConfigmap

  # There is no way to re-run a kubernetes job, so first delete any prior job
  CONTAINER_NAME_SUFFIX="deploy-artifacts-job"
  JOB_NAME="${domainUID}-${CONTAINER_NAME_SUFFIX}-${runId}"
  if [[ $domainType =~ "soa" ]]; then
    SOA_CONTAINER_NAME="soa-${CONTAINER_NAME_SUFFIX}"
  fi
  if [[ $domainType =~ "osb" ]]; then
    OSB_CONTAINER_NAME="osb-${CONTAINER_NAME_SUFFIX}"
  fi

  deleteK8sObj job $JOB_NAME ${createJobOutput}

  echo Deploying artifacts by creating the job ${createJobOutput}
  ${KUBERNETES_CLI:-kubectl} create -f ${createJobOutput}

  echo "Waiting for the job to complete..."
  JOB_STATUS="0"
  max=`expr ${timeout} / 30`
  count=0
  while [ "$JOB_STATUS" != "Completed" -a $count -lt $max ] ; do
    sleep 30
    count=`expr $count + 1`
    JOBS=`${KUBERNETES_CLI:-kubectl} get pods -n ${namespace} | grep ${JOB_NAME}`
    JOB_STATUS=`echo $JOBS | awk ' { print $3; } '`
    JOB_INFO=`echo $JOBS | awk ' { print "pod", $1, "status is", $3; } '`
    echo "status on iteration $count of $max for $domainUID"
    echo "$JOB_INFO"
    # Terminate the retry loop when a fatal error has already occurred.  Search for "ERROR:" in the job log file
    if [ "$JOB_STATUS" != "Completed" ]; then
       if [[ $domainType =~ "soa" ]]; then
          checkForErrors "soa"
       fi
       if [[ $domainType =~ "osb" ]]; then
           checkForErrors "osb"
       fi
    fi
  done

  # Confirm the job pod is status completed
  if [ "$JOB_STATUS" != "Completed" ]; then
    echo "The deploy artifacts job is not showing status completed after waiting ${timeout} seconds."
    echo "Check the log output for errors."
    if [[ $domainType =~ "soa" ]]; then
       ${KUBERNETES_CLI:-kubectl} logs jobs/$JOB_NAME $SOA_CONTAINER_NAME -n ${namespace}
    fi
    if [[ $domainType =~ "osb" ]]; then
       ${KUBERNETES_CLI:-kubectl} logs jobs/$JOB_NAME $OSB_CONTAINER_NAME -n ${namespace}
    fi
    fail "Exiting due to failure - the job status is not Completed!"
  fi

  # Check for successful completion in log file
  JOB_POD=`${KUBERNETES_CLI:-kubectl} get pods -n ${namespace} | grep ${JOB_NAME} | awk ' { print $1; } '`
  if [[ $domainType =~ "soa" ]]; then
     SOA_JOB_STS=`${KUBERNETES_CLI:-kubectl} logs jobs/$JOB_NAME $SOA_CONTAINER_NAME -n ${namespace} | grep "Successfully Completed" | awk ' { print $1; } '`
     if [ "${SOA_JOB_STS}" != "Successfully" ]; then
        echo The log file for the deploy artifacts job does not contain a successful completion status
        echo Check the log output for errors
        ${KUBERNETES_CLI:-kubectl} logs jobs/$JOB_NAME $SOA_CONTAINER_NAME -n ${namespace}
        deployFail="true"
     fi
  fi
  if [[ $domainType =~ "osb" ]]; then
     OSB_JOB_STS=`${KUBERNETES_CLI:-kubectl} logs jobs/$JOB_NAME $OSB_CONTAINER_NAME -n ${namespace} | grep "Successfully Completed" | awk ' { print $1; } '`
     if [ "${OSB_JOB_STS}" != "Successfully" ]; then
        echo The log file for the deploy artifacts job does not contain a successful completion status
        echo Check the log output for errors
        ${KUBERNETES_CLI:-kubectl} logs jobs/$JOB_NAME $OSB_CONTAINER_NAME -n ${namespace}
        deployFail="true"
     fi
  fi
  if [[ $deployFail == "true" ]]; then
    fail "Exiting due to failure - the job log file does not contain a successful completion status!"
  fi
}

#
# Function to output to the console a summary of the work completed
#

function printSummary {

  echo "The following files were generated:"
  echo "  ${deployOutputDir}/deploy-artifacts-inputs.yaml"
  echo "  ${createJobOutput}"
  echo "  ${dcrOutput}"
  echo ""
  echo "Completed"
}

# Perform the sequence of steps to deploy the artifacts
startDeployArtifacts


