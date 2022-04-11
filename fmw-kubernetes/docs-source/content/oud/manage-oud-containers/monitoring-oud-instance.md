---
title: "b) Monitoring an Oracle Unified Directory Instance"
date: 2019-02-22T15:44:42-05:00
draft: false
description: "Describes the steps for Monitoring the Oracle Unified Directory environment."
---

1. [Introduction](#introduction)
1. [Install Prometheus and Grafana](#install-prometheus-and-grafana)
	1. [Create a Kubernetes Namespace](#create-a-kubernetes-namespace)
	1. [Add Prometheus and Grafana Helm Repositories](#add-prometheus-and-grafana-helm-repositories)
	1. [Install the Prometheus Operator](#install-the-prometheus-operator)
	1. [View Prometheus and Grafana Objects Created](#view-prometheus-and-grafana-objects-created)
	1. [Add the NodePort](#add-the-nodeport)
1. [Verify Using Grafana GUI](#verify-using-grafana-gui)

### Introduction

After the Oracle Unified Directory instance is set up you can monitor it using Prometheus and Grafana.

### Install Prometheus and Grafana

#### Create a Kubernetes Namespace

Create a Kubernetes namespace to provide a scope for Prometheus and Grafana objects such as pods and services that you create in the environment. To create your namespace issue the following command:

```
$ kubectl create ns mypgns
namespace/mypgns created
```

#### Add Prometheus and Grafana Helm Repositories

Add the Prometheus and Grafana Helm repositories by issuing the following commands:

```
$ helm repo add prometheus https://prometheus-community.github.io/helm-charts
"prometheus" has been added to your repositories
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "prometheus" chart repository
Update Complete.  Happy Helming!
$
```

#### Install the Prometheus Operator

Install the Prometheus Operator using the `helm` command:

```
$ helm install <release_name> prometheus/kube-prometheus-stack grafana.adminPassword=<password> -n <namespace>
```

For example:

```
$ helm install mypg prometheus/kube-prometheus-stack grafana.adminPassword=<password> -n mypgns
```

Output should be similar to the following:

```
NAME: mypg
LAST DEPLOYED: Mon Oct 12 02:05:41 2020
NAMESPACE: mypgns
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace mypgns get pods -l "release=mypg"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

#### View Prometheus and Grafana Objects Created

View the objects created for Prometheus and Grafana by issuing the following command:

```
$ kubectl get all,service,pod -o wide -n <namespace>
```

For example:

```
$ kubectl get all,service,pod -o wide -n mypgns
NAME                                                         READY   STATUS        RESTARTS   AGE     IP             NODE           NOMINATED NODE   READINESS GATES
pod/alertmanager-mypg-kube-prometheus-stack-alertmanager-0   2/2     Running       0          25m     10.244.1.25    10.89.73.203   <none>           <none>
pod/mypg-grafana-b7d4fbfb-jzccm                              2/2     Running       0          25m     10.244.2.140   10.89.73.204   <none>           <none>
pod/mypg-kube-prometheus-stack-operator-7fb485bbcd-lbh9d     2/2     Running       0          25m     10.244.2.139   10.89.73.204   <none>           <none>
pod/mypg-kube-state-metrics-86dfdf9c75-nvbss                 1/1     Running       0          25m     10.244.1.146   10.89.73.203   <none>           <none>
pod/mypg-prometheus-node-exporter-29dzd                      1/1     Running       0          25m     10.244.2.141   10.89.73.204   <none>           <none>
pod/prometheus-mypg-kube-prometheus-stack-prometheus-0       3/3     Running       0          25m     10.244.2.140   10.89.73.203   <none>           <none>

NAME                                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE   SELECTOR
service/alertmanager-operated                     ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   25m   app=alertmanager
service/mypg-grafana                              ClusterIP   10.111.28.76     <none>        80/TCP                       25m   app.kubernetes.io/instance=mypg,app.kubernetes.io/name=grafana
service/mypg-kube-prometheus-stack-alertmanager   ClusterIP   10.103.83.97     <none>        9093/TCP                     25m   alertmanager=mypg-kube-prometheus-stack-alertmanager,app=alertmanager
service/mypg-kube-prometheus-stack-operator       ClusterIP   10.110.216.204   <none>        8080/TCP,443/TCP             25m   app=kube-prometheus-stack-operator,release=mypg
service/mypg-kube-prometheus-stack-prometheus     ClusterIP   10.104.11.9      <none>        9090/TCP                     25m   app=prometheus,prometheus=mypg-kube-prometheus-stack-prometheus
service/mypg-kube-state-metrics                   ClusterIP   10.109.172.125   <none>        8080/TCP                     25m   app.kubernetes.io/instance=mypg,app.kubernetes.io/name=kube-state-metrics
service/mypg-prometheus-node-exporter             ClusterIP   10.110.249.92    <none>        9100/TCP                     25m   app=prometheus-node-exporter,release=mypg
service/prometheus-operated                       ClusterIP   None             <none>        9090/TCP                     25m   app=prometheus

NAME                                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE   CONTAINERS      IMAGES                                    SELECTOR
daemonset.apps/mypg-prometheus-node-exporter   3         3         0       3            0           <none>          25m   node-exporter   quay.io/prometheus/node-exporter:v1.0.1   app=prometheus-node-exporter,release=mypg

NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS                        IMAGES                                                                               SELECTOR
deployment.apps/mypg-grafana                          1/1     1            1           25m   grafana-sc-dashboard,grafana      kiwigrid/k8s-sidecar:0.1.209,grafana/grafana:7.2.0                                   app.kubernetes.io/instance=mypg,app.kubernetes.io/name=grafana
deployment.apps/mypg-kube-prometheus-stack-operator   1/1     1            1           25m   kube-prometheus-stack,tls-proxy   quay.io/prometheus-operator/prometheus-operator:v0.42.1,squareup/ghostunnel:v1.5.2   app=kube-prometheus-stack-operator,release=mypg
deployment.apps/mypg-kube-state-metrics               1/1     1            1           25m   kube-state-metrics                quay.io/coreos/kube-state-metrics:v1.9.7                                             app.kubernetes.io/name=kube-state-metrics

NAME                                                             DESIRED   CURRENT   READY   AGE   CONTAINERS                        IMAGES                                                                               SELECTOR
replicaset.apps/mypg-grafana-b7d4fbfb                            1         1         1       25m   grafana-sc-dashboard,grafana      kiwigrid/k8s-sidecar:0.1.209,grafana/grafana:7.2.0                                   app.kubernetes.io/instance=mypg,app.kubernetes.io/name=grafana,pod-template-hash=b7d4fbfb
replicaset.apps/mypg-kube-prometheus-stack-operator-7fb485bbcd   1         1         1       25m   kube-prometheus-stack,tls-proxy   quay.io/prometheus-operator/prometheus-operator:v0.42.1,squareup/ghostunnel:v1.5.2   app=kube-prometheus-stack-operator,pod-template-hash=7fb485bbcd,release=mypg
replicaset.apps/mypg-kube-state-metrics-86dfdf9c75               1         1         1       25m   kube-state-metrics                quay.io/coreos/kube-state-metrics:v1.9.7                                             app.kubernetes.io/name=kube-state-metrics,pod-template-hash=86dfdf9c75

NAME                                                                    READY   AGE   CONTAINERS                                                       IMAGES
statefulset.apps/alertmanager-mypg-kube-prometheus-stack-alertmanager   1/1     25m   alertmanager,config-reloader                                     quay.io/prometheus/alertmanager:v0.21.0,jimmidyson/configmap-reload:v0.4.0
statefulset.apps/prometheus-mypg-kube-prometheus-stack-prometheus       0/1     25m   prometheus,prometheus-config-reloader,rules-configmap-reloader   quay.io/prometheus/prometheus:v2.21.0,quay.io/prometheus-operator/prometheus-config-reloader:v0.42.1,docker.io/jimmidyson/configmap-reload:v0.4.0

```

#### Add the NodePort

Edit the `grafana` service to add the NodePort in the `service.nodeport=<nodeport>` and `type=NodePort` and save:

```
$ kubectl edit service/prometheus-grafana -n <namespace>
 
  ports:
  - name: service
    nodePort: 30091
    port: 80
    protocol: TCP
    targetPort: 3000
  selector:
    app.kubernetes.io/instance: prometheus-operator
    app.kubernetes.io/name: grafana
  sessionAffinity: None
  type: NodePort

```

### Verify Using Grafana GUI

Access the Grafana GUI using `http://<HostIP>:<nodeport>` with the default `username=admin` and `password=grafana.adminPassword`:

Check the Prometheus datasource from the DataSource pane:

Add the customized k8cluster view dashboard json to view the cluster monitoring dashboard, by importing the following json file.

Download the JSON file from monitoring a Kubernetes cluster using Prometheus from https://grafana.com/grafana/dashboards/10856.  Import the downloaded json using the import option.

Verify your installation by viewing some of the customized dashboard views.
