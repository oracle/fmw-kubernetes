## Deploy Oracle SOA Suite on Oracle Kubernetes Engine (OKE)

This page walks you through the steps required to provision a Kubernetes cluster on Oracle Kubernetes Engine, with a database for the SOA Suite schemas and a file storage mountpath to store the SOA Suite domain files, and Oracle SOA Suite in Kubernetes.

If you need more detailed instructions, refer to the [Install Guide](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/install-guide.html).

1. [Prerequistes](#prerequistes)
2. [Create a Kubernetes cluster on OKE](#create-a-kubernetes-cluster-on-oke)
3. [Set up access to your Cluster](#set-up-access-to-your-cluster)
4. [Install tools](#install-tools)
5. [Create storage for Domain Home](#create-storage-for-domain-home)
6. [Create an ingress controller](#create-an-ingress-controller)
7. [Create an Oracle SOA Suite domain](#create-an-oracle-soa-suite-domain)


### Prerequistes

To deploy Oracle SOA Suite on Container Engine for Kubernetes, ensure you have available resources and quota for:

- One file storage systems.
- One mount target.
- One Database, either an on-premise Database or Oracle Base Database Service or Oracle Single Instance Database using Database Operator.
- One Kubernetes cluster and a node pool with the required number of nodes as per your requirement.
  
> **Note**: 
> - Refer the resource [sizing](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/domain-resource-sizing.html) and [prerequistes](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/requirements-and-pricing.html) and choose the node pool shape needed for an Oracle SOA Suite domains, one OCPU will not be sufficient.

> - Default cluster block volume size may be inadequate. Refer to [this documentation](https://docs.oracle.com/en-us/iaas/Content/Block/Tasks/resizingavolume.htm) for instructions on resizing the volume. It is recommended to allocate a minimum of 300 GB for each node. 

### Create a Kubernetes cluster on OKE

You can create a Kubernetes cluster using Container Engine for Kubernetes (OKE). See [here](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/create-cluster.htm#create-cluster) for details.

To ensure high availability, Container Engine for Kubernetes:

- Creates the Kubernetes Control Plane on multiple Oracle-managed control plane nodes (distributing the control plane nodes across different availability domains in a region, where supported).
- Creates worker nodes in each of the fault domains in an availability domain (distributing the worker nodes as evenly as possible across the fault domains, subject to any other infrastructure restrictions).


#### Preparing for OKE

Before you start creating the Container Engine for Kubernetes, refer the [Preparing for Container Engine for Kubernetes](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengprerequisites.htm#Preparing_for_Container_Engine_for_Kubernetes) and find out if you have met some of the below requirements:
- Access to an Oracle Cloud Infrastructure tenancy.
- Check the service limits for the components listed in [Prerequistes](#prerequistes) in your Oracle Cloud Infrastructure tenancy and, if necessary, request a service limit increase.
- Belong to  tenancy's Administrators group and also have appropriate Container Engine for Kubernetes permissions
- Access to perform Kubernetes operations on a cluster.


#### Create a compartment

Within your tenancy, there must already be a compartment to contain the necessary network resources (such as a VCN, subnets, internet gateway, route table, security lists). If such a compartment does not exist already, you will have to create it. Note that the network resources can reside in the root compartment. However, if you expect multiple teams to create clusters, best practice is to create a separate compartment for each team.

Refer [Managing Compartments](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingcompartments.htm) and [Network Resource Configuration for Cluster Creation and Deployment](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm) for more details.

#### Create a compartment policies

To create and/or manage clusters, you must belong to one of the following:
- The tenancy's Administrators group
- A group to which a policy grants the appropriate Container Engine for Kubernetes permissions.

See [Policy Configuration for Cluster Creation and Deployment](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengpolicyconfig.htm) for details.

#### Create an OKE Cluster
Create a new Kubernetes clusters using Container Engine for Kubernetes to create new Kubernetes clusters. You can create clusters using the Console, the CLI, and the API. See [Creating a Cluster](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/create-cluster.htm#create-cluster) for details.

#### Create node pool
When you create a new cluster using the Console, can create managed node pools using the Console. See [here](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/create-node-pool.htm) to create new managed node pools using the Console, the CLI, or the API.

If your worker nodes are configured as private, you will need to establish a bastion host to access them. Refer [Managing Bastions](https://docs.oracle.com/en-us/iaas/Content/Bastion/Tasks/managingbastions.htm).

### Set up access to your Cluster
Container Engine for Kubernetes creates a Kubernetes kubeconfig configuration file that you use to access the cluster using kubectl. Refer [Setting Up Cluster Access](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm) and create access via [Cloud Shell](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#cloudshelldownload) or [Local access](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm#localdownload).

### Install tools
Once you have setup the cluster access, verify or install the below  versions of the tools required for deploying Oracle SOA Suite domain:
    - **kubectl** (>= 1.24) : See [here](https://kubernetes.io/docs/tasks/tools/#kubectl) for the installation instructions.
    - **Helm** (>= 3.10.2): Helm is a Kubernetes deployment package manager. See [here](https://helm.sh/docs/intro/install) to install helm locally.

### Create storage for domain home

You can use the File Storage service to provision persistent volume claims which will be used for domain home. Refer [Provisioning PVCs on the File Storage Service](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingpersistentvolumeclaim_Provisioning_PVCs_on_FSS.htm) for details in the OCI documentation. 

[Sample](https://github.com/oracle/fmw-kubernetes/blob/master/OracleSOASuite/kubernetes/oke/samples) files are available for provisioning a PVC using the CSI Volume Plugin. You can update the ```fss-dyn-st-class.yaml``` and ```fss-dyn-claim.yaml``` files with the relevant parameters to provision the PVC for the domain.

Also see [WebLogic Kubernetes Operator documentation](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/persistent-storage/oci-fss-pv/) for updating the permissions of shared directory to 1000:0 for domain home.


### Create an ingress controller

When you create clusters using Container Engine for Kubernetes, you can set up:

- The OCI native ingress controller.

- A third-party ingress controller such as Nginx or Traefik ingress controller.

See [Managing Ingress Controllers](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengmanagingresscontrollers.htm).

See [SOA on Kubernetes documentation](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/set-load-balancer.html) for installation details on third-party ingress controller. Note to set the `service.type` to `LoadBalancer`, so that OCI provisions the LoadBalancer.

### Create an Oracle SOA Suite domain

#### Prepare for domain

See [SOA on Kubernetes documentation](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/prepare-your-environment.html) for preparing the environment for Oracle SOA Suite domains.

Addtionally see below steps:

- You need to create a Kubernetes secret to enable pulling the Oracle SOA Suite image from the registry.
    ```shell
      $ kubectl -n DOMAIN_NAMESPACE create secret docker-registry image-secret \
         --docker-server=container-registry.oracle.com \
         --docker-username=YOUR_REGISTRY_USERNAME \
         --docker-password=YOUR_REGISTRY_PASSWORD \
         --docker-email=YOUR_REGISTRY_EMAIL
    ```
    Replace DOMAIN_NAMESPACE, YOUR_REGISTRY_USERNAME, YOUR_REGISTRY_PASSWORD, and YOUR_REGISTRY_EMAIL with the values you use to access the registry.

- While creating a persistent storage as per [link](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/prepare-your-environment.html), make sure to set the `weblogicDomainStorageType` to NFS  and `weblogicDomainStoragePath`  to the address obtained in [Create Storage for Domain home](#create-storage-for-domain-home).

#### Create the domain

See [SOA on Kubernetes documentation](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/create-oracle-soa-suite-domains.html) for details on creation of an Oracle SOA Suite domain.

Note that, the default timeout value of `600s` may not be sufficient for creating the domain on OKE, hence pass a sufficient timeout value greater than `600` with `-t`.

#### Configure ingress contoller to access Oracle SOA Suite domain services

Refer [OCI documentation](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengsettingupnativeingresscontroller.htm#contengsettingupnativeingresscontroller-createresources), in case you have set up OCI native ingress controller.

See [SOA on Kubernetes documentation](https://docs.oracle.com/en/middleware/soa-suite/soa/14.1.2/soakn/set-load-balancer.html) for creating the ingress resources on third-party ingress controllers.
