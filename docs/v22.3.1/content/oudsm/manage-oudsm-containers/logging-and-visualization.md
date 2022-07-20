---
title: "b) Logging and Visualization for Helm Chart oudsm Deployment"
description: "Describes the steps for logging and visualization with Elasticsearch and Kibana."
---

1. [Introduction](#introduction)
1. [Installation](#installation)
    1. [Create a Kubernetes secret](#create-a-kubernetes-secret)
	1. [Enable Elasticsearch, Logstash, and Kibana](#enable-elasticsearch-logstash-and-kibana)
	1. [Upgrade OUDSM deployment with ELK configuration](#upgrade-oudsm-deployment-with-elk-configuration)
	1. [Verify the pods](#verify-the-pods)
1. [Verify using the Kibana application](#verify-using-the-kibana-application)

### Introduction

This section describes how to install and configure logging and visualization for the [oudsm](../../create-oudsm-instances) Helm Chart deployment.

The ELK stack consists of Elasticsearch, Logstash, and Kibana. Using ELK we can gain insights in real-time from the log data from your applications.

* Elasticsearch is a distributed, RESTful search and analytics engine capable of solving a growing number of use cases. As the heart of the Elastic Stack, it centrally stores your data so you can discover the expected and uncover the unexpected.
* Logstash is an open source, server-side data processing pipeline that ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite “stash.”
* Kibana lets you visualize your Elasticsearch data and navigate the Elastic Stack. It gives you the freedom to select the way you give shape to your data. And you don’t always have to know what you're looking for.

### Installation

ELK can be enabled for environments created using the Helm charts provided. The example below will demonstrate installation and configuration of ELK for the `oudsm` chart.


#### Create a Kubernetes secret

1. Create a Kubernetes secret to access the required images on [hub.docker.com](https://hub.docker.com):

   **Note:** You must first have a user account on [hub.docker.com](https://hub.docker.com).

   ```bash
   $ kubectl create secret docker-registry "dockercred" --docker-server="https://index.docker.io/v1/" --docker-username="<docker_username>" --docker-password=<password> --docker-email=<docker_email_credentials> --namespace=<domain_namespace>
   ```   
   
   For example:
   
   ```
   $ kubectl create secret docker-registry "dockercred" --docker-server="https://index.docker.io/v1/" --docker-username="username" --docker-password=<password> --docker-email=user@example.com --namespace=oudsmns
   ```
   
   The output will look similar to the following:
   
   ```bash
   secret/dockercred created
   ```  

#### Enable Elasticsearch, Logstash, and Kibana

1. Create a directory on the persistent volume to store the ELK log files:

   ```bash
   $ mkdir -p <persistent_volume>/oudsm_elk_data
   $ chmod 777 <persistent_volume>/oudsm_elk_data
   ```
   
   For example:
   
   ```bash
   $ mkdir -p /scratch/shared/oudsm_elk_data
   $ chmod 777 /scratch/shared/oudsm_elk_data
   ```

1. Navigate to the `$WORKDIR/kubernetes/helm` directory and create a `logging-override-values.yaml` with the following:


   ```yaml
   elk:
     enabled: true
	 imagePullSecrets:
	   - name: dockercred

   elkVolume:
     # If enabled, it will use the persistent volume.
     # if value is false, PV and PVC would not be used and there would not be any mount point available for config
     enabled: true
     type: filesystem
     filesystem:
       hostPath:
         path: <persistent_volume>/oudsm_elk_data
   ```

   For example:

   ```yaml
   elk:
     enabled: true
	 imagePullSecrets:
	   - name: dockercred

   elkVolume:
     # If enabled, it will use the persistent volume.
     # if value is false, PV and PVC would not be used and there would not be any mount point available for config
     enabled: true
     type: filesystem
     filesystem:
       hostPath:
         path: /scratch/shared/oudsm_elk_data
   ```

   If using NFS for the persistent volume change the `elkVolume` section as follows:


   ```yaml
   elkVolume:
   # If enabled, it will use the persistent volume.
   # if value is false, PV and PVC would not be used and there would not be any mount point available for config
   enabled: true
   type: networkstorage
   networkstorage:
     nfs:
       server: myserver
       path: <persistent_volume>/oudsm_elk_data
   ```

#### Upgrade OUDSM deployment with ELK configuration

1. Run the following command to upgrade the OUDSM deployment with the ELK configuration:

   ```bash
   $ helm upgrade --namespace <namespace> --values logging-override-values.yaml <release_name> oudsm --reuse-values
   ```

   For example:

   ```bash
   $ helm upgrade --namespace oudsmns --values logging-override-values.yaml oudsm oudsm --reuse-values
   ```

#### Verify the pods

1. Run the following command to verify the elasticsearch, logstash and kibana pods are running:

   ```bash
   $ kubectl get pods -o wide -n <namespace> | grep 'es\|kibana\|logstash'
   ```

   For example:

   ```bash
   $ kubectl get pods -o wide -n oudsmns | grep 'es\|kibana\|logstash'
   ```

   The output will look similar to the following:

   ```
   NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE               NOMINATED NODE   READINESS GATES
   oudsm-es-cluster-0                1/1     Running   0          4m5s  10.244.1.124   <worker-node>      <none>           <none>
   oudsm-kibana-7bf95b4c45-sfst6     1/1     Running   1          4m5s  10.244.2.137   <worker-node>      <none>           <none>
   oudsm-logstash-5bb6bc67bf-l4mdv   1/1     Running   0          4m5s  10.244.2.138   <worker-node>      <none>           <none>
   ```

   From the above identify the elasticsearch pod, for example: `oudsm-es-cluster-0`.


1. Run the `port-forward` command to allow ElasticSearch to be listening on port 9200:

   ```bash
   $ kubectl port-forward oudsm-es-cluster-0 9200:9200 --namespace=<namespace> &
   ```

   For example:

   ```bash
   $ kubectl port-forward oudsm-es-cluster-0 9200:9200 --namespace=oudsmns &
   ```
   
   The output will look similar to the following:
   
   ```
   [1] 98458
   bash-4.2$ Forwarding from 127.0.0.1:9200 -> 9200
   Forwarding from [::1]:9200 -> 9200
   ```

1. Verify that ElasticSearch is running by interrogating port 9200:


   ```bash
   $ curl http://localhost:9200
   ```
   
   The output will look similar to the following:
   
   ```bash
   {
     "name" : "oudsm-es-cluster-0",
     "cluster_name" : "OUD-elk",
     "cluster_uuid" : "TIKKJuK4QdWcOZrEOA1zeQ",
     "version" : {
       "number" : "6.8.0",
       "build_flavor" : "default",
       "build_type" : "docker",
       "build_hash" : "65b6179",
       "build_date" : "2019-05-15T20:06:13.172855Z",
       "build_snapshot" : false,
       "lucene_version" : "7.7.0",
       "minimum_wire_compatibility_version" : "5.6.0",
       "minimum_index_compatibility_version" : "5.0.0"
     },
     "tagline" : "You Know, for Search"
   }
   ```


### Verify using the Kibana application

1. List the Kibana application service using the following command:

   ```bash
   $ kubectl get svc -o wide -n <namespace> | grep kibana
   ```

   For example:

   ```bash
   $ kubectl get svc -o wide -n oudsmns | grep kibana
   ```

   The output will look similar to the following:

   ```
   oudsm-kibana             NodePort    10.101.248.248   <none>        5601:31195/TCP      7m56s   app=kibana
   ```

   In this example, the port to access Kibana application via a Web browser will be `31195`.

1. Access the Kibana console in a browser with: `http://${MASTERNODE-HOSTNAME}:${KIBANA-PORT}/app/kibana`.

1. From the Kibana portal navigate to `Management`> `Kibana` > `Index Patterns`.

1. In the **Create Index Pattern** page enter `*` for the **Index pattern**  and click **Next Step**.

1. In the **Configure settings** page, from the **Time Filter field name** drop down menu select `@timestamp` and click **Create index pattern**.

1. Once the index pattern is created click on **Discover** in the navigation menu to view the OUDSM logs.






