#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


# This sample script will read inputs from domain-inputs.yaml file and generate custom WDT metadata
# model based on defined templates. Also the script will generate domain.yaml based on user inputs
# All output files i.e. WDT model file and domain.yaml will be generated in the output folder.

# script usage:
# ./generate_wdt_models.sh -i domain-inputs.yaml -o output



# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"

# source weblogic operator provided common utility scripts
source ${scriptDir}/../../../../common/utility.sh
source ${scriptDir}/../../../../common/validate.sh


function usage {
  echo usage: ${script} -o dir -i file [-h]
  echo "  -i Parameter inputs file, must be specified."
  echo "  -o Output directory for the generated yaml files, must be specified."
  echo "  -h Help"
  exit $1
}

#
# Parse the command line options
#
while getopts "hi:o:" opt; do
  case $opt in
    i) valuesInputFile="${OPTARG}"
    ;;
    o) outputDir="${OPTARG}"
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

#
# Function to initialize and validate the output directory
# for the generated yaml files for this domain.

function initOutputDir {
  domainOutputDir="${outputDir}/weblogic-domains/${domainUID}"
  #echo $domainOutputDir
  # Create a directory for this domain's output files
  mkdir -p ${domainOutputDir}

  removeFileIfExists ${domainOutputDir}/${valuesInputFile}
  removeFileIfExists ${domainOutputDir}/domain-inputs.yaml
  removeFileIfExists ${domainOutputDir}/domain.yaml
}

#
# Function to remove a file if it exists
#
removeFileIfExists() {
  if [ -f $1 ]; then
    rm $1
  fi
}
#
# Function to parse a yaml file and generate the bash exports
# $1 - Input filename
# $2 - Output filename
parseYaml() {
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\):|\1|" \
     -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
     -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
  awk -F$fs '{
    if (length($3) > 0) {
      # javaOptions may contain tokens that are not allowed in export command
      # we need to handle it differently.
      if ($2=="javaOptions") {
        printf("%s=%s\n", $2, $3);
      } else {
        printf("export %s=\"%s\"\n", $2, $3);
      }
    }
  }' > $2
}

#
# Function to parse a properties file and generate the bash exports
# $1 - Input filename
# $2 - Output filename
parseProperties() {
  while IFS='=' read -r key value
  do
    echo "export ${key}=\"${value}\"" >> $2
  done < $1
}

#
# Function to parse the common parameter inputs file
#
parseCommonInputs() {
  exportValuesFile=$(mktemp /tmp/export-values-XXXXXXXXX.sh)
  tmpFile=$(mktemp /tmp/javaoptions_tmp-XXXXXXXXX.dat)
  parseYaml ${valuesInputFile} ${exportValuesFile}

  if [ ! -z ${valuesInputFile1} ]; then
   parseProperties ${valuesInputFile1} ${exportValuesFile}
  fi

  if [ ! -f ${exportValuesFile} ]; then
    echo Unable to locate the parsed output of ${valuesInputFile}.
    fail 'The file ${exportValuesFile} could not be found.'
  fi

  # Define the environment variables that will be used to fill in template values
  echo Input parameters being used
  cat ${exportValuesFile}
  echo

  # If we have 2 input files, we need to create a combined inputs file
  # exportsValueFile contains all the properties already
  # We just need to remove the term export from the file
  if [ ! -z ${valuesInputFile1} ]; then
    propsFile="domain.properties"
    cat ${exportValuesFile} > ${propsFile}
    sed  -i 's/export //g' ${propsFile}
    sed  -i 's/"//g' ${propsFile}
    valuesInputFile=${propsFile}
    cat ${valuesInputFile}
  fi

  # javaOptions may contain tokens that are not allowed in export command
  # we need to handle it differently.
  # we set the javaOptions variable that can be used later
  tmpStr=`grep "javaOptions" ${exportValuesFile}`
  javaOptions=${tmpStr//"javaOptions="/}

  # We exclude javaOptions from the exportValuesFile
  grep -v "javaOptions" ${exportValuesFile} > ${tmpFile}
  source ${tmpFile}

  rm ${exportValuesFile} ${tmpFile}
}

#
# Function to validate datasource input parameters type
#
function validateOAMDatasourceType {
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
# Function to validate the common input parameters for OAM
#
function validateInputs_OAM {
  sample_name=${1:-"other"}

  # Parse the common inputs file
  parseCommonInputs

  validateInputParamsSpecified \
    domainUID \
    namespace \
    version \
    datasourceType \
    domainHome \
    image \
    domainPVMountPath \
    weblogicDomainStoragePath \
    weblogicDomainStorageSize

  validateIntegerInputParamsSpecified \
    adminPort \
    initialManagedServerReplicas \
    t3ChannelPort \
    adminNodePort

  if [ ! "${sample_name}" == "fmw-domain-home-in-image" ]; then
    validateIntegerInputParamsSpecified configuredManagedServerCount
  fi

  validateBooleanInputParamsSpecified \
    productionModeEnabled \
    exposeAdminT3Channel \
    exposeAdminNodePort \
    edgInstall

  export requiredInputsVersion="create-weblogic-sample-domain-inputs-v1"
  validateVersion
  validateDomainUid
  validateNamespace
  validateAdminServerName
  validateManagedServerNameBase
  validateClusterName
  validateWeblogicCredentialsSecretName
  validateWeblogicImagePullSecretName

  validateLowerCase datasourceType
  validateOAMDatasourceType
  failIfValidationErrors

  validateWeblogicDomainStorageType
  validateWeblogicDomainStorageReclaimPolicy
  failIfValidationErrors
}

managedServerNameBase='oam_server'
policyServerNameBase='oam_policy_mgr'
oamCluster='oam_cluster'
policyCluster='policy_cluster'

server_definition_oam="            ListenPort: '@@PROP:Server.oam_server.ListenPort@@'
            CoherenceClusterSystemResource: defaultCoherenceCluster
            Cluster: <OAM_CLUSTER_NAME>
            ListenAddress: '@@ENV:DOMAIN_UID@@-@@PROP:Server.oam_server.ListenAddress@@<SERVER_COUNT>'
            NumOfRetriesBeforeMsiMode: 0
            RetryIntervalBeforeMsiMode: 1"

server_definition_policy="            ListenPort: '@@PROP:Server.oam_policy_mgr.ListenPort@@'
            CoherenceClusterSystemResource: defaultCoherenceCluster
            Cluster: <POLICY_CLUSTER_NAME>
            ListenAddress: '@@ENV:DOMAIN_UID@@-@@PROP:Server.oam_policy_mgr.ListenAddress@@<SERVER_COUNT>'
            NumOfRetriesBeforeMsiMode: 0
            RetryIntervalBeforeMsiMode: 1"
enable_admin_chanel="            NetworkAccessPoint: 
                'T3Channel': 
                    PublicPort: '@@PROP:Server.AdminServer.T3Channel.PublicPort@@' 
                    ListenPort: '@@PROP:Server.AdminServer.T3Channel.ListenPort@@' 
                    PublicAddress: '@@PROP:Server.AdminServer.T3Channel.PublicAddress@@' "
                     
function appendServers {

    for (( i = 1; i <= $configuredManagedServerCount; i++ ))
    do
        #append server definition for oam_servers
        echo -e "        ${managedServerNameBase}${i}:" >> ${outputModel}
        echo -e "${server_definition_oam}" | sed "s/<OAM_CLUSTER_NAME>/${oamCluster}/g" >> ${outputModel}
        sed -i -e "s:<OAM_SERVER_NAME>:${managedServerNameBase}${i}:g" ${outputModel}
        sed -i -e "s:<SERVER_COUNT>:${i}:g" ${outputModel}

        #append server definition for policy_servers
        echo -e "        ${policyServerNameBase}${i}:" >> ${outputModel}
        echo -e "${server_definition_policy}" | sed "s/<POLICY_CLUSTER_NAME>/${policyCluster}/g" >> ${outputModel}
        sed -i -e "s:<POLICY_SERVER_NAME>:${policyServerNameBase}${i}:g" ${outputModel}
        sed -i -e "s:<SERVER_COUNT>:${i}:g" ${outputModel}
    done
}


#validate inputs
validateInputs_OAM
#initialize directories
initOutputDir
# set template file paths
inputdomainInfoProdModel="${scriptDir}/templates/domainInfo_prod.yaml"
inputdomainInfoDevModel="${scriptDir}/templates/domainInfo_dev.yaml"
inputResouceModel="${scriptDir}/templates/resource.yaml"
inputResourceEDGMOdel="${scriptDir}/templates/resource_edg.yaml"
aglModel="${scriptDir}/templates/agl_jdbc.yaml"
topologyAdminProdModel="${scriptDir}/templates/topology_admin_prod.yaml"
topologyAdminDevModel="${scriptDir}/templates/topology_admin_dev.yaml"
outputModel="${domainOutputDir}/oam.yaml"

#copy model templates to output based on user inputs
if [ $productionModeEnabled == "true" ]; then
    cp ${inputdomainInfoProdModel} ${outputModel}
else
    cp ${inputdomainInfoDevModel} ${outputModel}
fi

if [ $edgInstall == "true" ]; then
    cat ${inputResourceEDGMOdel} >> ${outputModel}
else
    cat ${inputResouceModel} >> ${outputModel}
fi

if [ $datasourceType == "agl" ]; then
    sed -e "s/^/    /" ${aglModel} >> ${outputModel}
fi

if [ $productionModeEnabled == "true"  ]; then
    cat ${topologyAdminProdModel} >> ${outputModel}
else
    cat ${topologyAdminDevModel} >> ${outputModel}
fi

#copy property file
inputPropertyFile="${scriptDir}/templates/oam_template.properties"
outputPropertyFile="${domainOutputDir}/oam.properties"

cp ${inputPropertyFile} ${outputPropertyFile}

#replace property file values
sed -i -e "s:%ADMIN_SERVER_PORT%:${adminPort}:g" ${outputPropertyFile}

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
    echo -e "Server.AdminServer.T3Channel.PublicAddress=${t3PublicAddress}" >> ${outputPropertyFile}
    echo -e "Server.AdminServer.T3Channel.PublicPort=${t3ChannelPort}" >> ${outputPropertyFile}
    echo -e "Server.AdminServer.T3Channel.ListenPort=${t3ChannelPort}" >> ${outputPropertyFile}
    echo -e "${enable_admin_chanel}" >> ${outputModel}
else
    exposeAdminT3ChannelPrefix="${disabledPrefix}"
fi

if [ "${exposeAdminNodePort}" = true ]; then
    exposeAdminNodePortPrefix="${enabledPrefix}"
    exposeAnyChannelPrefix="${enabledPrefix}"
else
    exposeAdminNodePortPrefix="${disabledPrefix}"
fi


# call function to append server definitions based on user inputs
appendServers

# copy ang generate domain.yaml from sample domain template
inputDomainYaml="${scriptDir}/templates/domain-template.yaml"
outputDomainYaml="${domainOutputDir}/domain.yaml"
cp ${inputDomainYaml} ${outputDomainYaml}


if [ "${weblogicDomainStorageType}" == "NFS" ]; then
    hostPathPrefix="${disabledPrefix}"
    nfsPrefix="${enabledPrefix}"
    sed -i -e "s:%SAMPLE_STORAGE_NFS_SERVER%:${weblogicDomainStorageNFSServer}:g" ${outputDomainYaml}
else
    hostPathPrefix="${enabledPrefix}"
    nfsPrefix="${disabledPrefix}"
fi

# For some parameters, use the default value if not defined.
# if [ -z "${domainPVMountPath}" ]; then
# domainPVMountPath="/shared"
# fi

if [ -z "${logHome}" ]; then
    logHome="${domainPVMountPath}/logs/${domainUID}"
fi



# Must escape the ':' value in image for sed to properly parse and replace
image=$(echo ${image} | sed -e "s/\:/\\\:/g")
sed -i -e "s:%NAMESPACE%:${namespace}:g" ${outputDomainYaml}
sed -i -e "s:%SAMPLE_STORAGE_PATH%:${weblogicDomainStoragePath}:g" ${outputDomainYaml}
sed -i -e "s:%SAMPLE_STORAGE_RECLAIM_POLICY%:${weblogicDomainStorageReclaimPolicy}:g" ${outputDomainYaml}
sed -i -e "s:%SAMPLE_STORAGE_SIZE%:${weblogicDomainStorageSize}:g" ${outputDomainYaml}
sed -i -e "s:%HOST_PATH_PREFIX%:${hostPathPrefix}:g" ${outputDomainYaml}
sed -i -e "s:%NFS_PREFIX%:${nfsPrefix}:g" ${outputDomainYaml}
sed -i -e "s:%DOMAIN_UID%:${domainUID}:g" ${outputDomainYaml}
sed -i -e "s:%DOMAIN_HOME%:${domainHome}:g" ${outputDomainYaml}
sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_PREFIX%:${imagePullSecretPrefix}:g" ${outputDomainYaml}
sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_NAME%:${imagePullSecretName}:g" ${outputDomainYaml}
sed -i -e "s:%LOG_HOME%:${logHome}:g" ${outputDomainYaml}
sed -i -e "s:%NAMESPACE%:${namespace}:g" ${outputDomainYaml}
sed -i -e "s:%IMAGE_PULL_POLICY%:${imagePullPolicy}:g" ${outputDomainYaml}
sed -i -e "s:%INCLUDE_SERVER_OUT_IN_POD_LOG%:${includeServerOutInPodLog}:g" ${outputDomainYaml}
sed -i -e "s:%OAM_IMAGE%:${image}:g" ${outputDomainYaml}
sed -i -e "s:%JAVA_OPTIONS%:${javaOptions}:g" ${outputDomainYaml}
sed -i -e "s:%STORAGE_SIZE%:${weblogicDomainStorageSize}:g" ${outputDomainYaml}
sed -i -e "s:%DOMAIN_ROOT_DIR%:${domainPVMountPath}:g" ${outputDomainYaml}
sed -i -e "s:%INITIAL_MANAGED_SERVER_REPLICAS%:${initialManagedServerReplicas}:g" ${outputDomainYaml}
sed -i -e "s:%OAMSERVER_JAVA_PARAMS%:${oamServerJavaParams}:g" ${outputDomainYaml}
sed -i -e "s:%POLICYSERVER_JAVA_PARAMS%:${policyServerJavaParams}:g" ${outputDomainYaml}
sed -i -e "s:%OAM_MAX_CPU%:${oamMaxCPU}:g" ${outputDomainYaml}
sed -i -e "s:%OAM_MAX_MEMORY%:${oamMaxMemory}:g" ${outputDomainYaml}
sed -i -e "s:%OAM_CPU%:${oamCPU}:g" ${outputDomainYaml}
sed -i -e "s:%OAM_MEMORY%:${oamMemory}:g" ${outputDomainYaml}


sed -i -e "s:%EXPOSE_T3_CHANNEL_PREFIX%:${exposeAdminT3ChannelPrefix}:g" ${outputDomainYaml}
sed -i -e "s:%EXPOSE_ANY_CHANNEL_PREFIX%:${exposeAnyChannelPrefix}:g" ${outputDomainYaml}
sed -i -e "s:%EXPOSE_ADMIN_PORT_PREFIX%:${exposeAdminNodePortPrefix}:g" ${outputDomainYaml}
sed -i -e "s:%ADMIN_NODE_PORT%:${adminNodePort}:g" ${outputDomainYaml}

# Remove any "...yaml-e" files left over from running sed
rm -f ${domainOutputDir}/*.yaml-e

echo "WDT model file, property file and sample domain.yaml are genereted successfully at ${domainOutputDir}"
