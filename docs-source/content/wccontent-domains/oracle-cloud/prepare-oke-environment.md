+++
title = "Preparing an OKE environment"
date =  2021-02-14T16:43:45-05:00
weight = 1
pre = "<b>1 a.  </b>"
description = "Running WebLogic Kubernetes Operator managed WebCenter Content domain on Oracle Kubernetes Engine (OKE)."
+++

#### Contents
* [Create Public SSH Key to access all the Bastion and Worker nodes](#create-public-ssh-key-to-access-all-the-bastion-and-worker-nodes)
* [Create a compartment for OKE](#create-a-compartment-for-oke)
* [Create Container Clusters (OKE)](#create-container-clusters-oke)
* [Create Bastion Node to access Cluster](#create-bastion-node-to-access-cluster)
* [Setup OCI CLI to download kubeconfig and access OKE Cluster](#setup-oci-cli)


#### Create Public SSH Key to access all the Bastion and Worker nodes
Create SSH key using `ssh-keygen` on linux terminal to access (ssh) the Compute 
instances (worker/bastion) in OCI.

```bash
ssh-keygen -t rsa -N "" -b 2048 -C demokey -f id_rsa
```

#### Create a compartment for OKE
Within your tenancy, there must be a compartment to contain the necessary network resources (VCN, subnets, internet gateway, route table, security lists).
1. Go to OCI console, and use the top-left Menu to select the Identity > Compartments option.
2. Click the `Create Compartment` button.
3. Enter the compartment name(For example, WCCStorage) and description(OKE compartment), the click the `Create Compartment` button.

#### Create Container Clusters (OKE)
1. In the Console, open the navigation menu. Go to `Developer Services` and click `Kubernetes Clusters (OKE)`.
![OKE-CLUSTER](images/cluster-1.PNG)
1. Choose a Compartment you have permission to work in. Here we will use WCCStorage compartment.
1. On the Cluster List page, select your Compartment and click Create Cluster.![OKE-CLUSTER](images/cluster-2.PNG)
1. In the Create Cluster dialog, select Quick Create and click Launch Workflow.
![OKE-CLUSTER](images/cluster-4.PNG)
1. On the Create Cluster page specify the values as per your environment (like the sample values shown below)
   * NAME:  WCCOKEPHASE1
   * COMPARTMENT: WCCStorage
   * KUBERNETES VERSION: v1.23.4
   * CHOOSE VISIBILITY TYPE: Private
   * SHAPE: VM.Standard.E3.Flex  (Choose the available shape for worker node pool. The list shows only those shapes available in your tenancy that are supported by Container Engine for Kubernetes. See Supported Images and Shapes for Worker Nodes.)
   * NUMBER OF NODES:  3 (The number of worker nodes to create in the node pool, placed in the regional subnet created for the 'quick cluster').
   * Click Show Advanced Options and enter PUBLIC SSK KEY:  ssh-rsa AA......bmVnWgX/ demokey      (The public key id_rsa.pub created at Step1)
![OKE-CLUSTER](images/cluster-5.PNG)   
1. Click Next to review the details you entered for the new cluster.   
![OKE-CLUSTER](images/OCI-Console-OKE-Cluster-Creation-2.png)
1. Click `Create Cluster` to create the new network resources and the new cluster.
![OKE-CLUSTER](images/cluster-7.PNG)
1. Container Engine for Kubernetes starts creating resources (as shown in the Creating cluster and associated network resources dialog). Click Close to return to the Console.
![OKE-CLUSTER](images/cluster-8.jpg)
1. Initially, the new cluster appears in the Console with a status of Creating. When the cluster has been created, it has a status of Active.
![OKE-CLUSTER](images/cluster-9.PNG)
1. Click on the `Node Pools` on Resources and then `View` to view the Node Pool and worker node status
![OKE-CLUSTER](images/cluster-10.PNG)
1. You can view the status of Worker node and make sure all Node State in Active and Kubernetes Node Condition is Ready.The worker node gets listed in the kubectl command once the `Kubernetes Node Condition` is Ready.
![OKE-CLUSTER](images/cluster-11.PNG)
1. To access the Cluster, Click on `Access Cluster` on the Cluster `WCCOKEPHASE1` page.
![OKE-CLUSTER](images/cluster-12.PNG)
1. We will be creating the bastion node and then access the Cluster.

#### Create Bastion Node to access Cluster
Setup a bastion node for accessing internal resources.
We will create the bastion node in same VCN following below steps, so that we can ssh into worker nodes.
Here we will choose `CIDR Block: 10.0.22.0/24` . You can choose a different block, if you want.

1. Click on the VCN Name from the Cluster Page as shown below
![Bastion-Node](images/vcn-name-1.PNG)
1. Next Click on `Security List` and then `Create Security List`
![Bastion-Node](images/security-list-2.PNG)
1. Create a `bastion-private-sec-list` security with below Ingress and Egress Rules.

    Ingress Rules:   
    ![Bastion-Node](images/bastion-private-sc-ingress-3.PNG)
	Egress Rules:
	![Bastion-Node](images/bastion-private-scl-egress-3.1.PNG)
1. Create a `bastion-public-sec-list` security with below Ingress and Egress Rules.

   Ingress Rules:   
    ![Bastion-Node](images/bastion-pblic-sl-ingress-4.PNG)
   Egress Rules:
	![Bastion-Node](images/bastion-pblic-sl-egress-4.1.PNG)
1. Create the `bastion-route-table` with `Internet Gateway`, so that we can add to bastion instance for internet access
![Bastion-Node](images/route-table-5.PNG)
1. Next create a Regional Public Subnet for bastion instance with name `bastion-subnet` with below details:
   * CIDR BLOCK:         10.0.22.0/24
   * ROUTE TABLE:   oke-bastion-routetables
   * SUBNET ACCESS: PUBLIC SUBNET
   * Security List: bastion-public-sec-list
   * DHCP OPTIONS:  Select the Default DHCP Options
   ![Bastion-Node](images/crearte-subnet-6.PNG)
   ![Bastion-Node](images/subnet-6.1.PNG)
1. Next Click on the Private Subnet which has Worker Nodes
![Bastion-Node](images/Private-subnet-7.PNG)
1. And then add the `bastion-private-sec-list` to Worker Private Subnet, so that bastion instance can access the Worker nodes
![Bastion-Node](images/private-sl-8.PNG)
1. Next Create Compute Instance `oke-bastion` with below details
   * Name: BastionHost
   * Image: Oracle Linux 7.X
   * Availability Domain:  Choose any AD which has limit for creating Instance
   * VIRTUAL CLOUD NETWORK COMPARTMENT: WCCStorage( i.e., OKE Compartment)
   * SELECT A VIRTUAL CLOUD NETWORK: Select VCN created by Quick Cluster
   * SUBNET COMPARTMENT: WCCStorage ( i.e., OKE Compartment)
   * SUBNET: bastion-subnet (create above)
   * SELECT ASSIGN A PUBLIC IP ADDRESS
   * SSH KEYS:  Copy content of id_rsa.pub created in Step1
   ![Bastion-Node](images/create-instance-9.1.PNG)
   ![Bastion-Node](images/create-instance-9.2.PNG)
   ![Bastion-Node](images/OCI-Console-OKE-Bastion-VCN-CreateBastionInstance3.jpg)
1. Once bastion Instance `BastionHost` is created, get the Public IP to ssh into the bastion instance
![Bastion-Node](images/bastionhost-detail-10.PNG)
1. Login to bastion host as below
   ```bash
   ssh -i <your_ssh_bastion.key> opc@123.456.xxx.xxx
   ```
#### Setup OCI CLI
1. Install OCI CLI
   ```bash
   bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"
   ```
1. Respond to the Installation Script Prompts.
1. To download the kubeconfig later after setup, we need to setup the oci config file. Follow the below command and enter the details when prompted
   ```bash
   $ oci setup config
   ```
   {{%expand "Click here to see the Sample Output" %}}
   ```
   $ oci setup config
   This command provides a walkthrough of creating a valid CLI config file.
 
   The following links explain where to find the information required by this
   script:
 
    User API Signing Key, OCID and Tenancy OCID:
 
        https://docs.cloud.oracle.com/Content/API/Concepts/apisigningkey.htm#Other
 
    Region:
 
        https://docs.cloud.oracle.com/Content/General/Concepts/regions.htm
 
    General config documentation:
 
        https://docs.cloud.oracle.com/Content/API/Concepts/sdkconfig.htm
 
 
   Enter a location for your config [/home/opc/.oci/config]:
   Enter a user OCID: ocid1.user.oc1..aaaaaaaao3qji52eu4ulgqvg3k4yf7xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   Enter a tenancy OCID: ocid1.tenancy.oc1..aaaaaaaaf33wodv3uhljnn5etiuafoxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   Enter a region (e.g. ap-hyderabad-1, ap-melbourne-1, ap-mumbai-1, ap-osaka-1, ap-seoul-1, ap-sydney-1, ap-tokyo-1, ca-montreal-1, ca-toronto-1, eu-amsterdam-1, eu-frankfurt-1, eu-zurich-1, me-jeddah-1, sa-saopaulo-1, uk-gov-london-1, uk-london-1, us-ashburn-1, us-gov-ashburn-1, us-gov-chicago-1, us-gov-phoenix-1, us-langley-1, us-luke-1, us-phoenix-1): us-phoenix-1
   Do you want to generate a new API Signing RSA key pair? (If you decline you will be asked to supply the path to an existing key.) [Y/n]: Y
   Enter a directory for your keys to be created [/home/opc/.oci]:
   Enter a name for your key [oci_api_key]:
   Public key written to: /home/opc/.oci/oci_api_key_public.pem
   Enter a passphrase for your private key (empty for no passphrase):
   Private key written to: /home/opc/.oci/oci_api_key.pem
   Fingerprint: 74:d2:f2:db:62:a9:c4:bd:9b:4f:6c:d8:31:1d:a1:d8
   Config written to /home/opc/.oci/config
 
 
    If you haven't already uploaded your API Signing public key through the
    console, follow the instructions on the page linked below in the section
    'How to upload the public key':
 
        https://docs.cloud.oracle.com/Content/API/Concepts/apisigningkey.htm#How2
   
   ```
{{% /expand %}}
1. Now you need to upload the created public key in $HOME/.oci (oci_api_key_public.pem) to OCI console
Login to OCI Console and navigate to `User Settings`, which is in the drop down under your OCI userprofile, located at the top-right corner of the page.
   ![Bastion-Node](images/ocir-image-1.PNG)
1. On User Details page, Click `Api Keys` link, located near bottom-left corner of the page and then Click the `Add API Key` button. Copy the content of `oci_api_key_public.pem` and Click `Add`.
   ![Bastion-Node](images/api-public-key-5.png)
1. Now you can use the oci cli to access the OCI resources.
1. To access the Cluster, Click on `Access Cluster` on the Cluster `WCCOKEPHASE1` page
   ![Bastion-Node](images/cluster-12.PNG)
1. To access the Cluster from Bastion node perform steps as per the `Local Access`.
   ![Bastion-Node](images/local-access-8.PNG)
   ```bash
   $ oci -v
   $ mkdir -p $HOME/.kube
 
   $ oci ce cluster create-kubeconfig --cluster-id ocid1.cluster.oc1.phx.aaaaaaaaae4xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxrqgjtd 
   --file $HOME/.kube/config --region us-phoenix-1 --token-version 2.0.0
 
   $ export KUBECONFIG=$HOME/.kube/config
   ```
1. Install kubectl Client to access the Cluster
   ```bash
   $ curl -LO https://dl.k8s.io/release/v1.15.7/bin/linux/amd64/kubectl
   $ sudo mv kubectl  /bin/
   $ sudo chmod +x /bin/kubectl
   ```
1. Access the Cluster from bastion node
   ```bash
   $ kubectl get nodes
   NAME          STATUS   ROLES   AGE   VERSION
   10.0.10.197   Ready    node    14d   v1.23.4
   10.0.10.206   Ready    node    14d   v1.23.4
   10.0.10.50    Ready    node    14d   v1.23.4
   ```
1. Install required add-ons for Oracle WebCenter Content Cluster setup
   * Install helm v3
     ```bash
     $ wget https://get.helm.sh/helm-v3.5.4-linux-amd64.tar.gz
     $ tar -zxvf  helm-v3.5.4-linux-amd64.tar.gz
     $ sudo mv linux-amd64/helm  /bin/helm
     $ helm version
     version.BuildInfo{Version:"v3.5.4", GitCommit:"1b5edb69df3d3a08df77c9902dc17af864ff05d1", GitTreeState:"clean", GoVersion:"go1.15.11"}
     ```
   * Install git
     ```bash
     sudo yum install git -y
     ```
