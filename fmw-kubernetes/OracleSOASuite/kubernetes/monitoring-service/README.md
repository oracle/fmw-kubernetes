# Monitor the Oracle SOA Suite instance using Prometheus and Grafana
Using the `WebLogic Monitoring Exporter` you can scrape runtime information from a running Oracle SOA Suite instance and monitor them using Prometheus and Grafana.

## Prerequisites
- Have Docker and a Kubernetes cluster running and have `kubectl` installed and configured.
- Have Helm installed.
- An Oracle SOA Suite domain cluster deployed by `weblogic-operator` is running in the Kubernetes cluster.

## Set up monitoring for Oracle SOA Suite domain 

Set up the WebLogic Monitoring Exporter that will collect WebLogic Server metrics and monitor Oracle SOA Suite domain. 

**Note**: Either of the following methods can be used to set up monitoring for Oracle SOA Suite domain. Using `setup-monitoring.sh` does the set up in an automated way.

1. [Set up manually](#set-up-manually)
1. [Set up using `setup-monitoring.sh`](#set-up-using-setup-monitoringsh)

## Set up manually

Before setting up WebLogic Monitoring Exporter, make sure that Prometheus and Grafana are deployed on the Kubernetes cluster. Refer [Deploy Prometheus and Grafana](https://oracle.github.io/fmw-kubernetes/soa-domains/adminguide/monitoring-soa-domains/#deploy-prometheus-and-grafana) for details.

#### Generate the WebLogic Monitoring Exporter Deployment Package

The `wls-exporter.war` package need to be updated and created for each listening ports (Administration Server and Managed Servers) in the domain.
Set the below environment values based on your domainType and run the script `get-wls-exporter.sh` to generate the required WAR files at `${WORKDIR}/monitoring-service/scripts/wls-exporter-deploy`:
- adminServerPort
- wlsMonitoringExporterTosoaCluster
- soaManagedServerPort
- wlsMonitoringExporterToosbCluster
- osbManagedServerPort

Example for `soaosb` domainType:

```
$ cd ${WORKDIR}/monitoring-service/scripts
$ export adminServerPort=7001 
$ export wlsMonitoringExporterTosoaCluster=true
$ export soaManagedServerPort=8001
$ export wlsMonitoringExporterToosbCluster=true
$ export osbManagedServerPort=9001
$ sh get-wls-exporter.sh
```

Verify whether the required WAR files are generated at `${WORKDIR}/monitoring-service/scripts/wls-exporter-deploy`.

```
$ ls ${WORKDIR}/monitoring-service/scripts/wls-exporter-deploy
```

#### Deploy the WebLogic Monitoring Exporter into the Oracle SOA Suite domain

Follow these steps to copy and deploy the WebLogic Monitoring Exporter WAR files into the Oracle SOA Suite Domain. 
**Note**: Replace the `<xxxx>` with appropriate values based on your environment:

```
$ cd ${WORKDIR}/monitoring-service/scripts
$ kubectl cp wls-exporter-deploy <namespace>/<admin_pod_name>:/u01/oracle
$ kubectl cp deploy-weblogic-monitoring-exporter.py <namespace>/<admin_pod_name>:/u01/oracle/wls-exporter-deploy
$ kubectl exec -it -n <namespace> <admin_pod_name> -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py \
-domainName <domainUID> -adminServerName <adminServerName> -adminURL <adminURL> \
-soaClusterName <soaClusterName> -wlsMonitoringExporterTosoaCluster <wlsMonitoringExporterTosoaCluster> \
-osbClusterName <osbClusterName> -wlsMonitoringExporterToosbCluster <wlsMonitoringExporterToosbCluster> \
-username <username> -password <password> 
```

Example for `soaosb` domainType:

```
$ cd ${WORKDIR}/monitoring-service/scripts
$ kubectl cp wls-exporter-deploy soans/soainfra-adminserver:/u01/oracle
$ kubectl cp deploy-weblogic-monitoring-exporter.py soans/soainfra-adminserver:/u01/oracle/wls-exporter-deploy
$ kubectl exec -it -n soans soainfra-adminserver -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py \
-domainName soainfra -adminServerName AdminServer -adminURL soainfra-adminserver:7001 \
-soaClusterName soa_cluster -wlsMonitoringExporterTosoaCluster true \
-osbClusterName osb_cluster -wlsMonitoringExporterToosbCluster true \
-username weblogic -password Welcome1 
```

#### Configure Prometheus Operator 

Prometheus enables you to collect metrics from the WebLogic Monitoring Exporter. The Prometheus Operator identifies the targets using service discovery. To get the WebLogic Monitoring Exporter end point discovered as a target, you must create a service monitor pointing to the service.

The service monitor deployment YAML configuration file is available at `${WORKDIR}/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml.template`. Copy the file as `wls-exporter-ServiceMonitor.yaml` to update with appropraite values as detailed below.

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
$ kubectl apply -f .
```

#### Verify the service discovery of WebLogic Monitoring Exporter

After the deployment of the service monitor, Prometheus should be able to discover wls-exporter and collect the metrics.

1. Access the Prometheus dashboard at `http://mycompany.com:32101/` 

1. Navigate to **Status** to see the **Service Discovery** details.

1. Verify that `wls-exporter` is listed in the discovered Services.


#### Deploy Grafana Dashboard

You can access the Grafana dashboard at `http://mycompany.com:32100/`. 

1. Log in to Grafana dashboard with username: admin and password: admin`.

1. Navigate to + (Create) -> Import -> Upload the `weblogic-server-dashboard-import.json` file (provided at `${WORKDIR}/monitoring-service/config/weblogic-server-dashboard-import.json`).


## Set up using `setup-monitoring.sh`

Alternatively, you can run the helper script `setup-monitoring.sh` available at `${WORKDIR}/monitoring-service` to setup the monitoring for Oracle SOA Suite domain. 

This script creates kube-prometheus-stack(Prometheus, Grafana and Alertmanager), WebLogic Monitoring Exporter and imports `weblogic-server-dashboard.json` into Grafana for WebLogic Server Dashboard.

### Prepare to use the setup monitoring script

The sample scripts for setup monitoring for Oracle SOA Suite domain are available at `${WORKDIR}/monitoring-service`.

You must edit `monitoring-inputs.yaml`(or a copy of it) to provide the details of your domain. Refer to the configuration parameters below to understand the information that you must provide in this file.

#### Configuration parameters

The following parameters can be provided in the inputs file.

| Parameter | Description | Default |
| --- | --- | --- |
| `domainUID` | domainUID of the Oracle SOA Suite domain. | `soainfra` |
| `domainNamespace` | Kubernetes namespace of the Oracle SOA Suite domain. | `soans` |
| `setupKubePrometheusStack` | Boolean value indicating whether kube-prometheus-stack (Prometheus, Grafana and Alertmanager) to be installed | `true` |
| `additionalParamForKubePrometheusStack` | The script install's kube-prometheus-stack with `service.type` as NodePort and values for `service.nodePort` as per the parameters defined in `monitoring-inputs.yaml`. Use `additionalParamForKubePrometheusStack` parameter to further configure with additional parameters as per [values.yaml](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml). Sample value to disable NodeExporter, Prometheus-Operator TLS support and Admission webhook support for PrometheusRules resources is `--set nodeExporter.enabled=false --set prometheusOperator.tls.enabled=false --set prometheusOperator.admissionWebhooks.enabled=false`|  |
| `monitoringNamespace` | Kubernetes namespace for monitoring setup. | `monitoring` |
| `adminServerName` | Name of the Administration Server. | `AdminServer` |
| `adminServerPort` | Port number for the Administration Server inside the Kubernetes cluster. | `7001` |
| `soaClusterName` | Name of the soaCluster. | `soa_cluster` |
| `soaManagedServerPort` | Port number of the managed servers in the soaCluster. | `8001` |
| `wlsMonitoringExporterTosoaCluster` | Boolean value indicating whether to deploy WebLogic Monitoring Exporter to soaCluster. | `false` |
| `osbClusterName` | Name of the osbCluster. | `osb_cluster` |
| `osbManagedServerPort` | Port number of the managed servers in the osbCluster. | `9001` |
| `wlsMonitoringExporterToosbCluster` | Boolean value indicating whether to deploy WebLogic Monitoring Exporter to osbCluster. | `false` |
| `exposeMonitoringNodePort` | Boolean value indicating if the Monitoring Services (Prometheus, Grafana and Alertmanager) is exposed outside of the Kubernetes cluster. | `false` |
| `prometheusNodePort` | Port number of the Prometheus outside the Kubernetes cluster. | `32101` |
| `grafanaNodePort` | Port number of the Grafana outside the Kubernetes cluster. | `32100` |
| `alertmanagerNodePort` | Port number of the Alertmanager outside the Kubernetes cluster. | `32102` |
| `weblogicCredentialsSecretName` | Name of the Kubernetes secret which has Administration Server’s user name and password. | `soainfra-domain-credentials` |

Note that the values specified in the `monitoring-inputs.yaml` file will be used to install kube-prometheus-stack (Prometheus, Grafana and Alertmanager) and deploying WebLogic Monitoring Exporter into the Oracle SOA Suite domain. Hence make the domain specific values to be same as that used during domain creation.

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
- Deploys WebLogic Monitoring Exporter to `osbCluster` if `wlsMonitoringExporterToosbCluster` is set to `true`.
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
