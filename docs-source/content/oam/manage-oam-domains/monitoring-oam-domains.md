---
title: "d. Monitoring an OAM domain"
description: "Describes the steps for Monitoring the OAM domain."
---

After the OAM domain is set up you can monitor the OAM instance using Prometheus and Grafana. See [Monitoring a domain](https://github.com/oracle/weblogic-monitoring-exporter).

The WebLogic Monitoring Exporter uses the WLS RESTful Management API to scrape runtime information and then exports Prometheus-compatible metrics. It is deployed as a web application in a WebLogic Server (WLS) instance, version 12.2.1 or later, typically, in the instance from which you want to get metrics.

There are two ways to setup monitoring and you should choose one method or the other:

1. [Setup automatically using setup-monitoring.sh](#setup-automatically-using-setup-monitoring.sh)
1. [Setup using manual configuration](#setup-using-manual-configuration)

### Setup automatically using setup-monitoring.sh

The  `$WORKDIR/kubernetes/monitoring-service/setup-monitoring.sh` sets up  the monitoring for the OAM domain. It installs Prometheus, Grafana, WebLogic Monitoring Exporter and deploys the web applications to the OAM domain. It also deploys the WebLogic Server Grafana dashboard.

For usage details execute `./setup-monitoring.sh -h`.

1. Edit the `$WORKDIR/kubernetes/monitoring-service/monitoring-inputs.yaml` and change the `domainUID`, `domainNamespace`, and `weblogicCredentialsSecretName` to correspond to your deployment. For example:

   ```
   version: create-accessdomain-monitoring-inputs-v1

   # Unique ID identifying your domain.
   # This ID must not contain an underscope ("_"), and must be lowercase and unique across all domains in a Kubernetes cluster.
   domainUID: accessdomain

   # Name of the domain namespace
   domainNamespace: oamns

   # Boolean value indicating whether to install kube-prometheus-stack
   setupKubePrometheusStack: true

   # Additional parameters for helm install kube-prometheus-stack
   # Refer https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml for additional parameters
   # Sample :
   # additionalParamForKubePrometheusStack: --set nodeExporter.enabled=false --set prometheusOperator.tls.enabled=false --set prometheusOperator.admissionWebhooks.enabled=false
   additionalParamForKubePrometheusStack:

   # Name of the monitoring namespace
   monitoringNamespace: monitoring

   # Name of the Admin Server
   adminServerName: AdminServer
   #
   # Port number for admin server
   adminServerPort: 7001

   # Cluster name
   oamClusterName: oam_cluster

   # Port number for managed server
   oamManagedServerPort: 14100

   # WebLogic Monitoring Exporter to Cluster
   wlsMonitoringExporterTooamCluster: true

   # Cluster name
   policyClusterName: policy_cluster

   # Port number for managed server
   policyManagedServerPort: 15100

   # WebLogic Monitoring Exporter to Cluster
   wlsMonitoringExporterTopolicyCluster: true


   # Boolean to indicate if the adminNodePort will be exposed
   exposeMonitoringNodePort: true

   # NodePort to expose Prometheus
   prometheusNodePort: 32101

   # NodePort to expose Grafana
   grafanaNodePort: 32100

   # NodePort to expose Alertmanager
   alertmanagerNodePort: 32102

   # Name of the Kubernetes secret for the Admin Server's username and password
   weblogicCredentialsSecretName: accessdomain-credentials
   ```

1. Run the following command to setup monitoring.

   ```bash
   $ cd $WORKDIR/kubernetes/monitoring-service
   $ ./setup-monitoring.sh -i monitoring-inputs.yaml
   ```

   The output should be similar to the following:
   
   ```
   Monitoring setup in  monitoring in progress

   node/worker-node1 not labeled
   node/worker-node2 not labeled
   node/master-node not labeled
   Setup prometheus-community/kube-prometheus-stack started
   "prometheus-community" has been added to your repositories
   Hang tight while we grab the latest from your chart repositories...
      ...Successfully got an update from the "stable" chart repository
      ...Successfully got an update from the "prometheus" chart repository
      ...Successfully got an update from the "prometheus-community" chart repository
      ...Successfully got an update from the "appscode" chart repository
   Update Complete. ⎈ Happy Helming!⎈ 
   Setup prometheus-community/kube-prometheus-stack in progress
   NAME: monitoring
   LAST DEPLOYED: Tue Jul 12 14:13:49 2022
   NAMESPACE: monitoring
   STATUS: deployed
   REVISION: 1
   NOTES:
   kube-prometheus-stack has been installed. Check its status by running:
     kubectl --namespace monitoring get pods -l "release=monitoring"

   Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
   Setup prometheus-community/kube-prometheus-stack completed
   Deploy WebLogic Monitoring Exporter started
   Deploying WebLogic Monitoring Exporter with domainNamespace[oamns], domainUID[accessdomain], adminServerPodName[accessdomain-adminserver]
     % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
   100   655  100   655    0     0   1564      0 --:--:-- --:--:-- --:--:--  1566
   100 2196k  100 2196k    0     0  2025k      0  0:00:01  0:00:01 --:--:-- 5951k
   created $WORKDIR/kubernetes/monitoring-service/scripts/wls-exporter-deploy dir
   created /tmp/ci-EHhB7bP847
   /tmp/ci-EHhB7bP847 $WORKDIR/kubernetes/monitoring-service
   in temp dir
     adding: WEB-INF/weblogic.xml (deflated 61%)
     adding: config.yml (deflated 60%)
   $WORKDIR/kubernetes/monitoring-service
   created /tmp/ci-e7wPrlLlud
   14:26
   /tmp/ci-e7wPrlLlud $WORKDIR/kubernetes/monitoring-service
   in temp dir
     adding: WEB-INF/weblogic.xml (deflated 61%)
     adding: config.yml (deflated 60%)
   $WORKDIR/kubernetes/monitoring-service
   created /tmp/ci-U38XXs6d06
   /tmp/ci-U38XXs6d06 $WORKDIR/kubernetes/monitoring-service
   in temp dir
     adding: WEB-INF/weblogic.xml (deflated 61%)
     adding: config.yml (deflated 60%)
   $WORKDIR/kubernetes/monitoring-service

   Initializing WebLogic Scripting Tool (WLST) ...

   Welcome to WebLogic Server Administration Scripting Shell

   Type help() for help on available commands

   Connecting to t3://accessdomain-adminserver:7001 with userid weblogic ...
   Successfully connected to Admin Server "AdminServer" that belongs to domain "accessdomain".

   Warning: An insecure protocol was used to connect to the server. 
   To ensure on-the-wire security, the SSL port or Admin port should be used instead.

   Deploying .........
   Deploying application from /u01/oracle/wls-exporter-deploy/wls-exporter-adminserver.war to targets AdminServer (upload=true) ...
   <Jul 12, 2022 2:14:31 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating deploy operation for application, wls-exporter-adminserver [archive: /u01/oracle/wls-exporter-deploy/wls-exporter-adminserver.war], to AdminServer .> 
   .Completed the deployment of Application with status completed
   Current Status of your Deployment:
   Deployment command type: deploy
   Deployment State : completed
   Deployment Message : no message
   Starting application wls-exporter-adminserver.
   <Jul 12, 2022 2:14:36 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating start operation for application, wls-exporter-adminserver [archive: null], to AdminServer .> 
   Completed the start of Application with status completed
   Current Status of your Deployment:
   Deployment command type: start
   Deployment State : completed
   14:27
   Deployment command type: start
   Deployment State : completed
   Deployment Message : no message
   Deploying .........
   Deploying application from /u01/oracle/wls-exporter-deploy/wls-exporter-oam.war to targets oam_cluster (upload=true) ...
   <Jul 12, 2022 2:14:37 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating deploy operation for application, wls-exporter-oam [archive: /u01/oracle/wls-exporter-deploy/wls-exporter-oam.war], to oam_cluster .> 
   .Completed the deployment of Application with status completed
   Current Status of your Deployment:
   Deployment command type: deploy
   Deployment State : completed
   Deployment Message : no message
   Starting application wls-exporter-oam.
   <Jul 12, 2022 2:14:41 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating start operation for application, wls-exporter-oam [archive: null], to oam_cluster .> 
   .Completed the start of Application with status completed
   Current Status of your Deployment:
   Deployment command type: start
   Deployment State : completed
   Deployment Message : no message
   Deploying .........
   Deploying application from /u01/oracle/wls-exporter-deploy/wls-exporter-policy.war to targets policy_cluster (upload=true) ...
   <Jul 12, 2022 2:14:44 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating deploy operation for application, wls-exporter-policy [archive: /u01/oracle/wls-exporter-deploy/wls-exporter-policy.war], to policy_cluster .> 
   .Completed the deployment of Application with status completed
   Current Status of your Deployment:
   Deployment command type: deploy
   Deployment State : completed
   Deployment Message : no message
   Starting application wls-exporter-policy.
   <Jul 12, 2022 2:14:49 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating start operation for application, wls-exporter-policy [archive: null], to policy_cluster .> 
   .Completed the start of Application with status completed
   Current Status of your Deployment:
   Deployment command type: start
   Deployment State : completed
   Deployment Message : no message
   Disconnected from weblogic server: AdminServer
 

   Exiting WebLogic Scripting Tool.

   <Jul 12, 2022 2:14:52 PM GMT> <Warning> <JNDI> <BEA-050001> <WLContext.close() was called in a different thread than the one in which it was created.> 
   14:27
   Deploy WebLogic Monitoring Exporter completed
   secret/basic-auth created
   servicemonitor.monitoring.coreos.com/wls-exporter created
   Deploying WebLogic Server Grafana Dashboard....
   {"id":25,"slug":"weblogic-server-dashboard","status":"success","uid":"5yUwzbZWz","url":"/d/5yUwzbZWz/weblogic-server-dashboard","version":1}
   Deployed WebLogic Server Grafana Dashboard successfully

   Grafana is available at NodePort: 32100
   Prometheus is available at NodePort: 32101
   Altermanager is available at NodePort: 32102
   ==============================================================
   ```
   
#### Prometheus service discovery

After the ServiceMonitor is deployed, the wls-exporter should be discovered by Prometheus and be able to collect metrics. 

1. Access the following URL to view Prometheus service discovery: `http://${MASTERNODE-HOSTNAME}:32101/service-discovery`

1. Click on `serviceMonitor/oamns/wls-exporter/0` and then *show more*. Verify all the targets are mentioned.

**Note** : It may take several minutes for `serviceMonitor/oamns/wls-exporter/0` to appear, so refresh the page until it does.

#### Grafana dashboard

1. Access the Grafana dashboard with the following URL: `http://${MASTERNODE-HOSTNAME}:32100` and login with `admin/admin`. Change your password when prompted.

1. In the `Dashboards` panel, click on `WebLogic Server Dashboard`. The dashboard for your OAM domain should be displayed. If it is not displayed, click the `Search` icon in the left hand menu and search for `WebLogic Server Dashboard`.
   
#### Cleanup   

To uninstall the Prometheus, Grafana, WebLogic Monitoring Exporter and the deployments, you can run the `$WORKDIR/monitoring-service/kubernetes/delete-monitoring.sh` script. For usage details execute `./delete-monitoring.sh -h`.

1. To uninstall run the following command:
   
   For example:
   
   ```bash
   $ cd $WORKDIR/kubernetes/monitoring-service
   $ ./delete-monitoring.sh -i monitoring-inputs.yaml
   $ kubectl delete namespace monitoring
   ```   


### Setup using manual configuration

Install Prometheus, Grafana and WebLogic Monitoring Exporter manually. Create the web applications and deploy to the OAM domain.

#### Deploy the Prometheus operator

1. Kube-Prometheus requires all nodes to be labelled with `kubernetes.io/os=linux`. To check if your nodes are labelled, run the following:

   ```bash
   $ kubectl get nodes --show-labels
   ```
   
   If the nodes are labelled the output will look similar to the following:
   
   ```
   NAME             STATUS   ROLES    AGE   VERSION   LABELS
   worker-node1     Ready    <none>   42d   v1.20.10  beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker-node1,kubernetes.io/os=linux
   worker-node2     Ready    <none>   42d   v1.20.10  beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker-node2,kubernetes.io/os=linux
   master-node      Ready    master   42d   v1.20.10 beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=master-node,kubernetes.io/os=linux,node-role.kubernetes.io/master=
   ```

   If the nodes are not labelled, run the following command:
   
   ```bash
   $ kubectl label nodes --all kubernetes.io/os=linux
   ```

1. Clone Prometheus by running the following commands:

   ```bash
   $ cd $WORKDIR/kubernetes/monitoring-service
   $ git clone https://github.com/coreos/kube-prometheus.git -b v0.7.0
   ```
   
   **Note**: Please refer the compatibility matrix of [Kube Prometheus](https://github.com/coreos/kube-prometheus#kubernetes-compatibility-matrix). Please download the [release](https://github.com/prometheus-operator/kube-prometheus/releases) of the repository according to the Kubernetes version of your cluster.
   
   
1. Run the following command to create the namespace and custom resource definitions:

   ```bash
   $ cd kube-prometheus
   $ kubectl create -f manifests/setup
   ```
   
   The output will look similar to the following:
   
   ```
   namespace/monitoring created
   customresourcedefinition.apiextensions.k8s.io/alertmanagerconfigs.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/podmonitors.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/probes.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/prometheuses.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com created
   customresourcedefinition.apiextensions.k8s.io/thanosrulers.monitoring.coreos.com created
   clusterrole.rbac.authorization.k8s.io/prometheus-operator created
   clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator created
   deployment.apps/prometheus-operator created
   service/prometheus-operator created
   serviceaccount/prometheus-operator created
   ```
   
1. Run the following command to created the rest of the resources:

   ```bash
   $ kubectl create -f manifests/
   ```
   
   The output will look similar to the following:
   
   ```
   alertmanager.monitoring.coreos.com/main created
   prometheusrule.monitoring.coreos.com/alertmanager-main-rules created
   secret/alertmanager-main created
   service/alertmanager-main created
   serviceaccount/alertmanager-main created
   servicemonitor.monitoring.coreos.com/alertmanager-main created
   clusterrole.rbac.authorization.k8s.io/blackbox-exporter created
   clusterrolebinding.rbac.authorization.k8s.io/blackbox-exporter created
   configmap/blackbox-exporter-configuration created
   deployment.apps/blackbox-exporter created
   service/blackbox-exporter created
   serviceaccount/blackbox-exporter created
   servicemonitor.monitoring.coreos.com/blackbox-exporter created
   secret/grafana-config created
   secret/grafana-datasources created
   configmap/grafana-dashboard-alertmanager-overview created
   configmap/grafana-dashboard-apiserver created
   configmap/grafana-dashboard-cluster-total created
   configmap/grafana-dashboard-controller-manager created
   configmap/grafana-dashboard-k8s-resources-cluster created
   configmap/grafana-dashboard-k8s-resources-namespace created
   configmap/grafana-dashboard-k8s-resources-node created
   configmap/grafana-dashboard-k8s-resources-pod created
   configmap/grafana-dashboard-k8s-resources-workload created
   configmap/grafana-dashboard-k8s-resources-workloads-namespace created
   configmap/grafana-dashboard-kubelet created
   configmap/grafana-dashboard-namespace-by-pod created
   configmap/grafana-dashboard-namespace-by-workload created
   configmap/grafana-dashboard-node-cluster-rsrc-use created
   configmap/grafana-dashboard-node-rsrc-use created
   configmap/grafana-dashboard-nodes created
   configmap/grafana-dashboard-persistentvolumesusage created
   configmap/grafana-dashboard-pod-total created
   configmap/grafana-dashboard-prometheus-remote-write created
   configmap/grafana-dashboard-prometheus created
   configmap/grafana-dashboard-proxy created
   configmap/grafana-dashboard-scheduler created
   configmap/grafana-dashboard-workload-total created
   configmap/grafana-dashboards created
   deployment.apps/grafana created
   service/grafana created
   serviceaccount/grafana created
   servicemonitor.monitoring.coreos.com/grafana created
   prometheusrule.monitoring.coreos.com/kube-prometheus-rules created
   clusterrole.rbac.authorization.k8s.io/kube-state-metrics created
   clusterrolebinding.rbac.authorization.k8s.io/kube-state-metrics created
   deployment.apps/kube-state-metrics created
   prometheusrule.monitoring.coreos.com/kube-state-metrics-rules created
   service/kube-state-metrics created
   serviceaccount/kube-state-metrics created
   servicemonitor.monitoring.coreos.com/kube-state-metrics created
   prometheusrule.monitoring.coreos.com/kubernetes-monitoring-rules created
   servicemonitor.monitoring.coreos.com/kube-apiserver created
   servicemonitor.monitoring.coreos.com/coredns created
   servicemonitor.monitoring.coreos.com/kube-controller-manager created
   servicemonitor.monitoring.coreos.com/kube-scheduler created
   servicemonitor.monitoring.coreos.com/kubelet created
   clusterrole.rbac.authorization.k8s.io/node-exporter created
   clusterrolebinding.rbac.authorization.k8s.io/node-exporter created
   daemonset.apps/node-exporter created
   prometheusrule.monitoring.coreos.com/node-exporter-rules created
   service/node-exporter created
   serviceaccount/node-exporter created
   servicemonitor.monitoring.coreos.com/node-exporter created
   apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
   clusterrole.rbac.authorization.k8s.io/prometheus-adapter created
   clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
   clusterrolebinding.rbac.authorization.k8s.io/prometheus-adapter created
   clusterrolebinding.rbac.authorization.k8s.io/resource-metrics:system:auth-delegator created
   clusterrole.rbac.authorization.k8s.io/resource-metrics-server-resources created
   configmap/adapter-config created
   deployment.apps/prometheus-adapter created
   rolebinding.rbac.authorization.k8s.io/resource-metrics-auth-reader created
   service/prometheus-adapter created
   serviceaccount/prometheus-adapter created
   servicemonitor.monitoring.coreos.com/prometheus-adapter created
   clusterrole.rbac.authorization.k8s.io/prometheus-k8s created
   clusterrolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   prometheusrule.monitoring.coreos.com/prometheus-operator-rules created
   servicemonitor.monitoring.coreos.com/prometheus-operator created
   prometheus.monitoring.coreos.com/k8s created
   prometheusrule.monitoring.coreos.com/prometheus-k8s-prometheus-rules created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s-config created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   role.rbac.authorization.k8s.io/prometheus-k8s-config created
   role.rbac.authorization.k8s.io/prometheus-k8s created
   role.rbac.authorization.k8s.io/prometheus-k8s created
   role.rbac.authorization.k8s.io/prometheus-k8s created
   service/prometheus-k8s created
   serviceaccount/prometheus-k8s created
   servicemonitor.monitoring.coreos.com/prometheus-k8s created
   unable to recognize "manifests/alertmanager-podDisruptionBudget.yaml": no matches for kind "PodDisruptionBudget" in version "policy/v1"
   unable to recognize "manifests/prometheus-adapter-podDisruptionBudget.yaml": no matches for kind "PodDisruptionBudget" in version "policy/v1"
   unable to recognize "manifests/prometheus-podDisruptionBudget.yaml": no matches for kind "PodDisruptionBudget" in version "policy/v1"
   ```


1. Provide external access for Grafana, Prometheus, and Alertmanager, by running the following commands:

   ```bash
   $ kubectl patch svc grafana -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32100 }]'
   
   $ kubectl patch svc prometheus-k8s -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32101 }]'
 
   $ kubectl patch svc alertmanager-main -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32102 }]'
   ```
   
   **Note**: This assigns port 32100 to Grafana, 32101 to Prometheus, and 32102 to Alertmanager.
   
   The output will look similar to the following:
   
   ```
   service/grafana patched
   service/prometheus-k8s patched
   service/alertmanager-main patched
   ```

1. Verify that the Prometheus, Grafana, and Alertmanager pods are running in the monitoring namespace and the respective services have the exports configured correctly:

   ```bash
   $ kubectl get pods,services -o wide -n monitoring
   ```
   
   The output should look similar to the following:
   
   ```
   NAME                                      READY   STATUS    RESTARTS   AGE   IP             NODE           NOMINATED NODE   READINESS GATES
   pod/alertmanager-main-0                    2/2     Running  0          67s   10.244.1.7     worker-node1   <none>           <none>
   pod/alertmanager-main-1                    2/2     Running  0          67s   10.244.2.26    worker-node2   <none>           <none>
   pod/alertmanager-main-2                    2/2     Running  0          67s   10.244.1.8     worker-node1   <none>           <none>
   pod/grafana-f8cd57fcf-tmlqt                1/1     Running  0          65s   10.244.2.28    worker-node2   <none>           <none>
   pod/kube-state-metrics-587bfd4f97-l8knh    3/3     Running  0          65s   10.244.1.9     worker-node1   <none>           <none>
   pod/node-exporter-2ztpd                    2/2     Running  0          65s   10.247.95.26   worker-node1   <none>           <none>
   pod/node-exporter-92sxb                    2/2     Running  0          65s   10.250.40.59   worker-node2   <none>           <none>
   pod/node-exporter-d77tl                    2/2     Running  0          65s   10.196.54.36   master-node    <none>           <none>
   pod/prometheus-adapter-69b8496df6-6gqrz    1/1     Running  0          65s   10.244.2.29    worker-node2   <none>           <none>
   pod/prometheus-k8s-0                       2/2     Running  1          66s   10.244.2.27    worker-node2   <none>           <none>
   pod/prometheus-k8s-1                       2/2     Running  1          66s   10.244.1.10    worker-node1   <none>           <none>
   pod/prometheus-operator-7649c7454f-9p747   2/2     Running  0          2m    10.244.2.25    worker-node2   <none>           <none>

   NAME                            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE    SELECTOR
   service/alertmanager-main       NodePort    10.104.92.62    <none>        9093:32102/TCP               67s    alertmanager=main,app=alertmanager
   service/alertmanager-operated   ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP   67s    app=alertmanager
   service/grafana                 NodePort    10.100.171.3    <none>        3000:32100/TCP               66s    app=grafana
   service/kube-state-metrics      ClusterIP   None            <none>        8443/TCP,9443/TCP            66s    app.kubernetes.io/name=kube-state-metrics
   service/node-exporter           ClusterIP   None            <none>        9100/TCP                     66s    app.kubernetes.io/name=node-exporter
   service/prometheus-adapter      ClusterIP   10.109.248.92   <none>        443/TCP                      66s    name=prometheus-adapter
   service/prometheus-k8s          NodePort    10.98.212.247   <none>        9090:32101/TCP               66s    app=prometheus,prometheus=k8s
   service/prometheus-operated     ClusterIP   None            <none>        9090/TCP                     66s    app=prometheus
   service/prometheus-operator     ClusterIP   None            <none>        8443/TCP                     2m1s   app.kubernetes.io/component=controller,app.kubernetes.io/name=prometheus-operator
   ```
  

#### Deploy WebLogic Monitoring Exporter


1. Generate the WebLogic Monitoring Exporter deployment package. The `wls-exporter.war` package need to be updated and created for each listening port (Administration Server and Managed Servers) in the domain. Set the below environment values and run the script `get-wls-exporter.sh` to generate the required WAR files at `${WORKDIR}/kubernetes/monitoring-service/scripts/wls-exporter-deploy`:

   ```bash
   $ cd $WORKDIR/kubernetes/monitoring-service/scripts
   $ export adminServerPort=7001
   $ export wlsMonitoringExporterTopolicyCluster=true
   $ export policyManagedServerPort=15100
   $ export wlsMonitoringExporterTooamCluster=true
   $ export oamManagedServerPort=14100
   $ sh get-wls-exporter.sh
   ```

   The output will look similar to the following:
   
   ```
     % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
   100   655  100   655    0     0   1107      0 --:--:-- --:--:-- --:--:--  1108
   100 2196k  100 2196k    0     0  1787k      0  0:00:01  0:00:01 --:--:-- 9248k
   created $WORKDIR/kubernetes/monitoring-service/scripts/wls-exporter-deploy dir
   domainNamespace is empty, setting to default oamns
   domainUID is empty, setting to default accessdomain
   weblogicCredentialsSecretName is empty, setting to default "accessdomain-domain-credentials"
   adminServerName is empty, setting to default "AdminServer"
   oamClusterName is empty, setting to default "oam_cluster"
   policyClusterName is empty, setting to default "policy_cluster"
   created /tmp/ci-Bu74rCBxwu
   /tmp/ci-Bu74rCBxwu $WORKDIR/kubernetes/monitoring-service/scripts
   in temp dir
     adding: WEB-INF/weblogic.xml (deflated 61%)
     adding: config.yml (deflated 60%)
   $WORKDIR/kubernetes/monitoring-service/scripts
   created /tmp/ci-RQv3rLbLsX
   /tmp/ci-RQv3rLbLsX $WORKDIR/kubernetes/monitoring-service/scripts
   in temp dir
     adding: WEB-INF/weblogic.xml (deflated 61%)
     adding: config.yml (deflated 60%)
   $WORKDIR/kubernetes/monitoring-service/scripts
   created /tmp/ci-DWIYlocP5e
   /tmp/ci-DWIYlocP5e $WORKDIR/kubernetes/monitoring-service/scripts
   in temp dir
     adding: WEB-INF/weblogic.xml (deflated 61%)
     adding: config.yml (deflated 60%)
   $WORKDIR/kubernetes/monitoring-service/scripts
   ```
   
1. Deploy the WebLogic Monitoring Exporter WAR files into the Oracle Access Management domain:

   ```bash
   $ cd $WORKDIR/kubernetes/monitoring-service/scripts
   $ kubectl cp wls-exporter-deploy <domain_namespace>/<domain_uid>-adminserver:/u01/oracle
   $ kubectl cp deploy-weblogic-monitoring-exporter.py <domain_namespace>/<domain_uid>-adminserver:/u01/oracle/wls-exporter-deploy
   $ kubectl exec -it -n <domain_namespace> <domain_uid>-adminserver -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py -domainName <domain_uid> -adminServerName AdminServer -adminURL <domain_uid>-adminserver:7001 -username weblogic -password <password> -oamClusterName oam_cluster -wlsMonitoringExporterTooamCluster true -policyClusterName policy_cluster -wlsMonitoringExporterTopolicyCluster true
   ```
   
   For example:
   
   ```bash
   $ cd $WORKDIR/kubernetes/monitoring-service/scripts
   $ kubectl cp wls-exporter-deploy oamns/accessdomain-adminserver:/u01/oracle
   $ kubectl cp deploy-weblogic-monitoring-exporter.py oamns/accessdomain-adminserver:/u01/oracle/wls-exporter-deploy
   $ kubectl exec -it -n oamns accessdomain-adminserver -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py -domainName accessdomain -adminServerName AdminServer -adminURL accessdomain-adminserver:7001 -username weblogic -password <password> -oamClusterName oam_cluster -wlsMonitoringExporterTooamCluster true -policyClusterName policy_cluster -wlsMonitoringExporterTopolicyCluster true
   ```
   
   The output will look similar to the following:
   
   ```
   Initializing WebLogic Scripting Tool (WLST) ...

   Welcome to WebLogic Server Administration Scripting Shell

   Type help() for help on available commands

   Connecting to t3://accessdomain-adminserver:7001 with userid weblogic ...
   Successfully connected to Admin Server "AdminServer" that belongs to domain "accessdomain".

   Warning: An insecure protocol was used to connect to the server.
   To ensure on-the-wire security, the SSL port or Admin port should be used instead.

   Deploying .........
   Deploying application from /u01/oracle/wls-exporter-deploy/wls-exporter-adminserver.war to targets AdminServer (upload=true) ...
   <Jul 12, 2022 3:38:15 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating deploy operation for application, wls-exporter-adminserver [archive:    /u01/oracle/wls-exporter-deploy/wls-exporter-adminserver.war], to AdminServer .>
   ..Completed the deployment of Application with status completed
   Current Status of your Deployment:
   Deployment command type: deploy
   Deployment State : completed
   Deployment Message : no message
   Starting application wls-exporter-adminserver.
   <Jul 12, 2022 3:38:25 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating start operation for application, wls-exporter-adminserver [archive: null], to AdminServer .>
   .Completed the start of Application with status completed
   Current Status of your Deployment:
   Deployment command type: start
   Deployment State : completed
   Deployment Message : no message
   Deploying .........
   Deploying application from /u01/oracle/wls-exporter-deploy/wls-exporter-oam.war to targets oam_cluster (upload=true) ...
   <Jul 12, 2022 3:38:28 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating deploy operation for application, wls-exporter-oam [archive: /u01/oracle/wls-exporter-deploy/wls-exporter-oam.war], to oam_cluster .>
   .Completed the deployment of Application with status completed
   Current Status of your Deployment:
   Deployment command type: deploy
   Deployment State : completed
   Deployment Message : no message
   Starting application wls-exporter-oam.
   <Jul 12, 2022 3:38:34 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating start operation for application, wls-exporter-oam [archive: null], to oam_cluster .>
   .Completed the start of Application with status completed
   Current Status of your Deployment:
   Deployment command type: start
   Deployment State : completed
   Deployment Message : no message
   Deploying .........
   Deploying application from /u01/oracle/wls-exporter-deploy/wls-exporter-policy.war to targets policy_cluster (upload=true) ...
   <Jul 12, 2022 3:38:38 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating deploy operation for application, wls-exporter-policy [archive: /u01/oracle/wls-exporter-deploy/wls-exporter-policy.war], to policy_cluster .>
   .Completed the deployment of Application with status completed
   Current Status of your Deployment:
   Deployment command type: deploy
   Deployment State : completed
   Deployment Message : no message
   Starting application wls-exporter-policy.
   <Jul 12, 2022 3:38:44 PM GMT> <Info> <J2EE Deployment SPI> <BEA-260121> <Initiating start operation for application, wls-exporter-policy [archive: null], to policy_cluster .>
   .Completed the start of Application with status completed
   Current Status of your Deployment:
   Deployment command type: start
   Deployment State : completed
   Deployment Message : no message
   Disconnected from weblogic server: AdminServer

   Exiting WebLogic Scripting Tool.

   <Jul 12, 2022 3:38:47 PM GMT> <Warning> <JNDI> <BEA-050001> <WLContext.close() was called in a different thread than the one in which it was created.>
   ```

####  Configure Prometheus Operator

Prometheus enables you to collect metrics from the WebLogic Monitoring Exporter. The Prometheus Operator identifies the targets using service discovery. To get the WebLogic Monitoring Exporter end point discovered as a target, you must create a service monitor pointing to the service.

The exporting of metrics from wls-exporter requires basicAuth, so a Kubernetes Secret is created with the user name and password that are base64 encoded. This Secret is used in the ServiceMonitor deployment. The `wls-exporter-ServiceMonitor.yaml` has basicAuth with credentials as username: `weblogic` and password: `<password>` in base64 encoded. 

1. Run the following command to get the base64 encoded version of the weblogic password:

   ```bash
   $ echo -n "<password>" | base64
   ```
   
   The output will look similar to the following:
   
   ```
   V2VsY29tZTE=
   ```
   
1. Update the `$WORKDIR/kubernetes/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml` and change the `password:` value to the value returned above. Also change the `namespace:` and `weblogic.domainName:` values to match your OAM namespace and domain name:

   ```
   apiVersion: v1
   kind: Secret
   metadata:
     name: basic-auth
     namespace: oamns
   data:
     password: V2VsY29tZTE=
     user: d2VibG9naWM=
   type: Opaque
   ---
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: wls-exporter
     namespace: oamns
     labels:
       k8s-app: wls-exporter
       release: monitoring
   spec:
     namespaceSelector:
       matchNames:
       - oamns
     selector:
       matchLabels:
         weblogic.domainName: accessdomain
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

1. Update the `$WORKDIR/kubernetes/monitoring-service/manifests/prometheus-roleSpecific-domain-namespace.yaml` and change the `namespace` to match your OAM namespace. For example:

   ```
   apiVersion: rbac.authorization.k8s.io/v1
   items:
   - apiVersion: rbac.authorization.k8s.io/v1
     kind: Role
     metadata:
       name: prometheus-k8s
       namespace: oamns
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
   kind: RoleList
   ```
   
1. Update the `$WORKDIR/kubernetes/monitoring-service/manifests/prometheus-roleBinding-domain-namespace.yaml and change the `namespace` to match your OAM namespace. For example:
   
   ```
   apiVersion: rbac.authorization.k8s.io/v1
   items:
   - apiVersion: rbac.authorization.k8s.io/v1
     kind: RoleBinding
     metadata:
       name: prometheus-k8s
       namespace: oamns
     roleRef:
       apiGroup: rbac.authorization.k8s.io
       kind: Role
       name: prometheus-k8s
     subjects:
     - kind: ServiceAccount
       name: prometheus-k8s
       namespace: monitoring
   kind: RoleBindingList
   ```   
   
   
1. Run the following command to enable Prometheus:

   ```bash 
   $ kubectl apply -f .
   ```

   The output will look similar to the following:
   
   ```
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   role.rbac.authorization.k8s.io/prometheus-k8s created
   secret/basic-auth created
   servicemonitor.monitoring.coreos.com/wls-exporter created
   ```

   
   
   
#### Prometheus Service Discovery

After the ServiceMonitor is deployed, the wls-exporter should be discovered by Prometheus and be able to collect metrics. 

1. Access the following URL to view Prometheus service discovery: `http://${MASTERNODE-HOSTNAME}:32101/service-discovery`

1. Click on `oamns/wls-exporter/0 ` and then *show more*. Verify all the targets are mentioned.

#### Grafana Dashboard

1. Access the Grafana dashboard with the following URL: `http://${MASTERNODE-HOSTNAME}:32100` and login with `admin/admin`. Change your password when prompted.

1. Import the Grafana dashboard by navigating on the left hand menu to *Create* > *Import*. Copy the content from `$WORKDIR/kubernetes/monitoring-service/config/weblogic-server-dashboard-import.json` and paste. Then click *Load* and *Import*. The dashboard should be displayed in the Dashboards panel.
   
   
#### Cleanup

To clean up a manual installation:

1. Run the following commands:

   ```bash
   $ cd $WORKDIR/kubernetes/monitoring-service/manifests/
   $ kubectl delete -f .
   ```
   
1. Delete the deployments:

   ```bash
   $ cd $WORKDIR/kubernetes/monitoring-service/scripts/
   $ kubectl cp undeploy-weblogic-monitoring-exporter.py <domain_namespace>/<domain_uid>-adminserver:/u01/oracle/wls-exporter-deploy
   $ kubectl exec -it -n <domain_namespace> <domain_uid>-adminserver -- /u01/oracle/oracle_common/common/bin/wlst.sh /u01/oracle/wls-exporter-deploy/undeploy-weblogic-monitoring-exporter.py -domainName <domain_uid>  -adminServerName AdminServer -adminURL <domain_uid>-adminserver:7001 -username weblogic -password <password> -oamClusterName oam_cluster -wlsMonitoringExporterTooamCluster true -policyClusterName policy_cluster -wlsMonitoringExporterTopolicyCluster true
   ```

1. Delete Prometheus:

   ```bash
   $ cd $WORKDIR/kubernetes/monitoring-service/kube-prometheus
   $ kubectl delete -f manifests
   $ kubectl delete -f manifests/setup
   ```

1. Delete the monitoring namespace:

   ```bash
   $ kubectl delete namespace monitoring
   ```
   
   
