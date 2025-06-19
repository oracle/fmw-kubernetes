#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/common/helper.sh
source ${scriptDir}/common/utility.sh
set -eu

initGlobals() {
  KUBERNETES_CLI=${KUBERNETES_CLI:-kubectl}
  claimName=""
  mountPath=""
  namespace="default"
  image="ghcr.io/oracle/oraclelinux:8"
  imagePullPolicy="IfNotPresent"
  pullsecret=""
  pullsecretPrefix=""
  pvcPrefix=""
  emptyDirPrefix="#"
  serviceType="NodePort"
  vncpassword="vncpassword"
  cleanup=false
}

usage() {
  cat << EOF

  This is a helper script for starting VNC session in a container environment.

  Please see README.md for more details.

  Usage:

    $(basename $0) [-c persistentVolumeClaimName] [-m mountPath]  [-n namespace] [-i image] [-u imagePullPolicy] [-t serviceType] [-d vncpassword] [-k killvnc] [-h]"
    
    [-c | --claimName]                : Persistent volume claim name.

    [-m | --mountPath]                : Mount path of the persistent volume in vnchelper deployment.

    [-n | --namespace]                : Domain namespace. Default is 'default'.

    [-i | --image]                    : Container image for the vnchelper deployment (optional). Default is 'ghcr.io/oracle/oraclelinux:8'.

    [-u | --imagePullPolicy]          : Image pull policy for the helper deployment (optional). Default is 'IfNotPresent'.

    [-p | --imagePullSecret]          : Image pull secret for the helper deployment (optional). Default is 'None'.

    [-t | --serviceType]              : Kubernetes service type for VNC port. Default is 'NodePort'. Supported values are NodePort and LoadBalancer.

    [-d | --vncpassword]              : Password for VNC access. Default is 'vncpassword'.
    
    [-k | --killvnc                   : Removes the Kubernetes resources created in the namespace created for VNC session. 

    [-h | --help]                     : This help.


EOF
exit $1
}

killvnc() {
    ${KUBERNETES_CLI} delete deployment/vnchelper -n ${namespace} --ignore-not-found
    ${KUBERNETES_CLI} delete service/vnchelper -n ${namespace} --ignore-not-found
    printInfo "Cleanup of Kubernetes resources created for VNC access completed at $namespace"
    exit 0
}

processCommandLine() {
  while [[ "$#" -gt "0" ]]; do
    key="$1"
    case $key in
      -c|--claimName)
        claimName="$2"
        shift 
        ;;
      -m|--mountPath)
        mountPath="$2"
        shift
        ;;
      -n|--namespace)
        namespace="$2"
        shift
        ;;
      -i|--image)
        image="$2"
        shift
        ;;
      -u|--imagePullPolicy)
        imagePullPolicy="$2"
        shift
        ;;
      -p|--pullsecret)
        pullsecret="$2"
        shift
        ;;
      -t|--serviceType)
        serviceType="$2"
        shift
        ;;
      -d|--vncpassword)
        vncpassword="$2"
        shift
        ;;
      -k|--killvnc)
        cleanup=true
        ;;
      -h|--help)
        usage 0
        ;;
      -*|--*)
        echo "Unknown option $1"
        usage 1
        ;;
      *)
        # unknown option
        ;;
    esac
    shift # past arg or value
  done

  if $cleanup; then
     killvnc
  fi
}

validatePvc() {
  if [ -z "${claimName}" ]; then
    printInfo "CAUTION!!!! The presistenceVolumeClaimName is not provided. Any data stored in this setup is ephemeral and not persistent"
    printInfo "CAUTION!!!! In case you want to access domain home or any projects/applications created to be persistent, recommended to pass a persistentVolumeClaimName with option -c"
    pvcPrefix="#"
    emptyDirPrefix="" 
  else
    pvc=$(${KUBERNETES_CLI} get pvc ${claimName} -n ${namespace} --ignore-not-found)
    if [ -z "${pvc}" ]; then
      printError "${script}: Persistent volume claim '$claimName' does not exist in namespace ${namespace}. \
        Please specify an existing persistent volume claim name using '-c' parameter."
      exit 1
    fi
  fi
  
}

validateMountPath() {
  if [ -z "${mountPath}" ]; then
    mountPath="/shared"
  elif [[ ! "$mountPath" =~ '/' ]] &&  [[ ! "$mountPath" =~ '\' ]]; then
    printError "${script}: -m mountPath is not a valid path."
    usage 1
  fi
}

checkAndDefaultPullSecret() {
  if [ -z "${pullsecret}" ]; then
    pullsecret="none"
    pullsecretPrefix="#"
  fi
}

validateParameters() {
  validatePvc
  validateMountPath
  checkAndDefaultPullSecret
}

# create configmap with scripts required for starting vnc session
createScriptConfigmap() {
   ScriptForConfigmap=${scriptDir}/common/startVNC.sh

   local cmName="vnchelper-scripts-cm"
   ${KUBERNETES_CLI:-kubectl} create configmap ${cmName} -n $namespace --from-file $ScriptForConfigmap --dry-run=client -o yaml | ${KUBERNETES_CLI:-kubectl} apply -f -
   
   echo Checking the configmap $cmName was created
   local num=`${KUBERNETES_CLI:-kubectl} get cm -n $namespace | grep ${cmName} | wc | awk ' { print $1; } '`
   if [ "$num" != "1" ]; then
     fail "The configmap ${cmName} was not created"
   fi
}

# create secret with vnc password for vnc session access
createSecret() {
   local secretName="vnchelper-scripts-secret"
   ${KUBERNETES_CLI:-kubectl} create secret generic ${secretName} -n $namespace --from-literal=password=$vncpassword  --dry-run=client -o yaml | ${KUBERNETES_CLI:-kubectl} apply -f -
   echo Checking the secret $secretName was created
   local num=`${KUBERNETES_CLI:-kubectl} get secret -n $namespace | grep ${secretName} | wc | awk ' { print $1; } '`
   if [ "$num" != "1" ]; then
     fail "The secret ${secretName} was not created"
   fi
}


createVNCDeployment() {
  printInfo "Creating deployment 'vnchelper' using image '${image}', persistent volume claim \
    '${claimName}' and mount path '${mountPath}'."
  createScriptConfigmap
  createSecret
  vnchelperYamlTemp=${scriptDir}/common/vnchelper.yaml.template
  template="$(cat ${vnchelperYamlTemp})"

  template=$(echo "$template" | sed -e "s:%NAMESPACE%:${namespace}:g;\
    s:%WEBLOGIC_IMAGE_PULL_POLICY%:${imagePullPolicy}:g;\
    s:%WEBLOGIC_IMAGE_PULL_SECRET_NAME%:${pullsecret}:g;\
    s:%CLAIM_NAME%:${claimName}:g;s:%VOLUME_MOUNT_PATH%:${mountPath}:g;\
    s:%IMAGE_PULL_SECRET_PREFIX%:${pullsecretPrefix}:g;\
    s:%PVC_PREFIX%:${pvcPrefix}:g;\
    s:%EMPTY_PREFIX%:${emptyDirPrefix}:g;\
    s?image:.*?image: ${image}?g; \
    s?type:.*?type: ${serviceType}?g")
  ${KUBERNETES_CLI} delete deployment/vnchelper -n ${namespace} --ignore-not-found
  echo "$template" | ${KUBERNETES_CLI} apply -f -
}

printSummary() {
   if [ $serviceType == "NodePort" ]; then
      VNC_PORT="$(${KUBERNETES_CLI:-kubectl} get svc vnchelper -n $namespace  -o=jsonpath='{.spec.ports[?(@.port==5901)].nodePort}')"
      VNC_IP="$(${KUBERNETES_CLI:-kubectl} get nodes --selector=node-role.kubernetes.io/control-plane -o jsonpath='{$.items[*].status.addresses[?(@.type=="InternalIP")].address}')"
   elif [ $serviceType == "LoadBalancer" ]; then
      VNC_PORT="$(${KUBERNETES_CLI:-kubectl} get svc vnchelper -n $namespace  -o=jsonpath='{.spec.ports[?(@.port==5901)].port}')"
      VNC_IP="$(${KUBERNETES_CLI:=kubectl} get svc -n $namespace vnchelper -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
   else
      printError "Unsupported serviceType"
      exit 1
   fi
   printInfo "=========================================== VNC environment details ===================================================="
   printInfo "VNCSERVER started on DISPLAY= $VNC_PORT"
   printInfo "To start using VNC Session ==> connect via VNC viewer with $VNC_IP:$VNC_PORT"
   printInfo ""
   if [ -z "${claimName}" ]; then
      printInfo "Data stored in this session are ephemeral and not persistent as no persistentvolumeClaim is used"
   else
      printInfo "Your data hosted at persistentvolumeClaim $claimName, are available for access at $mountPath"
   fi
   printInfo "========================================================================================================================"
   printInfo ""
   printInfo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
   printInfo ">>>>>> To cleanup the Kubernetes resources created for VNC session"
   printInfo ">>>>>> Run: \$ ./start_vnc.sh -k -n $namespace"
   printInfo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
}


main() {
  createVNCDeployment
  sleep 10
  printSummary
}

initGlobals
processCommandLine "${@}"
validateParameters
main
