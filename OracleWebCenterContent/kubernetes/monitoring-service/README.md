# Monitor the OracleWebCenterContent instance using Prometheus and Grafana
Using the `WebLogic Monitoring Exporter` you can scrape runtime information from a running OracleWebCenterContent instance and monitor them using Prometheus and Grafana.

## Prerequisites

- Have Docker and a Kubernetes cluster running and have `kubectl` installed and configured.
- Have Helm installed.
- An OracleWebCenterContent domain deployed by `weblogic-operator` is running in the Kubernetes cluster.

## Set up monitoring for OracleWebCenterContent domain 

Set up the WebLogic Monitoring Exporter that will collect WebLogic Server metrics and monitor OracleWebCenterContent domain. 

**Note**: Either of the following methods can be used to set up monitoring for OracleWebCenterContent domain. Using `setup-monitoring.sh` does the set up in an automated way.

1. [Set up manually](#set-up-manually)
1. [Set up using `setup-monitoring.sh`](#set-up-using-setup-monitoringsh)

## Set up manually

### Deploy Prometheus and Grafana

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

### Generate the WebLogic Monitoring Exporter Deployment Package  

The `wls-exporter.war` package need to be updated and created for each listening ports (Administration Server and Managed Servers) in the domain.
Set the below environment values based on your environment and run the script `get-wls-exporter.sh` to generate the required WAR files at `${WORKDIR}/monitoring-service/scripts/wls-exporter-deploy`:
- adminServerPort
- wlsMonitoringExporterToibrCluster
- ibrManagedServerPort
- wlsMonitoringExporterToucmCluster
- ucmManagedServerPort
- wlsMonitoringExporterToipmCluster
- ipmManagedServerPort
- wlsMonitoringExporterTocaptureCluster
- captureManagedServerPort
- wlsMonitoringExporterTowccadfCluster
- wccadfManagedServerPort

For example:

```
$ cd ${WORKDIR}/monitoring-service/scripts
$ export adminServerPort=7001 
$ export wlsMonitoringExporterToibrCluster=true
$ export ibrManagedServerPort=16250
$ export wlsMonitoringExporterToucmCluster=true
$ export ucmManagedServerPort=16200
$ export wlsMonitoringExporterToipmCluster=true
$ export ipmManagedServerPort=16000
$ export wlsMonitoringExporterTocaptureCluster=true
$ export captureManagedServerPort=16400
$ export wlsMonitoringExporterTowccadfCluster=true
$ export wccadfManagedServerPort=16225
$ sh get-wls-exporter.sh
```

Verify whether the required WAR files are generated at `${WORKDIR}/monitoring-service/scripts/wls-exporter-deploy`.

```
$ ls ${WORKDIR}/monitoring-service/scripts/wls-exporter-deploy
```

### Deploy the WebLogic Monitoring Exporter into the OracleWebCenterContent domain

Follow these steps to copy and deploy the WebLogic Monitoring Exporter WAR files into the OracleWebCenterContent Domain. 

**Note**: Replace the `<xxxx>` with appropriate values based on your environment:

```
$ cd ${WORKDIR}/monitoring-service/scripts
$ kubectl cp wls-exporter-deploy <namespace>/<admin_pod_name>:/u01/oracle
$ kubectl cp deploy-weblogic-monitoring-exporter.py <namespace>/<admin_pod_name>:/u01/oracle/wls-exporter-deploy
$ kubectl exec -it -n <namespace> <admin_pod_name> -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py \
-domainName <domainUID> -adminServerName <adminServerName> -adminURL <adminURL> \
-ibrClusterName <ibrClusterName> -wlsMonitoringExporterToibrCluster <wlsMonitoringExporterToibrCluster> \
-ucmClusterName <ucmClusterName> -wlsMonitoringExporterToucmCluster <wlsMonitoringExporterToucmCluster> \
-ipmClusterName <ipmClusterName> -wlsMonitoringExporterToipmCluster <wlsMonitoringExporterToipmCluster> \
-captureClusterName <captureClusterName> -wlsMonitoringExporterTocaptureCluster <wlsMonitoringExporterTocaptureCluster> \
-wccadfClusterName <wccadfClusterName> -wlsMonitoringExporterTowccadfCluster <wlsMonitoringExporterTowccadfCluster> \
-username <username> -password <password> 
```

For example:

```
$ cd ${WORKDIR}/monitoring-service/scripts
$ kubectl cp wls-exporter-deploy wccns/wccinfra-adminserver:/u01/oracle
$ kubectl cp deploy-weblogic-monitoring-exporter.py wccns/wccinfra-adminserver:/u01/oracle/wls-exporter-deploy
$ kubectl exec -it -n wccns wccinfra-adminserver -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py \
-domainName wccinfra -adminServerName adminserver -adminURL wccinfra-adminserver:7001 \
-ibrClusterName ibr_cluster -wlsMonitoringExporterToibrCluster true \
-ucmClusterName ucm_cluster -wlsMonitoringExporterToucmCluster true \
-ipmClusterName ipm_cluster -wlsMonitoringExporterToipmCluster true \
-captureClusterName capture_cluster -wlsMonitoringExporterTocaptureCluster true \
-wccadfClusterName wccadf_cluster -wlsMonitoringExporterTowccadfCluster true \
-username weblogic -password Welcome1 
```

### Configure Prometheus Operator 

Prometheus enables you to collect metrics from the WebLogic Monitoring Exporter. The Prometheus Operator identifies the targets using service discovery. To get the WebLogic Monitoring Exporter end point discovered as a target, you must create a service monitor pointing to the service.

The service monitor deployment YAML configuration file is available at `${WORKDIR}/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml.template`. Copy the file as `wls-exporter-ServiceMonitor.yaml` to update with appropriate values as detailed below.

The exporting of metrics from `wls-exporter` requires `basicAuth`, so a Kubernetes `Secret` is created with the user name and password that are base64 encoded. This `Secret` is used in the `ServiceMonitor` deployment. The `wls-exporter-ServiceMonitor.yaml` has namespace as `wccns` and has `basicAuth` with credentials as `username: %USERNAME%` and `password: %PASSWORD%`. Update `%USERNAME%` and `%PASSWORD% ` in base64 encoded and all occurences of `wccns` based on your environment.  

Use the following example for base64 encoded:

```
$ echo -n "Welcome1" | base64
V2VsY29tZTE=
```

You need to add `RoleBinding` and `Role` for the namespace (wccns) under which the WebLogic Servers pods are running in the Kubernetes cluster. These are required for Prometheus to access the endpoints provided by the WebLogic Monitoring Exporters. The YAML configuration files for wccns namespace are provided in "${WORKDIR}/monitoring-service/manifests/".

If you are using namespace other than `wccns`, update the namespace details in `prometheus-roleBinding-domain-namespace.yaml` and `prometheus-roleSpecific-domain-namespace.yaml`.

Perform the below steps for enabling Prometheus to collect the metrics from the WebLogic Monitoring Exporter:

```
$ cd ${WORKDIR}/monitoring-service/manifests
$ kubectl apply -f .
```

### Verify the service discovery of WebLogic Monitoring Exporter

After the deployment of the service monitor, Prometheus should be able to discover wls-exporter and collect the metrics.

1. Access the Prometheus dashboard at `http://mycompany.com:32101/` 

1. Navigate to **Status** to see the **Service Discovery** details.

1. Verify that `wls-exporter` is listed in the discovered Services.


### Deploy Grafana Dashboard

You can access the Grafana dashboard at `http://mycompany.com:32100/`. 

1. Log in to Grafana dashboard with username: admin and password: admin`.

1. Navigate to + (Create) -> Import -> Upload the `weblogic-server-dashboard-import.json` file (provided at `${WORKDIR}/monitoring-service/config/weblogic-server-dashboard-import.json`).


## Set up using `setup-monitoring.sh`

Alternatively, you can run the helper script `setup-monitoring.sh` available at `${WORKDIR}/monitoring-service` to setup the monitoring for OracleWebCenterContent domain. 

This script creates kube-prometheus-stack(Prometheus, Grafana and Alertmanager), WebLogic Monitoring Exporter and imports `weblogic-server-dashboard.json` into Grafana for WebLogic Server Dashboard.

### Prepare to use the setup monitoring script

The sample scripts for setup monitoring for OracleWebCenterContent domain are available at `${WORKDIR}/monitoring-service`.

You must edit `monitoring-inputs.yaml`(or a copy of it) to provide the details of your domain. Refer to the configuration parameters below to understand the information that you must provide in this file.

#### Configuration parameters

The following parameters can be provided in the inputs file.

| Parameter | Description | Default |
| --- | --- | --- |
| `domainUID` | domainUID of the OracleWebCenterContent domain. | `wccinfra` |
| `domainNamespace` | Kubernetes namespace of the OracleWebCenterContent domain. | `wccns` |
| `setupKubePrometheusStack` | Boolean value indicating whether kube-prometheus-stack (Prometheus, Grafana and Alertmanager) to be installed | `true` |
| `additionalParamForKubePrometheusStack` | The script install's kube-prometheus-stack with `service.type` as NodePort and values for `service.nodePort` as per the parameters defined in `monitoring-inputs.yaml`. Use `additionalParamForKubePrometheusStack` parameter to further configure with additional parameters as per [values.yaml](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml). Sample value to disable NodeExporter, Prometheus-Operator TLS support and Admission webhook support for PrometheusRules resources is `--set nodeExporter.enabled=false --set prometheusOperator.tls.enabled=false --set prometheusOperator.admissionWebhooks.enabled=false`|  |
| `monitoringNamespace` | Kubernetes namespace for monitoring setup. | `monitoring` |
| `adminServerName` | Name of the Administration Server. | `adminserver` |
| `adminServerPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `ibrClusterName` | Name of the ibrCluster. | `ibr_cluster` |
| `ibrManagedServerPort` | Port number of the managed servers in the ibrCluster. | `16250` |
| `wlsMonitoringExporterToibrCluster` | Boolean value indicating whether to deploy WebLogic Monitoring Exporter to ibrCluster. | `false` |
| `ucmClusterName` | Name of the ucmCluster. | `ucm_cluster` |
| `ucmManagedServerPort` | Port number of the managed servers in the ucmCluster. | `16200` |
| `wlsMonitoringExporterToucmCluster` | Boolean value indicating whether to deploy WebLogic Monitoring Exporter to ucmCluster. | `false` |
| `ipmClusterName` | Name of the ipmCluster. | `ipm_cluster` |
| `ipmManagedServerPort` | Port number of the managed servers in the ipmCluster. | `16000` |
| `wlsMonitoringExporterToipmCluster` | Boolean value indicating whether to deploy WebLogic Monitoring Exporter to ipmCluster. | `false` |
| `captureClusterName` | Name of the captureCluster. | `capture_cluster` |
| `captureManagedServerPort` | Port number of the managed servers in the captureCluster. | `16400` |
| `wlsMonitoringExporterTocaptureCluster` | Boolean value indicating whether to deploy WebLogic Monitoring Exporter to captureCluster. | `false` |
| `wccadfClusterName` | Name of the wccadfCluster. | `wccadf_cluster` |
| `wccadfManagedServerPort` | Port number of the managed servers in the wccadfCluster. | `16225` |
| `wlsMonitoringExporterTowccadfCluster` | Boolean value indicating whether to deploy WebLogic Monitoring Exporter to wccadfCluster. | `false` |
| `exposeMonitoringNodePort` | Boolean value indicating if the Monitoring Services (Prometheus, Grafana and Alertmanager) is exposed outside of the Kubernetes cluster. | `false` |
| `prometheusNodePort` | Port number of the Prometheus outside the Kubernetes cluster. | `32101` |
| `grafanaNodePort` | Port number of the Grafana outside the Kubernetes cluster. | `32100` |
| `alertmanagerNodePort` | Port number of the Alertmanager outside the Kubernetes cluster. | `32102` |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret which has Administration Server's user name and password. | `wccinfra-domain-credentials` |

Note that the values specified in the `monitoring-inputs.yaml` file will be used to install kube-prometheus-stack (Prometheus, Grafana and Alertmanager) and deploying WebLogic Monitoring Exporter into the OracleWebCenterContent domain. Hence make the domain specific values to be same as that used during domain creation.

### Run the setup monitoring script

Update the values in `monitoring-inputs.yaml` as per your requirement and run the `setup-monitoring.sh` script, specifying your inputs file:

```bash
$ cd ${WORKDIR}/monitoring-service
$ ./setup-monitoring.sh \
  -i monitoring-inputs.yaml
```
The script will perform the following steps:

- Helm install `prometheus-community/kube-prometheus-stack` of version "16.5.0" if `setupKubePrometheusStack` is set to `true`.
- Deploys WebLogic Monitoring Exporter to Administration Server.
- Deploys WebLogic Monitoring Exporter to `ibrCluster` if `wlsMonitoringExporterToibrCluster` is set to `true`.
- Deploys WebLogic Monitoring Exporter to `ucmCluster` if `wlsMonitoringExporterToucmCluster` is set to `true`.
- Deploys WebLogic Monitoring Exporter to `ipmCluster` if `wlsMonitoringExporterToipmCluster` is set to `true`.
- Deploys WebLogic Monitoring Exporter to `captureCluster` if `wlsMonitoringExporterTocaptureCluster` is set to `true`.
- Deploys WebLogic Monitoring Exporter to `wccadfCluster` if `wlsMonitoringExporterTowccadfCluster` is set to `true`.
- Exposes the Monitoring Services (Prometheus at `32101`, Grafana at `32100` and Alertmanager at `32102`) outside of the Kubernetes cluster if `exposeMonitoringNodePort` is set to `true`.
- Imports the WebLogic Server Grafana Dashboard if `setupKubePrometheusStack` is set to `true`.


### Verify the results
The setup monitoring script will report failure if there was any error. However, verify that required resources were created by the script.

#### Verify the kube-prometheus-stack

To confirm that `prometheus-community/kube-prometheus-stack` was installed when `setupKubePrometheusStack` is set to `true`, run the following command:

```bash
$ helm ls -n <monitoringNamespace>
```
Replace <monitoringNamespace> with value for Kubernetes namespace used for monitoring.

Sample output:
```bash
$ helm ls -n monitoring
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
monitoring      monitoring      1               2021-06-18 12:58:35.177221969 +0000 UTC deployed        kube-prometheus-stack-16.5.0    0.48.0
$
```

#### Verify the Prometheus, Grafana and Alertmanager setup

When `exposeMonitoringNodePort` was set to `true`, verify that monitoring services are accessible outside of the Kubernetes cluster:
 
- `32100` is the external port for Grafana and with credentials `admin:admin`
- `32101` is the external port for Prometheus
- `32102` is the external port for Alertmanager

#### Verify the service discovery of WebLogic Monitoring Exporter

Verify whether prometheus is able to discover wls-exporter and collect the metrics:

1. Access the Prometheus dashboard at http://mycompany.com:32101/

1. Navigate to Status to see the Service Discovery details.

1. Verify that wls-exporter is listed in the discovered services.

#### Verify the WebLogic Server dashoard

You can access the Grafana dashboard at http://mycompany.com:32100/.

1. Log in to Grafana dashboard with username: `admin` and password: `admin`.

1. Navigate to "WebLogic Server Dashboard" under General and verify.

### Delete the monitoring setup

To delete the monitoring setup created by [Run the setup monitoring script](#run-the-setup-monitoring-script), run the below command:

```bash
$ cd ${WORKDIR}/monitoring-service
$ ./delete-monitoring.sh \
  -i monitoring-inputs.yaml
```
	
