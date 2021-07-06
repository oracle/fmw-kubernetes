## Monitor the OracleSOASuite instance using Prometheus and Grafana
Using the `WebLogic Monitoring Exporter` you can scrape runtime information from a running OracleSOASuite instance and monitor them using Prometheus and Grafana.

### Prerequisites

This document assumes that the Prometheus Operator is deployed on the Kubernetes cluster. If it is not already deployed, follow the steps below for deploying the Prometheus Operator.

#### Clone the kube-prometheus project

```bash
$ cd $HOME
$ wget https://github.com/coreos/kube-prometheus/archive/v0.5.0.zip
$ unzip v0.5.0.zip
```

#### Label the nodes
Kube-Prometheus requires all the exporter nodes to be labelled with `kubernetes.io/os=linux`. If a node is not labelled, then you must label it using the following command:

```
$ kubectl label nodes --all kubernetes.io/os=linux
```

#### Create Prometheus and Grafana resources

Execute the following commands to create the namespace and CRDs:

**NOTE**: Wait for a minute for each command to process.

```bash
$ cd kube-prometheus-0.5.0
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

### Set Up the WebLogic Monitoring Exporter 

Set up the WebLogic Monitoring Exporter that will collect WebLogic Server metrics and monitor OracleSOASuite domain.

#### Generate the WebLogic Monitoring Exporter Deployment Package

The `wls-exporter.war` package need to be updated and created for each listening ports (Administration Server and Managed Servers) in the domain.
Run the script `get-wls-exporter.sh <domainType>` to generate the required WAR files at `${WORKDIR}/monitoring-service/scripts/wls-exporter-deploy`:

```bash
$ cd ${WORKDIR}/monitoring-service/scripts
$ sh get-wls-exporter.sh <domainType>
```

For `soaosb` domainType :

```bash
$ sh get-wls-exporter.sh soaosb
```

Sample output:
```
created XXXX/monitoring-service/scripts/wls-exporter-deploy dir
created /tmp/ci-f1xt9gdpMH
/tmp/ci-f1xt9gdpMH XXXX/monitoring-service/scripts
in temp dir
  adding: WEB-INF/weblogic.xml (deflated 66%)
  adding: config.yml (deflated 63%)
XXXX/monitoring-service/scripts
created /tmp/ci-2LGWm8WLDA
/tmp/ci-2LGWm8WLDA XXXX/monitoring-service/scripts
in temp dir
  adding: WEB-INF/weblogic.xml (deflated 66%)
  adding: config.yml (deflated 63%)
XXXX/monitoring-service/scripts
created /tmp/ci-62Wuwbupgq
/tmp/ci-62Wuwbupgq XXXX/monitoring-service/scripts
in temp dir
  adding: WEB-INF/weblogic.xml (deflated 66%)
  adding: config.yml (deflated 63%)
XXXX/monitoring-service/scripts
```

#### Deploy the WebLogic Monitoring Exporter into the OracleSOASuite domain

Follow these steps to copy and deploy the WebLogic Monitoring Exporter WAR files into the OracleSOASuite Domain. Replace the <domainType> with appropriate value:

```
$ cd ${WORKDIR}/monitoring-service/scripts
$ kubectl cp wls-exporter-deploy soans/soainfra-adminserver:/u01/oracle
$ kubectl cp deploy-weblogic-monitoring-exporter.py soans/soainfra-adminserver:/u01/oracle/wls-exporter-deploy
$ kubectl exec -it -n soans soainfra-adminserver -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py -domainType <domainType> 
```

#### Configure Prometheus Operator 

Prometheus enables you to collect metrics from the WebLogic Monitoring Exporter. The Prometheus Operator identifies the targets using service discovery. To get the WebLogic Monitoring Exporter end point discovered as a target, you must create a service monitor pointing to the service.

The service monitor deployment YAML configuration file is available at `${WORKDIR}/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml.template`. Copy the file as `wls-exporter-ServiceMonitor.yaml` to update with appropraite values as detailed below.

The exporting of metrics from `wls-exporter` requires `basicAuth`, so a Kubernetes `Secret` is created with the user name and password that are base64 encoded. This `Secret` is used in the `ServiceMonitor` deployment. The `wls-exporter-ServiceMonitor.yaml` has `basicAuth` with credentials as username: weblogic and password: Welcome1 in base64 encoded.

If you are using a different credentials, then update `wls-exporter-ServiceMonitor.yaml` for `basicAuth` with required details.Use the following example for base64 encoded:

```
$ echo -n "Welcome1" | base64
V2VsY29tZTE=
```
You need to add `RoleBinding` and `Role` for the namespace (soans) under which the WebLogic Servers pods are running in the Kubernetes cluster. These are required for Prometheus to access the endpoints provided by the WebLogic Monitoring Exporters. The YAML configuration files for soans namespace are provided in "${WORKDIR}/monitoring-service/manifests/".

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

1. Navigate to + (Create) -> Import -> Upload the `weblogic-server-dashboard.json` file (provided at `${WORKDIR}/monitoring-service/config/weblogic-server-dashboard.json`).


### Setup Prometheus, Grafana and WebLogic Monitoring Exporter using `setup-monitoring.sh`

Alternatively, you can run the helper script `setup-monitoring.sh` available at `${WORKDIR}/monitoring-service` to setup the monitoring for OracleSOASuite domain. For usage details execute `./setup-monitoring.sh -h`. 

Sample `delete-monitoring.sh` is available at `${WORKDIR}/monitoring-service`, to uninstall the Prometheus, Grafana and WebLogic Monitoring Exporter. For usage details execute `./delete-monitoring.sh -h`.
