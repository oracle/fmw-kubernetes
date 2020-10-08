---
title: "Monitor a domain and publish logs"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 3
pre : "<b> </b>"
description: "Monitor an Oracle SOA Suite domain and publish the WebLogic Server logs to Elasticsearch."
---

After the Oracle SOA Suite domain is set up, you can:

* [Monitor the Oracle SOA Suite instance using Prometheus and Grafana](#monitor-the-oracle-soa-suite-instance-using-prometheus-and-grafana)
* [Publish WebLogic Server logs into Elasticsearch](#publish-weblogic-server-logs-into-elasticsearch)


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
