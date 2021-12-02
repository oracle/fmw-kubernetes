---
title: "Monitoring an OIG domain"
weight: 5
pre : "<b>5. </b>"
description: "Describes the steps for Monitoring the OIG domain and Publising the logs to Elasticsearch."
---

After the OIG domain is set up you can monitor the OIG instance using Prometheus and Grafana. See [Monitoring a domain](https://github.com/oracle/weblogic-monitoring-exporter).


The WebLogic Monitoring Exporter uses the WLS RESTful Management API to scrape runtime information and then exports Prometheus-compatible metrics. It is deployed as a web application in a WebLogic Server (WLS) instance, version 12.2.1 or later, typically, in the instance from which you want to get metrics.

### Deploy the Prometheus operator

1. Clone Prometheus by running the following commands:

   ```bash
   $ cd <work directory>
   $ git clone https://github.com/coreos/kube-prometheus.git
   ```
   
   **Note**: Please refer the compatibility matrix of [Kube Prometheus](https://github.com/coreos/kube-prometheus#kubernetes-compatibility-matrix). Please download the [release](https://github.com/prometheus-operator/kube-prometheus/releases) of the repository according to the Kubernetes version of your cluster. In the above example the latest release will be downloaded.
   
   For example:
   
   ```bash
   $ cd /scratch/OIGDockerK8S
   $ git clone https://github.com/coreos/kube-prometheus.git
   ```
   
   
   
1. Run the following command to create the namespace and custom resource definitions:

   ```bash
   $ cd kube-prometheus
   $ kubectl create -f manifests/setup
   ```
   
   The output will look similar to the following:
   
   ```bash
   kubectl create -f manifests/setup
   namespace/monitoring created
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
   
   ```bash
   alertmanager.monitoring.coreos.com/main created
   secret/alertmanager-main created
   service/alertmanager-main created
   serviceaccount/alertmanager-main created
   servicemonitor.monitoring.coreos.com/alertmanager created
   secret/grafana-datasources created
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
   configmap/grafana-dashboard-statefulset created
   configmap/grafana-dashboard-workload-total created
   configmap/grafana-dashboards created
   deployment.apps/grafana created
   service/grafana created
   serviceaccount/grafana created
   servicemonitor.monitoring.coreos.com/grafana created
   clusterrole.rbac.authorization.k8s.io/kube-state-metrics created
   clusterrolebinding.rbac.authorization.k8s.io/kube-state-metrics created
   deployment.apps/kube-state-metrics created
   service/kube-state-metrics created
   serviceaccount/kube-state-metrics created
   servicemonitor.monitoring.coreos.com/kube-state-metrics created
   clusterrole.rbac.authorization.k8s.io/node-exporter created
   clusterrolebinding.rbac.authorization.k8s.io/node-exporter created
   daemonset.apps/node-exporter created
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
   servicemonitor.monitoring.coreos.com/prometheus-operator created
   prometheus.monitoring.coreos.com/k8s created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s-config created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   role.rbac.authorization.k8s.io/prometheus-k8s-config created
   role.rbac.authorization.k8s.io/prometheus-k8s created
   role.rbac.authorization.k8s.io/prometheus-k8s created
   role.rbac.authorization.k8s.io/prometheus-k8s created
   prometheusrule.monitoring.coreos.com/prometheus-k8s-rules created
   service/prometheus-k8s created
   serviceaccount/prometheus-k8s created
   servicemonitor.monitoring.coreos.com/prometheus created
   servicemonitor.monitoring.coreos.com/kube-apiserver created
   servicemonitor.monitoring.coreos.com/coredns created
   servicemonitor.monitoring.coreos.com/kube-controller-manager created
   servicemonitor.monitoring.coreos.com/kube-scheduler created
   servicemonitor.monitoring.coreos.com/kubelet created
   ```

1. Kube-Prometheus requires all nodes to be labelled with `kubernetes.io/os=linux`. To check if your nodes are labelled, run the following:

   ```bash
   $ kubectl get nodes --show-labels
   ```
   
   If the nodes are labelled the output will look similar to the following:
   
   ```bash
   NAME             STATUS   ROLES    AGE   VERSION   LABELS
   worker-node1     Ready    <none>   42d   v1.18.4   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker-node1,kubernetes.io/os=linux
   worker-node2     Ready    <none>   42d   v1.18.4   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker-node2,kubernetes.io/os=linux
   master-node      Ready    master   42d   v1.18.4  beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=masternode,kubernetes.io/os=linux,node-role.kubernetes.io/master=
   ```

   If the nodes are not labelled, run the following command:
   
   ```bash
   $ kubectl label nodes --all kubernetes.io/os=linux
   ```
   
1. Provide external access for Grafana, Prometheus, and Alertmanager, by running the following commands:

   ```bash
   $ kubectl patch svc grafana -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32100 }]'
   
   $ kubectl patch svc prometheus-k8s -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32101 }]'
 
   $ kubectl patch svc alertmanager-main -n monitoring --type=json -p '[{"op": "replace", "path": "/spec/type", "value": "NodePort" },{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 32102 }]'
   ```
   
   **Note**: This assigns port 32100 to Grafana, 32101 to Prometheus, and 32102 to Alertmanager.
   
   The output will look similar to the following:
   
   ```bash
   service/grafana patched
   service/prometheus-k8s patched
   service/alertmanager-main patched
   ```

1. Verify that the Prometheus, Grafana, and Alertmanager pods are running in the monitoring namespace and the respective services have the exports configured correctly:

   ```bash
   $ kubectl get pods,services -o wide -n monitoring
   ```
   
   The output should look similar to the following:
   
   ```bash
   NAME                                      READY   STATUS    RESTARTS   AGE     IP               NODE             NOMINATED NODE   READINESS GATES
   pod/alertmanager-main-0                    2/2     Running   0          97s    10.244.2.52      worker-node2   <none>           <none>
   pod/alertmanager-main-1                    2/2     Running   0          97s    10.244.1.61      worker-node1   <none>           <none>
   pod/alertmanager-main-2                    2/2     Running   0          97s    10.244.2.53      worker-node2   <none>           <none>
   pod/grafana-86445dccbb-dln2l               1/1     Running   0          96s    10.244.2.55      worker-node2   <none>           <none>
   pod/kube-state-metrics-5b67d79459-k7xrb    3/3     Running   0          96s    10.244.1.63      worker-node1   <none>           <none>
   pod/node-exporter-dhp4k                    2/2     Running   0          96s    10.250.111.111   worker-node2   <none>           <none>
   pod/node-exporter-jknkv                    2/2     Running   0          96s    10.196.4.112     masternode       <none>           <none>
   pod/node-exporter-vpn9l                    2/2     Running   0          96s    10.250.111.112   worker-node1   <none>           <none>
   pod/prometheus-adapter-66b855f564-snkjb    1/1     Running   0          96s    10.244.2.56      worker-node2   <none>           <none>
   pod/prometheus-k8s-0                       3/3     Running   0          96s    10.244.2.54      worker-node2   <none>           <none>
   pod/prometheus-k8s-1                       3/3     Running   0          96s    10.244.1.62      worker-node1   <none>           <none>
   pod/prometheus-operator-78fcb48ccf-gcgc5   2/2     Running   0          107s   10.244.1.60      worker-node1   <none>           <none>

   NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE    SELECTOR
   service/alertmanager-main       NodePort    10.107.184.118   <none>        9093:32102/TCP               98s    alertmanager=main,app=alertmanager
   service/alertmanager-operated   ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   97s    app=alertmanager
   service/grafana                 NodePort    10.96.249.254    <none>        3000:32100/TCP               97s    app=grafana
   service/kube-state-metrics      ClusterIP   None             <none>        8443/TCP,9443/TCP            97s    app.kubernetes.io/name=kube-state-metrics
   service/node-exporter           ClusterIP   None             <none>        9100/TCP                     97s    app.kubernetes.io/name=node-exporter
   service/prometheus-adapter      ClusterIP   10.100.222.239   <none>        443/TCP                      97s    name=prometheus-adapter
   service/prometheus-k8s          NodePort    10.106.163.78    <none>        9090:32101/TCP               96s    app=prometheus,prometheus=k8s
   service/prometheus-operated     ClusterIP   None             <none>        9090/TCP                     96s    app=prometheus
   service/prometheus-operator     ClusterIP   None             <none>        8443/TCP                     108s   app.kubernetes.io/component=contr                                oller,app.kubernetes.io/name=prometheus-operator
   ```
   


### Deploy WebLogic Monitoring Exporter

1. Download WebLogic Monitoring Exporter:

   ```bash
   $ mkdir -p <work_directory>/wls_exporter
   $ cd <work_directory>/wls_exporter
   $ wget https://github.com/oracle/weblogic-monitoring-exporter/releases/download/<version>/wls-exporter.war
   $ wget https://github.com/oracle/weblogic-monitoring-exporter/releases/download/<version>/get<version>.sh
   ```
   
   For example:
   
   ```bash
   $ mkdir -p /scratch/OIGDockerK8S/wls_exporter
   $ cd /scratch/OIGDockerK8S/wls_exporter
   $ wget https://github.com/oracle/weblogic-monitoring-exporter/releases/download/v1.2.0/wls-exporter.war
   $ wget https://github.com/oracle/weblogic-monitoring-exporter/releases/download/v1.2.0/get1.2.0.sh
   ```

1. Create a configuration file `config-admin.yaml` in the `<work_directory>/wls_exporter` directory that contains the following. Modify the `restPort` to match the server port for the OIG Administration Server:

   ```
   metricsNameSnakeCase: true
   restPort: 7001
   queries:
     - key: name
       keyName: location
       prefix: wls_server_
       applicationRuntimes:
         key: name
         keyName: app
         componentRuntimes:
           prefix: wls_webapp_config_
           type: WebAppComponentRuntime
           key: name
           values: [deploymentState, contextRoot, sourceInfo, openSessionsHighCount, openSessionsCurrentCount, sessionsOpenedTotalCount, sessionCookieMaxAgeSecs, sessionInvalidationIntervalSecs, sessionTimeoutSecs, singleThreadedServletPoolSize, sessionIDLength, servletReloadCheckSecs, jSPPageCheckSecs]
           servlets:
             prefix: wls_servlet_
             key: servletName
     - JVMRuntime:
         prefix: wls_jvm_
         key: name
     - executeQueueRuntimes:
         prefix: wls_socketmuxer_
         key: name
         values: [pendingRequestCurrentCount]
     - workManagerRuntimes:
         prefix: wls_workmanager_
         key: name
         values: [stuckThreadCount, pendingRequests, completedRequests]
     - threadPoolRuntime:
         prefix: wls_threadpool_
         key: name
         values: [executeThreadTotalCount, queueLength, stuckThreadCount, hoggingThreadCount]
     - JMSRuntime:
         key: name
         keyName: jmsruntime
         prefix: wls_jmsruntime_
         JMSServers:
           prefix: wls_jms_
           key: name
           keyName: jmsserver
           destinations:
             prefix: wls_jms_dest_
             key: name
             keyName: destination
     - persistentStoreRuntimes:
         prefix: wls_persistentstore_
         key: name
     - JDBCServiceRuntime:
         JDBCDataSourceRuntimeMBeans:
           prefix: wls_datasource_
           key: name
     - JTARuntime:
         prefix: wls_jta_
         key: name
   ```



1. Create a configuration file `config-oimserver.yaml` in the `<work_directory>/wls_exporter` directory that contains the following. Modify the `restPort` to match the server port for the OIG Managed Servers:

   ```
   metricsNameSnakeCase: true
   restPort: 14000
   queries:
     - key: name
       keyName: location
       prefix: wls_server_
       applicationRuntimes:
         key: name
         keyName: app
         componentRuntimes:
           prefix: wls_webapp_config_
           type: WebAppComponentRuntime
           key: name
           values: [deploymentState, contextRoot, sourceInfo, openSessionsHighCount, openSessionsCurrentCount, sessionsOpenedTotalCount, sessionCookieMaxAgeSecs, sessionInvalidationIntervalSecs, sessionTimeoutSecs, singleThreadedServletPoolSize, sessionIDLength, servletReloadCheckSecs, jSPPageCheckSecs]
           servlets:
             prefix: wls_servlet_
             key: servletName
     - JVMRuntime:
         prefix: wls_jvm_
         key: name
     - executeQueueRuntimes:
         prefix: wls_socketmuxer_
         key: name
         values: [pendingRequestCurrentCount]
     - workManagerRuntimes:
         prefix: wls_workmanager_
         key: name
         values: [stuckThreadCount, pendingRequests, completedRequests]
     - threadPoolRuntime:
         prefix: wls_threadpool_
         key: name
         values: [executeThreadTotalCount, queueLength, stuckThreadCount, hoggingThreadCount]
     - JMSRuntime:
         key: name
         keyName: jmsruntime
         prefix: wls_jmsruntime_
         JMSServers:
           prefix: wls_jms_
           key: name
           keyName: jmsserver
           destinations:
             prefix: wls_jms_dest_
             key: name
             keyName: destination
     - persistentStoreRuntimes:
         prefix: wls_persistentstore_
         key: name
     - JDBCServiceRuntime:
         JDBCDataSourceRuntimeMBeans:
           prefix: wls_datasource_
           key: name
     - JTARuntime:
         prefix: wls_jta_
         key: name
   ```

1. Create a configuration file `config-soaserver.yaml` in the `<work_directory>/wls_exporter` directory that contains the following. Modify the `restPort` to match the server port for the SOA Managed Servers:

   ```
   metricsNameSnakeCase: true
   restPort: 8001
   queries:
     - key: name
       keyName: location
       prefix: wls_server_
       applicationRuntimes:
         key: name
         keyName: app
         componentRuntimes:
           prefix: wls_webapp_config_
           type: WebAppComponentRuntime
           key: name
           values: [deploymentState, contextRoot, sourceInfo, openSessionsHighCount, openSessionsCurrentCount, sessionsOpenedTotalCount, sessionCookieMaxAgeSecs, sessionInvalidationIntervalSecs, sessionTimeoutSecs, singleThreadedServletPoolSize, sessionIDLength, servletReloadCheckSecs, jSPPageCheckSecs]
           servlets:
             prefix: wls_servlet_
             key: servletName
     - JVMRuntime:
         prefix: wls_jvm_
         key: name
     - executeQueueRuntimes:
         prefix: wls_socketmuxer_
         key: name
         values: [pendingRequestCurrentCount]
     - workManagerRuntimes:
         prefix: wls_workmanager_
         key: name
         values: [stuckThreadCount, pendingRequests, completedRequests]
     - threadPoolRuntime:
         prefix: wls_threadpool_
         key: name
         values: [executeThreadTotalCount, queueLength, stuckThreadCount, hoggingThreadCount]
     - JMSRuntime:
         key: name
         keyName: jmsruntime
         prefix: wls_jmsruntime_
         JMSServers:
           prefix: wls_jms_
           key: name
           keyName: jmsserver
           destinations:
             prefix: wls_jms_dest_
             key: name
             keyName: destination
     - persistentStoreRuntimes:
         prefix: wls_persistentstore_
         key: name
     - JDBCServiceRuntime:
         JDBCDataSourceRuntimeMBeans:
           prefix: wls_datasource_
           key: name
     - JTARuntime:
         prefix: wls_jta_
         key: name
   ```
   
1. Generate the deployment package for the OIG Administration Server:

   ```bash
   $ chmod 777 get<version>.sh
   $ ./get<version> config-admin.yaml
   ```
   
   For example:
   
   ```bash
   $ chmod 777 get1.2.0.sh
   $ ./get1.2.0.sh config-admin.yaml
   ```
   
   The output will look similar to the following:
   
   ```
   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
   100   629  100   629    0     0   1241      0 --:--:-- --:--:-- --:--:--  1240
   100 2033k  100 2033k    0     0  1219k      0  0:00:01  0:00:01 --:--:-- 2882k
   created /tmp/ci-lKm0dOnLwU
   /tmp/ci-lKm0dOnLwU /scratch/OIGDockerK8S/wls_exporter
   in temp dir
     adding: config.yml (deflated 65%)
   /scratch/OIGDockerK8S/wls_exporter
   ```
   
   This will generate a `wls-exporter.war` file in the same directory that contains a `config.yml` that corresponds to `config-admin.yaml`. Rename the file as follows:
   
   ```bash
   mv wls-exporter.war wls-exporter-admin.war
   ```
   

1. Generate the deployment package for the OIG Managed Server and Policy Manager Server, for example:
   
   ```bash
   $ ./get1.2.0.sh config-oimserver.yaml
   $ mv wls-exporter.war wls-exporter-oimserver.war
   $ ./get1.2.0.sh config-soaserver.yaml
   $ mv wls-exporter.war wls-exporter-soaserver.war
   ```
   
1. Copy the war files to the persistent volume directory:

   ```bash
   cp wls-exporter*.war <work_directory>/<persistent_volume>/
   ```
   
   For example:
   
   ```bash
   $ cp wls-exporter*.war /scratch/OIGDockerK8S/governancedomainpv/
   ```

### Deploy the wls-exporter war files in OIG WebLogic server

1. Login to the Oracle Enterprise Manager Console using the URL `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/em`.

1. Navigate to *WebLogic Domain* > *Deployments*. Click on the padlock in the upper right hand corner and select *Lock and Edit*.

1. From the 'Deployment' drop down menu select *Deploy*.

1. In the *Select Archive* screen, under *Archive or exploded directory is on the server where Enterprise Manager is running*, click *Browse*. Navigate to the `/u01/oracle/user_projects/domains`
directory and select `wls-exporter-admin.war`. Click *OK* and then *Next*.

1. In *Select Target* check *AdminServer* and click *Next*.

1. In *Application Attributes* set the following and click *Next*:

   * Application Name: `wls-exporter-admin`
   * Context Root: `wls-exporter`
   * Distribution: `Install and start application (servicing all requests)`
  
1. In *Deployment Settings* click *Deploy*. 

1. Once you see the message *Deployment Succeeded*, click *Close*.

1. Click on the padlock in the upper right hand corner and select *Activate Changes*.

1. Repeat the above steps to deploy `wls-exporter-oimserver.war` with the following caveats:

   * In *Select Target* choose *oim_cluster*
   * In *Application Attributes* set Application Name: `wls-exporter-oimserver`, Context Root: `wls-exporter`
   * In *Distribution* select `Install and start application (servicing all requests)`
   
1. Repeat the above steps to deploy `wls-exporter-soaserver.war` with the following caveats:

   * In *Select Target* choose *soa_cluster*
   * In *Application Attributes* set Application Name: `wls-exporter-soaserver`, Context Root: `wls-exporter`
   * In *Distribution* select `Install and start application (servicing all requests)`
   
1. Check the wls-exporter is accessible using the URL: `https://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/wls-exporter`.
    
   You should see a page saying *This is the WebLogic Monitoring Exporter*.


### Prometheus Operator Configuration

Prometheus has to be configured to collect the metrics from the weblogic-monitor-exporter. The Prometheus operator identifies the targets using service discovery. To get the weblogic-monitor-exporter end point discovered as a target, you will need to create a service monitor to point to the service as follows:

1. Create a `wls-exporter-service-monitor.yaml` in the `<work_directory>/wls_exporter` directory with the following contents:

   ```
   apiVersion: v1
   kind: Secret
   metadata:
     name: basic-auth
     namespace: monitoring
   data:
     password: V2VsY29tZTE=    ## <password> base64
     user: d2VibG9naWM=        ## weblogic base64
   type: Opaque
   ---
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: wls-exporter-governancedomain
     namespace: monitoring
     labels:
       k8s-app: wls-exporter
   spec:
     namespaceSelector:
       matchNames:
       - oigns
     selector:
       matchLabels:
         weblogic.domainName: governancedomain
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
   
   **Note**: In the above example, change the `password` value to the base64 encoded version of your weblogic password. To find the base64 value run the following:
   
   ```bash
   $ echo -n "<password>" | base64
   ```
   
   If using a different namespace from `oigns` or a different `domainUID` from `governancedomain`, then change accordingly.
   
1. Add Rolebinding for the WebLogic OIG domain namespace:

   ```bash
   $ cd <work_directory>/kube-prometheus/manifests
   ```
   
   Edit the `prometheus-roleBindingSpecificNamespaces.yaml` file and add the following to the file for your OIG domain namespace, for example `oigns`:
   
   ```
   - apiVersion: rbac.authorization.k8s.io/v1
     kind: RoleBinding
     metadata:
       name: prometheus-k8s
       namespace: oigns
     roleRef:
       apiGroup: rbac.authorization.k8s.io
       kind: Role
       name: prometheus-k8s
     subjects:
     - kind: ServiceAccount
       name: prometheus-k8s
       namespace: monitoring
   ```
   
   For example the file should now read:
   
   ```
   apiVersion: rbac.authorization.k8s.io/v1
   items:
   - apiVersion: rbac.authorization.k8s.io/v1
     kind: RoleBinding
     metadata:
       name: prometheus-k8s
       namespace: oigns
     roleRef:
       apiGroup: rbac.authorization.k8s.io
       kind: Role
       name: prometheus-k8s
     subjects:
     - kind: ServiceAccount
       name: prometheus-k8s
       namespace: monitoring
   - apiVersion: rbac.authorization.k8s.io/v1
     kind: RoleBinding
     metadata:
       name: prometheus-k8s
       namespace: default
   ....
   ```

1. Add the Role for WebLogic OIG domain namespace. Edit the `prometheus-roleSpecificNamespaces.yaml` and change the namespace to your OIG domain namespace, for example `oigns`:

   ```
   - apiVersion: rbac.authorization.k8s.io/v1
     kind: Role
     metadata:
       name: prometheus-k8s
       namespace: oigns
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
   ....	   
   ```

1. Apply the yaml files as follows:

   ```bash
   $ kubectl apply -f prometheus-roleBindingSpecificNamespaces.yaml
   $ kubectl apply -f prometheus-roleSpecificNamespaces.yaml
   ```

   The output should look similar to the following:

   ```
   kubectl apply -f prometheus-roleBindingSpecificNamespaces.yaml
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
   Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s configured
   Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s configured
   Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
   rolebinding.rbac.authorization.k8s.io/prometheus-k8s configured
   
   $ kubectl apply -f prometheus-roleSpecificNamespaces.yaml
   role.rbac.authorization.k8s.io/prometheus-k8s created
   Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
   role.rbac.authorization.k8s.io/prometheus-k8s configured
   Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
   role.rbac.authorization.k8s.io/prometheus-k8s configured
   Warning: kubectl apply should be used on resource created by either kubectl create --save-config or kubectl apply
   role.rbac.authorization.k8s.io/prometheus-k8s configured
   ```

### Deploy the ServiceMonitor

1. Run the following command to create the ServiceMonitor:

   ```bash
   $ cd <work_directory>/wls_exporter
   $ kubectl create -f wls-exporter-service-monitor.yaml
   ```
   
   The output will look similar to the following:
   
   ```
   servicemonitor.monitoring.coreos.com/wls-exporter-oim-cluster created
   ```
   
### Prometheus Service Discovery

After ServiceMonitor is deployed, the wls-exporter should be discovered by Prometheus and be able to scrape metrics. 

1. Access the following URL to view Prometheus service discovery: `http://${MASTERNODE-HOSTNAME}:32101/service-discovery`

1. Click on `monitoring/wls-exporter-governancedomain/0 ` and then *show more*. Verify all the targets are mentioned.

### Grafana Dashboard

1. Access the Grafana dashboard with the following URL: `http://${MASTERNODE-HOSTNAME}:32100` and login with `admin/admin`. Change your password when prompted.

1. Import the Grafana dashboard by navigating on the left hand menu to *Create* > *Import*. Copy the content from `<work_directory>/fmw-kubernetes/OracleIdentityGovernance/kubernetes/3.0.1/grafana/weblogic_dashboard.json` and paste. Then click *Load* and *Import*.

  

   
   
   