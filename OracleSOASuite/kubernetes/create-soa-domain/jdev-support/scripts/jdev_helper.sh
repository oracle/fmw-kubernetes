#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# Launch a "Persistent volume cleanup helper" pod for examining or cleaning up the contents 
# of domain directory on a persistent volume.

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

  This is a helper script for SOA jdeveloper access setup in container environment.

  Please see README.md for more details.

  Usage:

    $(basename $0) [-c persistentVolumeClaimName] [-m mountPath]  [-n namespace] [-i image] [-u imagePullPolicy] [-t serviceType] [-d vncpassword] [-k killvnc] [-h]"
    
    [-c | --claimName]                : Persistent volume claim name.

    [-m | --mountPath]                : Mount path of the persistent volume in jdevhelper deployment.

    [-n | --namespace]                : Domain namespace. Default is 'default'.

    [-i | --image]                    : Container image for the jdevhelper deployment (optional). Default is 'ghcr.io/oracle/oraclelinux:8'.

    [-u | --imagePullPolicy]          : Image pull policy for the helper deployment (optional). Default is 'IfNotPresent'.

    [-p | --imagePullSecret]          : Image pull secret for the helper deployment (optional). Default is 'None'.

    [-t | --serviceType]              : Kubernetes service type for VNC port. Default is 'NodePort'. Supported values are NodePort and LoadBalancer.

    [-d | --vncpassword]              : Password for VNC access. Default is 'vncpassword'.
    
    [-k | --killvnc                   : Removes the Kubernetes resources created in the namespace created for SOA JDeveloper access through VNC. 

    [-h | --help]                     : This help.


EOF
exit $1
}

killjdevvnc() {
    ${KUBERNETES_CLI} delete deployment/jdevhelper -n ${namespace} --ignore-not-found
    ${KUBERNETES_CLI} delete service/jdevhelper -n ${namespace} --ignore-not-found
    printInfo "Cleanup of Kubernetes resources created for SOA jdeveloper access completed at $namespace"
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
     killjdevvnc
  fi
}

validatePvc() {
  if [ -z "${claimName}" ]; then
    printInfo "CAUTION!!!! The presistenceVolumeClaimName is not provided. Projects/applications stored in this setup is ephemeral and not persistent"
    printInfo "CAUTION!!!! In case you want the projects/applications created to be persistent, recommended to pass a persistentVolumeClaimName with option -c"
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


createJdevDeployment() {
  printInfo "Creating deployment 'jdevhelper' using image '${image}', persistent volume claim \
    '${claimName}' and mount path '${mountPath}'."

  jdevhelperYamlTemp=${scriptDir}/common/jdevhelper.yaml.template
  template="$(cat ${jdevhelperYamlTemp})"

  template=$(echo "$template" | sed -e "s:%NAMESPACE%:${namespace}:g;\
    s:%WEBLOGIC_IMAGE_PULL_POLICY%:${imagePullPolicy}:g;\
    s:%WEBLOGIC_IMAGE_PULL_SECRET_NAME%:${pullsecret}:g;\
    s:%CLAIM_NAME%:${claimName}:g;s:%VOLUME_MOUNT_PATH%:${mountPath}:g;\
    s:%IMAGE_PULL_SECRET_PREFIX%:${pullsecretPrefix}:g;\
    s:%PVC_PREFIX%:${pvcPrefix}:g;\
    s:%EMPTY_PREFIX%:${emptyDirPrefix}:g;\
    s?image:.*?image: ${image}?g; \
    s?type:.*?type: ${serviceType}?g")
  ${KUBERNETES_CLI} delete deployment/jdevhelper -n ${namespace} --ignore-not-found
  echo "$template" | ${KUBERNETES_CLI} apply -f -
}

printSummary() {
   if [ $serviceType == "NodePort" ]; then
      VNC_PORT="$(${KUBERNETES_CLI:-kubectl} get svc jdevhelper -n $namespace  -o=jsonpath='{.spec.ports[?(@.port==5901)].nodePort}')"
      VNC_IP="$(${KUBERNETES_CLI:-kubectl} get nodes --selector=node-role.kubernetes.io/control-plane -o jsonpath='{$.items[*].status.addresses[?(@.type=="InternalIP")].address}')"
   elif [ $serviceType == "LoadBalancer" ]; then
      VNC_PORT="$(${KUBERNETES_CLI:-kubectl} get svc jdevhelper -n $namespace  -o=jsonpath='{.spec.ports[?(@.port==5901)].port}')"
      VNC_IP="$(${KUBERNETES_CLI:=kubectl} get svc -n $namespace jdevhelper -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
   else
      printError "Unsupported serviceType"
      exit 1
   fi
   printInfo "=========================================== VNC environment details ===================================================="
   printInfo "VNCSERVER started on DISPLAY= $VNC_PORT"
   printInfo "To start using Oracle JDeveloper ==> connect via VNC viewer with $VNC_IP:$VNC_PORT"
   printInfo ""
   if [ -z "${claimName}" ]; then
      printInfo "Your projects/applications created are ephemeral and not persistent as no persistentvolumeClaim is used"
   else
      printInfo "Your projects/applications hosted at persistentvolumeClaim $claimName, are available for JDeveloper access at $mountPath"
   fi
   printInfo "========================================================================================================================"
   printInfo "Navigate to the following location from VNCViewer on terminal"
   printInfo "  \$ cd /u01/oracle/jdeveloper/jdev/bin"
   printInfo ""
   printInfo "For example, to connect to secure Oracle SOA Domain with DemoTrust, run the following command:"
   printInfo "  \$ ./jdev -J-Dweblogic.security.SSL.ignoreHostnameVerify=true -J-Dweblogic.security.TrustKeyStore=DemoTrust"
   printInfo ""
   printInfo "While creating Application Server Connection, use Administration server pod name and internal configured ports."
   printInfo "For example 'WebLogic Hostname' value is 'soainfra-adminserver'"
   printInfo "            'SSL Port' is '9002' for secure domain or 'Port' is '7001' for non-secure domain" 
   printInfo "========================================================================================================================"
   printInfo ""
   printInfo ""
   printInfo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
   printInfo ">>>>>> To cleanup the Kubernetes resources created for Oracle JDeveloper access through VNC"
   printInfo ">>>>>> Run: \$ ./jdev_helper.sh -k -n $namespace"
   printInfo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
}


main() {
  createJdevDeployment
  sleep 10
  ${KUBERNETES_CLI:-kubectl} exec -n $namespace -i deployments/jdevhelper -- bash -c 'cat > /u01/oracle/start_vnc.sh' < ${scriptDir}/common/start_vnc.sh || exit -5
  ${KUBERNETES_CLI:-kubectl} exec -n $namespace -i deployments/jdevhelper -- /bin/bash /u01/oracle/start_vnc.sh ${vncpassword}
  printSummary
}

initGlobals
processCommandLine "${@}"
validateParameters
main
