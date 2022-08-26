---
title: "Topology"
date: 2022-06-22T15:44:42-05:00
draft: false
weight: 1
pre : "<b>a. </b>"
description: "Topology for Oracle SOA Suite Enterprise Deployment on Kubernetes."
---  

### Assumptions

The most relevant assumptions for the Oracle SOA Suite Kubernetes Enterprise Deployment Guide (EDG) topology are related to the database and web tiers. Typical on-premises production systems keep their high end database (such as RAC, RAC+DG, Exadata, Autonomous Database) out of the Kubernetes cluster and manage that tier separately. This implies that the database runs separately from the Kubernetes cluster hosting the application tier. The database provisioning and configuration process is out of the scope of the Oracle SOA Suite Kubernetes setup. Typically, it is administered and maintained by different teams and the Oracle SOA Suite Enterprise Deployment Guide would need to consume just the scan address and database service to be used for the RCU and data source creation. Similarly, the demilitarized zone (DMZ) will likely remain untouched: Customer investments in load balancers (LBRs) are well consolidated, and the security and DMZ policies are well established. Using an HTTP proxy in the DMZ has become a standard. Additionally, Single Sign On (such as OAM and others) may remain for some time and those are best addressed in the web tier than as part of the Kubernetes cluster.

Due to total cost of ownership reasons, the Kubernetes control plane uses a [stacked etcd](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/#stacked-etcd-topology). External etcd is also possible but, given RAFT protocol's reliability, this option requires a significant amount of additional setup work and three additional nodes just to host the etcd system.

### Topology Diagram

![Topology](/fmw-kubernetes/images/soa-domains/SOA_EDG_Topology.png)

### Tier Description
#### Control Plane
The control plane consists of three nodes where the Kubernetes API server is deployed, front-ended by a load balancer (LBR). The LBR exposes the required virtual IP address (VIP) and virtual server (VS) for both the Oracle SOA Suite and the control plane itself (although an internal-only VS can also be used). This URL must be site or data center agnostic in preparation for disaster protection. The control plane and worker nodes must be able to resolve this hostname name properly AND SHOULD NOT USE IPs for it. As explained in the assumptions section, the etcd tier is stacked with the `kube-api` servers. Each control plane node runs Kubernetes `kube-api`, `kube-controller`, `kube-scheduler`, and `etcd` instances pointing to local etcd mounts. The etcd has been tested by the Maximum Availability Architecture (MAA) team on DBFS, NFS, and local file systems. No significant performance differences were observed between the two options for an Oracle SOA Suite system. However, this decision may require additional analysis in each customer case depending on the usage by other apps in the same cluster. Using etcd directly on DBFS allows shipping etcd directly to secondary data centers and allows flashing back quickly to previous versions of the control plane using DB technology. However, it creates a dependency between etcd and the database that is discouraged. The etcd snapshots CAN, however, be placed on DBFS to simplify the continuous shipping of copies to secondary regions and leaving it to Data Guard. These are the options that will be applicable or not depending on the customer needs:

- Place etcd on root or local volumes, ship snapshots with regular rsyncs over reliable networks.
- Place etcd on NFS, ship snapshots with regular rsyncs over reliable networks.
- Place etcd on NFS or local volume, copy snapshots to DBFS for shipping to secondary.
- Application tier.

#### Application Tier

Oracle SOA Suite internal applications and custom deployments on SOA (composites) and WebLogic (ears, jars, wars) are run on three worker nodes in the Kubernetes cluster. The typical allocation on Kubernetes places the WebLogic Administration Server on the first node and each of the servers in the Oracle SOA Suite and/or Service Bus clusters in the other two. This can vary depending on the workloads and kube controller and scheduler decisions.

```bash
$ kubectl get pods -A -o wide | grep soa
soans         soaedgdomain-adminserver                         1/1     Running     0          19h   10.244.3.127   olk8-w1   <none>           <none>
soans         soaedgdomain-create-soa-infra-domain-job-6pq9z   0/1     Completed   0          67d   10.244.4.2     olk8-w2   <none>           <none>
soans         soaedgdomain-soa-server1                         1/1     Running     0          22h   10.244.5.161   olk8-w3   <none>           <none>
soans         soaedgdomain-soa-server2                         1/1     Running     0          22h   10.244.4.178   olk8-w2   <none>           <none>

```

The application tier is critically dependent on the Kubernetes DNS pods to be able to resolve the scan address for the RAC database.

A dual configuration for persistent volumes is used to avoid a single point of failure in the Oracle SOA Suite domain configuration. Two separate NFS devices are used for high availability. Refer to the [Configure redundant persistent volume](../setup-edg/#configure-redundant-persistent-volume) for details.

The internal Oracle SOA Suite and Service Bus clusters use some of the configuration best practices prescribed for on-premises systems. Refer to the [Enterprise Deployment Guide for Oracle SOA Suite 12c (12.2.1.4)](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/soedg/understanding-enterprise-deployment.html):

- Automatic Service Migration is used for the Java Message Service (JMS) and Java Transaction API (JTA) Services.

- All the persistent stores are JDBC persistent stores.

- Node manager is used to monitor the managed server's health.


There are significant differences with an on-premises Enterprise Deployment Guide. The most relevant are:

- WebLogic Kubernetes Operator is used to manage the lifecycle of the managed servers, instead of the WebLogic Administration Console or WLST.

- Scale out procedures are based on the Kubernetes cluster.

- The WebLogic Administration Server does NOT use its own/separate WebLogic domain directory.

- Listen addresses and hostnames are "virtual" out-of-the-box, which provides a significant advantage when considering disaster protection.

- The OHS/DMZ tier routes to the back-end WebLogic clusters and Administration Server, using a precise node port available in the different nodes.
