#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl

prop() {
    grep "${1}" ${propsFile}| grep -v "#" | cut -d'=' -f2
}

generateTFVarFile() {
    tfVarsFile=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
    rm -f ${tfVarsFile}
    cp ${opentofuVarDir}/terraform.tfvars.template $tfVarsFile
    chmod 777 $tfVarsFile

    sed -i -e "s:@OCI_TENANCY_ID@:${tenancy_id}:g" ${tfVarsFile}
    sed -i -e "s:@OCI_COMPARTMENT_ID@:${compartment_id}:g" ${tfVarsFile}
    sed -i -e "s:@OCI_USER_ID@:${user_id}:g" ${tfVarsFile}
    sed -i -e "s/@OCI_FINGERPRINT@/"${fingerprint}"/g" ${tfVarsFile}
    sed -i -e "s:@OCI_API_PRIVATE_KEY_PATH@:${api_private_key_path}:g" ${tfVarsFile}

    sed -i -e "s:@OCI_REGION@:${region}:g" ${tfVarsFile}
    sed -i -e "s/@OCI_AVAILABILITY_DOMAIN_ID@/"${availability_domain_id}"/g" ${tfVarsFile}
    sed -i -e "s:@OCI_INSTANCE_PREFIX@:${prefix}:g" ${tfVarsFile}


    sed -i -e "s:@OCI_SSH_PRIVATE_KEY_PATH@:${ssh_private_key_path}:g" ${tfVarsFile}
    sed -i -e "s:@OCI_SSH_PUBLIC_KEY_PATH@:${ssh_public_key_path}:g" ${tfVarsFile}

    sed -i -e "s:@OCI_BASTION_PRIVATE_KEY_PATH@:${bastion_private_key_path}:g" ${tfVarsFile}
    sed -i -e "s:@OCI_ENABLE_BASTION@:${enable_bastion}:g" ${tfVarsFile}

    sed -i -e "s:@OCNE_CONTROL_PLANE_NODE_COUNT@:${control_plane_node_count}:g" ${tfVarsFile}
    sed -i -e "s:@OCNE_WORKER_NODE_COUNT@:${worker_node_count}:g" ${tfVarsFile}
    sed -i -e "s:@OCNE_ENVIRONMENT_NAME@:${environment_name}:g" ${tfVarsFile}
    sed -i -e "s:@OCNE_K8S_CLUSTER_NAME@:${kubernetes_name}:g" ${tfVarsFile}

    sed -i -e "s:@OCNE_VERSION@:${ocne_version}:g" ${tfVarsFile}

    sed -i -e "s#@PROXY@#${http_proxy}#g" ${tfVarsFile}
    sed -i -e "s:@NO_PROXY@:${no_proxy}:g" ${tfVarsFile}

    echo "Generated TFVars file [${tfVarsFile}]"
    cat "${tfVarsFile}"
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

    # install yq
    wget -q https://github.com/mikefarah/yq/releases/download/v4.44.5/yq_${os_type}_${platform}64
    mv yq_${os_type}_${platform}64 yq
    chmod +x ${opentofuDir}/yq


    # install jq
    wget -q https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-${os_type}-${platform}64
    mv jq-${os_type}-${platform}64 jq
    chmod +x ${opentofuDir}/jq

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
    echo "tofu plan -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars"
    tofu plan -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
    echo "tofu apply -auto-approve -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars"
    tofu apply -auto-approve -var-file=${opentofuVarDir}/${clusterTFVarsFile}.tfvars
}


checkKubernetesConfigFile() {
    if [ ! -f ${opentofuVarDir}/kubeconfig ]; then
        echo "[ERROR] Unable to locate ${opentofuVarDir}/kubeconfig file"
        echo '- Check for errors during OCNE cluster creation. Aborting..'
        sleep 10
        tofu destroy -auto-approve -var-file="${opentofuVarDir}/${clusterTFVarsFile}.tfvars"
        exit 1
    else
        echo "kubeconfig file successfully created in ${opentofuVarDir}."
    fi
}

#MAIN
propsFile=${1:-$PWD/oci.props}
opentofuVarDir=${2:-$PWD}
platform=${3:-amd}

#grep props's values from oci.props file
clusterTFVarsFile=$(prop 'tfvars.filename')
tenancy_id=$(prop 'tenancy_id')
compartment_id=$(prop 'compartment_id')
user_id=$(prop 'user_id')
fingerprint=$(prop 'fingerprint')
api_private_key_path=$(prop 'api_private_key_path')

region=$(prop 'region')
availability_domain_id=$(prop 'availability_domain_id')
prefix=$(prop 'prefix')

#deploy_networking=$(prop 'deploy_networking')
#subnet_id=$(prop 'subnet_id')
#vcn_id=$(prop 'vcn_id')

ssh_public_key_path=$(prop 'ssh_public_key_path')
ssh_private_key_path=$(prop 'ssh_private_key_path')

enable_bastion=$(prop 'enable_bastion')
bastion_private_key_path=$(prop 'bastion_private_key_path')
#virtual_ip=$(prop 'virtual_ip')

control_plane_node_count=$(prop 'control_plane_node_count')
worker_node_count=$(prop 'worker_node_count')
environment_name=$(prop 'environment_name')
kubernetes_name=$(prop 'kubernetes_name')

ocne_version=$(prop 'ocne_version')

http_proxy=$(prop 'http_proxy')
no_proxy=$(prop 'no_proxy')
opentofuDir=$(prop 'tofu.installdir')
installType=$(prop 'installer.type')

# generate tofu configuration file with name $(clusterTFVarsFile).tfvar
generateTFVarFile

# cleanup previously installed tofu binaries
rm -rf ${opentofuDir}

# download tofu binaries into ${opentofuDir}
#setupTerraform
setupOpentofu

# clean previous versions of tofu  oci provider
deleteOlderVersionOCIProvider

# run tofu init,plan,apply to create OCNE cluster based on the provided tfvar file ${tfVarsFile}
createCluster

#Check for kubeconfig file
checkKubernetesConfigFile

