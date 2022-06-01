---
title: "Logging and visualization"
weight: 4
pre : "<b>4. </b>"
description: "Describes the steps for logging and visualization with Elasticsearch and Kibana."
---

After the OIG domain is set up you can publish operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.

### Install Elasticsearch and Kibana

1. If your domain namespace is anything other than `oigns`, edit the `$WORKDIR/kubernetes/elasticsearch-and-kibana/elasticsearch_and_kibana.yaml` and change all instances of `oigns` to your domain namespace.

1. Create a Kubernetes secret to access the elasticsearch and kibana container images:

   **Note:** You must first have a user account on [hub.docker.com](https://hub.docker.com).

   ```bash
   $ kubectl create secret docker-registry "dockercred" --docker-server="https://index.docker.io/v1/" --docker-username="<docker_username>" --docker-password=<password> --docker-email=<docker_email_credentials> --namespace=<domain_namespace>
   ```   
   
   For example:
   
   ```
   $ kubectl create secret docker-registry "dockercred" --docker-server="https://index.docker.io/v1/" --docker-username="username" --docker-password=<password> --docker-email=user@example.com --namespace=oigns
   ```
   
   The output will look similar to the following:
   
   ```bash
   secret/dockercred created
   ```  
   
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
   image: ghcr.io/oracle/weblogic-kubernetes-operator:3.3.0
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

   ```bash
   $ kubectl get pods -n <namespace> | grep 'elasticsearch\|kibana'
   ```
   
   For example:
   
   ```bash
   $ kubectl get pods -n oigns | grep 'elasticsearch\|kibana'
   ```
   
   The output will look similar to the following:
   
   ```
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
   
   ```
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
   
   ```
   Mount Path:  /u01/oracle/user_projects/domains
   ```
   
1. Navigate to the `$WORKDIR/kubernetes/elasticsearch-and-kibana` directory and create a `logstash.yaml` file as follows.
   Change the `claimName` and `mountPath` values to match the values returned in the previous commands. Change `namespace` to your domain namespace e.g `oigns`:
   
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
           imagePullSecrets:
         - name: dockercred
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
   
1. In the persistent volume directory that corresponds to the mountPath `/u01/oracle/user_projects/domains`, create a `logstash` directory. For example:
   
   ```bash
   $ mkdir -p  /scratch/shared/governancedomainpv/logstash
   ```
   
1. Create a `logstash.conf` in the newly created `logstash` directory that contains the following. Make sure the paths correspond to your `mountPath` and `domain` name. Also, if your namespace is anything other than `oigns` change `"elasticsearch.oigns.svc.cluster.local:9200"` to `"elasticsearch.<namespace>.svc.cluster.local:9200"`::
   
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
       hosts => ["elasticsearch.oigns.svc.cluster.local:9200"]
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
   $ kubectl get pods -n oigns
   ```
   
   The output should look similar to the following:
   
   ```
   NAME                                                        READY   STATUS      RESTARTS   AGE
   elasticsearch-678ff4fb5-89rpf                               1/1     Running     0          13m
   governancedomain-adminserver                                1/1     Running     0          90m
   governancedomain-create-fmw-infra-sample-domain-job-8cww8   0/1     Completed   0          25h
   governancedomain-oim-server1                                1/1     Running     0          87m
   governancedomain-soa-server1                                1/1     Running     0          87m
   kibana-589466bb89-k8wdr                                     1/1     Running     0          13m
   logstash-wls-f448b44c8-92l27                                1/1     Running     0          7s
   ```
   
   

### Verify and access the Kibana console
    
1. Check if the indices are created correctly in the elasticsearch pod shown above:
   
   ```bash
   $ kubectl exec -it <elasticsearch-pod> -n <namespace> -- /bin/bash
   ```
   
   For example:
   
   ```bash
   $ kubectl exec -it elasticsearch-678ff4fb5-89rpf -n oigns -- /bin/bash
   ```
   
   This will take you into a bash shell in the elasticsearch pod:
   
   ```bash
   [root@elasticsearch-678ff4fb5-89rpf elasticsearch]#
   ```
   
1. In the elasticsearch bash shell run the following to check the indices:
   
   ```bash
   [root@elasticsearch-678ff4fb5-89rpf elasticsearch]# curl -i "127.0.0.1:9200/_cat/indices?v"
   ```
   
   The output will look similar to the following:
   
   ```
   HTTP/1.1 200 OK
   content-type: text/plain; charset=UTF-8
   content-length: 580

   health status index                uuid                   pri rep docs.count docs.deleted store.size pri.store.size
   yellow open   logstash-2022.03.10  7oXXCureSWKwNY0626Szeg   5   1      46887            0     11.7mb         11.7mb
   green  open   .kibana_task_manager alZtnv2WRy6Y4iSRIbmCrQ   1   0          2            0     12.6kb         12.6kb
   green  open   .kibana_1            JeZKrO4fS_GnRL92qRmQDQ   1   0          2            0      7.6kb          7.6kb
   ```
   
   Exit the bash shell by typing `exit`.
   
1. Find the Kibana port by running the following command:
   
   ```bash
   $ kubectl get svc -n <namespace> | grep kibana
   ```
   
   For example:
   
   ```bash
   $ kubectl get svc -n oigns | grep kibana
   ```
   
   The output will look similar to the following:
   
   ```
   kibana          NodePort    10.111.224.230  <none>        5601:31490/TCP      11m
   ```
   
   In the example above the Kibana port is `31490`.
   
   
1. Access the Kibana console with `http://${MASTERNODE-HOSTNAME}:${KIBANA-PORT}/app/kibana`.

1. Click on **Dashboard** in the left hand Navigation Menu.

1. In the **Create index pattern** page enter `logstash*` and click **Next Step**.

1. From the **Time Filter field name** drop down menu select `@timestamp` and click **Create index pattern**.

1. Once the index pattern is created click on **Discover** in the navigation menu to view the logs.

For more details on how to use the Kibana console see the [Kibana Guide](https://www.elastic.co/guide/en/kibana/current/index.html)
   
### Cleanup

To clean up the Elasticsearch and Kibana install:

1. Run the following command to delete logstash:

   ```bash
   $ kubectl delete -f $WORKDIR/kubernetes/elasticsearch-and-kibana/logstash.yaml
   ```

   The output will look similar to the following:

   ```
   deployment.apps "logstash-wls" deleted
   ```

1. Run the following command to delete Elasticsearch and Kibana:

   ```bash
   $ kubectl delete -f $WORKDIR/kubernetes/elasticsearch-and-kibana/elasticsearch_and_kibana.yaml
   ```

   The output will look similar to the following:

   ```
   deployment.apps "elasticsearch" deleted
   service "elasticsearch" deleted
   deployment.apps "kibana" deleted
   service "kibana" deleted
   ```
   
   
   