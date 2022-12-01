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

#### Set up monitoring
Follow [these steps](https://github.com/oracle/fmw-kubernetes/blob/v22.4.2/OracleSOASuite/kubernetes/monitoring-service/README.md) to set up monitoring for an Oracle SOA Suite instance. For more details on WebLogic Monitoring Exporter, see [here](https://github.com/oracle/weblogic-monitoring-exporter).

### Publish WebLogic Server logs into Elasticsearch

You can publish the WebLogic Server logs to Elasticsearch using the `WebLogic Logging exporter` and interact with them in Kibana.
See [Publish logs to Elasticsearch](https://github.com/oracle/weblogic-logging-exporter).

WebLogic Server logs can also be published to Elasticsearch using `Fluentd`. See [Fluentd configuration steps](https://oracle.github.io/weblogic-kubernetes-operator/samples/elastic-stack/weblogic-domain/).

### Publish SOA server diagnostics logs into Elasticsearch

This section shows you how to publish diagnostics logs to Elasticsearch and view them in Kibana. For publishing operator logs, see [this sample](https://oracle.github.io/weblogic-kubernetes-operator/samples/elastic-stack/operator/).

#### Prerequisites

If you have not already set up Elasticsearch and Kibana for logs collection, refer to [this document](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/scripts/elasticsearch-and-kibana/README.md) and complete the setup.

#### Publish to Elasticsearch

The diagnostics or other logs can be pushed to Elasticsearch server using logstash pod. The logstash pod should have access to the shared domain home or the log location. In case of the Oracle SOA Suite domain, the persistent volume of the domain home can be used in the logstash pod. To create the logstash pod, follow these steps:

1. Get the domain home persistence volume claim details of the domain home of the Oracle SOA Suite domain. The following command lists the persistent volume claim details in the namespace - `soans`. In the example below, the persistent volume claim is `soainfra-domain-pvc`:
   ```
   $ kubectl get pvc -n soans   
   ```

   Sample output:
   ```
   NAME                  STATUS   VOLUME               CAPACITY   ACCESS MODES   STORAGECLASS                    AGE
   soainfra-domain-pvc   Bound    soainfra-domain-pv   10Gi       RWX            soainfra-domain-storage-class   xxd
   ```

1. Create the logstash configuration file (`logstash.conf`). Below is a sample logstash configuration to push diagnostic logs of all servers available at DOMAIN_HOME/servers/<server_name>/logs/<Server Name>-diagnostic.log:

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

1. Copy the `logstash.conf` into `/u01/oracle/user_projects/domains` so that it can be used for logstash deployment, using the Administration Server pod (for example `soainfra-adminserver` pod in namespace `soans`):

   ```
   $ kubectl cp logstash.conf  soans/soainfra-adminserver:/u01/oracle/user_projects/domains --namespace soans
   ```

1. Create a deployment YAML (`logstash.yaml`) for the logstash pod using the domain home persistence volume claim. Make sure to point the logstash configuration file to the correct location (for example, copy logstash.conf to /u01/oracle/user_projects/domains/logstash.conf) and also the correct domain home persistence volume claim. Below is a sample logstash deployment YAML:

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
