# Set up Oracle SOA Suite on a Kubernetes cluster

Scripts to deploy Oracle SOA Suite on a Kubernetes cluster.

## Prerequisites

- The passwordless `ssh` access to the master node from where the script is run.
- The `user` with the passwordless sudo access.
- The `user` with access to the Kubernetes cluster from the master node.

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

Update the values in the `maak8soa.env` script with the values for your environment. The script requires information about different properties detailed in the table below with default values:

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
| `wlsoperator_version` | WebLogic Kubernetes Operator version to be used | `3.4.2` |
| `soak8branch` | fmw-kubernetes release version | `22.3.2`  |
| `soaimage` | Oracle SOA Suite Docker image | `soasuite:12.2.1.4`  |
| `soaedgprefix` | RCU prefix for SOA schemas | `K8EDG`|
| `db_url` | Database connection URL | `mydb.example.com:1521/mypdb.example.com` |
| `soaedgdomain` | Oracle SOA Suite domain name | `soaedgdomain`|
| `domain_type` | Type of Oracle SOA Suite domain. Values are `soa` or `osb` or`soaosb`. | `soaosb` |
| `LBR_HN` | Load balancer virtual hostname (front end) | `k8lbr.paasmaaexample.com` |
| `soapdb` | DB PDB that will host the SOA schemas | `SOAPDB`|
| `max_trycountpod` | Number of checks on Kubernetes SOA pod creation | `90` |
| `sleeplapsepod` | Timeout settings for retries on Kubernetes SOA pod check | `20` |

## Deploy Oracle SOA Suite domain

Scripts to deploy an Oracle SOA Suite domain are located in `FMWKubernetesMAA/OracleEnterpriseDeploymentAutomation/OracleSOASuite`. Run the `maak8soa.sh` script to deploy the Oracle SOA Suite domain.

``` bash
$ cd ${EDG_WORKDIR}
$ ./maak8soa.sh
```

The script performs the following operations, among others:
- Deploys Helm.
- Installs WebLogic Kubernetes Operator and configures it.
- Clones the [fmw-kubernetes](https://github.com/oracle/fmw-kubernetes) GitHub repository.
- Creates Kubernetes secrets for RCU schema and domain credentials.
- Creates persistent volume (PV) and persistent volume claim (PVC).
- Creates RCU schemas using the RCU pod.
- Creates the SOA domain YAML file.
- Creates the SOA EDG domain.
- Creates a node port for each of the cluster services in the SOA domain.
