# Monitor the OracleSOASuite instance using Prometheus and Grafana
Using the `WebLogic Monitoring Exporter` you can scrape runtime information from a running OracleSOASuite instance and monitor them using Prometheus and Grafana.

## Prerequisites

- Have Docker and a Kubernetes cluster running and have `${KUBERNETES_CLI:-kubectl}` installed and configured.
- Have Helm installed.
- Before installing kube-prometheus-stack (Prometheus, Grafana and Alertmanager), refer [link](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#uninstall-helm-chart) and cleanup if any older CRDs for monitoring services exists in your Kubernetes cluster.
  **Note**: Make sure no existing monitoring services is running in the Kubernetes cluster before cleanup. If you do not want to cleanup monitoring services CRDs, refer [link](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#upgrading-chart) for upgrading the CRDs.
- An OracleSOASuite domain deployed by `weblogic-operator` is running in the Kubernetes cluster.

## Set up monitoring for OracleSOASuite domain 

Set up the WebLogic Monitoring Exporter that will collect WebLogic Server metrics and monitor OracleSOASuite domain. 

**Note**: Either of the following methods can be used to set up monitoring for OracleSOASuite domain. Using `setup-monitoring.sh` does the set up in an automated way.

1. [Set up manually](#set-up-manually)
1. [Set up using `setup-monitoring.sh`](#set-up-using-setup-monitoringsh)

## Set up manually

### Install kube-prometheus-stack

Refer to [link](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) and install the Kube Prometheus stack.

1. Get Helm Repository Info for the `kube-prometheus`:
    ```
    $ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    $ helm repo update
    ```

1. Install the helm chart:
    ```
    namespace=monitoring
    release_name=myrelease
    prometheusNodePort=32101
    alertmanagerNodePort=32102
    grafanaNodePort=32100
    $ helm install $release_name prometheus-community/kube-prometheus-stack \
       --namespace $namespace \
       --set prometheus.service.type=NodePort --set prometheus.service.nodePort=${prometheusNodePort} \
       --set alertmanager.service.type=NodePort --set alertmanager.service.nodePort=${alertmanagerNodePort} \
       --set grafana.adminPassword=admin --set grafana.service.type=NodePort  --set grafana.service.nodePort=${grafanaNodePort} \
       --wait
    ```

1. `kube-prometheus` requires all nodes in the Kubernetes cluster to be labeled with `kubernetes.io/os=linux`. If any node is not labeled with this, then you need to label it using the following command:

    ```
    $ ${KUBERNETES_CLI:-kubectl} label nodes --all kubernetes.io/os=linux
    ```

1. With the nodePort values provided during helm install, monitoring serives will be available at:

    * `32100` is the external port for Grafana
    * `32101` is the external port for Prometheus
    * `32102` is the external port for Alertmanager

### Use the Monitoring Exporter with WebLogic Kubernetes Operator  

For enabling monitoring exporter, simply add the [monitoringExporter](https://github.com/oracle/weblogic-kubernetes-operator/blob/main/documentation/domains/Domain.md#monitoring-exporter-specification) configuration element in the domain resource.
Sample configuration available at `${WORKDIR}/monitoring-service/config/config.yaml` can be added to your domain using below command:

```
$ kubectl patch domain ${domainUID} -n ${domainNamespace} --patch-file ${WORKDIR}/monitoring-service/config/config.yaml --type=merge
```

This will trigger the restart of domain. The newly created server pods will have the exporter sidecar. See https://github.com/oracle/weblogic-monitoring-exporter for details.

### Configure Prometheus Operator 

Prometheus enables you to collect metrics from the WebLogic Monitoring Exporter. The Prometheus Operator identifies the targets using service discovery. To get the WebLogic Monitoring Exporter end point discovered as a target, you must create a service monitor pointing to the service.

The service monitor deployment YAML configuration file is available at `${WORKDIR}/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml.template`. Copy the file as `wls-exporter-ServiceMonitor.yaml` to update with appropriate values as detailed below.

The exporting of metrics from `wls-exporter` requires `basicAuth`, so a Kubernetes `Secret` is created with the user name and password that are base64 encoded. This `Secret` is used in the `ServiceMonitor` deployment. The `wls-exporter-ServiceMonitor.yaml` has namespace as `soans` and has `basicAuth` with credentials as `username: %USERNAME%` and `password: %PASSWORD%`. Update `%USERNAME%` and `%PASSWORD% ` in base64 encoded and all occurences of `soans` based on your environment.  

Use the following example for base64 encoded:

```
$ echo -n "Welcome1" | base64
V2VsY29tZTE=
```

You need to add `RoleBinding` and `Role` for the namespace (soans) under which the WebLogic Servers pods are running in the Kubernetes cluster. These are required for Prometheus to access the endpoints provided by the WebLogic Monitoring Exporters. The YAML configuration files for soans namespace are provided in "${WORKDIR}/monitoring-service/manifests/".

If you are using namespace other than `soans`, update the namespace details in `prometheus-roleBinding-domain-namespace.yaml` and `prometheus-roleSpecific-domain-namespace.yaml`.

Perform the below steps for enabling Prometheus to collect the metrics from the WebLogic Monitoring Exporter:

```
$ cd ${WORKDIR}/monitoring-service/manifests
$ ${KUBERNETES_CLI:-kubectl} apply -f .
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

Alternatively, you can run the helper script `setup-monitoring.sh` available at `${WORKDIR}/monitoring-service` to setup the monitoring for OracleSOASuite domain. 

This script creates kube-prometheus-stack(Prometheus, Grafana and Alertmanager), WebLogic Monitoring Exporter and imports `weblogic-server-dashboard.json` into Grafana for WebLogic Server Dashboard.

### Prepare to use the setup monitoring script

The sample scripts for setup monitoring for OracleSOASuite domain are available at `${WORKDIR}/monitoring-service`.

You must edit `monitoring-inputs.yaml`(or a copy of it) to provide the details of your domain. Refer to the configuration parameters below to understand the information that you must provide in this file.

#### Configuration parameters

The following parameters can be provided in the inputs file.

| Parameter | Description | Default |
| --- | --- | --- |
| `domainUID` | domainUID of the OracleSOASuite domain. | `soainfra` |
| `domainNamespace` | Kubernetes namespace of the OracleSOASuite domain. | `soans` |
| `setupKubePrometheusStack` | Boolean value indicating whether kube-prometheus-stack (Prometheus, Grafana and Alertmanager) to be installed | `true` |
| `additionalParamForKubePrometheusStack` | The script install's kube-prometheus-stack with `service.type` as NodePort and values for `service.nodePort` as per the parameters defined in `monitoring-inputs.yaml`. Use `additionalParamForKubePrometheusStack` parameter to further configure with additional parameters as per [values.yaml](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml). Sample value to disable NodeExporter, Prometheus-Operator TLS support, Admission webhook support for PrometheusRules resources and custom Grafana image repository is `--set nodeExporter.enabled=false --set prometheusOperator.tls.enabled=false --set prometheusOperator.admissionWebhooks.enabled=false --set grafana.image.repository=xxxxxxxxx/grafana/grafana`|  |
| `monitoringNamespace` | Kubernetes namespace for monitoring setup. | `monitoring` |
| `monitoringHelmReleaseName` | Helm release name for monitoring resources. | `monitoring` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `exposeMonitoringNodePort` | Boolean value indicating if the Monitoring Services (Prometheus, Grafana and Alertmanager) is exposed outside of the Kubernetes cluster. | `false` |
| `prometheusNodePort` | Port number of the Prometheus outside the Kubernetes cluster. | `32101` |
| `grafanaNodePort` | Port number of the Grafana outside the Kubernetes cluster. | `32100` |
| `alertmanagerNodePort` | Port number of the Alertmanager outside the Kubernetes cluster. | `32102` |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret which has Administration Server's user name and password. | `soainfra-domain-credentials` |

Note that the values specified in the `monitoring-inputs.yaml` file will be used to install kube-prometheus-stack (Prometheus, Grafana and Alertmanager) and enabling WebLogic Monitoring Exporter into the OracleSOASuite domain. Hence make the domain specific values to be same as that used during domain creation.

### Run the setup monitoring script

Update the values in `monitoring-inputs.yaml` as per your requirement and run the `setup-monitoring.sh` script, specifying your inputs file:

```bash
$ cd ${WORKDIR}/monitoring-service
$ ./setup-monitoring.sh \
  -i monitoring-inputs.yaml
```
The script will perform the following steps:

- Helm install `prometheus-community/kube-prometheus-stack` if `setupKubePrometheusStack` is set to `true`.
- Configures Monitoring Exporter as sidecar
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
monitoring      monitoring      1               2023-03-15 10:31:42.44437202 +0000 UTC  deployed        kube-prometheus-stack-45.7.1    v0.63.0
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
	
