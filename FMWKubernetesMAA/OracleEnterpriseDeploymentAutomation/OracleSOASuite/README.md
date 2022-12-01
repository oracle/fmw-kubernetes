# Set up Oracle SOA Suite on a Kubernetes cluster

Scripts to set up Kubernetes Cluster and deploy Oracle SOA Suite.

## Prerequisites

- The passwordless `ssh` access to the master node from where the script is run.
- The `user` with the passwordless sudo access.

## Set up the code repository

- Create a working directory to set up the source code:
  ```bash
  $ mkdir $HOME/soa_edg
  $ cd $HOME/soa_edg
  ```

- Download the deployment scripts from the `fmw-kubernetes` repository. Required scripts are available at `FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleSOASuite`:

  ```bash
  $ cd ${HOME}/soa_edg
  $ git clone https://github.com/oracle/fmw-kubernetes.git
  $ export EDG_WORKDIR=$HOME/soa_edg/fmw-kubernetes/FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleSOASuite
  $ cd ${EDG_WORKDIR}
  ```

## Set environment values

Update the values in the `maak8master.env`, `maak8worker.env` and `maak8soa.env` script with the values for your environment. The script requires information about different properties detailed in the table below with default values:

| Parameter | Description | Default |
| --- | --- | --- |
| `share_dir` | Kubernetes PV shared storage that will host the Oracle SOA Suite domain. | `/k8nfs` |
| `script_dir` | Directory for deployment scripts | `/scripts` |
| `output_dir` | Location to generate the output log and deployment files | `/soak8edg/output$dt` |
| `user` | User with passwordless sudo access to the master node| `myuser` |
| `ssh_key` | ssh key for master node access | `/home/myuser/KeySOAMAA.ppk` |
| `mnode1` | Kubernetes control plane node1 hostname | `olk8-m1` |
| `mnode2` | Kubernetes control plane node2 hostname | `olk8-m2` |
| `mnode3` | Kubernetes control plane node3 hostname | `olk8-m3` |
| `wnode1` | Worker node1 hostname | `olk8-w1` |
| `wnode2` | Worker node2 hostname | `olk8-w2` |
| `wnode3` | Worker node3 hostname | `olk8-w3` |
| `helm_version` | Helm version to be used | `3.5.4` |
| `wlsoperator_version` | WebLogic Kubernetes Operator version to be used | `3.4.4` |
| `soak8branch` | fmw-kubernetes release version | `22.4.2`  |
| `soaimage` | Oracle SOA Suite Docker image | `soasuite:12.2.1.4`  |
| `soaedgprefix` | RCU prefix for SOA schemas | `K8EDG`|
| `db_url` | Database connection URL | `mydb.example.com:1521/mypdb.example.com` |
| `soaedgdomain` | Oracle SOA Suite domain name | `soaedgdomain`|
| `domain_type` | Type of Oracle SOA Suite domain. Values are `soa` or `osb` or`soaosb`. | `soaosb` |
| `LBR_HN` | Load balancer virtual hostname (front end) | `k8lbr.paasmaaexample.com` |
| `soapdb` | DB PDB that will host the SOA schemas | `SOAPDB`|
| `pod_network_cidr` | CIDR for pod network | `10.244.0.0/16`|
| `proxy` | Boolean value indicating presence of proxy server details | `false`|
| `http_proxy` | HTTP proxy server as http://<Proxy-Server-IP-Address>:<Proxy_Port> | |
| `https_proxy` | HTTPS proxy server as https://<Proxy-Server-IP-Address>:<Proxy_Port> | |
| `no_proxy` | List of destination addresses or other network CIDRs to exclude proxying | |
| `max_trycountpod` | Number of checks on Kubernetes SOA pod creation | `90` |
| `sleeplapsepod` | Timeout settings for retries on Kubernetes SOA pod check | `20` |

## Set up Master nodes
Script to set up master nodes are located in `FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleSOASuite`. Run the `maak8master.sh` script to set up Kubernetes master nodes.

``` bash
$ cd ${EDG_WORKDIR}
$ ./maak8master.sh
```
The script performs the following operations, among others:
- Configures Operating system for IPV4 and firewalld requirements.
- Install and configures Docker.
- Installs kube packages required for Kubernetes setup with `kubeadm`.
- Set up Master nodes.
- Installs Helm.

## Set up Worker nodes
Script to add worker nodes to Master nodes are located in `FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleSOASuite`. Run the `maak8worker.sh` script to add worker nodes.

``` bash
$ cd ${EDG_WORKDIR}
$ ./maak8worker.sh
```

The script performs the following operations, among others:
- Configures Operating system for IPV4 and firewalld requirements.
- Install and configures Docker.
- Installs kube packages required for Kubernetes setup with `kubeadm`.
- Adds worker node to the Master node.

## Deploy Oracle SOA Suite domain

Scripts to deploy an Oracle SOA Suite domain are located in `FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleSOASuite`. Run the `maak8soa.sh` script to deploy the Oracle SOA Suite domain.

``` bash
$ cd ${EDG_WORKDIR}
$ ./maak8soa.sh
```

The script performs the following operations, among others:
- Installs WebLogic Kubernetes Operator and configures it.
- Clones the [fmw-kubernetes](https://github.com/oracle/fmw-kubernetes) GitHub repository.
- Creates Kubernetes secrets for RCU schema and domain credentials.
- Creates persistent volume (PV) and persistent volume claim (PVC).
- Creates RCU schemas using the RCU pod.
- Creates the SOA domain YAML file.
- Creates the SOA EDG domain.
- Creates a node port for each of the cluster services in the SOA domain.
