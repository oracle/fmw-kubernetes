#!/usr/bin/env bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Description
#  This sample script to configure the OracleWebCenterContent Domain with custom trust keystore

# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
runId=$(date +%Y%m%d-%H%M%S)
# source weblogic operator provided common utility scripts
source ${scriptDir}/../common/utility.sh
source ${scriptDir}/../common/validate.sh

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
  custkeystoreOutputDir="${outputDir}/custom-keystore/${domainUID}/${runId}"
  # Create a directory for the output files
  mkdir -p ${custkeystoreOutputDir}

  removeFileIfExists ${custkeystoreOutputDir}/${valuesInputFile}
  removeFileIfExists ${custkeystoreOutputDir}/custom-keystore-inputs.yaml
  removeFileIfExists ${custkeystoreOutputDir}/configure-custom-keystore-pod.yaml
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
    validationError "You must use the -i option to specify the name of the inputs parameter file (a modified copy of kubernetes/custom-keystore/custom-keystore-inputs.yaml)."
  else
    if [ ! -f ${valuesInputFile} ]; then
      validationError "Unable to locate the input parameters file ${valuesInputFile}"
    fi
  fi

  if [ -z "${outputDir}" ]; then
    validationError "You must use the -o option to specify the name of an existing directory to store the generated yaml files in."
  fi

  createPodInput="${scriptDir}/template/configure-custom-keystore-pod.yaml.template"
  if [ ! -f ${createPodInput} ]; then
    validationError "The template file ${createPodInput} for configuring custom keystore to OracleWebCenterContent domain was not found"
  fi

  failIfValidationErrors


  initOutputDir

}


function createFiles {

    copyInputsFileToOutputDirectory ${valuesInputFile} "${custkeystoreOutputDir}/custom-keystore-inputs.yaml"
    domainName=${domainUID}
    adminSecurePort="9002"

    enabledPrefix=""     # uncomment the feature
    disabledPrefix="# "  # comment out the feature

    if [ -z "${weblogicCredentialsSecretName}" ]; then
      weblogicCredentialsSecretName="${domainUID}-weblogic-credentials"
    fi
	
    weblogicImagePullSecretPrefix=${disabledPrefix}    
    
    createPodOutput="${custkeystoreOutputDir}/configure-custom-keystore-pod.yaml"
     
    if [ ! -z "${imagePullSecretName}" ]; then
      weblogicImagePullSecretPrefix=${enabledPrefix}
    fi
     # Must escape the ':' value in image for sed to properly parse and replace
    image=$(echo ${image} | sed -e "s/\:/\\\:/g")
    
    if [ -z "${custKeystoreCredentialsSecretName}" ]; then
      custKeystoreCredentialsSecretName="${domainUID}-custom-keystore-credentials"
    fi
    ${KUBERNETES_CLI:-kubectl} get secret ${custKeystoreCredentialsSecretName} -n $namespace >/dev/null 2>/dev/null
    if [ $? -eq 1 ]; then
        echo "Secret ${custKeystoreCredentialsSecretName} does not exist!!!!."
        echo  "Creating secret ${custKeystoreCredentialsSecretName} with default values."
        identity_type="PKCS12"
        trust_type="PKCS12"
        identity_password="identityStorePassword"
        trust_password="trustKeyStorePassword"
        ${KUBERNETES_CLI:-kubectl} -n "$namespace" create secret generic "$custKeystoreCredentialsSecretName" \
                --from-literal=identity_type="$identity_type" \
                --from-literal=trust_type="$trust_type" \
                --from-literal=identity_password="$identity_password" \
                --from-literal=trust_password="$trust_password" 
    fi
    # Generate the yaml to create the kubernetes job that will deploy the artifacts
    echo Generating ${createPodOutput}

    cp ${createPodInput} ${createPodOutput}
    sed -i -e "s:%NAMESPACE%:$namespace:g" ${createPodOutput}
    sed -i -e "s:%WEBLOGIC_CREDENTIALS_SECRET_NAME%:${weblogicCredentialsSecretName}:g" ${createPodOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE%:${image}:g" ${createPodOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_POLICY%:${imagePullPolicy}:g" ${createPodOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_NAME%:${imagePullSecretName}:g" ${createPodOutput}
    sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_PREFIX%:${weblogicImagePullSecretPrefix}:g" ${createPodOutput}
    sed -i -e "s:%DOMAIN_UID%:${domainUID}:g" ${createPodOutput}
    sed -i -e "s:%DOMAIN_HOME%:${domainHome}:g" ${createPodOutput}
    sed -i -e "s:%DOMAIN_NAME%:${domainName}:g" ${createPodOutput}
    sed -i -e "s:%ADMIN_PORT%:${adminPort}:g" ${createPodOutput}
    sed -i -e "s:%SECURE_ENABLED%:${secureEnabled}:g" ${createPodOutput}
    sed -i -e "s:%ADMIN_SECURE_PORT%:${adminSecurePort}:g" ${createPodOutput}
    sed -i -e "s:%DOMAIN_ROOT_DIR%:${domainPVMountPath}:g" ${createPodOutput}
    sed -i -e "s:%ADMIN_SERVER_NAME%:${adminServerName}:g" ${createPodOutput}
    sed -i -e "s:%DOMAIN_PVC_NAME%:${persistentVolumeClaimName}:g" ${createPodOutput}
    sed -i -e "s:%CN_HOSTNAME%:${cnHostname}:g" ${createPodOutput}	
    sed -i -e "s:%CUSTOM_KEYSTORE_CREDENTIALS_SECRET_NAME%:${custKeystoreCredentialsSecretName}:g" ${createPodOutput}	
    sed -i -e "s:%ALIAS_PREFIX%:${aliasPrefix}:g" ${createPodOutput}	
	
	
    
      # Remove any "...yaml-e" and "...properties-e" files left over from running sed
  rm -f ${custkeystoreOutputDir}/*.yaml-e
  rm -f ${custkeystoreOutputDir}/*.properties-e


}  

# create configmap with scripts required for configuring custom keystores
function createScriptConfigmap {
   ScriptsConfigmapDir=${scriptDir}/scripts
   ScriptsConfigmapTmpDir=$custkeystoreOutputDir/scripts
   mkdir -p $ScriptsConfigmapTmpDir
   cp ${ScriptsConfigmapDir}/* ${ScriptsConfigmapTmpDir}/

   local cmName=${domainUID}-custom-keystore-pod-cm
   ${KUBERNETES_CLI:-kubectl} create configmap ${cmName} -n $namespace --from-file $ScriptsConfigmapTmpDir --dry-run=client -o yaml | ${KUBERNETES_CLI:-kubectl} apply -f -
   
   echo Checking the configmap $cmName was created
   local num=`${KUBERNETES_CLI:-kubectl} get cm -n $namespace | grep ${cmName} | wc | awk ' { print $1; } '`
   if [ "$num" != "1" ]; then
     fail "The configmap ${cmName} was not created"
   fi
   
   ${KUBERNETES_CLI:-kubectl} label configmap ${cmName} --overwrite=true -n $namespace weblogic.domainUID=$domainUID weblogic.domainName=$domainName
   rm -rf $ScriptsConfigmapTmpDir  
}



function createCustomKeystorePod {
   currPodName=$1
   PodName1=`${KUBERNETES_CLI:-kubectl} get po -n ${namespace} | grep "^configure-custom-keystore " | cut -f1 -d " " `
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


function updateJavaOptions {
  currPodName=$1
  export CUSTOM_KEYSTORE_DIR="${domainHome}/keystore/${aliasPrefix}" 
  export CUSTOM_IDEN_KEYSTORE_FILE="${CUSTOM_KEYSTORE_DIR}/identity.p12";
  export CUSTOM_TRUST_KEYSTORE_FILE="${CUSTOM_KEYSTORE_DIR}/trust.p12";
  export CUSTOM_IDEN_KEYSTORE_TYPE=$(${KUBERNETES_CLI:-kubectl} exec -n $namespace -i $currPodName -- cat /weblogic-operator/custom-keystore-secrets/identity_type)
  export CUSTOM_IDEN_KEYSTORE_PWD=$(${KUBERNETES_CLI:-kubectl} exec -n $namespace -i $currPodName -- cat /weblogic-operator/custom-keystore-secrets/identity_password);
  export CUSTOM_TRUST_KEYSTORE_TYPE=$(${KUBERNETES_CLI:-kubectl} exec -n $namespace -i $currPodName -- cat /weblogic-operator/custom-keystore-secrets/trust_type);
  export CUSTOM_TRUST_KEYSTORE_PWD=$(${KUBERNETES_CLI:-kubectl} exec -n $namespace -i $currPodName -- cat /weblogic-operator/custom-keystore-secrets/trust_password);
  javaOptions=$(${KUBERNETES_CLI:-kubectl} get domain $domainUID -n $namespace -o=jsonpath='{.spec.serverPod.env[?(@.name=="JAVA_OPTIONS")].value}')
  extraJavaOptions="-Dweblogic.http.disablehttp2=true -Djavax.net.ssl.keyStoreType=${CUSTOM_IDEN_KEYSTORE_TYPE} -Djavax.net.ssl.keyStore=${CUSTOM_IDEN_KEYSTORE_FILE} -Djavax.net.ssl.keyStorePassword=${CUSTOM_IDEN_KEYSTORE_PWD} -Djavax.net.ssl.trustStore=${CUSTOM_TRUST_KEYSTORE_FILE}  -Djavax.net.ssl.trustStorePassword=${CUSTOM_TRUST_KEYSTORE_PWD} -Dweblogic.security.SSL.trustedCAKeyStore=${CUSTOM_TRUST_KEYSTORE_FILE} -Dweblogic.security.SSL.trustedCAKeyStorePassPhrase=${CUSTOM_TRUST_KEYSTORE_PWD}"
 
  export newJavaOptions="$javaOptions $extraJavaOptions"
  ${KUBERNETES_CLI:-kubectl} patch domain $domainUID -n $namespace -p "{\"spec\":{\"serverPod\":{\"env\":[{\"name\":\"JAVA_OPTIONS\",\"value\":\"${newJavaOptions}\"}]}}}" --type=merge
}


initialize
podName="${domainUID}-configure-custom-keystore"
createCustomKeystorePod $podName
${KUBERNETES_CLI:-kubectl} exec -n $namespace -i $podName -- /bin/bash /u01/scripts/configure-custom-keystore.sh
echo "Restarting Administration server - ${adminServerName}"
${scriptDir}/scripts/restartServer.sh -s ${adminServerName} -d ${domainName} -n ${namespace}
echo "Waiting for ${adminServerName} server to up ...."
${scriptDir}/scripts/waitForDomain.sh -n ${namespace} -d ${domainName} -p Completed -i
sleep 10
${KUBERNETES_CLI:-kubectl} exec -n $namespace -i $podName -- /bin/bash /u01/scripts/update-opss-keystore.sh
sleep 10
updateJavaOptions $podName
${scriptDir}/scripts/rollDomain.sh -d ${domainName}  -n ${namespace}
echo "Waiting for domain ${domainName} server to up ...."
${scriptDir}/scripts/waitForDomain.sh -n ${namespace} -d ${domainName} -p Completed -i
echo "Removing the temporary pod ${podName} created for configuration."
${KUBERNETES_CLI:-kubectl} delete po ${podName} -n ${namespace} --ignore-not-found
echo "Custom keystore configuration completed successfully. Keystores are available in domain home at ${domainHome}/keystore/${aliasPrefix} directory."

