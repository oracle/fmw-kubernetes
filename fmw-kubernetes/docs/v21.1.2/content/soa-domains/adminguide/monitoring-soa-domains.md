---
title: "Monitor a domain and publish logs"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 4
pre : "<b> </b>"
description: "Monitor an Oracle SOA Suite domain and publish the WebLogic Server logs to Elasticsearch."
---

After the Oracle SOA Suite domain is set up, you can:

* [Monitor the Oracle SOA Suite instance using Prometheus and Grafana](#monitor-the-oracle-soa-suite-instance-using-prometheus-and-grafana)
* [Publish WebLogic Server logs into Elasticsearch](#publish-weblogic-server-logs-into-elasticsearch)
* [Publish SOA server diagnostics logs into Elasticsearch](#publish-soa-server-diagnostics-logs-into-elasticsearch)


### Monitor the Oracle SOA Suite instance using Prometheus and Grafana
Using the `WebLogic Monitoring Exporter` you can scrape runtime information from a running Oracle SOA Suite instance and monitor them using Prometheus and Grafana.

**Prerequisite**: Before setting up monitoring, make sure that Prometheus and Grafana are deployed on the Kubernetes cluster.

#### Deploy Prometheus and Grafana

Refer to the compatibility matrix of [Kube Prometheus](https://github.com/coreos/kube-prometheus#kubernetes-compatibility-matrix) and clone the [release](https://github.com/coreos/kube-prometheus/releases) version of the `kube-prometheus` repository according to the Kubernetes version of your cluster.

1. Clone the `kube-prometheus` repository:
    ```
    $ git clone https://github.com/coreos/kube-prometheus.git
    ```

1. Change to folder `kube-prometheus` and enter the following commands to create the namespace and CRDs, and then wait for their availability before creating the remaining resources:

    ```
    $ cd kube-prometheus
    $ kubectl create -f manifests/setup
    $ until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
    $ kubectl create -f manifests/
    ```

1. `kube-prometheus` requires all nodes in the Kubernetes cluster to be labeled with `kubernetes.io/os=linux`. If any node is not labeled with this, then you need to label it using the following command:

    ```
    $ kubectl label nodes --all kubernetes.io/os=linux
    ```

1. Enter the following commands to provide external access for Grafana, Prometheus, and Alertmanager:

    ```
    $ kubectl patch svc grafana -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32100 }]'

    $ kubectl patch svc prometheus-k8s -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32101 }]'

    $ kubectl patch svc alertmanager-main -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32102 }]'
    ```

    Note:
    * `32100` is the external port for Grafana
    * `32101` is the external port for Prometheus
    * `32102` is the external port for Alertmanager

#### Set up monitoring
Follow the steps [here](https://github.com/oracle/weblogic-monitoring-exporter) to set up monitoring for an Oracle SOA Suite instance.

### Publish WebLogic Server logs into Elasticsearch

You can publish the WebLogic Server logs to Elasticsearch using the `WebLogic logging exporter` and interact with them in Kibana.
See [Publish logs to Elasticsearch](https://github.com/oracle/weblogic-logging-exporter).

WebLogic Server logs can also be published to Elasticsearch using `Fluentd`. See [Fluentd configuration steps](https://oracle.github.io/weblogic-kubernetes-operator/samples/simple/elastic-stack/weblogic-domain/).

### Publish SOA server diagnostics logs into Elasticsearch

This section shows you how to publish diagnostics logs to Elasticsearch and view them in Kibana. For publishing operator logs, see this [sample](https://oracle.github.io/weblogic-kubernetes-operator/samples/simple/elastic-stack/operator/).

#### Prerequisites

If you have not already set up Elasticsearch and Kibana for logs collection, refer this [document](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/scripts/elasticsearch-and-kibana/README.md) and complete the setup.

#### Publish to Elasticsearch

The Diagnostics or other logs can be pushed to Elasticsearch server using logstash pod. The logstash pod should have access to the shared domain home or the log location. In case of the Oracle SOA Suite domain, the persistent volume of the domain home can be used in the logstash pod. The steps to create the logstash pod are,

1. Get Domain home persistence volume claim details of the domain home of the Oracle SOA Suite domain. The following command will list the persistent volume claim details in the namespace - `soans`. In the example below the persistent volume claim is `soainfra-domain-pvc`:
   ```
   $ kubectl get pvc -n soans   
   ```

   Sample output:
   ```
   NAME                  STATUS   VOLUME               CAPACITY   ACCESS MODES   STORAGECLASS                    AGE
   soainfra-domain-pvc   Bound    soainfra-domain-pv   10Gi       RWX            soainfra-domain-storage-class   xxd
   ```

1. Create logstash configuration file (`logstash.conf`). Below is a sample logstash configuration to push diagnostic logs of all servers available at DOMAIN_HOME/servers/<server_name>/logs/<Server Name>-diagnostic.log:

    ```
    input {                                                                                                                
      file {                                                                                                               
        path => "/u01/oracle/user_projects/domains/soainfra/servers/**/logs/*-diagnostic.log"                                          
        start_position => beginning                                                                                        
      }                                                                                                                    
    }                                                                                                                         
    filter {                                                                                                               
      grok {                                                                                                               
        match => [ "message", "<%{DATA:log_timestamp}> <%{WORD:log_level}> <%{WORD:thread}> <%{HOSTNAME:hostname}> <%{HOSTNAME:servername}> <%{DATA:timer}> <<%{DATA:kernel}>> <> <%{DATA:uuid}> <%{NUMBER:timestamp}> <%{DATA:misc}> <%{DATA:log_number}> <%{DATA:log_message}>" ]                                                                                        
      }                                                                                                                    
    }                                                                                                                         
    output {                                                                                                               
      elasticsearch {                                                                                                      
        hosts => ["elasticsearch.default.svc.cluster.local:9200"]                                                          
      }                                                                                                                    
    }
    ```

1. Copy the `logstash.conf` into say `/u01/oracle/user_projects/domains` so that it can be used for logstash deployment, using Administration Server pod ( For example `soainfra-adminserver` pod in namespace `soans`):

   ```
   $ kubectl cp logstash.conf  soans/soainfra-adminserver:/u01/oracle/user_projects/domains --namespace soans
   ```

1. Create deployment YAML (`logstash.yaml`) for logstash pod using the domain home persistence volume claim. Make sure to point the logstash configuration file to correct location ( For example: we copied logstash.conf to /u01/oracle/user_projects/domains/logstash.conf) and also correct domain home persistence volume claim. Below is a sample logstash deployment YAML:

    ```
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: logstash-soa
      namespace: soans
    spec:
      selector:
        matchLabels:
          app: logstash-soa
      template: # create pods using pod definition in this template
        metadata:
          labels:
            app: logstash-soa
        spec:
          volumes:
          - name: soainfra-domain-storage-volume
            persistentVolumeClaim:
              claimName: soainfra-domain-pvc
          - name: shared-logs
            emptyDir: {}
          containers:
          - name: logstash
            image: logstash:6.6.0
            command: ["/bin/sh"]
            args: ["/usr/share/logstash/bin/logstash", "-f", "/u01/oracle/user_projects/domains/logstash.conf"]
            imagePullPolicy: IfNotPresent
            volumeMounts:
            - mountPath: /u01/oracle/user_projects
              name: soainfra-domain-storage-volume
            - name: shared-logs
              mountPath: /shared-logs
            ports:
            - containerPort: 5044
              name: logstash
    ```


1. Deploy logstash to start publish logs to Elasticsearch:

   ```
   $ kubectl create -f  logstash.yaml
   ```

1. Now, you can view the diagnostics logs using Kibana with index pattern "logstash-*".
