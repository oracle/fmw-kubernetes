#!/usr/bin/env bash
# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl
#
# Description
#  This sample script creates a Fusion Middleware Infrastructure domain home on an existing PV/PVC,
#  and generates the domain resource yaml file, which can be used to restart the Kubernetes artifacts
#  of the corresponding domain.
#
#  The domain creation inputs can be customized by editing create-domain-inputs.yaml
#
#  The following pre-requisites must be handled prior to running this script:
#    * The kubernetes namespace must already be created
#    * The kubernetes secrets 'username' and 'password' of the admin account have been created in the namespace
#    * The host directory that will be used as the persistent volume must already exist
#      and have the appropriate file permissions set.
#    * The kubernetes persistent volume must already be created
#    * The kubernetes persistent volume claim must already be created
#

# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/../../common/utility.sh
source ${scriptDir}/../../common/validate.sh

function usage {
  echo usage: ${script} -o dir -i file [-e] [-v] [-h] [-t timeout]
  echo "  -i Parameter inputs file, must be specified."
  echo "  -o Output directory for the generated yaml files, must be specified."
  echo "  -e Also create the resources in the generated yaml files, optional."
  echo "  -v Validate the existence of persistentVolumeClaim, optional."
  echo "  -t Timeout (in seconds) for create domain job execution, optional."
  echo "  -h Help"
  exit $1
}

#
# Parse the command line options
#
doValidation=false
executeIt=false
timeout=600
while getopts "evhi:o:t:" opt; do
  case $opt in
    i) valuesInputFile="${OPTARG}"
    ;;
    o) outputDir="${OPTARG}"
    ;;
    v) doValidation=true
    ;;
    e) executeIt=true 
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
  domainOutputDir="${outputDir}/weblogic-domains/${domainUID}"
  # Create a directory for this domain's output files
  mkdir -p ${domainOutputDir}

  removeFileIfExists ${domainOutputDir}/${valuesInputFile}
  removeFileIfExists ${domainOutputDir}/create-domain-inputs.yaml
  removeFileIfExists ${domainOutputDir}/create-domain-job.yaml
  removeFileIfExists ${domainOutputDir}/delete-domain-job.yaml
  removeFileIfExists ${domainOutputDir}/domain.yaml
}

#
# Function to setup the environment to run the create domain job
#
function initialize {

  # Validate the required files exist
  validateErrors=false

  #validateKubectlAvailable

  if [ -z "${valuesInputFile}" ]; then
    validationError "You must use the -i option to specify the name of the inputs parameter file (a modified copy of kubernetes/create-wcsites-domain/domain-home-on-pv/create-domain-inputs.yaml)."
  else
    if [ ! -f ${valuesInputFile} ]; then
      validationError "Unable to locate the input parameters file ${valuesInputFile}"
    fi
  fi

  if [ -z "${outputDir}" ]; then
    validationError "You must use the -o option to specify the name of an existing directory to store the generated yaml files in."
  fi

  createJobInput="${scriptDir}/create-domain-job-template.yaml"
  if [ ! -f ${createJobInput} ]; then
    validationError "The template file ${createJobInput} for creating a WebLogic domain was not found"
  fi

  deleteJobInput="${scriptDir}/delete-domain-job-template.yaml"
  if [ ! -f ${deleteJobInput} ]; then
    validationError "The template file ${deleteJobInput} for deleting a WebLogic domain was not found"
  fi

  dcrInput="${scriptDir}/../../common/domain-template.yaml"
  if [ ! -f ${dcrInput} ]; then
    validationError "The template file ${dcrInput} for creating the domain resource was not found"
  fi

  failIfValidationErrors

  validateCommonInputs

  initOutputDir
  getKubernetesClusterIP
  if [ -z "${t3PublicAddress}" ]; then
    t3PublicAddress="${K8S_IP}"
  fi
  
  if [ -z "${secureEnabled}" ]; then
    sslEnabled="false"
  fi

  if [ "${secureEnabled}" == "true" ] && [ "${productionModeEnabled}" == "true" ]; then
    sslEnabled="true"
  fi
}

# create domain configmap using what is in the createDomainFilesDir
function createDomainConfigmap {
  # Use the default files if createDomainFilesDir is not specified
  if [ -z "${createDomainFilesDir}" ]; then
    createDomainFilesDir=${scriptDir}/wlst
  elif [[ ! ${createDomainFilesDir} == /* ]]; then
    createDomainFilesDir=${scriptDir}/${createDomainFilesDir}
  fi

  # customize the files with domain information
  externalFilesTmpDir=$domainOutputDir/tmp
  mkdir -p $externalFilesTmpDir
  cp ${createDomainFilesDir}/* ${externalFilesTmpDir}/
  if [ -d "${scriptDir}/common" ]; then
    cp ${scriptDir}/common/* ${externalFilesTmpDir}/
  fi
  cp ${domainOutputDir}/create-domain-inputs.yaml ${externalFilesTmpDir}/
 
  # Set the domainName in the inputs file that is contained in the configmap.
  # this inputs file can be used by the scripts, such as WDT, that creates the WebLogic
  # domain in the job.
  echo domainName: $domainName >> ${externalFilesTmpDir}/create-domain-inputs.yaml

  if [ -f ${externalFilesTmpDir}/prepare.sh ]; then
   bash ${externalFilesTmpDir}/prepare.sh -i ${externalFilesTmpDir}
  fi
 
  
  local cmName=${domainUID}-create-fmw-infra-sample-domain-job-cm
  ${KUBERNETES_CLI:-kubectl} delete configmap ${cmName} -n $namespace

  # create the configmap and label it properly
  ${KUBERNETES_CLI:-kubectl} create configmap ${cmName} -n $namespace --from-file $externalFilesTmpDir

  echo Checking the configmap $cmName was created
  local num=`${KUBERNETES_CLI:-kubectl} get cm -n $namespace | grep ${cmName} | wc | awk ' { print $1; } '`
  if [ "$num" != "1" ]; then
    fail "The configmap ${cmName} was not created"
  fi

  ${KUBERNETES_CLI:-kubectl} label configmap ${cmName} -n $namespace weblogic.resourceVersion=domain-v2 weblogic.domainUID=$domainUID weblogic.domainName=$domainName

  rm -rf $externalFilesTmpDir
}

#
# Function to run the job that creates the domain
#
function createDomainHome {

  # create the config map for the job
  createDomainConfigmap

  # There is no way to re-run a kubernetes job, so first delete any prior job
  CONTAINER_NAME="create-fmw-infra-sample-domain-job"
  JOB_NAME="${domainUID}-${CONTAINER_NAME}"
  deleteK8sObj job $JOB_NAME ${createJobOutput}
  
   # Below code updates domain.yaml file for SOASuite domains
  # 1. Adds precreateService: true  to serverPod and cluster definitions
  # 2. Adds osb_cluster if domainType is soaosb or soaessosb
  # 3. Updates %DOMAIN_TYPE% with value in create-domain-job.yaml
  cp ${dcrOutput} ${dcrOutput}.bak
   
  #Adding Init Container configuration
  export INIT_CONTAINER="\n\    \initContainers:\n\
      - name: server-config-update\n\
        image: ${image}\n\
        env:\n\
        - name: DOMAIN_UID\n\
          value: ${domainUID}\n\
        - name: ADMIN_SERVER_NAME\n\
          value: ${adminServerName}\n\
        command: ['bash', '-c', '${domainHome}/server-config-update.sh']\n\
        volumeMounts:\n\
        - name: weblogic-domain-storage-volume\n\
          mountPath: ${domainPVMountPath}\n\
      "

  #sed -i -e "/serverPod:/a ${INIT_CONTAINER}" ${dcrOutput}
  export INIT_CONTAINER=$(echo "$INIT_CONTAINER" | sed 's/\//\\\//g')
  sed -i -e "0,/serverPod:/s//serverPod: ${INIT_CONTAINER}/"  ${dcrOutput}

  #Adding Managed Servers startup configuration
  export MANAGED_SERVERS_CALC=""
  
  for i in $(seq 1 ${configuredManagedServerCount})
  do
    if (( $i == 1 )) ; then
      MANAGED_SERVERS_CALC="- serverName: ${managedServerNameBase}$i\n\
    serverStartPolicy: \"IfNeeded\"\n\ "
    else
      MANAGED_SERVERS_CALC="${MANAGED_SERVERS_CALC} - serverName: ${managedServerNameBase}$i\n\
    serverStartPolicy: \"IfNeeded\"\n\ "
    fi
  done
  
  export MANAGED_SERVERS="\  \managedServers:"
  export MANAGED_SERVERS_CALC="${MANAGED_SERVERS}\n\  ${MANAGED_SERVERS_CALC}"
  
  #sed -i -e "/spec:/a ${MANAGED_SERVERS_CALC}" ${dcrOutput}
  sed -i "0,/spec:/s//spec:\n${MANAGED_SERVERS_CALC}/" ${dcrOutput}
  
 #Traefik Session Setting  
  if [ -z "$loadBalancerType" ]
  then
  	echo "\$loadBalancerType is empty"
  else
  	echo "\$loadBalancerType is NOT empty"
  	if [ $loadBalancerType == "traefik" ] ; then
    export LB_SETTINGS="\  clusterService:\n\
      annotations: \n\
        traefik.ingress.kubernetes.io/service.sticky.cookie: \"true\"\n\
        traefik.ingress.kubernetes.io/service.sticky.cookie.name: sticky"
    sed -i -e "/clusterName: ${clusterName}/a ${LB_SETTINGS}" ${dcrOutput}    
    fi 
  fi
 
  #Replacing LoadBalancer parameters in script file.
  sed -i -e "s:%LOAD_BALANCER_HOSTNAME%:${loadBalancerHostName}:g" ${createJobOutput}
  sed -i -e "s:%LOAD_BALANCER_PORTNUMBER%:${loadBalancerPortNumber}:g" ${createJobOutput}
  sed -i -e "s:%LOAD_BALANCER_PROTOCOL%:${loadBalancerProtocol}:g" ${createJobOutput}
  sed -i -e "s:%UNICAST_PORTNUMBER%:${unicastPort}:g" ${createJobOutput}
  sed -i -e "s:%SITES_SAMPLES%:${sitesSamples}:g" ${createJobOutput}
  
  sed -i -e "s:%SECURE_ENABLED%:${secureEnabled}:g" ${createJobOutput}

  # updating Administration ports for AdminServer and Managed Server
  sed -i -e "s:%ADMIN_ADMINISTRATION_PORT%:${adminAdministrationPort}:g" ${createJobOutput}
  sed -i -e "s:%MANAGED_SERVER_ADMINISTRATION_PORT%:${managedServerAdministrationPort}:g" ${createJobOutput} 
  
  #replacing tokens for delete-domain-job
  sed -i -e "s|%CUSTOM_CONNECTION_STRING%|${rcuDatabaseURL}|g" ${deleteJobOutput}
  sed -i -e "s:%CUSTOM_RCUPREFIX%:${rcuSchemaPrefix}:g" ${deleteJobOutput}
  sed -i -e "s:%CREATE_DOMAIN_SCRIPT_DIR%:${createDomainScriptsMountPath}:g" ${deleteJobOutput}
  sed -i -e "s:%RCU_CREDENTIALS_SECRET_NAME%:${rcuCredentialsSecret}:g" ${deleteJobOutput}
  
  echo Creating the domain by creating the job ${createJobOutput}
  ${KUBERNETES_CLI:-kubectl} create -f ${createJobOutput}

  echo "Waiting for the job to complete..."
  JOB_STATUS="0"
  max=`expr ${timeout} / 30`
  count=0
  while [ "$JOB_STATUS" != "Completed" -a $count -lt $max ] ; do
    sleep 30
    count=`expr $count + 1`
    JOBS=`${KUBERNETES_CLI:-kubectl} get pods -n ${namespace} | grep ${JOB_NAME}`
    JOB_ERRORS=`${KUBERNETES_CLI:-kubectl} logs jobs/$JOB_NAME $CONTAINER_NAME -n ${namespace} | grep "ERROR:" `
    JOB_STATUS=`echo $JOBS | awk ' { print $3; } '`
    JOB_INFO=`echo $JOBS | awk ' { print "pod", $1, "status is", $3; } '`
    echo "status on iteration $count of $max"
    echo "$JOB_INFO"

    # Terminate the retry loop when a fatal error has already occurred.  Search for "ERROR:" in the job log file
    if [ "$JOB_STATUS" != "Completed" ]; then
      ERR_COUNT=`echo $JOB_ERRORS | grep "ERROR:" | wc | awk ' {print $1; }'`
      if [ "$ERR_COUNT" != "0" ]; then
        echo "A failure was detected in the log file for job $JOB_NAME."
        echo "$JOB_ERRORS"
        echo "Check the log output for additional information."
        fail "Exiting due to failure - the job has failed!"
      fi
    fi
  done

  # Confirm the job pod is status completed
  if [ "$JOB_STATUS" != "Completed" ]; then
    echo "The create domain job is not showing status completed after waiting 300 seconds."
    echo "Check the log output for errors."
    ${KUBERNETES_CLI:-kubectl} logs jobs/$JOB_NAME $CONTAINER_NAME -n ${namespace}
    fail "Exiting due to failure - the job status is not Completed!"
  fi

  # Check for successful completion in log file
  JOB_POD=`${KUBERNETES_CLI:-kubectl} get pods -n ${namespace} | grep ${JOB_NAME} | awk ' { print $1; } '`
  JOB_STS=`${KUBERNETES_CLI:-kubectl} logs $JOB_POD $CONTAINER_NAME -n ${namespace} | grep "Successfully Completed" | awk ' { print $1; } '`
  if [ "${JOB_STS}" != "Successfully" ]; then
    echo The log file for the create domain job does not contain a successful completion status
    echo Check the log output for errors
    ${KUBERNETES_CLI:-kubectl} logs $JOB_POD $CONTAINER_NAME -n ${namespace}
    fail "Exiting due to failure - the job log file does not contain a successful completion status!"
  fi
}

#
# Function to output to the console a summary of the work completed
#
function printSummary {

  # Get the IP address of the kubernetes cluster (into K8S_IP)
  getKubernetesClusterIP

  echo ""
  echo "Domain ${domainName} was created and will be started by the WebLogic Kubernetes Operator"
  echo ""
  if [ "${exposeAdminNodePort}" = true ]; then
    echo "Administration console access is available at http://${K8S_IP}:${adminNodePort}/console"
  fi
  if [ "${exposeAdminT3Channel}" = true ]; then
    echo "T3 access is available at t3://${K8S_IP}:${t3ChannelPort}"
  fi
  echo "The following files were generated:"
  echo "  ${domainOutputDir}/create-domain-inputs.yaml"
  echo "  ${createJobOutput}"
  echo "  ${dcrOutput}"
  echo ""
  echo "Completed"
}

# Perform the sequence of steps to create a domain
createDomain false
