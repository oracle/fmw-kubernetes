---
title: "Logging and Visualization"
weight: 4
pre : "<b>4. </b>"
description: "Describes the steps for logging and visualization with Elasticsearch and Kibana."
---

After the OIG domain is set up you can publish operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.

In [Prepare your environment](../../prepare-your-environment) if you decided to use the Elasticsearch and Kibana by setting the parameter `elkIntegrationEnabled` to `true`, then the steps below must be followed to complete the setup.

If you did not set `elkIntegrationEnabled` to `true` and want to do so post configuration, run the following command:

   ```bash
   $ helm upgrade --reuse-values --namespace operator --set "elkIntegrationEnabled=true" --set "logStashImage=logstash:6.6.0" --set "elasticSearchHost=elasticsearch.default.svc.cluster.local" --set "elasticSearchPort=9200" --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator
   ```
   
   The output will look similar to the following:
   
   ```bash
   Release "weblogic-kubernetes-operator" has been upgraded. Happy Helming!
   NAME: weblogic-kubernetes-operator
   LAST DEPLOYED: Tue Aug 18 05:57:11 2020
   NAMESPACE: operator
   STATUS: deployed
   REVISION: 3
   TEST SUITE: None
   ```

### Install Elasticsearch and Kibana

1. Create the Kubernetes resource using the following command:

   ```bash
   $ kubectl apply -f <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/elasticsearch-and-kibana/elasticsearch_and_kibana.yaml
   ```
   
   For example:
   
   ```bash
   $ kubectl apply -f /scratch/OIGDockerK8S/weblogic-kubernetes-operator/kubernetes/samples/scripts/elasticsearch-and-kibana/elasticsearch_and_kibana.yaml
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
   dedicated: false
   domainNamespaces:
   - oigns
   elasticSearchHost: elasticsearch.default.svc.cluster.local
   elasticSearchPort: 9200
   elkIntegrationEnabled: true
   externalDebugHttpPort: 30999
   externalRestEnabled: false
   externalRestHttpsPort: 31001
   image: weblogic-kubernetes-operator:3.0.1
   imagePullPolicy: IfNotPresent
   internalDebugHttpPort: 30999
   istioEnabled: false
   javaLoggingLevel: INFO
   logStashImage: logstash:6.6.0
   remoteDebugNodePortEnabled: false
   serviceAccount: operator-serviceaccount
   suspendOnDebugStartup: false
   ```
   
1. To check that Elasticsearch and Kibana are deployed in the Kubernetes cluster, run the following command:

   ```
   $ kubectl get pods
   ```
   
   The output will look similar to the following:
   
   ```bash
   NAME                             READY   STATUS    RESTARTS   AGE
   elasticsearch-857bd5ff6b-tvqdn   1/1     Running   0          2m9s
   kibana-594465687d-zc2rt          1/1     Running   0          2m9s
   ```

   
### Create the logstash pod

OIG Server logs can be pushed to the Elasticsearch server using the `logstash` pod. The `logstash` pod needs access to the persistent volume of the OIG domain created previously, for example `governancedomain-domain-pv`.  The steps to create the `logstash` pod are as follows:

1. Obtain the OIG domain persistence volume details:

   ```bash
   $ kubectl get pv -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl get pv -n oigns
   ```
   
   The output will look similar to the following:
   
   ```bash
   NAME                         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS                         REASON   AGE
   governancedomain-domain-pv   10Gi       RWX            Retain           Bound    oigns/governancedomain-domain-pvc   governancedomain-oim-storage-class            28h
   ```
   
   Make note of the `CLAIM` value, for example in this case `governancedomain-oim-pvc`
   
1. Run the following command to get the `mountPath` of your domain:
   
   ```bash
   $ kubectl describe domains <domain_uid> -n <domain_namespace> | grep "Mount Path"
   ```
   
   For example:
   
   ```bash
   $ kubectl describe domains governancedomain -n oigns | grep "Mount Path"
   ```
   
   The output will look similar to the following:
   
   ```bash
   Mount Path:  /u01/oracle/user_projects/domains
   ```
   
1. Navigate to the `<work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/elasticsearch-and-kibana` directory and create a `logstash.yaml` file as follows.
   Change the `claimName` and `mountPath` values to match the values returned in the previous commands:
   
   ```
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: logstash-wls
     namespace: oigns
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
             claimName: governancedomain-domain-pvc
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
   $ mkdir -p  /scratch/OIGDockerK8S/governancedomainpv/logstash
   ```
   
1. Create a `logstash.conf` in the newly created `logstash` directory that contains the following. Make sure the paths correspond to your `mountPath` and `domain` name:
   
   ```
   input {
     file {
       path => "/u01/oracle/user_projects/domains/logs/governancedomain/AdminServer*.log"
       tags => "Adminserver_log"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/logs/governancedomain/soa_server*.log"
       tags => "soaserver_log"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/logs/governancedomain/oim_server*.log"
       tags => "Oimserver_log"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/governancedomain/servers/AdminServer/logs/AdminServer-diagnostic.log"
       tags => "Adminserver_diagnostic"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/governancedomain/servers/**/logs/soa_server*-diagnostic.log"
       tags => "Soa_diagnostic"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/governancedomain/servers/**/logs/oim_server*-diagnostic.log"
       tags => "Oimserver_diagnostic"
       start_position => beginning
     }
     file {
       path => "/u01/oracle/user_projects/domains/governancedomain/servers/**/logs/access*.log"
       tags => "Access_logs"
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
   $ kubectl create -f <work directory>/weblogic-kubernetes-operator/kubernetes/samples/scripts/elasticsearch-and-kibana/logstash.yaml 
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
   $ kubectl get pods -n oigns
   ```
   
   The output should look similar to the following:
   
   ```bash
   NAME                                                        READY   STATUS      RESTARTS   AGE
   logstash-wls-85867765bc-bhs54                               1/1     Running     0          9s
   governancedomain-adminserver                                1/1     Running     0          90m
   governancedomain-create-fmw-infra-sample-domain-job-dktkk   0/1     Completed   0          25h
   governancedomain-oim-server1                                1/1     Running     0          87m
   governancedomain-soa-server1                                1/1     Running     0          87m
   ```
   
   Then run the following to get the Elasticsearch pod name:
   
   ```bash
   $ kubectl get pods
   ```
   
   The output should look similar to the following:
   
   ```bash
   NAME                             READY   STATUS    RESTARTS   AGE
   elasticsearch-857bd5ff6b-tvqdn   1/1     Running   0          7m48s
   kibana-594465687d-zc2rt          1/1     Running   0          7m48s
   ```

### Verify and access the Kibana console
    
1. Check if the indices are created correctly in the elasticsearch pod:
   
   ```bash
   $ kubectl exec -it elasticsearch-857bd5ff6b-tvqdn -- /bin/bash
   ```
   
   This will take you into a bash shell in the elasticsearch pod:
   
   ```bash
   [root@elasticsearch-857bd5ff6b-tvqdn elasticsearch]#
   ```
   
1. In the elasticsearch bash shell run the following to check the indices:
   
   ```
   [root@elasticsearch-857bd5ff6b-tvqdn elasticsearch]# curl -i "127.0.0.1:9200/_cat/indices?v"
   ```
   
   The output will look similar to the following:
   
   ```bash
   HTTP/1.1 200 OK
   content-type: text/plain; charset=UTF-8
   content-length: 580

   health status index                uuid                   pri rep docs.count docs.deleted store.size pri.store.size
   green  open   .kibana_task_manager 1qQ-C21GQJa38lAR28_7iA   1   0          2            0     12.6kb         12.6kb
   green  open   .kibana_1            TwIdqENXTqm6mZlBRVy__A   1   0          2            0      7.6kb          7.6kb
   yellow open   logstash-2020.09.30  6LuZLYgARYCGGN-yZT5bJA   5   1      90794            0       22mb           22mb
   yellow open   logstash-2020.09.29  QBYQrolXRiW9l8Ct3DrSyQ   5   1         38            0     86.3kb         86.3kb
   ```
   
   Exit the bash shell by typing `exit`.
   
1. Find the Kibana port by running the following command:
   
   ```bash
   $ kubectl get svc
   ```
   
   The output will look similar to the following:
   
   ```bash
   NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
   elasticsearch   ClusterIP   10.107.79.44    <none>        9200/TCP,9300/TCP   11m
   kibana          NodePort    10.103.60.126   <none>        5601:31490/TCP      11m
   kubernetes      ClusterIP   10.96.0.1       <none>        443/TCP             7d5h
   ```
   
   In the example above the Kibana port is `31490`.
   
   
1. Access the Kibana console with `http://${MASTERNODE-HOSTNAME}:${KIBANA-PORT}/app/kibana`.

1. Click on **Dashboard** in the left hand Navigation Menu.

1. In the **Create index pattern** page enter `logstash*` and click **Next Step**.

1. From the **Time Filter field name** drop down menu select `@timestamp` and click **Create index pattern**.

1. Once the index pattern is created click on **Discover** in the navigation menu to view the logs.

For more details on how to use the Kibana console see the [Kibana Guide](https://www.elastic.co/guide/en/kibana/current/index.html)
   
   
   
   
   