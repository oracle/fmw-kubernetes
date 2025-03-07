#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

prop() {
    grep "${1}" ${propsFile}| grep -v "#" | cut -d'=' -f2
}

generateTFVarFile() {
    tfVarsFiletfVarsFile=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
    rm -f ${tfVarsFiletfVarsFile}
    cp ${opentofuVarDir}/template.tfvars $tfVarsFiletfVarsFile
    chmod 777 ${opentofuVarDir}/template.tfvars $tfVarsFiletfVarsFile
    sed -i -e "s:@TENANCYOCID@:${tenancy_ocid}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@USEROCID@:${user_ocid}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@COMPARTMENTOCID@:${compartment_ocid}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@COMPARTMENTNAME@:${compartment_name}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@OKECLUSTERNAME@:${okeclustername}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s/@OCIAPIPUBKEYFINGERPRINT@/"${ociapi_pubkey_fingerprint}"/g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@OCIPRIVATEKEYPATH@:${ocipk_path}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@VCNCIDRPREFIX@:${vcn_cidr_prefix}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@VCNCIDR@:${vcn_cidr_prefix}.0.0/16:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@OKEK8SVERSION@:${k8s_version}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@NODEPOOLSHAPE@:${nodepool_shape}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@NODEPOOLIMAGENAME@:${nodepool_imagename}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@NODEPOOLSSHPUBKEY@:${nodepool_ssh_pubkey}:g" ${tfVarsFiletfVarsFile}
    sed -i -e "s:@REGION@:${region}:g" ${tfVarsFiletfVarsFile}
    echo "Generated TFVars file [${tfVarsFiletfVarsFile}]"
}

setupOpentofu() {
    mkdir ${opentofuDir}
    cd ${opentofuDir}
    if [[ "${OSTYPE}" == "darwin"* ]]; then
      os_type="darwin"
    elif [[ "${OSTYPE}" == "linux"* ]]; then
       os_type="linux"
    else
       echo "Unsupported OS"
    fi
    echo "https://github.com/opentofu/opentofu/releases/download/v1.8.5/tofu_1.8.5_${os_type}_${platform}64.zip"
    curl -fsSL -O https://github.com/opentofu/opentofu/releases/download/v1.8.5/tofu_1.8.5_${os_type}_${platform}64.zip
    unzip tofu_1.8.5_${os_type}_${platform}64.zip
    chmod +x ${opentofuDir}/tofu

    export PATH=${opentofuDir}:${PATH}
}

deleteOlderVersionOCIProvider() {
    if [ -d ~/.terraform.d/plugins ]; then
        echo "Deleting older version of opentofu plugins dir"
        rm -rf ~/.terraform.d/plugins
    fi
    if [ -d ${opentofuVarDir}/.terraform ]; then
        rm -rf ${opentofuVarDir}/.terraform
    fi
    if [ -e ~/.tofurc ]; then
      rm ~/.tofurc
    fi
}

createCluster () {
    cd ${opentofuVarDir}
    echo "tofu init -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars"
    tofu init -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
    tofu plan -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
    tofu apply -auto-approve -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
}

createRoleBindings () {
    ${KUBERNETES_CLI:-kubectl} -n kube-system create serviceaccount $okeclustername-sa
    ${KUBERNETES_CLI:-kubectl} create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:$okeclustername-sa
    TOKENNAME=`${KUBERNETES_CLI:-kubectl} -n kube-system get serviceaccount/$okeclustername-sa -o jsonpath='{.secrets[0].name}'`
    TOKEN=`${KUBERNETES_CLI:-kubectl} -n kube-system get secret $TOKENNAME -o jsonpath='{.data.token}'| base64 --decode`
    ${KUBERNETES_CLI:-kubectl} config set-credentials $okeclustername-sa --token=$TOKEN
    ${KUBERNETES_CLI:-kubectl} config set-context --current --user=$okeclustername-sa
}

checkClusterRunning () {

    echo "Confirm access to cluster..."
    myline=`${KUBERNETES_CLI:-kubectl} get nodes | awk '{print $2}'| tail -n+2`
    status="NotReady"
    max=50
    count=1

    privateIP=${vcn_cidr_prefix//./\\.}\\.10\\.
    myline=`${KUBERNETES_CLI:-kubectl} get nodes -o wide | grep "${privateIP}" | awk '{print $2}'`
    NODE_IP=`${KUBERNETES_CLI:-kubectl} get nodes -o wide| grep "${privateIP}" | awk '{print $7}'`
    echo $myline
    status=$myline
    max=100
    count=1
    while [ "$myline" != "Ready" -a $count -le $max ] ; do
      echo "echo '[ERROR] Some Nodes in the Cluster are not in the Ready Status , sleep 10s more ..."
      sleep 10
      myline=`${KUBERNETES_CLI:-kubectl} get nodes -o wide | grep "${privateIP}" | awk '{print $2}'`
      NODE_IP=`${KUBERNETES_CLI:-kubectl} get nodes -o wide| grep "${privateIP}" | awk '{print $7}'`
      [[ ${myline} -eq "Ready"  ]]
      echo "Status is ${myline} Iter [$count/$max]"
      count=`expr $count + 1`
    done

    NODES=`${KUBERNETES_CLI:-kubectl} get nodes -o wide | grep "${privateIP}" | wc -l`
    if [ "$NODES" == "1" ]; then
      echo '- able to access cluster'
    else
      echo '- could not access cluster, aborting'
      cd ${opentofuVarDir}
      tofu destroy -auto-approve -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
      exit 1
    fi

    if [ $count -gt $max ] ; then
       echo "[ERROR] Unable to start the nodes in oke cluster after 200s ";
       cd ${opentofuVarDir}
       tofu destroy -auto-approve -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
       exit 1
    fi
}

#MAIN
propsFile=${1:-$PWD/oci.props}
opentofuVarDir=${2:-$PWD}
platform=${3:-amd}

#grep props's values from oci.props file

clusterTFVarsFile=$(prop 'tfvars.filename')
tenancy_ocid=$(prop 'tenancy.ocid')
user_ocid=$(prop 'user.ocid')
compartment_ocid=$(prop 'compartment.ocid')
compartment_name=$(prop 'compartment.name')
okeclustername=$(prop 'okeclustername')
ociapi_pubkey_fingerprint=$(prop 'ociapi.pubkey.fingerprint')
ocipk_path=$(prop 'ocipk.path')
vcn_cidr_prefix=$(prop 'vcn.cidr.prefix')
k8s_version=$(prop 'k8s.version')
nodepool_shape=$(prop 'nodepool.shape')
nodepool_imagename=$(prop 'nodepool.imagename')
nodepool_ssh_pubkey=$(prop 'nodepool.ssh.pubkey')
region=$(prop 'region')
opentofuDir=$(prop 'tofu.installdir')
installType=$(prop 'installer.type')

# generate tofu configuration file with name $(clusterTFVarsFile).tfvar
generateTFVarFile

# cleanup previously installed tofu binaries
rm -rf ${opentofuDir}

# download tofu binaries into ${opentofuDir}
setupOpentofu

# clean previous versions of tofu oci provider
deleteOlderVersionOCIProvider

chmod 600 ${ocipk_path}

# run tofu init,plan,apply to create OKE cluster based on the provided tfvar file ${clusterTFVarsFile).tfvar
createCluster
#check status of OKE cluster nodes, destroy if can not access them
export KUBECONFIG=${opentofuVarDir}/${okeclustername}_kubeconfig
checkClusterRunning
echo "$okeclustername cluster is up and running"
