---
title: "Preparing the Bastion host"
date: 2019-09-21T15:44:42-05:00
draft: false
weight: 2
pre: "<b>b. </b>"
description: "Running WebLogic Kubernetes Operator managed Oracle WebCenter Sites domains on OKE"
---

#### STEP 1 : Create Public Security List
Create Public Security List (bastion_public_sec_list) in same VCN as that of OKE Cluster for Bastion Node
* Ingress Rules as: (where 10.0.22.0/24 is the CIDR planned to be used for bastion subnet)
![Bastion](images/bastion-1.png)
*  Egress as:
![Bastion](images/bastion-2.png)

#### STEP 2 : Create Private Security List
Create Private Security List (bastion_private_sec_list) in same VCN as that of OKE Cluster which will be added into Worker Node subnet.
* Ingress Rules as: (where 10.0.22.0/24 is the CIDR planned to be used for bastion subnet)
![Bastion](images/bastion-3.png)
* Egress Rules as:
![Bastion](images/bastion-4.png)

#### STEP 3 : Create Route Table
Create Route Table (oke-bastion-routetables) with below details which will be used for bastion subnet
![Bastion](images/bastion-5.png)

#### STEP 4 : Create Bastion Subnet
Create Bastion Subnet with CIDR Block : 10.0.22.0/24 , RouteTable: oke-bastion-routetables (created in step 3) , Security List: bastion_public_sec_list ( created in  Step 1) and DHCP Options : Default available
![Bastion](images/bastion-subnet-1.png)

#### STEP 5 : Add Private Security to Worker Subnet for bastion access
Add the private security list (bastion_private_sec_list), created at Step 2 to Worker Subnet, so that bastion node can ssh to Worker Nodes
![Bastion](images/bastion-subnet-2.png)

#### STEP 6 : Create Bastion Node
Create Bastion Node with Subnet as "bastion-subnet", created at Step 4,  Add the private security list (bastion_private_sec_list), created at Step 2 to Worker Subnet, so that bastion node can ssh to Worker Nodes
* Update Name for the instance, Chose the Operating System Image, Availability Domain and Instance Type
![Bastion](images/create-bastion-1.png)
* Select the Compartment, VCN and Subnet Compartment where Cluster is created.  Select the regional bastion-subnet created at Step4. Make sure to click on "Assign a public IP address".
![Bastion](images/create-bastion-2.png)
* Once the bastion is created as shown below
![Bastion](images/create-bastion-3.png)

#### STEP 7 : Access Worker Node from bastion host
a. Login to bastion host

```
scp -i id_rsa id_rsa opc@<bastion-host-address>:/home/opc
ssh -i id_rsa opc@<bastion-host-address>
```

b. Place a copy of id_rsa in bastion node to access worker node
```
ssh -i id_rsa opc@10.0.1.5
```

  More details refer: https://docs.cloud.oracle.com/en-us/iaas/Content/Resources/Assets/whitepapers/bastion-hosts.pdf
