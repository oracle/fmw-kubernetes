---
title: "Monitor a domain and publish logs"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 3
pre : "<b> </b>"
description: "Monitor an Oracle WebCenter Sites domain and publish the WebLogic Server logs to Elasticsearch."
---

After the Oracle WebCenter Sites domain is set up, you can:

* [Monitor the Oracle WebCenter Sites instance using Prometheus and Grafana](#monitor-the-oracle-wcsites-instance-using-prometheus-and-grafana)
* [Publish WebLogic Server logs into Elasticsearch](#publish-weblogic-server-logs-into-elasticsearch)

### Monitor the Oracle WebCenter Sites instance using Prometheus and Grafana
Using the `WebLogic Monitoring Exporter` you can scrape runtime information from a running Oracle WebCenter Sites instance and monitor them using Prometheus and Grafana.

### Prerequisites

This document assumes that the Prometheus Operator is deployed on the Kubernetes cluster. If it is not already deployed, follow the steps below for deploying the Prometheus Operator.

#### Clone the kube-prometheus project

```bash
$ git clone https://github.com/coreos/kube-prometheus.git
```

#### Label the nodes
Kube-Prometheus requires all the exporter nodes to be labelled with `kubernetes.io/os=linux`. If a node is not labelled, then you must label it using the following command:

```
$ kubectl label nodes --all kubernetes.io/os=linux
```

#### Create Prometheus and Grafana resources

Change to the `kube-prometheus` directory and execute the following commands to create the namespace and CRDs:

**NOTE**: Wait for a minute for each command to process.

```bash
$ cd kube-prometheus

$ kubectl create -f manifests/setup
$ until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
$ kubectl create -f manifests/
```

#### Provide external access
To provide external access for Grafana, Prometheus, and Alertmanager, execute the commands below:

```bash
$ kubectl patch svc grafana -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32100 }]'
$ kubectl patch svc prometheus-k8s -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32101 }]'
$ kubectl patch svc alertmanager-main -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32102 }]'
```

**NOTE**:

* `32100` is the external port for Grafana
* `32101` is the external port for Prometheus
* `32102` is the external port for Alertmanager

--------------

## Set Up the WebLogic Monitoring Exporter 

Set up the WebLogic Monitoring Exporter that will collect WebLogic Server metrics and monitor your WebCenter Sites domain.

#### Generate the WebLogic Monitoring Exporter Deployment Package

Two packages are required as the listening ports are different for the Administration Server and Managed Servers.
One binary required for the Admin Server (`wls-exporter-as.war`) and one for Managed Cluster (`wls-exporter-ms.war`).
Set the required proxies and then run the script `getX.X.X.sh` to generate two binaries:

```bash
$ cd kubernetes/samples/scripts/create-wcsites-domain/utils/weblogic-monitoring-exporter

$ sh get1.1.0.sh
```

Output:
```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   607    0   607    0     0    357      0 --:--:--  0:00:01 --:--:--   357
100 2016k  100 2016k    0     0   398k      0  0:00:05  0:00:05 --:--:--  797k
-------------------wls-exporter-ms start-------------------
created /tmp/ci-GNysQzP1kv
Copying completed
/tmp/ci-GNysQzP1kv /kubernetes/3.0.1/scripts/create-wcsites-domain/utils/weblogic-monitoring-exporter
in temp dir
  adding: WEB-INF/weblogic.xml (deflated 66%)
  adding: config.yml (deflated 63%)
wls-exporter-ms.war is ready
-------------------wls-exporter-ms end-------------------
-------------------wls-exporter-as start-------------------
Copying completed
in temp dir
  adding: WEB-INF/weblogic.xml (deflated 66%)
  adding: config.yml (deflated 52%)
wls-exporter-as.war is ready
-------------------wls-exporter-as end-------------------
zip completed
kubernetes/3.0.1/scripts/create-wcsites-domain/utils/weblogic-monitoring-exporter
```

#### Copy the WAR Files to the WebLogic Domain Home

Copy the `wls-exporter-as.war` and `wls-exporter-ms.war` files to the domain home directory in the Administration Server pod.

```
$ kubectl cp wls-exporter-as.war wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/

$ kubectl cp wls-exporter-ms.war wcsites-ns/wcsitesinfra-adminserver:/u01/oracle/user_projects/domains/wcsitesinfra/
```

#### Deploy the WebLogic Monitoring Exporter

Follow these steps to deploy the package in the WebLogic Server instances:

1.  In the Administration Server and Managed Servers, deploy the WebLogic Monitoring Exporter (`wls-exporter-ms.war`) separately using the Oracle Enterprise Manager.

	![Wme-Deploy](images/wme-deploy.png)

1. Select the servers to which the Exporter WAR should be deployed:

	![Wme-Deploy-Target-Server](images/wme-deploy-target-server.png)

1. Set the application name. The application name must be different if it is deployed separately in the Administration Server and Managed Servers. Make sure the context-root for both the deployments is `wls-exporter`:

	![Wme-Deploy-Contextroot](images/wme-deploy-contextroot.png)

1. Click **Install and start application**.

1. Then deploy the WebLogic Monitoring Exporter application (`wls-exporter-ms.war`).

1. Activate the changes to start the application. If the application is started and the port is exposed,
then you can access the WebLogic Monitoring Exporter console using this URL: `http://<server:port>/wls-exporter`.

	![Wme-Test-Url](images/wme-test-url.png)

1. Repeat same steps for `wls-exporter-as.war`.

#### Configure Prometheus Operator 

Prometheus enables you to collect metrics from the WebLogic Monitoring Exporter. The Prometheus Operator identifies the targets using service discovery. To get the WebLogic Monitoring Exporter end point discovered as a target, you must create a service monitor pointing to the service.

See the following sample service monitor deployment YAML configuration file located at 

`kubernetes/samples/scripts/create-wcsites-domain/utils/weblogic-monitoring-exporter/wls-exporter.yaml`.

`ServiceMonitor` for wls-exporter:
```
apiVersion: v1
kind: Secret
metadata:
  name: basic-auth
  namespace: monitoring
data:
  password: V2VsY29tZTE= # Welcome1 i.e.'WebLogic password'
  user: d2VibG9naWM= # weblogic  i.e. 'WebLogic username'
type: Opaque
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: wls-exporter-wcsitesinfra
  namespace: monitoring
  labels:
    k8s-app: wls-exporter
spec:
  namespaceSelector:
    matchNames:
    - wcsites-ns
  selector:
    matchLabels:
      weblogic.domainName: wcsitesinfra
  endpoints:
  - basicAuth:
      password:
        name: basic-auth
        key: password
      username:
        name: basic-auth
        key: user
    port: default
    relabelings:
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
    interval: 10s
    honorLabels: true
    path: /wls-exporter/metrics
```

The exporting of metrics from `wls-exporter` requires `basicAuth` so a Kubernetes `Secret` is created with the user name and password that are base64 encoded. This `Secret` will be used in the `ServiceMonitor` deployment.

When generating the base64 encoded strings for the user name and password, observe if a new line character is appended in the encoded string. This line character causes an authentication failure. To avoid a new line string, use the following example:

```
$ echo -n "Welcome1" | base64
V2VsY29tZTE=
```

In the deployment YAML configuration for `wls-exporter` shown above, `weblogic.domainName: wcsitesinfra` is used as a label under `spec.selector.matchLabels`, so all the services will be selected for the service monitor. If you don't use this label, you should create separate service monitors for each server--if the server name is used as matching labels in `spec.selector.matchLabels`.  Doing so will require you to relabel the configuration because Prometheus, by default, ignores the labels provided in the wls-exporter.

By default, Prometheus does not store all the labels provided by the target. In the service monitor deployment YAML configuration, you must mention the relabeling configuration (`spec.endpoints.relabelings`) so that certain labels provided by `weblogic-monitoring-exporter` (required for the Grafana dashboard) are stored in Prometheus. Do not delete the following section from the configuration YAML file:
```
relabelings:
  - action: labelmap
    regex: __meta_kubernetes_service_label_(.+)
```

#### Add `RoleBinding` and `Role` for the WebLogic Domain Namespace

The
RoleBinding is required for Prometheus to access the endpoints provided by the WebLogic Monitoring Exporter. You need to add RoleBinding for the namespace under which the WebLogic Servers pods are running in the Kubernetes cluster. Edit the `kube-prometheus/manifests/prometheus-roleBindingSpecificNamespaces.yaml` file in the Prometheus Operator deployment manifests and add the `RoleBinding` for the namespace (`wcsites-ns`) similar to the following example:

```
- apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: prometheus-k8s
    namespace: wcsites-ns
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: prometheus-k8s
  subjects:
  - kind: ServiceAccount
    name: prometheus-k8s
    namespace: monitoring
```
Similarly, add the `Role` for the namespace under which the WebLogic Servers pods are running in the Kubernetes cluster. Edit `kube-prometheus/manifests/prometheus-roleSpecificNamespaces.yaml` in the Prometheus Operator deployment manifests and add the `Role` for the namespace (`wcsites-ns`) similar to the following example:
```
- apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: prometheus-k8s
    namespace: wcsites-ns
  rules:
  - apiGroups:
    - ""
    resources:
    - services
    - endpoints
    - pods
    verbs:
    - get
    - list
    - watch
```
Then apply `prometheus-roleBindingSpecificNamespaces.yaml` and `prometheus-roleSpecificNamespaces.yaml` for the `RoleBinding` and `Role` to take effect in the cluster.
```
$ kubectl apply -f kube-prometheus/manifests/prometheus-roleBindingSpecificNamespaces.yaml

$ kubectl apply -f kube-prometheus/manifests/prometheus-roleSpecificNamespaces.yaml
```
#### Deploy the Service Monitor

To deploy the service monitor, use the above wls-exporter.yaml deployment YAML and run the following command:
```
$ kubectl create -f kubernetes/samples/scripts/create-wcsites-domain/utils/weblogic-monitoring-exporter/wls-exporter.yaml
```
#### Enable Prometheus to Discover the Service

After the deployment of the service monitor, Prometheus should be able to discover wls-exporter and export metrics.

You can access the Prometheus dashboard at `http://mycompany.com:32101/`. 

![Wme-Service-Discovery](images/wme-service-discovery.png)   


#### Deploy Grafana Dashboard

To view the domain metrics, deploy the Grafana dashboard provided in the [WebLogic Monitoring Exporter](https://github.com/oracle/weblogic-monitoring-exporter/tree/master/samples/kubernetes/end2end#monitoring-weblogic-server-with-the-grafana-dashboard).

You can access the Grafana dashboard at `http://mycompany.com:32100/`. 

1. Log in to Grafana dashboard with `admin/admin`.
1. Go to **Settings**, then select **DataSources**, and then **Add Data Source**.

	HTTP URL: Prometheus URL `http://mycompany.com:32101/`
	
	Auth: Enable Basic Auth
	
	Basic Auth Details: WebLogic credentials provided in step [Configure Prometheus Operator](#configure-prometheus-operator)
	    
	![Wme-GP-Add-Datasource](images/wme-gp-add-datasource.png)

1. Download the `weblogic_dashboard.json` file from [here](weblogic_dashboard.json).
1. Click **Add** and then **Import**. Paste the modified JSON in the Paste JSON block, and then load it.

	![Wme-GP-Import-Json](images/wme-gp-import-json.png)

	This displays the WebLogic Server Dashboard.

	![Wme-GP-WLS-Dashboard](images/wme-gp-wls-dashboard.png)