---
title: "c) Monitoring an Oracle Unified Directory Services Manager Instance"
description: "Describes the steps for Monitoring the Oracle Unified Directory Services Manager environment."
---

1. [Introduction](#introduction)
1. [Install Prometheus and Grafana](#install-prometheus-and-grafana)
	1. [Create a Kubernetes namespace](#create-a-kubernetes-namespace)
	1. [Add Prometheus and Grafana Helm repositories](#add-prometheus-and-grafana-helm-repositories)
	1. [Install the Prometheus operator](#install-the-prometheus-operator)
	1. [View Prometheus and Grafana Objects Created](#view-prometheus-and-grafana-objects-created)
	1. [Add the NodePort](#add-the-nodeport)
1. [Verify Using Grafana GUI](#verify-using-grafana-gui)

### Introduction

After the Oracle Unified Directory Services Manager instance is set up you can monitor it using Prometheus and Grafana.

### Install Prometheus and Grafana

#### Create a Kubernetes namespace

1. Create a Kubernetes namespace to provide a scope for Prometheus and Grafana objects such as pods and services that you create in the environment. To create your namespace issue the following command:

   ```bash
   $ kubectl create namespace <namespace>
   ```

   For example:

   ```bash
   $ kubectl create namespace monitoring
   ```

   The output will look similar to the following:

   ```
   namespace/monitoring created
   ```


#### Add Prometheus and Grafana Helm repositories

1. Add the Prometheus and Grafana Helm repositories by issuing the following command:

   ```bash
   $ helm repo add prometheus https://prometheus-community.github.io/helm-charts
   ```

   The output will look similar to the following:

   ```bash
   "prometheus" has been added to your repositories
   ```

1. Run the following command to update the repositories:

   ```bash
   $ helm repo update
   ```

   The output will look similar to the following:

   ```bash
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "stable" chart repository
   ...Successfully got an update from the "prometheus" chart repository
   ...Successfully got an update from the "prometheus-community" chart repository

   Update Complete.  Happy Helming!
   ```

#### Install the Prometheus operator

1. Install the Prometheus operator using the `helm` command:

   ```bash
   $ helm install <release_name> prometheus/kube-prometheus-stack -n <namespace>
   ```

   For example:

   ```bash
   $ helm install monitoring prometheus/kube-prometheus-stack -n monitoring
   ```

   The output should look similar to the following:

   ```bash
   NAME: monitoring
   LAST DEPLOYED: Mon Jul 11 16:29:23 2022
   NAMESPACE: monitoring
   STATUS: deployed
   REVISION: 1
   NOTES:
   kube-prometheus-stack has been installed. Check its status by running:
     kubectl --namespace monitoring get pods -l "release=monitoring"

   Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
   ```

#### View Prometheus and Grafana Objects created

View the objects created for Prometheus and Grafana by issuing the following command:

```
$ kubectl get all,service,pod -o wide -n <namespace>
```

For example:

```
$ kubectl get all,service,pod -o wide -n monitoring
```

The output will look similar to the following:

```
NAME                                                         READY   STATUS    RESTARTS   AGE   IP               NODE            NOMINATED NODE   READINESS GATES
pod/alertmanager-monitoring-kube-prometheus-alertmanager-0   2/2     Running   0          27s   10.244.2.141     <worker-node>   <none>           <none>
pod/monitoring-grafana-578f79599c-qqdfb                      2/3     Running   0          34s   10.244.1.127     <worker-node>   <none>           <none>
pod/monitoring-kube-prometheus-operator-65cdf7995-w6btr      1/1     Running   0          34s   10.244.1.126     <worker-node>   <none>           <none>
pod/monitoring-kube-state-metrics-56bfd4f44f-5ls8t           1/1     Running   0          34s   10.244.2.139     <worker-node>   <none>           <none>
pod/monitoring-prometheus-node-exporter-5b2f6                1/1     Running   0          34s   100.102.48.84    <worker-node>   <none>           <none>
pod/monitoring-prometheus-node-exporter-fw9xh                1/1     Running   0          34s   100.102.48.28    <worker-node>   <none>           <none>
pod/monitoring-prometheus-node-exporter-s5n9g                1/1     Running   0          34s   100.102.48.121   <master-node>   <none>           <none>
pod/prometheus-monitoring-kube-prometheus-prometheus-0       2/2     Running   0          26s   10.244.1.128     <worker-node>   <none>           <none>

NAME                                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE   SELECTOR
service/alertmanager-operated                     ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   27s   app.kubernetes.io/name=alertmanager
service/monitoring-grafana                        ClusterIP   10.110.97.252    <none>        80/TCP                       34s   app.kubernetes.io/instance=monitoring,app.kubernetes.io/name=grafana
service/monitoring-kube-prometheus-alertmanager   ClusterIP   10.110.82.176    <none>        9093/TCP                     34s   alertmanager=monitoring-kube-prometheus-alertmanager,app.kubernetes.io/name=alertmanager
service/monitoring-kube-prometheus-operator       ClusterIP   10.104.147.173   <none>        443/TCP                      34s   app=kube-prometheus-stack-operator,release=monitoring
service/monitoring-kube-prometheus-prometheus     ClusterIP   10.110.109.245   <none>        9090/TCP                     34s   app.kubernetes.io/name=prometheus,prometheus=monitoring-kube-prometheus-prometheus
service/monitoring-kube-state-metrics             ClusterIP   10.107.111.214   <none>        8080/TCP                     34s   app.kubernetes.io/instance=monitoring,app.kubernetes.io/name=kube-state-metrics
service/monitoring-prometheus-node-exporter       ClusterIP   10.108.97.196    <none>        9100/TCP                     34s   app=prometheus-node-exporter,release=monitoring
service/prometheus-operated                       ClusterIP   None             <none>        9090/TCP                     26s   app.kubernetes.io/name=prometheus

NAME                                                 DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE   CONTAINERS      IMAGES                                    SELECTOR
daemonset.apps/monitoring-prometheus-node-exporter   3         3         3       3            3           <none>          34s   node-exporter   quay.io/prometheus/node-exporter:v1.3.1   app=prometheus-node-exporter,release=monitoring

NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS                                            IMAGES                                                                                          SELECTOR
deployment.apps/monitoring-grafana                    0/1     1            0           34s   grafana-sc-dashboard,grafana-sc-datasources,grafana   quay.io/kiwigrid/k8s-sidecar:1.15.6,quay.io/kiwigrid/k8s-sidecar:1.15.6,grafana/grafana:8.4.2   app.kubernetes.io/instance=monitoring,app.kubernetes.io/name=grafana
deployment.apps/monitoring-kube-prometheus-operator   1/1     1            1           34s   kube-prometheus-stack                                 quay.io/prometheus-operator/prometheus-operator:v0.55.0                                         app=kube-prometheus-stack-operator,release=monitoring
deployment.apps/monitoring-kube-state-metrics         1/1     1            1           34s   kube-state-metrics                                    k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.4.1                                         app.kubernetes.io/instance=monitoring,app.kubernetes.io/name=kube-state-metrics

NAME                                                            DESIRED   CURRENT   READY   AGE   CONTAINERS                                            IMAGES                                                                                          SELECTOR
replicaset.apps/monitoring-grafana-578f79599c                   1         1         0       34s   grafana-sc-dashboard,grafana-sc-datasources,grafana   quay.io/kiwigrid/k8s-sidecar:1.15.6,quay.io/kiwigrid/k8s-sidecar:1.15.6,grafana/grafana:8.4.2   app.kubernetes.io/instance=monitoring,app.kubernetes.io/name=grafana,pod-template-hash=578f79599c
replicaset.apps/monitoring-kube-prometheus-operator-65cdf7995   1         1         1       34s   kube-prometheus-stack                                 quay.io/prometheus-operator/prometheus-operator:v0.55.0                                         app=kube-prometheus-stack-operator,pod-template-hash=65cdf7995,release=monitoring
replicaset.apps/monitoring-kube-state-metrics-56bfd4f44f        1         1         1       34s   kube-state-metrics                                    k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.4.1                                         app.kubernetes.io/instance=monitoring,app.kubernetes.io/name=kube-state-metrics,pod-template-hash=56bfd4f44f

NAME                                                                    READY   AGE   CONTAINERS                     IMAGES
statefulset.apps/alertmanager-monitoring-kube-prometheus-alertmanager   1/1     27s   alertmanager,config-reloader   quay.io/prometheus/alertmanager:v0.23.0,quay.io/prometheus-operator/prometheus-config-reloader:v0.55.0
statefulset.apps/prometheus-monitoring-kube-prometheus-prometheus       1/1     26s   prometheus,config-reloader     quay.io/prometheus/prometheus:v2.33.5,quay.io/prometheus-operator/prometheus-config-reloader:v0.55.0
```

#### Add the NodePort

1. Edit the `grafana` service to add the NodePort:

   ```bash
   $ kubectl edit service/<deployment_name>-grafana -n <namespace>
   ```

   For example:

   ```bash
   $ kubectl edit service/monitoring-grafana -n monitoring
   ```
 
   **Note**: This opens an edit session for the domain where parameters can be changed using standard `vi` commands.
   
   Change the ports entry and add `nodePort: 30091` and `type: NodePort`:

   ```
     ports:
     - name: http-web
       nodePort: 30091
       port: 80
       protocol: TCP
       targetPort: 3000
     selector:
       app.kubernetes.io/instance: monitoring
       app.kubernetes.io/name: grafana
     sessionAffinity: None
     type: NodePort
   ```

1. Save the file and exit `(:wq)`.


### Verify Using Grafana GUI

1. Access the Grafana GUI using `http://<HostIP>:<nodeport>` and login with `admin/prom-operator`. Change the password when prompted.

1. Download the K8 Cluster Detail Dashboard json file from: https://grafana.com/grafana/dashboards/10856.

1. Import the Grafana dashboard by navigating on the left hand menu to **Create** > **Import**. Click **Upload JSON file** and select the json downloaded file. In the `Prometheus` drop down box select `Prometheus`. Click **Import**. The dashboard should be displayed.

1. Verify your installation by viewing some of the customized dashboard views.

