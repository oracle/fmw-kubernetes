## Monitor the OracleIdentityGovernance instance using Prometheus and Grafana
Using the `WebLogic Monitoring Exporter` you can scrape runtime information from a running OracleIdentityGovernance instance and monitor them using Prometheus and Grafana.

### Prerequisites

- Have Docker and a Kubernetes cluster running and have `kubectl` installed and configured.
- Have Helm installed.
- An OracleIdentityGovernance domain deployed by `weblogic-operator` is running in the Kubernetes cluster.

### Prepare to use the setup monitoring script

The sample scripts for setup monitoring for OracleIdentityGovernance domain are available at `${WORKDIR}/monitoring-service`.

You must edit `monitoring-inputs.yaml`(or a copy of it) to provide the details of your domain. Refer to the configuration parameters below to understand the information that you must provide in this file.

#### Configuration parameters

The following parameters can be provided in the inputs file.

| Parameter | Description | Default |
| --- | --- | --- |
| `domainUID` | domainUID of the OracleIdentityGovernance domain. | `oimcluster` |
| `domainNamespace` | Kubernetes namespace of the OracleIdentityGovernance domain. | `oimcluster` |
| `setupKubePrometheusStack` | Boolean value indicating whether kube-prometheus-stack (Prometheus, Grafana and Alertmanager) to be installed | `true` |
| `additionalParamForKubePrometheusStack` | The script install's kube-prometheus-stack with `service.type` as NodePort and values for `service.nodePort` as per the parameters defined in `monitoring-inputs.yaml`. Use `additionalParamForKubePrometheusStack` parameter to further configure with additional parameters as per [values.yaml](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml). Sample value to disable NodeExporter, Prometheus-Operator TLS support and Admission webhook support for PrometheusRules resources is `--set nodeExporter.enabled=false --set prometheusOperator.tls.enabled=false --set prometheusOperator.admissionWebhooks.enabled=false`|  |
| `monitoringNamespace` | Kubernetes namespace for monitoring setup. | `monitoring` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `adminServerPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `soaClusterName` | Name of the soaCluster. | `soa_cluster` |
| `soaManagedServerPort` | Port number of the managed servers in the soaCluster. | `8001` |
| `wlsMonitoringExporterTosoaCluster` | Boolean value indicating whether to deploy WebLogic Monitoring Exporter to soaCluster. | `false` |
| `oimClusterName` | Name of the oimCluster. | `oim_cluster` |
| `oimManagedServerPort` | Port number of the managed servers in the oimCluster. | `14000` |
| `wlsMonitoringExporterTooimCluster` | Boolean value indicating whether to deploy WebLogic Monitoring Exporter to oimCluster. | `false` |
| `exposeMonitoringNodePort` | Boolean value indicating if the Monitoring Services (Prometheus, Grafana and Alertmanager) is exposed outside of the Kubernetes cluster. | `false` |
| `prometheusNodePort` | Port number of the Prometheus outside the Kubernetes cluster. | `32101` |
| `grafanaNodePort` | Port number of the Grafana outside the Kubernetes cluster. | `32100` |
| `alertmanagerNodePort` | Port number of the Alertmanager outside the Kubernetes cluster. | `32102` |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret which has Administration Server’s user name and password. | `oimcluster-domain-credentials` |

Note that the values specified in the `monitoring-inputs.yaml` file will be used to install kube-prometheus-stack (Prometheus, Grafana and Alertmanager) and deploying WebLogic Monitoring Exporter into the OracleIdentityGovernance domain. Hence make the domain specific values to be same as that used during domain creation.

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
- Deploys WebLogic Monitoring Exporter to `soaCluster` if `wlsMonitoringExporterTosoaCluster` is set to `true`.
- Exposes the Monitoring Services (Prometheus at `32101`, Grafana at `32100` and Alertmanager at `32102`) outside of the Kubernetes cluster if `exposeMonitoringNodePort` is set to `true`.
- Imports the WebLogic Server Grafana Dashboard if `setupKubePrometheusStack` is set to `true`.
- Deploys WebLogic Monitoring Exporter to Administration Server.
- Deploys WebLogic Monitoring Exporter to `oimCluster` if `wlsMonitoringExporterTooimCluster` is set to `true`.
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

	
