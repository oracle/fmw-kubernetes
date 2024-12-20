# OpenTofu for Oracle Cloud Native Environment

## Introduction

This repository is the top level for a modularized method for deploying OCNE and its subcomponents into OCI using OpenTofu.  Each submodule focuses on a specific portion of an OCNE deploymnent, allowing users to select specific configurations to deploy.

This module will create the following resources:

* **OCNE API Server**: The OCNE API Server to orchestrate OCNE agents running on Control Plane and Worker nodes to perform installation of Kubernetes and other OCNE modules.
* **Control Plane Nodes**: The compute instances for the Control Plane Nodes of Kubernetes cluster.
* **Worker Nodes**: The compute instances for the Worker Nodes of Kubernetes cluster.
* **Mount target**: A mount target and two filesystems using FSS for persistent volume (PV) usage: one for the domain home and the other for the database volume.
* **Bastion Server**: A Bastion server acts as a secure gateway for accessing private machines in a network.

### High-Level Deployment Options

This module supports several common deployment scenarios out of the box.  They are listed here to avoid having to duplicated them in each of the relevant module descriptions below

 * OCNE API Server on a dedicated compute instance
 * Passing in a default network to build the deployment in
 * Allowing these modules to create and configure a new network
 * Use openssl to generate and distribute certificates to each node

#### Prerequisites

To use these OpenTofu scripts, you will need fulfill the following prerequisites:

* Have an existing tenancy with enough compute and networking resources available for the desired cluster.
* Have an [Identity and Access Management](https://docs.cloud.oracle.com/iaas/Content/ContEng/Concepts/contengpolicyconfig.htm#PolicyPrerequisitesService) policy in place within that tenancy to allow the OCI Container Engine for Kubernetes service to manage tenancy resources.
* Have a user defined within that tenancy.
* Have an API key defined for use with the OCI API, as documented [here](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingcredentials.htm).
* Have an [SSH key pair](https://docs.oracle.com/en/cloud/iaas/compute-iaas-cloud/stcsg/generating-ssh-key-pair.html) for configuring SSH access to the nodes in the cluster.
* You must have downloaded, installed, and configured OCI CLI for use. See [here](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) for the installation instructions.


#### Overview of terraform.tfvars.template file variables

| Name  |Description |
|:---------- |:-----------|
|tenancy_id|The OCID of your tenancy. To get the value, see [Where to Get the Tenancy's OCID and User's OCID](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five).|
|compartment_id|The OCID of the compartment.|
|user_id|The OCID of the user that will be used by OpenTofu to create OCI resources. To get the value, see Where to Get the Tenancy's OCID and User's OCID.|
|fingerprint|Fingerprint for the key pair being used. To get the value, see [How to Get the Key's Fingerprint](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#four)|
|api_private_key_path|The path to the private key used by the OCI user to authenticate with OCI API's. For details on how to create and configure keys see [How to Generate an API Signing Key ](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#two) and [How to Upload the Public Key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#three).|
|region|The OCI region where resources will be created. To get the value, See [Regions and Availability Domains](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm#top).|
|availability_domain_id|The ID of the availability domain inside the `region` to create the deployment|
|prefix|A unique prefix to attach to the name of all OCNE resources that are created as a part of the deployment.|
|ssh_private_key_path|The SSH private key path that goes with the SSH public key that is used when accessing compute resources that are created as part of this deployment. To generate the keys see - [Generating an SSH Key Pair for Oracle Compute Cloud Service Instances](https://www.oracle.com/webfolder/technetwork/tutorials/obe/cloud/compute-iaas/generating_ssh_key/generate_ssh_key.html).|
|ssh_public_key_path|The SSH public key path to use when configuring access to any compute resources created as part of this deployment. To generate the keys see - [Generating an SSH Key Pair for Oracle Compute Cloud Service Instances](https://www.oracle.com/webfolder/technetwork/tutorials/obe/cloud/compute-iaas/generating_ssh_key/generate_ssh_key.html).|
|control_plane_node_count|The number of Kubernetes control plane nodes to deploy. To view the recommended worker node count, please see [Kubernetes High Availability Requirements](https://docs.oracle.com/en/operating-systems/olcne/start/hosts.html#kube-nodes).|
|worker_node_count|The number of Kubernetes worker nodes to deploy. To view the recommended worker node count, please see [Kubernetes High Availability Requirements](https://docs.oracle.com/en/operating-systems/olcne/start/hosts.html#kube-nodes).|
|os_version|The version of Oracle Linux to use as the base image for all compute resources that are part of this deployemnt.|
|environment_name|The name of the OCNE Environment that is created by this module to deploy module instances into. For more details, please see [Creating an Environment](https://docs.oracle.com/en/operating-systems/olcne/start/install.html#env-create).|
|kubernetes_name|The name of the instance of the OCNE Kubernetes module that is installed as part of this deployment. For more details, please see [Creating a Kubernetes Module](https://docs.oracle.com/en/operating-systems/olcne/start/install.html#mod-kube).|
|ocne_version|The version and release of OCNE to deploy. For more details on the versions, please see the [OCNE Release Notes](https://docs.oracle.com/en/operating-systems/olcne/1.9/relnotes/components.html#components). To install the latest patch version of <major.minor>, please set the value to `<major.minor>` or set the value to `<major.minor.patch>` to install a specific patch version.|
|config_file_path|The path to the OCNE configuration file. For more details on the configuration file, please see the [OCNE configuration file](https://docs.oracle.com/en/operating-systems/olcne/1.9/olcnectl/config.html)|


#### Deploying Environment

Copy provided `oci.props.template` file to `oci.props` and add all required values:

To run the script, use the command:
```shell
$ kubernetes/ocne/samples/opentofu/ocne.create.sh oci.props
```
The script collects the values from `oci.props` file and performs the following steps:
* Creates a new tfvars file based on the values from the provided `oci.props` file.
* Downloads and installs all the necessary binaries for OpenTofu, yq and jq tools.
* Applies the configuration, creates OCNE environment using OpenTofu and generates kubeconfig file.

If the OCNE environment is created successfully, below output will be displayed by `ocne.create.sh`
```aidl
api_private_key_path = "/home/user1/.oci/oci_api_key.pem"
apiserver_ip = "10.0.0.33"
availability_domain_id = "PJzM:PHX-AD-2"
bastion_private_key_path = "/home/user1/.ssh/id_rsa"
bastion_public_ip = "129.xxx.xxx.xx"
bastion_user = "opc"
compartment_id = "ocid1.compartment.oc1..aaaaaaaaq6xxxxxxx....4a"
config_file_path = ""
container_registry = "container-registry.oracle.com/olcne"
control_plane_node_count = 1
control_plane_nodes = tolist([
  "10.0.0.155",
])
environment_name = "myenvironment"
extra_cas = tolist([])
fingerprint = "a6:c8:xx:xx:xx:xx..:XX"
fmw1_export_path = "/fmw1"
fmw1_fs_ocid = "ocid1.filesystem.oc1.phx.aaaaaaaaaaj7vxxxxxx...aa"
fmw2_export_path = "/fmw2"
fmw2_fs_ocid = "ocid1.filesystem.oc1.phx.aaaaaaaaaaxxxxxx...aaaa"
freeform_tags = tomap({})
image_ocid = "ocid1.image.oc1.phx.aaaaaaaahgrsxxxxx...cq"
instance_shape = tomap({
  "memory" = "32"
  "ocpus" = "2"
  "shape" = "VM.Standard.E4.Flex"
})
key_ocid = ""
kube_apiserver_endpoint_ip = "10.0.0.207"
kube_apiserver_port = "6443"
kube_apiserver_virtual_ip = ""
kubernetes_name = "mycluster"
load_balancer_ip = "10.0.0.207"
load_balancer_policy = "LEAST_CONNECTIONS"
load_balancer_shape = tomap({
  "flex_max" = "50"
  "flex_min" = "10"
  "shape" = "flexible"
})
mount_target_ip = "10.0.0.128"
ocne_secret_name = "vk1-ocne_keys"
ocne_vault_client_token = ""
ocne_version = "1.9"
os_version = "8"
prefix = "vk1"
provision_mode = "OCNE"
provision_modes_map = {
  "provision_mode_infrastucture" = "Infrastructure"
  "provision_mode_ocne" = "OCNE"
}
proxy = ""
region = "us-phoenix-1"
secret_name = "vk1-vault_keys"
ssh_private_key_path = "/home/user1/.ssh/id_rsa"
standalone_api_server = true
subnet_id = "ocid1.subnet.oc1.phx.aaaaaaaas77xxxxxxx...wq"
tenancy_id = "ocid1.tenancy.oc1..aaaaaaaxxxxx......bmffq"
use_vault = false
user_id = "ocid1.user.oc1..aaaaaaxxxxxxx.....sya"
vault_ha_storage_bucket = ""
vault_instances = []
vault_namespace = ""
vault_ocid = ""
vault_pool_size = 1
vault_storage_bucket = ""
vault_uri = ""
vault_version = "1.3.4"
vcn_id = "ocid1.vcn.oc1.phx.amaaaaaxxxxxx....kq"
worker_node_count = 1
worker_nodes = [
  "10.0.0.76",
]
yum_repo_url = "http://yum.oracle.com/repo/OracleLinux/OL8/olcne16/x86_64"
kubeconfig file successfully created in /home/user1/ocne_env/opentofu.
```

To delete the OCNE environment, run `ocne.delete.sh` script. It reads the `oci.props` file from the current directory and deletes the cluster.
```shell
$ kubernetes/ocne/samples/opentofu/ocne.delete.sh oci.props
```

#### Installing the Oracle Cloud Infrastructure Cloud Controller Manager Module(OCI-CCM) in an OCNE environment configured using Tofu

The Oracle Cloud Infrastructure Cloud Controller Manager module is used to provision Oracle Cloud Infrastructure storage. See [here](https://docs.oracle.com/en/operating-systems/olcne/1.9/ociccm/install.html#oci-install) for detailed installation steps.

Create an Oracle Cloud Infrastructure Cloud Controller Manager module and associate it with the Kubernetes module named mycluster using the --oci-ccm-kubernetes-module option. In this example, the Oracle Cloud Infrastructure Cloud Controller Manager module is named myoci. 

After successfully creating the OCNE environment using Tofu configurations, you can retrieve the vcn and subnet details from the console output. Then, log in to the platform API server node(OCNE Operator node) and follow these steps. For example:

Once you've successfully created the OCNE environment using Tofu configurations, you can obtain the vcn and subnet details from the console output. Alternatively, you can run tofu and get the vcn and subnet IDs from the `tofu output`. Next, log in to the platform API server node (OCNE Operator node) and follow these steps. For example:


```aidl
# The path to the node certificate(IP refers to the operator/platform API server node).
export OLCNE_SM_CA_PATH=/home/opc/.olcne/certificates/10.0.0.137\:8091/ca.cert

# The path to the Certificate Authority certificate. 
export OLCNE_SM_CERT_PATH=/home/opc/.olcne/certificates/10.0.0.137\:8091/node.cert

# The path to the key for the node's certificate. 
export OLCNE_SM_KEY_PATH=/home/opc/.olcne/certificates/10.0.0.137\:8091/node.key

olcnectl module create \
--environment-name myenvironment \
--module oci-ccm \
--name myoci \
--oci-ccm-kubernetes-module mycluster \
--oci-region us-ashburn-1 \
--oci-tenancy ocid1.tenancy.oc1..unique_ID \
--oci-compartment ocid1.compartment.oc1..unique_ID \
--oci-user ocid1.user.oc1..unique_ID \
--oci-fingerprint b5:52:... \
--oci-private-key-file /home/opc/.oci/oci_api_key.pem \
--oci-vcn ocid1.vcn.oc1..unique_ID \
--oci-lb-subnet1 ocid1.subnet.oc1..unique_ID 
```

Use the olcnectl module install command to install the Oracle Cloud Infrastructure Cloud Controller Manager module. For example: 

```aid1
olcnectl module install \
--environment-name myenvironment \
--name myoci
```

Verify the Oracle Cloud Infrastructure Cloud Controller Manager module is deployed using the olcnectl module instances. For example:

```aid1
olcnectl module instances \
--environment-name myenvironment

INSTANCE        MODULE          STATE
10.0.0.24:8090  node            installed
10.0.0.199:8090 node            installed
mycluster       kubernetes      installed
myoci           oci-ccm         installed


[opc@vk-api-server-001 ~]$ kubectl get nodes --kubeconfig=kubeconfig.myenvironment.mycluster
NAME                   STATUS   ROLES           AGE   VERSION
vk-control-plane-001   Ready    control-plane   17m   v1.29.3+3.el8
vk-worker-001          Ready    <none>          17m   v1.29.3+3.el8

```

#### Using Object Storage for State Files

Using Object Storage statefile requires that you create an AWS S3 Compatible API Key on OCI. This can be done from both the OCI UI and CLI.  For more details visit [Using Object Storage for State Files](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformUsingObjectStore.htm#s3).

To get started, rename `state_backend.tf.example` to `state_backend.tf` and fill out the appropriate variables. Variable definitions for the S3 Backend can be found in the [OpenTofu S3 Backend Documentation](https://opentofu.org/docs/language/settings/backends/s3/).


#### Deploying SOA on a OCNE cluster using Helmfile

Refer to `OracleSOASuite/helm-charts/README.md` for detailed instructions. 


OCI NFS Volume Static Provisioning:


For `SOA` usage, the file system can be directly referenced in the `values.yaml` file under the `domain.storage` section. Example:
```aidl
   storage:
     capacity: 10Gi
     reclaimPolicy: Retain
     type: nfs 
     path: /fmw1   #Export Path
     nfs:
      server: 10.0.10.156 #Mount Target IP Address
```

For `DB` usage, here is an example of persistent volume(PV) definition using a File System(FS) and a Mount target IP:


```aidl
apiVersion: v1
kind: PersistentVolume
metadata:
  name: fmw2-pv-db
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: fss.csi.oraclecloud.com
    volumeHandle: "<OCID of the file system>:<Mount Target IP Address>:/<Export Path>"
```

Update the `values.yaml` file under `oracledb.persistence` section to use the created PV as a volume. Example:

```aidl
   persistence:
     storageClass: ""
     size: 10Gi
     accessMode: "ReadWriteOnce"
     volumeName: "fmw2-pv-db"
```
**Note:** 
- Example volumeHandle in the above config file : 
  `volumeHandle: "ocid1.filesystem.oc1.phx.aaaaanoxxxxx....aaaa:10.0.10.156:/fmw2"`
- Obtain the `volumeHandle` details from the console output after the cluster is created successfully.
- Whenever a mount target is provisioned in OCI, its `Reported Size (GiB)` values are very large. This is visible on the mount target page when logged in to the OCI console. Applications will fail to install if the results of a space requirements check show too much available disk space. So in the OCI Console, click the little "Pencil" icon besides the **Reported Size** parameter of the Mount Target to specify, in gigabytes (GiB), the maximum capacity reported by file systems exported through this mount target. This setting does not limit the actual amount of data you can store. See [here](https://docs.oracle.com/en-us/iaas/Content/File/Tasks/change-file-system-size-mt.htm) for setting a File System's Reported Size.

## License

Copyright (c) 2024, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
