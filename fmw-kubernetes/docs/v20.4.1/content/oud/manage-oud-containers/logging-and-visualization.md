---
title: "a) Logging and Visualization for Helm Chart oud-ds-rs Deployment"
date: 2019-02-22T15:44:42-05:00
draft: false
description: "Describes the steps for logging and visualization with Elasticsearch and Kibana."
---

1. [Introduction](#introduction)
1. [Installation](#installation)
	1. [Enable Elasticsearch, Logstash, and Kibana](#enable-elasticsearch-logstash-and-kibana)
	1. [Create Data Mount Points](#create-data-mount-points)
	1. [Configure Logstash](#configure-logstash)
	1. [Install or Upgrade Oracle Unified Directory Container with ELK Configuration](#install-or-upgrade-oracle-unified-directory-container-with-elk-configuration)
	1. [Configure ElasticSearch](#configure-elasticsearch)
1. [Verify Using the Kibana Application](#verify-using-the-kibana-application)

### Introduction

This section describes how to install and configure logging and visualization for the [oud-ds-rs]({{< relref "/oud/create-oud-instances-helm/oud-ds-rs" >}}) Helm Chart deployment.

The ELK stack consists of Elasticsearch, Logstash, and Kibana. Using ELK we can gain insights in real-time from the log data from your applications.

* Elasticsearch is a distributed, RESTful search and analytics engine capable of solving a growing number of use cases. As the heart of the Elastic Stack, it centrally stores your data so you can discover the expected and uncover the unexpected.
* Logstash is an open source, server-side data processing pipeline that ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite “stash.”
* Kibana lets you visualize your Elasticsearch data and navigate the Elastic Stack. It gives you the freedom to select the way you give shape to your data. And you don’t always have to know what you're looking for.

### Installation

ELK can be enabled for environments created using the Helm charts provided with this project.  The example below will demonstrate installation and configuration of ELK for the `oud-ds-rs` chart.

#### Enable Elasticsearch, Logstash, and Kibana

Edit `logging-override-values.yaml` and set the `enabled` flag for each component to 'true'.

```
elk:
  elasticsearch:
    enabled: true
...
kibana:
    enabled: true
...
  logstash:
    enabled: true
...
elkVolume:
  # If enabled, it will use the persistent volume.
  # if value is false, PV and PVC would not be used and there would not be any mount point available for config
  enabled: true
  type: networkstorage
  networkstorage:
    nfs:
      server: myserver
      path: /scratch/oud_elk_data
```

**Note**: if `elkVolume.enabled` is set to 'true' you should supply a directory for the ELK log files.  The userid for the directory can be anything but it must have uid:guid as 1000:1000, which is the same as the ‘oracle’ user running in the container. This ensures the ‘oracle’ user has access to the shared volume/directory.

#### Install or Upgrade Oracle Unified Directory Container with ELK Configuration

If you have not installed the `oud-ds-rs` chart then you should install with the following command, picking up the ELK configuration from the previous steps:

```
$ helm install --namespace <namespace> --values <valuesfile.yaml> <releasename> oud-ds-rs
```

For example:

```
$ helm install --namespace myhelmns --values logging-override-values.yaml my-oud-ds-rs oud-ds-rs

```

If the `oud-ds-rs` chart is already installed then update the configuration with the ELK configuration from the previous steps:

```
$ helm upgrade --namespace <namespace> --values <valuesfile.yaml> <releasename> oud-ds-rs
```

For example:

```
$ helm upgrade --namespace myhelmns --values logging-override-values.yaml my-oud-ds-rs oud-ds-rs
```

#### Configure ElasticSearch

List the PODs in your namespace:

```
$ kubectl get pods -o wide -n <namespace>
```

For example:

```
$ kubectl get pods -o wide -n myhelmns
```

Output will be similar to the following:

```
$ kubectl get pods -o wide -n myhelmns
NAME                                     READY   STATUS    RESTARTS   AGE   IP             NODE           NOMINATED NODE   READINESS GATES
my-oud-ds-rs-0                           1/1     Running   0          39m   10.244.1.107   10.89.73.203   <none>           <none>
my-oud-ds-rs-1                           1/1     Running   0          39m   10.244.1.108   10.89.73.203   <none>           <none>
my-oud-ds-rs-2                           1/1     Running   0          39m   10.244.1.106   10.89.73.203   <none>           <none>
my-oud-ds-rs-es-cluster-0                1/1     Running   0          39m   10.244.1.109   10.89.73.203   <none>           <none>
my-oud-ds-rs-kibana-665f9d5fb-pmz4v      1/1     Running   0          39m   10.244.1.110   10.89.73.203   <none>           <none>
my-oud-ds-rs-logstash-756fd7c5f5-kvwrw   1/1     Running   0          39m   10.244.2.103   10.89.73.204   <none>           <none>
```

From this, identify the ElastiSearch POD, `my-oud-ds-rs-es-cluster-0`.

Run the `port-forward` command to allow ElasticSearch to be listening on port 9200:

```
$ kubectl port-forward oud-ds-rs-es-cluster-0 9200:9200 --namespace=<namespace> &
```

For example:

```
$ kubectl port-forward my-oud-ds-rs-es-cluster-0 9200:9200 --namespace=myhelmns &
[1] 98458
bash-4.2$ Forwarding from 127.0.0.1:9200 -> 9200
Forwarding from [::1]:9200 -> 9200
```

Verify that ElasticSearch is running by interrogating port 9200:

```
$ curl http://localhost:9200
Handling connection for 9200
{
  "name" : "mike-oud-ds-rs-es-cluster-0",
  "cluster_name" : "OUD-elk",
  "cluster_uuid" : "H2EBtAlJQUGpV6IkS46Yzw",
  "version" : {
    "number" : "6.4.3",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "fe40335",
    "build_date" : "2018-10-30T23:17:19.084789Z",
    "build_snapshot" : false,
    "lucene_version" : "7.4.0",
    "minimum_wire_compatibility_version" : "5.6.0",
    "minimum_index_compatibility_version" : "5.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

### Verify Using the Kibana Application

List the Kibana application service using the following command:

```
$ kubectl get svc -o wide -n <namespace> | grep kibana
```

For example:

```
$ kubectl get svc -o wide -n myhelmns | grep kibana
```

Output will be similar to the following:

```
my-oud-ds-rs-kibana             NodePort    10.103.169.218   <none>        5601:31199/TCP               67m   app=kibana
```

In this example, the port to access Kibana application via a Web browser will be `31199`.

Enter the following URL in a browser to access the Kibana application:

`http://<hostname>:<NodePort>/app/kibana`

For example:

`http://myserver:31199/app/kibana`

From the Kibana Portal navigate to:

`Management -> Index Patterns`

Create an Index Pattern using the pattern '*'

Navigate to `Discover` : from here you should be able to see logs from the Oracle Unified Directory environment.





