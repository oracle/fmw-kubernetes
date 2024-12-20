# Sample to create an OKE cluster using OpenTofu scripts

The provided sample will create:

* A new Virtual Cloud Network (VCN) for the cluster
* Two LoadBalancer subnets with security lists
* Three Worker subnets with security lists
* A Kubernetes Cluster with one Node Pool
* A `kubeconfig` file to allow access using `kubectl`
* A Mount target and two filesystems based on FSS for PV usage, one for the domain home and the other for the database volume.

Nodes and network settings will be configured to allow SSH access, and the cluster networking policies will allow `NodePort` services to be exposed. This cluster can be used for testing and development purposes only. The provided samples of OpenTofu scripts should not be considered for creating production clusters, without more of a review.

All OCI Container Engine masters are Highly Available (HA) and fronted by load balancers.



## Prerequisites

To use these OpenTofu scripts, you will need fulfill the following prerequisites:
* Have an existing tenancy with enough compute and networking resources available for the desired cluster.
* Have an [Identity and Access Management](https://docs.cloud.oracle.com/iaas/Content/ContEng/Concepts/contengpolicyconfig.htm#PolicyPrerequisitesService) policy in place within that tenancy to allow the OCI Container Engine for Kubernetes service to manage tenancy resources.
* Have a user defined within that tenancy.
* Have an API key defined for use with the OCI API, as documented [here](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingcredentials.htm).
* Have an [SSH key pair](https://docs.oracle.com/en/cloud/iaas/compute-iaas-cloud/stcsg/generating-ssh-key-pair.html) for configuring SSH access to the nodes in the cluster.
* Install kubectl, kubectl version must be within one minor version(older or newer) of the kubernetes version running on the control plane nodes. See [here](https://kubernetes.io/docs/tasks/tools/#kubectl) for the installation instructions.
* You must have downloaded, installed, and configured OCI CLI for use. See [here](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) for the installation instructions.


Copy provided `oci.props.template` file to `oci.props` and add all required values:
* `user.ocid` - OCID for the tenancy user - can be obtained from the user settings in the OCI console.
* `tfvars.filename` - File name for generated tfvar file.
* `okeclustername` - The name for OCI Container Engine for Kubernetes cluster.
* `tenancy.ocid` - OCID for the target tenancy.
* `region` - name of region in the target tenancy.
* `compartment.ocid` - OCID for the target compartment. To find the OCID of the compartment - https://docs.oracle.com/en-us/iaas/Content/GSG/Tasks/contactingsupport_topic-Finding_the_OCID_of_a_Compartment.htm
* `compartment.name` - Name for the target compartment.
* `ociapi.pubkey.fingerprint` - Fingerprint of the OCI user's public key.
* `ocipk.path` - API Private Key -- local path to the private key for the API key pair.
* `vcn.cidr.prefix` - Prefix for VCN CIDR, used when creating subnets -- you should examine the target compartment find a CIDR that is available.
* `vcn.cidr` - Full CIDR for the VCN, must be unique within the compartment, first 2 octets should match the vcn_cidr_prefix.
* `nodepool.shape` - A valid OCI VM Shape for the cluster nodes.
* `k8s.version` - Kubernetes version.
* `nodepool.ssh.pubkey` - SSH public key (key contents as a string).
* `nodepool.imagename` - A valid image OCID for Node Pool creation. To find the OCID of the image - https://docs.oracle.com/en-us/iaas/Content/ContEng/Reference/contengimagesshapes.htm#images__oke-images
* `tofu.installdir` - Location to install tofu binaries.

Optional, to modify the shape of the node, edit node-pool.tf 
```aidl
  node_shape_config {
        #Optional
        memory_in_gbs = 48.0
        ocpus = 4.0
  }
```
Optional, to add more nodes to the cluster(by default 2 worker nodes are created)
modify vcn.tf to add worker subnets
```aidl
resource "oci_core_subnet" "oke-subnet-worker-3" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[2]["name"]
  cidr_block          = "${var.vcn_cidr_prefix}.12.0/24"
  display_name        = "${var.cluster_name}-WorkerSubnet03"
  dns_label           = "workers03"
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_virtual_network.oke-vcn.id
  security_list_ids   = [oci_core_security_list.oke-worker-security-list.id]
  route_table_id      = oci_core_virtual_network.oke-vcn.default_route_table_id
  dhcp_options_id     = oci_core_virtual_network.oke-vcn.default_dhcp_options_id
}
```
Add corresponding egress_security_rules and ingress_security_rules for the worker subnets
```aidl
 egress_security_rules {
    destination = "${var.vcn_cidr_prefix}.12.0/24"
    protocol    = "all"
    stateless   = true
  }
```
```aidl
  ingress_security_rules {
    stateless = true
    protocol  = "all"
    source    = "${var.vcn_cidr_prefix}.12.0/24"
  }
```
Modify node-pool.tf `subnet_ids` to add new worker subnets to the pool
```aidl
subnet_ids = [oci_core_subnet.oke-subnet-worker-1.id, oci_core_subnet.oke-subnet-worker-2.id, oci_core_subnet.oke-subnet-worker-3.id]
```

To run the script, use the command:
```shell
$ kubernetes/oke/samples/opentofu/oke.create.sh oci.props
```
The script collects the values from `oci.props` file and performs the following steps:
* Creates a new tfvars file based on the values from the provided `oci.props` file.
* Downloads and installs all needed binaries for OpenTofu, OpenTofu OCI Provider, based on OS system (macOS or Linux)
* Applies the configuration, creates OKE Cluster using OpenTofu and generates kubeconfig file based on the `okeclustername` property defined in `oci.props` file.

Output of the oke.create.sh script
If there are errors in the configuration, output will be displayed like this
```
If you ever set or change modules or backend configuration for tofu,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
\u2577
\u2502 Error: Reference to undeclared resource
\u2502 
\u2502   on node-pool.tf line 12, in resource "oci_containerengine_node_pool" "fmw_node_pool":
\u2502   12:   subnet_ids = [oci_core_subnet.oke-subnet-worker-1.id, oci_core_subnet.oke-subnet-worker-2.id, oci_core_subnet.oke-subnet-worker-3.id, oci_core_subnet.oke-subnet-worker-4.id, oci_core_subnet.oke-subnet-worker-5.id]
\u2502 
\u2502 A managed resource "oci_core_subnet" "oke-subnet-worker-5" has not been declared in the root module.
\u2575
\u2577
\u2502 Error: Reference to undeclared resource
\u2502 
\u2502   on node-pool.tf line 12, in resource "oci_containerengine_node_pool" "fmw_node_pool":
\u2502   12:   subnet_ids = [oci_core_subnet.oke-subnet-worker-1.id, oci_core_subnet.oke-subnet-worker-2.id, oci_core_subnet.oke-subnet-worker-3.id, oci_core_subnet.oke-subnet-worker-4.id, oci_core_subnet.oke-subnet-worker-5.id]
\u2502 
\u2502 A managed resource "oci_core_subnet" "oke-subnet-worker-5" has not been declared in the root module.
\u2575
```

If the cluster is created successfully, below output will be displayed
```aidl
cluster_id = "ocid1.cluster.oc1.phx.axxxxxxx.....jlxa"
fmw1_export_path = "/fmw1"
fmw1_fs_ocid = "ocid1.filesystem.oc1.phx.aaaxxxxxx....fuzaaaaa"
fmw2_export_path = "/fmw2"
fmw2_fs_ocid = "ocid1.filesystem.oc1.phx.aaaaxxxxx....xxxxxxaaaa"
fmw_mount_target_ip = "10.1.11.43"
Confirm access to cluster...
NotReady
echo '[ERROR] Some Nodes in the Cluster are not in the Ready Status , sleep 10s more ...
Status is Ready Iter [1/100]
- able to access cluster
okecluster6 cluster is up and running
```

To access the cluster, set the `KUBECONFIG` environment variable or use the `--kubeconfig` option with the kubeconfig file generated based on the `okeclustername` property defined in `oci.props` file. For example: `okeclustername6_kubeconfig`
```
$ kubectl get nodes --kubeconfig=okecluster6_kubeconfig
NAME          STATUS   ROLES   AGE     VERSION
10.1.10.2    Ready    node    2d11h   v1.29.1
10.1.11.3    Ready    node    2d11h   v1.29.1
```

To add new nodes to the cluster after its created, make changes in vcn.tf and node-pool.tf files and
run the below commands.
```aidl
${tofu.installdir}/tofu plan -var-file=<tfvars.filename>
${tofu.installdir}/tofu apply -var-file=<tfvars.filename>
```

To delete the cluster, run `oke.delete.sh` script. It reads the `oci.props` file from the current directory and deletes the cluster.
```shell
$ kubernetes/oke/samples/opentofu/oke.delete.sh oci.props
```

**Deploying SOA on a OKE cluster using Helmfile:** 

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
