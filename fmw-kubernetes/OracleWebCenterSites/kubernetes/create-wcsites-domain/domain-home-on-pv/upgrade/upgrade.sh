#!/usr/bin/env bash

# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl


# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"

#
# Function to exit and print an error message
# $1 - text of message
function fail {
  printError $*
  exit 1
}

# Function to print an error message
function printError {
  echo [ERROR] $*
}


#
# Function to remove a file if it exists 
#
function removeFileIfExists {
  echo "input is $1"
  if [ -f $1 ]; then
    rm -f $1
  fi
}


#
# Function to parse a yaml file and generate the bash exports
# $1 - Input filename
# $2 - Output filename
function parseYaml {
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

function usage {
  echo usage: ${script} -o dir -i file [-v] [-h]
  echo "  -i Parameter inputs file, must be specified."
  echo "  -o Output directory for the generated properties and YAML files, must be specified."
  echo "  -h Help"
  exit $1
}


#Parse the inputs
while getopts "hi:o:" opt; do
  case $opt in
    i) valuesInputFile="${OPTARG}"
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

if [ "${missingRequiredOption}" == "true" ]; then
  usage 1
fi


exportValuesFile="/tmp/export-values.sh"
parseYaml ${valuesInputFile} ${exportValuesFile}


source ${exportValuesFile}
rm ${exportValuesFile}
#Initialze response file creation



#Getting pod names from input
managedpodname=`echo ${managedServerNameBase}|sed -e 's/\(.*\)/\L\1/'|sed -e 's/_/-/g'`
adminpodname=`echo ${adminServerName}|sed -e 's/\(.*\)/\L\1/'|sed -e 's/_/-/g'`
echo ${managedpodname}
echo ${adminpodname}



#Starting image upgrade
#IMG_PATCH_CMD="kubectl patch domain ${domainUID} -n ${namespace} --type merge  -p '{\"spec\":{\"image\":\"${image}\"}}'"
IMG_PATCH_CMD="kubectl patch domain ${domainUID} -n ${namespace} --type='json' -p='[{\"op\": \"replace\", \"path\": \"/spec/image\", \"value\": \"${image}\" },{\"op\": \"replace\", \"path\": \"/spec/serverPod/initContainers/0/image\", \"value\": \"${image}\" }]'";
eval ${IMG_PATCH_CMD}

echo "Binary Upgrade in progress..."
echo "Please wait until all servers gets restarted......"

echo "Waiting for ${adminServerName} to run with upgraded binary...."
POD_STATUS="0"
max=30 #increasing max count to handle scenario when WCS image needs to be pulled which may take 6+ minutes
count=0

#Wait for Admin Server restart with new image
 while [ "$POD_STATUS" != "True" -a $count -lt $max ] ; do
    sleep 30
    count=`expr $count + 1`
    POD_STATUS=`kubectl describe pod ${domainUID}-${adminpodname} -n ${namespace}|grep  ContainersReady| awk ' { print $2; } '`
    echo "  status on iteration $count of $max: ${adminpodname} Ready:$POD_STATUS"
 done
 if [ "$POD_STATUS" != "True" ]; then
    POD_ERRORS=`kubectl logs ${domainUID}-${adminpodname} -n ${namespace}| grep -i "error"`
    echo "${adminServerName} not started after timeout of 900 secs"
    echo "A failure was detected in the log file for pod ${domainUID}-${adminpodname}"
    echo "$POD_ERRORS"
    echo "Check the log output for additional information."
    fail "Exiting due to failure - the job has failed!"
 else
  echo "${adminServerName} started successfully"
 fi
echo "Now waiting for Managed servers to run with upgraded binary...."
POD_COUNT=0
max=$((managedServerRunning*30)) #increasing max count to handle scenario when WCS image needs to be pulled which may take 6+ minutes
count=0

#Wait for Managed Servers restart with new image
while [ $POD_COUNT -ne $managedServerRunning  -a $count -lt $max ] ; do
   echo "Waiting for restarting $managedServerRunning managed servers"
   sleep 30
   count=`expr $count + 1`
   m_count=0
   for (( i=1; i<=$managedServerRunning; i++)); do
      POD_IMAGE=`kubectl describe pod ${domainUID}-${managedpodname}$i  -n ${namespace}| grep "Image:" | head -1 | awk ' { print $2; }'`
      POD_STATUS=`kubectl describe pod ${domainUID}-${managedpodname}$i  -n ${namespace}|grep  ContainersReady| awk ' { print $2; } '`
      echo "  status on iteration $count of $max: ${managedpodname}$i Ready:$POD_STATUS"
      if [[ $POD_IMAGE == ${image} && $POD_STATUS == "True" ]]; then
         m_count=$((m_count+1))
      fi 
   done
   POD_COUNT=$m_count
done
if [ $POD_COUNT -ne $managedServerRunning ]; then
   for (( i=1; i<=$managedServerRunning; i++)); do
      POD_STATUS=`kubectl describe pod ${domainUID}-${managedpodname}$i  -n ${namespace}|grep  ContainersReady| awk ' { print $2; } '`
      if [ "$POD_STATUS" != "True" ]; then
         POD_ERRORS=`kubectl logs ${domainUID}-${managedpodname}$i  -n ${namespace}| grep -i "error"`
         echo "A failure was detected in the log file for pod ${domainUID}-${managedpodname}$i"
         echo "$POD_ERRORS"
         echo "Check the log output for additional information."
      fi
   done
   fail "Exiting due to failure - the job has failed!"
fi
echo "-----------------------------------------------------"
echo "                 WCS Pod Status                      "
echo "-----------------------------------------------------"
kubectl get pod ${domainUID}-${adminpodname} -n ${namespace}
for (( i=1; i<=$managedServerRunning; i++)); do
   kubectl get pod ${domainUID}-${managedpodname}$i  -n ${namespace}
done
echo "====================================================="
echo "   Admin and Managed Servers started successfully    "
echo "        WCS Upgrade completed successfully           "
echo "====================================================="
