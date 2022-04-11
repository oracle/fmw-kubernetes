---
title: "c. Logging and Visualization"
description: "Describes the steps for logging and visualization with Elasticsearch and Kibana."
---

After the OAM domain is set up you can publish operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.

In [Prepare your environment](../../prepare-your-environment) if you decided to use the Elasticsearch and Kibana by setting the parameter `elkIntegrationEnabled` to `true`, then the steps below must be followed to complete the setup.

If you did not set `elkIntegrationEnabled` to `true` and want to do so post configuration, run the following command from the `$WORKDIR` directory:

   ```bash
   $ helm upgrade --reuse-values --namespace operator --set "elkIntegrationEnabled=true" --set "logStashImage=logstash:6.6.0" --set "elasticSearchHost=elasticsearch.default.svc.cluster.local" --set "elasticSearchPort=9200" --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```
   
   The output will look similar to the following:
   
   ```
   Release "weblogic-kubernetes-operator" has been upgraded. Happy Helming!
   NAME: weblogic-kubernetes-operator
   LAST DEPLOYED: Tue Nov 2 03:49:45 2021
   NAMESPACE: operator
   STATUS: deployed
   REVISION: 3
   TEST SUITE: None
   ```

### Install Elasticsearch and Kibana
   
1. Create the Kubernetes resource using the following command:

   ```bash
   $ kubectl apply -f $WORKDIR/kubernetes/elasticsearch-and-kibana/elasticsearch_and_kibana.yaml
   ```
 
   The output will look similar to the following:
   
   ```
   deployment.apps/elasticsearch created
   service/elasticsearch created
   deployment.apps/kibana created
   service/kibana created
   ```

1. Run the following command to ensure Elasticsearch is used by the operator:

   ```bash
   $ helm get values --all weblogic-kubernetes-operator -n opns
   ```
   
   The output will look similar to the following:
   
   ```
   COMPUTED VALUES:
   clusterSizePaddingValidationEnabled: true
   domainNamespaceLabelSelector: weblogic-operator=enabled
   domainNamespaceSelectionStrategy: LabelSelector
   domainNamespaces:
   - default
   elasticSearchHost: elasticsearch.default.svc.cluster.local
   elasticSearchPort: 9200
   elkIntegrationEnabled: true
   enableClusterRoleBinding: true
   externalDebugHttpPort: 30999
   externalRestEnabled: false
   externalRestHttpsPort: 31001
   externalServiceNameSuffix: -ext
   image: weblogic-kubernetes-operator:3.3.0
   imagePullPolicy: IfNotPresent
   internalDebugHttpPort: 30999
   introspectorJobNameSuffix: -introspector
   javaLoggingFileCount: 10
   javaLoggingFileSizeLimit: 20000000
   javaLoggingLevel: FINE
   logStashImage: logstash:6.6.0
   remoteDebugNodePortEnabled: false
   serviceAccount: op-sa
   suspendOnDebugStartup: false
   ```
   
1. To check that Elasticsearch and Kibana are deployed in the Kubernetes cluster, run the following command:

   ```
   $ kubectl get pods
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                             READY   STATUS    RESTARTS   AGE 
   elasticsearch-f7b7c4c4-tb4pp   1/1     Running   0          85s
   kibana-57f6685789-mgwdl        1/1     Running   0          85s
   ```

   
### Create the logstash pod

OAM Server logs can be pushed to the Elasticsearch server using the `logstash` pod. The `logstash` pod needs access to the persistent volume of the OAM domain created previously, for example `accessdomain-domain-pv`.  The steps to create the `logstash` pod are as follows:

1. Obtain the OAM domain persistence volume details:

   ```bash
   $ kubectl get pv -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get pv -n oamns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                           STORAGECLASS                       REASON   AGE
   accessdomain-domain-pv   10Gi       RWX            Retain           Bound   oamns/accessdomain-domain-pvc   accessdomain-domain-storage-class           23h
   ```
   
   Make note of the `CLAIM` value, for example in this case `accessdomain-domain-pvc`
   
1. Run the following command to get the `mountPath` of your domain:
   
   ```bash
   $ kubectl describe domains <domain_uid> -n <domain_namespace> | grep "Mount Path"
   ```
   
   For example:
   
   ```bash
   $ kubectl describe domains accessdomain -n oamns | grep "Mount Path"
   ```
   
   The output will look similar to the following:
   
   ```
   Mount Path:  /u01/oracle/user_projects/domains
   ```
   
1. Navigate to the `$WORKDIR/kubernetes/elasticsearch-and-kibana` directory and create a `logstash.yaml` file as follows.
   Change the `claimName` and `mountPath` values to match the values returned in the previous commands. Change `namespace` to your domain namespace e.g `oamns`:
   
   ```
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: logstash-wls
     namespace: oamns
   spec:
     selector:
       matchLabels:
         k8s-app: logstash-wls
     template: # create pods using pod definition in this template
       metadata:
         labels:
           k8s-app: logstash-wls
       spec:
         volumes:
         - name: weblogic-domain-storage-volume
           persistentVolumeClaim:
             claimName: accessdomain-domain-pvc
         - name: shared-logs
           emptyDir: {}
         containers:
         - name: logstash
           image: logstash:6.6.0
           command: ["/bin/sh"]
           args: ["/usr/share/logstash/bin/logstash", "-f", "/u01/oracle/user_projects/domains/logstash/logstash.conf"]
           imagePullPolicy: IfNotPresent
           volumeMounts:
           - mountPath: /u01/oracle/user_projects/domains
             name: weblogic-domain-storage-volume
           - name: shared-logs
             mountPath: /shared-logs
           ports:
           - containerPort: 5044
             name: logstash
   ```   
   
1. In the NFS persistent volume directory that corresponds to the mountPath `/u01/oracle/user_projects/domains`, create a `logstash` directory. For example:
   
   ```
   $ mkdir -p  /scratch/OAMK8S/accessdomainpv/logstash
   ```
   
1. Create a `logstash.conf` in the newly created `logstash` directory that contains the following. Make sure the paths correspond to your `mountPath` and `domain` name:
   
   ```
   input {
     file {
       path => "/u01/oracle/user_projects/domains/logs/accessdomain/AdminServer*.log"
       tags => "Adminserver_log"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/logs/accessdomain/oam_policy_mgr*.log"
       tags => "Policymanager_log"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/logs/accessdomain/oam_server*.log"
       tags => "Oamserver_log"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/accessdomain/servers/AdminServer/logs/AdminServer-diagnostic.log"
       tags => "Adminserver_diagnostic"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/accessdomain/servers/**/logs/oam_policy_mgr*-diagnostic.log"
       tags => "Policy_diagnostic"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/accessdomain/servers/**/logs/oam_server*-diagnostic.log"
       tags => "Oamserver_diagnostic"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/accessdomain/servers/**/logs/access*.log"
       tags => "Access_logs"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/accessdomain/servers/AdminServer/logs/auditlogs/OAM/audit.log"
       tags => "Audit_logs"
       start_position => beginning
     }
   }
   filter {
     grok {
       match => [ "message", "<%{DATA:log_timestamp}> <%{WORD:log_level}> <%{WORD:thread}> <%{HOSTNAME:hostname}> <%{HOSTNAME:servername}> <%{DATA:timer}> <<%{DATA:kernel}>> <> <%{DATA:uuid}> <%{NUMBER:timestamp}> <%{DATA:misc}> <%{DATA:log_number}> <%{DATA:log_message}>" ]
     }
   if "_grokparsefailure" in [tags] {
       mutate {
           remove_tag => [ "_grokparsefailure" ]
       }
   }
   }
   output {
     elasticsearch {
       hosts => ["elasticsearch.default.svc.cluster.local:9200"]
     }
   }
   ```   
   
1. Deploy the `logstash` pod by executing the following command:
   
   ```bash
   $ kubectl create -f $WORKDIR/kubernetes/elasticsearch-and-kibana/logstash.yaml 
   ```
   
   The output will look similar to the following:
   
   ```
   deployment.apps/logstash-wls created
   ```
   
1. Run the following command to check the `logstash` pod is created correctly:
   
   ```bash
   $ kubectl get pods -n <namespace>
   ```
  
   For example:
   
   ```bash
   $ kubectl get pods -n oamns
   ```
   
   The output should look similar to the following:
   
   ```
   NAME                                            READY   STATUS      RESTARTS   AGE
   accessdomain-adminserver                                 1/1     Running     0          18h
   accessdomain-create-oam-infra-domain-job-7c9r9           0/1     Completed   0          23h
   accessdomain-oam-policy-mgr1                             1/1     Running     0          18h
   accessdomain-oam-policy-mgr2                             1/1     Running     0          18h
   accessdomain-oam-server1                                 1/1     Running     1          18h
   accessdomain-oam-server2                                 1/1     Running     1          18h
   helper                                                   1/1     Running     0          23h
   logstash-wls-6687c5bf6-jmmdp                             1/1     Running     0          12s
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          20h
   ```
   
   Then run the following to get the Elasticsearch pod name:
   
   ```bash
   $ kubectl get pods
   ```
   
   The output should look similar to the following:
   
   ```
   NAME                             READY   STATUS    RESTARTS   AGE
   elasticsearch-f7b7c4c4-tb4pp   1/1     Running   0          9m28s
   kibana-57f6685789-mgwdl        1/1     Running   0          9m28s
   ```

### Verify and access the Kibana console
    
1. Check if the indices are created correctly in the elasticsearch pod:
   
   ```bash
   $ kubectl exec -it elasticsearch-f7b7c4c4-tb4pp -- /bin/bash
   ```
   
   This will take you into a bash shell in the elasticsearch pod:
   
   ```bash
   [root@elasticsearch-f7b7c4c4-tb4pp elasticsearch]#
   ```
   
1. In the elasticsearch bash shell, run the following to check the indices:
   
   ```bash
   [root@elasticsearch-f7b7c4c4-tb4pp elasticsearch]# curl -i "127.0.0.1:9200/_cat/indices?v"
   ```
   
   The output will look similar to the following:
   
   ```
   HTTP/1.1 200 OK
   content-type: text/plain; charset=UTF-8
   content-length: 696

   health status index                uuid                   pri rep docs.count docs.deleted store.size pri.store.size
   green  open   .kibana_task_manager -IPDdiajTSyIRjelI2QJIg   1   0          2            0     12.6kb         12.6kb
   green  open   .kibana_1            YI9CZAjsTsCCuAyBb1ho3A   1   0          2            0      7.6kb          7.6kb
   yellow open   logstash-2021.11.01  4pDJSTGVR3-oOwTtHnnTkQ   5   1        148            0    173.9kb        173.9kb
   yellow open   logstash-2021.11.02  raOvTDoOTuC49nq241h4wg   5   1     115834            0     31.7mb         31.7mb
   ```
   
   Exit the bash shell by typing `exit`.
   
1. Find the Kibana port by running the following command:
   
   ```bash
   $ kubectl get svc | grep kibana
   ```
   
   The output will look similar to the following:
   
   ```
   NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
   kibana          NodePort    10.104.248.203   <none>        5601:31394/TCP      11m
   ```
   
   In the example above the Kibana port is `31394`.
   
   
1. Access the Kibana console with `http://${MASTERNODE-HOSTNAME}:${KIBANA-PORT}/app/kibana`.

1. Click **Dashboard** and in the **Create index pattern** page enter `logstash*`. Click **Next Step**.

1. From the **Time Filter field name** drop down menu select `@timestamp` and click **Create index pattern**.

1. Once the index pattern is created click on **Discover** in the navigation menu to view the logs.

For more details on how to use the Kibana console see the [Kibana Guide](https://www.elastic.co/guide/en/kibana/current/index.html)
   
   
   
   
   