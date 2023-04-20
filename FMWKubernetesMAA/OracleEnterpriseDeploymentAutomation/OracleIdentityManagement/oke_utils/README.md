# Automating the Creation of an OCI Infrastructure for the Identity and Access Management Kubernetes Cluster

When following the Enterprise Deployment Guide for setting up an  Oracle Identity and Access Management in a Kubernetes Cluster chapter 9 presents many security lists, hosts, VCN's and related resources that need to be created for a successful deployment. This utility consists of a number of sample scripts designed to automate this configuration, making use of the OCI command-line interface.

These scripts are provided as examples and can be customized as desired.

See the ["Enterprise Deployment Guide for Oracle Identity and Access Management in a Kubernetes Cluster"](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-oracle-cloud-infrastructure-enterprise-deployment.html#GUID-3782C6F9-8F6C-4763-BC54-7E6E8D976726) chapter 9 for more details.

## Obtaining the Scripts
The scripts are included with the EDG Automation scripts.  The automation scripts are available for download from GitHub.

To obtain the scripts, use the following command:

```
git clone https://github.com/oracle/fmw-kubernetes.git
```

The scripts appear in the following directory:

```
fmw-kubernetes/FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleIdentityManagement/oke_utils
```

Copy these template scripts to your working directory. For example:

```cp -R fmw-kubernetes/FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleIdentityManagement/* /workdir/scripts```

This directory will be referred to `SCRIPTDIR` in the remainder of this document.


## Scope
This section lists the actions that the scripts perform as part of the deployment process. It also lists the tasks the scripts do not perform.
### What the Script Will do
The script completes chapters 9 and 10 from the Enterprise Deployment Guide. This includes:

* Creating a Bastion host
* Creating 2 Compute instance for the Oracle HTTP Server
* Creating the NFS file systems and mount points for the Kubernetes persistent volume data
* Create a public and internal load balancer for routing requests to the OHS servers
* Creates a TCP load balancer to route requests to the Kubernetes nodes
* Create the RAC database used for the Identity Management product schemas
* Create a DNS server for name resolution within the Kubernetes cluster
* Tunes the RAC database as mentioned in the EDG
* Install the Java Server and Oracle Text database options which are required by the OIM server
* Install the XA views into the OIM pluggable database
* Creates pluggable databases, as configured, for the OAM, OIM, OAA, and OIRI schemas
* Creates database services for the above pluggable databases

### What the Script Will Not Do
The script does not include the installation of any monitoring software such as Grafana or Prometheus nor does it install or configure the log file monitoring tools Elasticsearch and Kibana.

## Key Concepts of the Scripts

To make things simple and easy to manage the scripts are based around the following concepts:

* A response file with details of your environment.
* Template files you can easily modify or add to as required.
* The scripts can be run from any host which has access to the Kubernetes cluster.

> Note: Provisioning scripts are re-entrant, if something fails it can be restarted at the point at which it failed.
 
## Pre-requisites

Before running the utility ensure that the following Pre-Requisites are in place:

* Install and configure the OCI command-line tools using KM note 2432759.1 or the official [OCI documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm).
* Ensure that the 'oci' command runs properly by executing the command `oci iam availability-domain list` and checking that valid output is returned.
* Create an SSH private/public key that will be used to access the OCI instances using the Linux command `ssh-keygen`.
* Create a configuration response file defining the parameters desired for this EDG installation using the delivered `oci-oke.rsp` file as an example.
* You have enough quota available in your tennancy to create the various resources.
 
## Creating a Response File

A Sample response file is created for you in the `SCRIPT_DIR/oke_utils/responsefile` directory called `oci-oke.rsp.` You can edit this file or make a copy of it to another file in the same directory.

All parameters in the section  `MANDATORY PARAMETERS` should be carefully reviewed and set as appropriate. Some values include reasonable default values while others are installation dependent and require to be explictly set.

This file will be referenced as `TEMPLATE_NAME` in the rest of this document.

**Notes:**  
> The file consists of key/value pairs. There should be no spaces between the name of the key and its value. For example: Key=value.

> The OCI image names change frequently and may be out-of-date and require an update before any of the instances can be successfully created.


## Provisioning the Environment
Run the provision script by executing the following commands.

```
cd $SCRIPT_DIR/oke_utils
./provision_oke.sh <TEMPLATE_NAME>
```

> Note: The provision script runs non-interactively after first asking for confirmation that the listed compartment should be used to install the OCI components. Output from the script is printed to the screen as well as into the provision\_oci.log file.
 
## Log Files

The provisioning scripts create log files for each product inside the working directory in a `TEMPLATE_NAME/logs` sub-directory. This directory contains the following files:

* `progressfile` – This file contains the last successfully executed step. If you want to restart the process at a different step, update this file.

* `timings.log` – This file is used for informational purposes to show how much time was spent on each stage of the provisioning process.

* `provision_oci.log` - This file is used to capture the output from the execution of the various `oci` commands that were run by the `provision_oke.sh` script. This is the main provisioning log file.  


## Output Files

These files are generated as part of the provisioning process.

| **Filename** | **Contents** | 
| :--- | :--- | 
| \$WORKDIR/TEMPLATE_NAME/output/ca.crt | The self-signed certificate authority SSL certificate. | 
| \$WORKDIR/TEMPLATE_NAME/output/ca.csr | The certificate authority signing request which can be helpful when needing to renew the CA certificate. | 
| \$WORKDIR/TEMPLATE_NAME/output/ca.key | The self-signed certificate authority SSL private key. | 
| \$WORKDIR/TEMPLATE_NAME/output/ca.srl | The openssl serial number using when signing the CA certificate. | 
| \$WORKDIR/TEMPLATE_NAME/output/TEMPLATE\_NAME.ocid | A listing that includes all of the resources created by the script and their associated OCID value. This file is used when the `delete_oke.sh` script is run to know which resources to delete. | 
| \$WORKDIR/TEMPLATE_NAME/output/loadbalancer.crt | The self-signed SSL certificate used by the public and internal load balancers. This file is also used by the OAM WebGate for making an SSL connection to public load balancer. | 
| \$WORKDIR/TEMPLATE_NAME/output/loadbalancer.key | The SSL private key for the public/internal load balancer SSL certificate. | 
| \$WORKDIR/TEMPLATE_NAME/output/bastion\_mounts.sh | A bash shell script that can be run manually to mount the NFS volumes on the Bastion host. | 
| \$WORKDIR/TEMPLATE_NAME/output/webhost1\_mounts.sh | A bash shell script that can be run manually to mount the NFS volumes on WebHost1. | 
| \$WORKDIR/TEMPLATE_NAME/output/webhost2\_mounts.sh | A bash shell script that can be run manually to mount the NFS volumes on WebHost2. | 
| \$WORKDIR/TEMPLATE_NAME/output/db-tuning.sh | A bash schell script that can be run manually to configure the database init.ora parameters for the selected memory size defined by the `DB_MEMORY_CONFIG` parameter. | 
| \$WORKDIR/TEMPLATE_NAME/output/db-xaviews.sh | A bash schell script that can be run manually to install the XA views into the OIG pluggable database. | 



### Deleting the Environment
The deletion script will read the `$WORKDIR/TEMPLATE_NAME/output/TEMPLATE_NAME.ocid` file to determine which resources were created by the provisioning script and attempt to delete them. 
Run the deletion script by executing the following commands.

```
cd $SCRIPT_DIR/oke_utils
./delete_oke.sh <TEMPLATE_NAME>
```
Like the provisioning script, the delete script will first confirm that the resources should be deleted from the listed compartment and then proceed to run without further user input to delete the resources.

### Deletion Output Files
| **Filename** | **Contents** | 
| :--- | :--- | 
| \$WORKDIR/TEMPLATE_NAME/logs/delete\_oke.log | The output from the execution of the various `oci` commands that were run by the `delete_oke.sh` script. This is the main deletion log file. | 
| \$WORKDIR/TEMPLATE_NAME/logs/timings.log | This file is used for informational purposes to show how much time was spent on each stage of the deletion process. | 

## Response File Reference

### Parameters that <u>_MUST_</u> be Reviewed/Set/Modified.
Some values include reasonable default values while others are installation dependent and require to be explictly set.

| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| WORKDIR | /home/opc/workdir/OKE | Absolute path to the directory where you wish to have the output and log files written to. |
| REGION | \<your-region\> | Which OCI region to create all of the resource in. For example `us-ashburn-1`. |
| COMPARTMENT\_NAME | \<your-compartment-name\> | The compartment name which will hold all of the created resources. |
| SSH\_PUB\_KEYFILE | \<path-to\>/id\_rsa.pub | Absolute path to the SSH public keyfile. |
| SSH\_ID\_KEYFILE | \<path-to\>/id\_rsa | Absolute path to the SSH private keyfile used to connect to the Bastion host. |
| SSL\_COUNTRY | \<country\> | Which country to use in the 'C' portion of the SSL certificate. |
| SSL\_STATE | \<state\> | Which state to use in the 'ST' portion of the SSL certificate. |
| SSL\_LOCALE | \<city\> | Which city to use in the 'L' portion of the SSL certificate. |
| SSL\_ORG | \<company\> | Which organization to use in the 'O' portion of the SSL certificate. |
| SSL_ORGUNIT | \<organization\> | Which organization unit to use in the 'OU' portion of the SSL certificate. |
| DB\_PWD | \<dbpwd\> | The password for the `SYS` and `SYSTEM` users in the RAC database. **Note the password requirements in OCI are 2 upper, 2 lower, 2 number, and 2 special characters and a minimum length of 10 characters.** |
| DB\_NAME | idmdb | The value to use for the datbase `DB_NAME` parameter. |
| DB\_SUFFIX | edg | A suffix, which combined with the DB_NAME value, makes up the value for the `DB_UNIQUE_NAME` database parameter. | 
| DB\_MEMORY\_CONFIG | dev | Which set of database tuning parameters to use, from ["Table 10-3 in the EDG"](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/preparing-existing-database-enterprise-deployment.html#GUID-4597879E-0E9C-4727-8C9F-94DE3EE6BEFB), should be used for the RAC database. |
| CONFIGURE_DATABASE | true | Should the RAC database configuration/tuning script be run automatically after the database is created. **Note that if this is set to "true" then the provisioning script will wait up to 3 hours for the initial RAC database to become available before proceeding.**
| CREATE\_OAM\_PDB | true | If the `CONFIGURE_DATABASE` is enabled should an OAM pluggable database be created. |
| OAM\_PDB\_NAME | oampdb | The name of the OAM pluggable database. |
| OAM\_SERVICE\_NAME | oam\_s | The name of the OAM database service. |
| CREATE\_OIG\_PDB | true | If the `CONFIGURE_DATABASE` is enabled should an OIM pluggable database be created. |
| OIG\_PDB\_NAME | oigpdb | The name of the OIG pluggable database. |
| OIG\_SERVICE\_NAME | oig\_s | The name of the OIG database service. |
| CREATE\_OAA\_PDB | false | If the `CONFIGURE_DATABASE` is enabled should an OAA pluggable database be created. |
| OAA\_PDB\_NAME | oaapdb | The name of the OAA pluggable database. |
| OAA\_SERVICE\_NAME | oaa\_s | The name of the OAA database service. |
| CREATE\_OIRI\_PDB | false | If the `CONFIGURE_DATABASE` is enabled should an OIRI pluggable database be created. |
| OIRI\_PDB\_NAME | oiripdb | The name of the OIRI pluggable database. |
| OIRI\_SERVICE\_NAME | oiri\_s | The name of the OIRI database service. |
| BASTION\_IMAGE\_NAME | Oracle-Linux-8.7-2023.01.31-3 | The Linux image to use for the Bastion host. |
| WEB\_IMAGE\_NAME | \$BASTION\_IMAGE\_NAME | The Linux image to use for the 2 WebTiers. |
| OKE\_NODE\_POOL\_IMAGE\_NAME | \$BASTION\_IMAGE\_NAME | The Linux image to use for the OKE nodes. |
| CONFIGURE\_BASTION | true | Should the Bastion host be automatically configured with the required OS packages, OCI tools, helm, and Kubernetes configuration once the installation is complete. |
| HELM\_VER | 3.7.1 | The version of helm to install on the Bastion node. |
| CONFIGURE\_WEBHOSTS | true | Should the WebTiers be automatically configured with the required OS packages & firewall settings once the installation is complete. |
| OHS\_SOFTWARE\_OWNER | opc | The OS user that will own the OHS configration on the WebTiers. |
| OHS\_SOFTWARE\_GROUP | opc | The OS group that will own the OHS configuration on the WebTiers. |

The rest of the parameters all use a reasonable default and it is not required to change any of these values. However, it may be desirable to review and change them to customize the installation.

### OCI Command-line Interface Region
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| OCI\_CLI\_REGION | \$REGION | **Do not change this value unless you know what you are doing.** This value overrides the default REGION set in the \$HOME/.oci/config file. |

### Port Numbers
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| OAM\_ADMIN\_SERVICE\_PORT | 30701 | OAM AdminServer Kubernetes service port. |
| OAM\_POLICY\_SERVICE\_PORT | 30510 | OAM Policy Manager Kubernetes service port. |
| OAM\_SERVER\_SERVICE\_PORT | 30410 | OAM Server Kubernetes service port. |
| OIG\_ADMIN\_SERVICE\_PORT | 30711 | OIG AdminServer Kubernetes service port. |
| OIG\_SERVER\_SERVICE\_PORT | 30140 | OIM Server Kubernetes service port. |
| SOA\_SERVER\_SERICE\_PORT | 30801 |  SOA Server Kubernetes service port. |
| OUDSM\_SERVER\_SERVICE\_PORT | 30901 | OUDSM Server Kubernetes service port. |
| INGRESS\_SERVICE\_PORT | 30777 | Ingress Controller Kubernetes service port. |
| OHS\_NON\_SSL\_PORT | 7777 | OHS port used by the internal load balancer for internal callback requests. |
| PUBLIC\_LBR\_NON\_SSL\_PORT | 80 | Load balancer port used for HTTP requests to the OAM & OIM AdminServers. |
| PUBLIC\_LBR\_SSL\_PORT | 443 | Load balancer port used for HTTPS requests to the OAM login page and the OIG provisioning server. |

### Subnet Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| VCN\_SUBNET\_CIDR | 10.0.0.0/16 | The CIDR to use for the Virtual Cloud Network. |
| BASTION\_SUBNET\_CIDR | 10.0.1.0/29 | The subnet (which must be contained within the main VCN subnet) to use for the Bastion host. |
| WEB\_SUBNET\_CIDR | 10.0.2.0/28 | The subnet (which must be contained within the main VCN subnet) to use for the WebTier hosts. |
| LBR1\_SUBNET\_CIDR | 10.0.4.0/24 | The first subnet (which must be contained within the main VCN subnet) to use for the public load balancer. |
| LBR2\_SUBNET\_CIDR | 10.0.5.0/24 | The second subnet (which must be contained within the main VCN subnet) to use for the public load balancer. |
| DB\_SUBNET\_CIDR | 10.0.11.0/24 | The subnet (which must be contained within the main VCN subnet) to use for the RAC database. |
| OKE\_NODE\_SUBNET\_CIDR | 10.0.10.0/24 | The subnet (which must be contained within the main VCN subnet) to use for the OKE nodes. |
| OKE\_API\_SUBNET\_CIDR | 10.0.0.0/28 | The subnet (which must be contained within the main VCN subnet) to use for the OKE API endpoint. |
| OKE\_SVCLB\_SUBNET\_CIDR | 10.0.20.0/24 | The subnet (which must be contained within the main VCN subnet) to use for the OKE services load balancer. |

### DNS Zone Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| DNS\_DOMAIN\_NAME | example.com | DNS domain name for the environment. |
| DNS\_ZONE\_TYPE | PRIMARY |  Is this a primary or secondary zone. |
| DNS\_SCOPE | PRIVATE | Is this a private or global DNS zone. |
| DNS\_INTERNAL\_LBR\_DNS\_HOSTNAME | loadbalancer.example.com | Hostname of the load balancer used for internal routing. |

### VCN Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| VCN\_DISPLAY\_NAME | idm-oke-vcn | Display name for the virtual cloud network. |
| VCN\_PRIVATE\_ROUTE\_TABLE\_DISPLAY\_NAME | oke-private-rt | Display name for the VCN private route table. |
| VCN\_PUBLIC\_ROUTE\_TABLE\_DISPLAY\_NAME | oke-public-rt | Display name for the VCN public route table. |
| VCN\_DNS\_LABEL | oke | DNS label for the VCN. Used in conjunction with the hostname and subnet DNS label to form a FQDN for each host. |
| VCN\_INTERNET\_GATEWAY\_DISPLAY\_NAME | oke-igw | Display name for the VCN internet gateway. |
| VCN\_NAT\_GATEWAY\_DISPLAY\_NAME | oke-nat |  Display name for the VCN NAT gateway. |
| VCN\_SERVICE\_GATEWAY\_DISPLAY\_NAME | oke-sgw | Display name for the VCN service gateway. |

### OKE Cluster Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| OKE\_CLUSTER\_DISPLAY\_NAME | oke-cluster | Display name for the OKE cluster. |
| OKE\_CLUSTER\_VERSION | v1.24.1 | What version of Kubernetes to deploy on the OKE nodes. |
| OKE\_MOUNT\_TARGET\_AD | ad1 | Which availability domain to use for the OKE mount target. **Note: this value is not the actual availability domain name but a representation of the AD to use. For example: ad1, ad2, or ad3.** |
| OKE\_PODS\_CIDR | 10.244.0.0/16 | The CIDR for the OKE pods. |
| OKE\_SERVICES\_CIDR | 10.96.0.0/16 | The CIDR for the OKE load balancer services. |
| OKE\_NETWORK\_TYPE | FLANNEL\_OVERLAY | The CNI type for the node pools of the cluster. |
| OKE\_API\_SUBNET\_DISPLAY\_NAME | oke-k8sApiEndpoint-subnet | Display name of the OKE API subnet. |
| OKE\_API\_DNS\_LABEL | apidns | DNS label for the OKE API subnet. Used in conjunction with the hostname and subnet DNS label to form a FQDN for each host within the subnet. |
| OKE\_API\_SECLIST\_DISPLAY\_NAME | oke-k8sApiEndpoint-seclist | Display name of the OKE API security list. |
| OKE\_NODE\_SUBNET\_DISPLAY\_NAME | oke-node-subnet | Display name of the OKE node security list. |
| OKE\_NODE\_DNS\_LABEL | nodedns | DNS label for the OKE nodes. Used in conjunction with the hostname and subnet DNS label to form a FQDN for each host within the subnet. |
| OKE\_NODE\_SECLIST\_DISPLAY\_NAME | oke-node-seclist | Display name of the OKE node security list. |
| OKE\_SVCLB\_SUBNET\_DISPLAY\_NAME | oke-svclb-subnet | Display name of the OKE service load balancer subnet. |
| OKE\_SVCLBR\_DNS\_LABEL | svclbdns | DNS label for the OKE service load balancer. Used in conjunction with the hostname and subnet DNS label to form a FQDN for each host within the subnet. |
| OKE\_SVCLBR\_SECLIST\_DISPLAY\_NAME | oke-svclb-seclist | Display name for the service load balancer security list. |
| OKE\_NODE\_POOL\_DISPLAY\_NAME | pool1 | Display name for the OKE node pool. |
| OKE\_NODE\_POOL\_SIZE | 3 | How many nodes to add to the OKE node pool. |
| OKE\_NODE\_POOL\_SHAPE | VM.Standard.E4.Flex | Which image shape to use for the OKE nodes. |
| OKE\_NODE\_POOL\_SHAPE\_CONFIG | '{\\\"memoryInGBs\\\": 32.0, \\\"ocpus\\\": 2.0}' | Shape configuration for the memory and OCPUs for the OKE nodes. **Note that entire string must be enclosed inside single quotes and parameter names must be enclosed inside of double quotes that are escaped with a backslash.**|

### Bastion Host Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| BASTION\_PRIVATE\_SECLIST\_DISPLAY\_NAME | bastion-private-seclist | Display name for the Bastion private security list. |
| BASTION\_PUBLIC\_SECLIST\_DISPLAY\_NAME | bastion-public-seclist | Display name for the Bastion public security list. |
| BASTION\_SETUP\_SECLIST\_DISPLAY\_NAME | bastion-setup-seclist | Display name for the Bastion setup security list. |
| BASTION\_ROUTE\_TABLE\_DISPLAY\_NAME | bastion-route-table | Display name for the Bastion route table. |
| BASTION\_SUBNET\_DISPLAY\_NAME | bastion-subnet | Display name for the Bastion subnet. |
| BASTION\_DNS\_LABEL | bastionsubnet | DNS label for the Bastion subnet. Used in conjunction with the hostname and subnet DNS label to form a FQDN for each host. |
| BASTION\_INSTANCE\_DISPLAY\_NAME | idm-bastion | Display name for the Bastion compute instance. |
| BASTION\_AD | ad1 | Which availability domain to use for the Bastion host. **Note: this value is not the actual availability domain name but a representation of the AD to use. For example: ad1, ad2, or ad3.** |
| BASTION\_INSTANCE\_SHAPE | VM.Standard.E4.Flex |  Which image shape to use for the Bastion compute instance. |
| BASTION\_SHAPE\_CONFIG | '{\memoryInGBs\: 16.0, \ocpus\: 1.0}' | Shape configuration for the memory and OCPUs for the Bastion node. **Note that entire string must be enclosed inside single quotes and parameter names must be enclosed inside of double quotes that are escaped with a backslash.** |
| BASTION\_PUBLIC\_IP | true | Should the Bastion host get assigned a public IP address. |
| BASTION\_HOSTNAME | idm-bastion | Hostname to use for the Bastion host. |

### OHS/WebTier Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| OHS\_SECLIST\_DISPLAY\_NAME | ohs-seclist | Display name for the OHS security list. |
| WEB\_PUBLIC\_SECLIST\_DISPLAY\_NAME | web-public-seclist | Display name for the Web public security list. |
| WEB\_ROUTE\_TABLE\_DISPLAY\_NAME | web-route-table | Display name for the Web route table. |
| WEB\_SUBNET\_DISPLAY\_NAME | web-subnet | Display name for the Web subnet. |
| WEB\_DNS\_LABEL | websubnet | DNS label for the Web subnet.  Used in conjunction with the hostname and subnet DNS label to form a FQDN for each host. |
| WEB\_PROHIBIT\_PUBLIC\_IP | true | Should the Web subnet allow compute instances with a public IP address. |
| WEBHOST1\_DISPLAY\_NAME | webhost1 | Display name for the first OHS Web host. |
| WEBHOST1\_AD | ad1 |   Which availability domain to use for the first Web host. **Note: this value is not the actual availability domain name but a representation of the AD to use. For example: ad1, ad2, or ad3.** |
| WEBHOST1\_SHAPE | VM.Standard.E4.Flex | Which image shape to use for the first Web host. |
| WEBHOST1\_SHAPE\_CONFIG | '{\memoryInGBs\: 16.0, \ocpus\: 1.0}' | Shape configuration for the memory and OCPUs for the first Web host. **Note that entire string must be enclosed inside single quotes and parameter names must be enclosed inside of double quotes that are escaped with a backslash.** |
| WEBHOST1\_PUBLIC\_IP | false | Should the first Web host get assigned a public IP address. |
| WEBHOST1\_HOSTNAME | webhost1.example.com | Hostname of the first Web host. |
| WEBHOST1\_HOSTNAME\_LABEL | webhost1 | Hostname label for the first Web host. |
| WEBHOST1\_PRODUCTS\_PATH | /u02/private/oracle/products | Where on the first Web host will the OHS product be installed. |
| WEBHOST1\_CONFIG\_PATH | /u02/private/oracle/config | Where on the first Web host will the OHS configuration files be stored. |
| WEBHOST2\_DISPLAY\_NAME | webhost2 | Display name for the second OHS Web host. |
| WEBHOST2\_AD | ad2 | Which availability domain to use for the first Web host. **Note: this value is not the actual availability domain name but a representation of the AD to use. For example: ad1, ad2, or ad3.** |
| WEBHOST2\_SHAPE | VM.Standard.E4.Flex | Which image shape to use for the second Web host. |
| WEBHOST2\_SHAPE\_CONFIG | '{\memoryInGBs\: 16.0, \ocpus\: 1.0}' | Shape configuration for the memory and OCPUs for the second Web host. **Note that entire string must be enclosed inside single quotes and parameter names must be enclosed inside of double quotes that are escaped with a backslash.** |
| WEBHOST2\_PUBLIC\_IP | false | Should the secod Web host get assigned a public IP address. |
| WEBHOST2\_HOSTNAME | webhost2.example.com |  Hostname of the second Web host. |
| WEBHOST2\_HOSTNAME\_LABEL | webhost2 | Hostname label for the second Web host. |
| WEBHOST2\_PRODUCTS\_PATH | /u02/private/oracle/products | Where on the second Web host will the OHS product be installed. |
| WEBHOST2\_CONFIG\_PATH | /u02/private/oracle/config | Where on the second Web host will the OHS configuration files be stored. |

### NFS/Persistent Volume Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| WEBHOST1\_MOUNT\_TARGET\_DISPLAY\_NAME | webhost1-mt | Display name for the mount target used by webhost1. |
| WEBHOST2\_MOUNT\_TARGET\_DISPLAY\_NAME | webhost2-mt | Display name for the mount target used by webhost2. |
| OKE\_MOUNT\_TARGET\_DISPLAY\_NAME | oke-mt | Display name for the mount target used by the OKE nodes. |
| PV\_SECLIST\_DISPLAY\_NAME | pv-seclist | Display name for the persistent volume security list. |
| FS\_WEBBINARIES1\_DISPLAY\_NAME | webbinaries1 | Display name for the NFS file system for the OHS binaries on webhost1. |
| FS\_WEBBINARIES1\_PATH | /export/IAMBINARIES/webbinaries1 | Path to the NFS file system where the OHS binaries are installed on webhost1. |
| FS\_WEBBINARIES2\_DISPLAY\_NAME | webbinaries2 | Display name for the NFS file system for the OHS binaries on webhost2. |
| FS\_WEBBINARIES2\_PATH | /export/IAMBINARIES/webbinaries2 | Path to the NFS file system where the OHS binaries are installed on webhost2. |
| FS\_WEBCONFIG1\_DISPLAY\_NAME | webconfig1 | Display name for the NFS file system for the OHS configuration data on webhost1. |
| FS\_WEBCONFIG1\_PATH | /export/IAMCONFIG/webconfig1 | Path to the NFS file system where the OHS configuration data is installed on webhost1. |
| FS\_WEBCONFIG2\_DISPLAY\_NAME | webconfig2 | Display name for the NFS file system for the OHS configuration data on webhost2. |
| FS\_WEBCONFIG2\_PATH | /export/IAMCONFIG/webconfig2 | Path to the NFS file system where the OHS configuration data is installed on webhost2. |
| FS\_OAMPV\_DISPLAY\_NAME | oampv | Display name for the OAM persistent volume file system. |
| FS\_OAMPV\_NFS\_PATH | /export/IAMPVS/oampv | Path to the NFS file system for the OAM domain. |
| FS\_OAMPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/oampv | Local mount point on the bastion host for the OAM persistent volume. |
| FS\_OIGPV\_DISPLAY\_NAME | oigpv | Display name for the OIG persistent volume file system. |
| FS\_OIGPV\_NFS\_PATH | /export/IAMPVS/oigpv | Path to the NFS file system for the OIG domain. |
| FS\_OIGPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/oigpv | Local mount point on the bastion host for the OIG persistent volume. |
| FS\_OUDPV\_DISPLAY\_NAME | oudpv | Display name for the OUD persistent volume file system. |
| FS\_OUDPV\_NFS\_PATH | /export/IAMPVS/oudpv | Path to the NFS file system for the OUD domain. |
| FS\_OUDPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/oudpv | Local mount point on the bastion host for the OUD persistent volume. |
| FS\_OUDCONFIGPV\_DISPLAY\_NAME | oudconfigpv | Display name for the OUD configuration persistent volume file system. |
| FS\_OUDCONFIGPV\_NFS\_PATH | /export/IAMPVS/oudconfigpv | Path to the NFS file system for the OUD configuration data. |
| FS\_OUDCONFIGPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/oudconfigpv | Local mount point on the bastion host for the OUD configuration data. |
| FS\_OUDSMPV\_DISPLAY\_NAME | oudsmpv | Display name for the OUD services manager persistent volume file system. |
| FS\_OUDSMPV\_NFS\_PATH | /export/IAMPVS/oudsmpv | Path to the NFS file system for the OUD services manager domain. |
| FS\_OUDSMPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/oudsmpv | Local mount point on the bastion host for the OUD services manager persistent volume. |
| FS\_OIRIPV\_DISPLAY\_NAME | oiripv | Display name for the OIRI persistent volume file system. |
| FS\_OIRIPV\_NFS\_PATH | /export/IAMPVS/oiripv | Path to the NFS file system for the OIRI domain. |
| FS\_OIRIPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/oiripv | Local mount point on the bastion host for the OIRI persistent volume. |
| FS\_DINGPV\_DISPLAY\_NAME | dingpv | Display name for the data ingestor persistent volume file system. |
| FS\_DINGPV\_NFS\_PATH | /export/IAMPVS/dingpv | Path to the NFS file system for the OIRI ingestor data. |
| FS\_DINGPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/dingpv | Local mount point on the bastion host for the OIRI ingestor data. |
| FS\_WORKPV\_DISPLAY\_NAME | workpv | Display name for the OIRI working directory  volume file system. |
| FS\_WORKPV\_NFS\_PATH | /export/IAMPVS/workpv | Path to the NFS file system for the OIRI working directory. |
| FS\_WORKPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/workpv | Local mount point on the bastion host for the OIRI working directory. |
| FS\_OAACONFIGPV\_DISPLAY\_NAME | oaaconfigpv | Display name for the OAA configuration persistent volume file system. |
| FS\_OAACONFIGPV\_NFS\_PATH | /export/IAMPVS/oaaconfigpv | Path to the NFS file system for the OAA configuration data. |
| FS\_OAACONFIGPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/oaaconfigpv | Local mount point on the bastion host for the OAA configuration persistent volume data. |
| FS\_OAACREDPV\_DISPLAY\_NAME | oaacredpv | Display name for the OAA credential store persistent volume file system. |
| FS\_OAACREDPV\_NFS\_PATH | /export/IAMPVS/oaacredpv | Path to the NFS file system for the OAA credential store data. |
| FS\_OAACREDPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/oaacredpv | Local mount point on the bastion host for the OAA credential store persistent volume data. |
| FS\_OAAVAULTPV\_DISPLAY\_NAME | oaavaultpv | Display name for the OAA Vault persistent volume file system. |
| FS\_OAAVAULTPV\_NFS\_PATH | /export/IAMPVS/oaavaultpv | Path to the NFS file system for the OAA Vault store data. |
| FS\_OAAVAULTPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/oaavaultpv | Local mount point on the bastion host for the OAA Vault store persistent volume data. |
| FS\_OAALOGPV\_DISPLAY\_NAME | oaalogpv | Display name for the OAA log file persistent volume file system. |
| FS\_OAALOGPV\_NFS\_PATH | /export/IAMPVS/oaalogpv | Path to the NFS file system for the OAA log files. |
| FS\_OAALOGPV\_LOCAL\_MOUNTPOINT | /nfs\_volumes/oaalogpv | Local mount point on the bastion host for the OAA log files. |
| FS\_IMAGES\_DISPLAY\_NAME | images | Display name for the IDM container images persistent volume file system. |
| FS\_IMAGES\_NFS\_PATH | /export/IMAGES/images | Path to the NFS file system for the container images. |
| FS\_IMAGES\_LOCAL\_MOUNTPOINT | /images | Local mount point on the bastion host for the container images. |

### SSL Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| SSL\_CERT\_VALIDITY\_DAYS | 750 | How long into the future to set the SSL certificate validity. |
| SSL\_CERT\_BITS | 2048 | Specifies the default key size for the SSL certificate in bits. |
| SSL\_CN | *.example.com | What domain name to set in the SSL certificate. |

### Internal Load Balancer Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| LBR1\_AD | ad1 | Which availability domain to use for the first internal load balancer. **Note: this value is not the actual availability domain name but a representation of the AD to use. For example: ad1, ad2, or ad3.** |
| LBR1\_DISPLAY\_NAME | lbr-subnet1 | Display name for the first internal load balancer. |
| LBR1\_DNS\_LABEL | lbrsubnet1 | DNS subnet label to use for the first internal load balancer. |
| LBR2\_AD | ad2 | Which availability domain to use for the second internal load balancer. **Note: this value is not the actual availability domain name but a representation of the AD to use. For example: ad1, ad2, or ad3.** |
| LBR2\_DISPLAY\_NAME | lbr-subnet2 | Display name for the second internal load balancer. |
| LBR2\_DNS\_LABEL | lbrsubnet2 | DNS subnet label to use for the second internal load balancer. |

### Load Balancer Log Group Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| LBR\_LOG\_GROUP\_NAME | Default\_Group | Name of the log group that will hold the access and error logs for the public and internal load balancers. |

### Public Load Balancer Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| PUBLIC\_LBR\_ACCESS\_LOG\_DISPLAY\_NAME | public\_loadbalancer\_access | Display name for the public load balancer access log file. |
| PUBLIC\_LBR\_ERROR\_LOG\_DISPLAY\_NAME | public\_loadbalancer\_error | Display name for the public load balancer error log. |
| PUBLIC\_LBR\_CERTIFICATE\_NAME | loadbalancer | Display name for the SSL certificate loaded into the public load balancer. |
| PUBLIC\_LBR\_DISPLAY\_NAME | public-loadbalancer | Display name of the public load balancer. |
| PUBLIC\_LBR\_PRIVATE | false | Should the public load balancer only be assigned an internal IP address. |
| PUBLIC\_LBR\_ROUTE\_TABLE\_DISPLAY\_NAME | lbr-route-table | Display name for the public load balancer route table. |
| PUBLIC\_LBR\_SECLIST\_DISPLAY\_NAME | public-lbr-seclist | Display name for the public load balancer security list. |
| PUBLIC\_LBR\_SHAPE | flexible | Pubic load balancer shape configuration. |
| PUBLIC\_LBR\_SHAPE\_DETAILS | '{\minimumBandwidthInMbps\: 10, \maximumBandwidthInMbps\: 100}' | Min/Max bandwidth values for the public load balancer. |
| PUBLIC\_LBR\_IADADMIN\_DISPLAY\_NAME | iadadmin | Display name for the OAM iadadmin hostname on the public load balancer. |
| PUBLIC\_LBR\_IADADMIN\_HOSTNAME | iadadmin.example.com | Hostname for the OAM iadadmin host on the public load balancer. |
| PUBLIC\_LBR\_IADADMIN\_LISTENER\_DISPLAY\_NAME | iadadmin | Display name for the OAM iadadmin listener on the public load balancer. |
| PUBLIC\_LBR\_IGDADMIN\_DISPLAY\_NAME | igdadmin | Display name for the OIM igdadmin hostname on the public load balancer. |
| PUBLIC\_LBR\_IGDADMIN\_HOSTNAME | igdadmin.example.com | Hostname for the OIM igdadmin host on the public load balancer. |
| PUBLIC\_LBR\_IGDADMIN\_LISTENER\_DISPLAY\_NAME | igdadmin | Display name for the OIM igdadmin listener on the public load balancer. |
| PUBLIC\_LBR\_LOGIN\_DISPLAY\_NAME | login | Display name for the OAM login host on the public load balancer. |
| PUBLIC\_LBR\_LOGIN\_HOSTNAME | login.example.com | Hostname for the OAM login host on the public load balancer. |
| PUBLIC\_LBR\_LOGIN\_LISTENER\_DISPLAY\_NAME | login | Display name for the OAM login listener on the public load balancer. |
| PUBLIC\_LBR\_PROV\_DISPLAY\_NAME | prov | Display name for the OIM provisioning host on the public load balancer. |
| PUBLIC\_LBR\_PROV\_HOSTNAME | prov.example.com | Hostname for the OIM provisioning host on the public load balancer. |
| PUBLIC\_LBR\_PROV\_LISTENER\_DISPLAY\_NAME | prov | Display name for the OIM provisioning listener on the public load balancer. |
| PUBLIC\_LBR\_OHS\_SERVERS\_BS\_NAME | ohs\_servers | Display name for the backend set pointing to the OHS servers. |
| PUBLIC\_LBR\_OHS\_SERVERS\_BS\_POLICY | WEIGHTED\_ROUND\_ROBIN | Load balancing policy for the OHS servers backend set. |
| PUBLIC\_LBR\_OHS\_SERVERS\_BS\_PROTOCOL | HTTP | Protocol used by the public load balancer health checker to determine if the load balancer is accessible. |
| PUBLIC\_LBR\_OHS\_SERVERS\_BS\_URI\_PATH | / | URI used by the public load balancer health checker to determine if the load balancer is accessible. |


### Internal Load Balancer Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| INT\_LBR\_ACCESS\_LOG\_DISPLAY\_NAME | internal\_loadbalancer\_access |  Display name for the internal load balancer access log file. |
| INT\_LBR\_ERROR\_LOG\_DISPLAY\_NAME | internal\_loadbalancer\_error | Display name for the internal load balancer error log. |
| INT\_LBR\_CERTIFICATE\_NAME | loadbalancer | Display name for the SSL certificate loaded into the internal load balancer. |
| INT\_LBR\_PRIVATE | true | Should the internal load balancer only be assigned an internal IP address. |
| INT\_LBR\_SHAPE | flexible | Internal load balancer shape configuration. |
| INT\_LBR\_SHAPE\_DETAILS | '{\minimumBandwidthInMbps\: 10, \maximumBandwidthInMbps\: 100}' | Min/Max bandwidth values for the internal load balancer. |
| INT\_LBR\_DISPLAY\_NAME | internal-loadbalancer | Display name of the internal load balancer. |
| INT\_LBR\_IADADMIN\_DISPLAY\_NAME | iadadmin | Display name for the OAM iadadmin hostname on the internal load balancer. |
| INT\_LBR\_IADADMIN\_HOSTNAME | iadadmin.example.com | Hostname for the OAM iadadmin host on the internal load balancer. |
| INT\_LBR\_IADADMIN\_LISTENER\_DISPLAY\_NAME | iadadmin | Display name for the OAM iadadmin listener on the internal load balancer. |
| INT\_LBR\_IGDADMIN\_DISPLAY\_NAME | igdadmin | Display name for the OIM igdadmin hostname on the internal load balancer. |
| INT\_LBR\_IGDADMIN\_HOSTNAME | igdadmin.example.com | Hostname for the OIM igdadmin host on the internal load balancer. |
| INT\_LBR\_IGDADMIN\_LISTENER\_DISPLAY\_NAME | igdadmin | Display name for the OIM igdadmin listener on the internal load balancer. |
| INT\_LBR\_IGDINTERNAL\_DISPLAY\_NAME | igdinternal | Display name for the OIM igdinternal hostname on the internal load balancer. |
| INT\_LBR\_IGDINTERNAL\_HOSTNAME | igdinternal.example.com | Hostname for the OIM igdinternal host on the internal load balancer. |
| INT\_LBR\_IGDINTERNAL\_LISTENER\_DISPLAY\_NAME | igdinternal | Display name for the OIM igdinternal listener on the internal load balancer. |
| INT\_LBR\_LOGIN\_DISPLAY\_NAME | login | Display name for the OAM login host on the internal load balancer. |
| INT\_LBR\_LOGIN\_HOSTNAME | login.example.com | Hostname for the OAM login host on the internal load balancer. |
| INT\_LBR\_LOGIN\_LISTENER\_DISPLAY\_NAME | login | Display name for the OAM login listener on the internal load balancer. |
| INT\_LBR\_PROV\_DISPLAY\_NAME | prov | Display name for the OIM provisioning host on the internal load balancer. |
| INT\_LBR\_PROV\_HOSTNAME | prov.example.com | Hostname for the OIM provisioning host on the internal load balancer. |
| INT\_LBR\_PROV\_LISTENER\_DISPLAY\_NAME | prov | Display name for the OIM provisioning host on the internal load balancer. 
| INT\_LBR\_OHS\_SERVERS\_BS\_NAME | ohs\_servers | Display name for the backend set pointing to the OHS servers. |
| INT\_LBR\_OHS\_SERVERS\_BS\_POLICY | WEIGHTED\_ROUND\_ROBIN | Load balancing policy for the OHS servers backend set. |
| INT\_LBR\_OHS\_SERVERS\_BS\_PROTOCOL | HTTP | Protocol used by the public load balancer health checker to determine if the load balancer is accessible. |
| INT\_LBR\_OHS\_SERVERS\_BS\_URI\_PATH | / | URI used by the public load balancer health checker to determine if the load balancer is accessible. |

### Network Load Balancer Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| K8\_LBR\_DISPLAY\_NAME | k8workers | Display name for the Kuberentes load balancer. |
| K8\_LBR\_PRIVATE | true | Should the Kubernetes load balancer only be assigned an internal IP address. |
| K8\_LBR\_PRESERVE\_SRC\_DEST | false | Should requests be sent with the entire IP header intact. |
| K8\_LBR\_K8\_WORKERS\_BS\_NAME | kubernetes\_workers | Display name for the backend set pointing to the OHS servers. |
| K8\_LBR\_K8\_WORKERS\_BS\_POLICY | FIVE\_TUPLE | The Kubernetes load balancer policy for the backend set. |
| K8\_LBR\_K8\_WORKERS\_BS\_PRESERVE\_SRC | true | Should requests be sent with the entire IP header intact. |
| K8\_LBR\_LISTENER\_DISPLAY\_NAME | k8workers | Display name for the Kuberentes load balancer listener. |

### Database Configuration
| **Parameter** | **Default Value** | **Comments** | 
| :--- | :--- | :--- | 
| DB\_SUBNET\_DISPLAY\_NAME | db-subnet | Display name for database subnet. |
| DB\_SUBNET\_DNS\_LABEL | dbsubnet | DNS subnet label to use for the database subnet. |
| DB\_SUBNET\_PROHIBIT\_PUBLIC\_IP | true | Should the database only be assigned an internal IP address. |
| DB\_SECLIST\_DISPLAY\_NAME | db-seclist | Display name for the datbabase security list. |
| DB\_ROUTE\_TABLE\_DISPLAY\_NAME | db-route-table | Display name for the database route table. |
| DB\_SQLNET\_PORT | 1521 | Port number of the database SQL*Net listener. |
| DB\_AD | ad1 | Which availability domain to use for the internal load balancer. **Note: this value is not the actual availability domain name but a representation of the AD to use. For example: ad1, ad2, or ad3.** |
| DB\_CPU\_COUNT | 8 | Number of CPUs requested for the database hosts. |
| DB\_EDITION | ENTERPRISE\_EDITION\_EXTREME\_PERFORMANCE | Database edition to install. |
| DB\_VERSION | 19.0.0.0 | Database version to install. |
| DB\_DISPLAY\_NAME | Identity-Management-Database | Display name for the database. |
| DB\_INITIAL\_STORAGE | 256 | Database storage size in GBs. |
| DB\_LICENSE | BRING\_YOUR\_OWN\_LICENSE | Database license type. |
| DB\_NODE\_COUNT | 2 | How many nodes to include in the RAC database installation. |
| DB\_SHAPE | VM.Standard2.4 | Instance shape for the database nodes. |
| DB\_STORAGE\_MGMT | ASM | Database storage management type. |
| DB\_TIMEZONE | UTC | Database timezone. |

## Components of the Deployment Script
| **Filename** | **Directory** | **Purpose** | 
| :--- | :--- | :--- |
| provision\_oci.sh | \$SCRIPT\_DIR/oke\_utils |The main provisioning script. Run this as shown in the `Getting Started` section to create the resources defined in Chapter 9 of the EDG. | 
| delete\_oci.sh | \$SCRIPT\_DIR/oke\_utils |Script to delete all of the resources created by the provisioning script. This script requires the `$WORKDIR/TEMPLATE_NAME/output/TEMPLATE_NAME.ocid` to be available to read the list of resource OCIDs to delete. | 
| create\_idm\_rsp.sh | \$SCRIPT\_DIR/oke\_utils |Script to populate and Identity Management Response file with resources created by the provisioning script. This script will generate a file called `$WORKDIR/TEMPLATE_NAME/output/TEMPLATE_NAME_idm.rsp` this file can be used as the basis of a responsefile used to invoke Oracle Identity Management Enterprise Deployment Automation scripts. |
| oci\_create\_functions.sh | \$SCRIPT\_DIR/oke\_utils/common | Helper script that contains all of the shell functions used by the `provision_oke.sh` script. | 
| oci\_delete\_functions.sh | \$SCRIPT\_DIR/oke\_utils/common | Helper script that contains all of the shell functions used by the `delete_oke.sh` script.| 
| oci\_setup\_functions.sh | \$SCRIPT\_DIR/oke\_utils/common | Helper script that contains all of the functions to setup/configure the Bastion host, WebTiers, and database. | 
| oci\_util\_functions.sh | \$SCRIPT\_DIR/oke\_utils/common | Helper script that contains all of the functions shared between the provisioning and deletion scripts.  | 
| oci\_oke.rsp | \$SCRIPT\_DIR/oke\_utils/responsefile |An example responsefile that is used as a startng point for end-user response files. | 
| oci\_setup\_bastion.sh | \$SCRIPT\_DIR/oke\_utils/utils | Helper script that can be executed manually to configure the Bastion host. The script executes the same functions that are called when the `CONFIGURE_BASTION` parameter is enabled. | 
| oci\_setup\_webhosts.sh | \$SCRIPT\_DIR/oke\_utils/utils |Helper script that can be executed manually to configure the WebTier hosts. The script executes the same functions that are called when the `CONFIGURE_WEBHOSTS` parameter is enabled. | 
| oci\_setup\_database.sh | \$SCRIPT\_DIR/oke\_utils/utils | Helper script that can be executed manually to configure the RAC database. The script executes the same functions that are called when the `CONFIGURE_DATABASE` parameter is enabled. | 

