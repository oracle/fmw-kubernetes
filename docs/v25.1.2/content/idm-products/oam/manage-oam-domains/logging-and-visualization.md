---
title: "c. Logging and Visualization"
description: "Describes the steps for logging and visualization with Elasticsearch and Kibana."
---

After the OAM domain is set up you can publish operator and WebLogic Server logs into Elasticsearch and interact with them in Kibana.

### Install Elasticsearch stack and Kibana

If you do not already have a centralized Elasticsearch (ELK) stack then you must configure this first. For details on how to configure the ELK stack, follow
[Installing Elasticsearch (ELK) Stack and Kibana](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html)


### Create the logstash pod

#### Variables used in this chapter

In order to create the logstash pod, you must create several files. These files contain variables which you must substitute with variables applicable to your environment.

Most of the values for the variables will be based on your ELK deployment as per [Installing Elasticsearch (ELK) Stack and Kibana](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html).

The table below outlines the variables and values you must set:



| Variable | Sample Value | Description |
| --- | --- | --- |
| `<ELK_VER>` | `8.3.1` | The version of logstash you want to install.|
| `<ELK_SSL>` | `true` | If SSL is enabled for ELK set the value to `true`, or if NON-SSL set to `false`. This value must be lowercase.|
| `<ELK_HOSTS>` | `https://elasticsearch.example.com:9200` | The URL for sending logs to Elasticsearch. HTTP if NON-SSL is used.|
| `<ELKNS>` | `oamns` | The domain namespace.|
| `<ELK_USER>` | `logstash_internal` | The name of the user for logstash to access Elasticsearch.|
| `<ELK_PASSWORD>` |  `password` | The password for ELK_USER.|
| `<ELK_APIKEY>` | `apikey` | The API key details.|

You will also need the BASE64 version of the Certificate Authority (CA) certificate(s) that signed the certificate of the Elasticsearch server. If using a self-signed certificate, this is the self signed certificate of the Elasticsearch server. See [Copying the Elasticsearch Certificate](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html#GUID-C1FC1063-FA76-48AD-AE3D-A39390874C74) for details on how to get the correct certificate. In the example below the certificate is called `elk.crt`.
   

#### Create Kubernetes secrets

1. Create a Kubernetes secret for Elasticsearch using the API Key or Password.

   a) If ELK uses an API Key for authentication:

   ```
   $ kubectl create secret generic elasticsearch-pw-elastic -n <domain_namespace> --from-literal password=<ELK_APIKEY>
   ```

   For example:
   
   ```
   $ kubectl create secret generic elasticsearch-pw-elastic -n oamns --from-literal password=<ELK_APIKEY>
   ```
   
   The output will look similar to the following:
   
   ```
   secret/elasticsearch-pw-elastic created
   ```


   b) If ELK uses a password for authentication:

   ```
   $ kubectl create secret generic elasticsearch-pw-elastic -n <domain_namespace> --from-literal password=<ELK_PASSWORD>
   ```

   For example:
   
   ```
   $ kubectl create secret generic elasticsearch-pw-elastic -n oamns --from-literal password=<ELK_PASSWORD>
   ```
   
   The output will look similar to the following:
   
   ```
   secret/elasticsearch-pw-elastic created
   ```
   
     
   **Note**: It is recommended that the ELK Stack is created with authentication enabled. If no authentication is enabled you may create a secret using the values above.
   
   
1. Create a Kubernetes secret to access the required images on [hub.docker.com](https://hub.docker.com):

   **Note**: Before executing the command below, you must first have a user account on [hub.docker.com](https://hub.docker.com).

   ```bash
   kubectl create secret docker-registry "dockercred" --docker-server="https://index.docker.io/v1/" \
   --docker-username="<DOCKER_USER_NAME>" \
   --docker-password=<DOCKER_PASSWORD> --docker-email=<DOCKER_EMAIL_ID> \
   --namespace=<domain_namespace>
   ```
   
   For example,
   
   ```bash
   kubectl create secret docker-registry "dockercred" --docker-server="https://index.docker.io/v1/" \
   --docker-username="user@example.com" \
   --docker-password=password --docker-email=user@example.com \
   --namespace=oamns
   ```

   The output will look similar to the following:
   
   ```bash
   secret/dockercred created
   ```
   
#### Find the mountPath details

  
1. Run the following command to get the `mountPath` of your domain:
   
   ```bash
   $ kubectl describe domains <domain_uid> -n <domain_namespace> | grep "Mount Path"
   ```
   
   For example:
   
   ```bash
   $ kubectl describe domains accessdomain -n oamns | grep "Mount Path"
   ```
   
   If you deployed OAM using WLST, the output will look similar to the following:
   
   ```
   Mount Path:  /u01/oracle/user_projects/domains
   ```
   
   If you deployed OAM using WDT, the output will look similar to the following:
   
   ```
   Mount Path:  /u01/oracle/user_projects
   ```

#### Find the Domain Home and Log Home details

1. Run the following command to get the `Domain Home` and `Log Home` of your domain:

   ```bash
	$ kubectl describe domains <domain_uid> -n <domain_namespace> | egrep "Domain Home: | Log Home:"
	```
	
	For example:
	
	```bash
	$ kubectl describe domains accessdomain -n oamns  | egrep "Domain Home: | Log Home:"
	```
	
	The output will look similar to the following:
	
	```
	Domain Home:                     /u01/oracle/user_projects/domains/accessdomain
   Http Access Log In Log Home:     true
   Log Home:                           /u01/oracle/user_projects/domains/logs/accessdomain
   ```
	
	
   
#### Find the persistentVolumeClaim details

1. Run the following command to get the OAM domain persistence volume details:

   ```
   $ kubectl get pv -n <domain_namespace>
   ```

   For example:

   ```
   $ kubectl get pv -n oamns
   ```
   
   The output will look similar to the following:

   ```
   NAME                     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS  CLAIM                           STORAGECLASS                         REASON   AGE
   accessdomain-domain-pv   10Gi       RWX            Retain           Bound   oamns/accessdomain-domain-pvc   accessdomain-domain-storage-class           23h
   ```
   
   Make note of the CLAIM value, for example in this case `accessdomain-domain-pvc`.
  
#### Create the Configmap

1. Copy the `elk.crt` file to the `$WORKDIR/kubernetes/elasticsearch-and-kibana` directory.

1. Navigate to the `$WORKDIR/kubernetes/elasticsearch-and-kibana` directory and run the following:

   ```
   kubectl create configmap elk-cert --from-file=elk.crt -n <namespace>
   ```
   
   For example:
   
   ```
   kubectl create configmap elk-cert --from-file=elk.crt -n oamns
   ```
   
   The output will look similar to the following:
   
   ```
   configmap/elk-cert created
   ```
   
   

1. Create a `logstash_cm.yaml` file in the `$WORKDIR/kubernetes/elasticsearch-and-kibana` directory as follows:

   ```
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: oam-logstash-configmap
     namespace: <ELKNS>
   data:
     logstash.yml: |
     #http.host: "0.0.0.0"
     logstash-config.conf: |
       input {
        file {
           path => "<Log Home>/**/logs/AdminServer*.log"
           tags => "Adminserver_log"
           start_position => beginning
         }
         file {
           path => "<Log Home>/**/logs/oam_policy_mgr*.log"
           tags => "Policymanager_log"
           start_position => beginning
         }
         file {
           path => "<Log Home>/**/logs/oam_server*.log"
           tags => "Oamserver_log"
           start_position => beginning
         }
         file {
           path => "<Domain Home>/servers/AdminServer/logs/AdminServer-diagnostic.log"
           tags => "Adminserver_diagnostic"
           start_position => beginning
         }
         file {
           path => "<Domain Home>/servers/**/logs/oam_policy_mgr*-diagnostic.log"
           tags => "Policy_diagnostic"
           start_position => beginning
         }
         file {
         path => "<Domain Home>/servers/AdminServer/logs/auditlogs/OAM/audit.log"
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
       hosts => ["<ELK_HOSTS>"]
       cacert => '/usr/share/logstash/config/certs/elk.crt'
       index => "oamlogs-000001"
       ssl => true
       ssl_certificate_verification => false
       user => "<ELK_USER>"
       password => "${ELASTICSEARCH_PASSWORD}"
	   api_key => "${ELASTICSEARCH_PASSWORD}"
         }
       }
   ```
   
   Change the values in the above file as follows:
   
   + Change the `<ELKNS>`, `<ELK_HOSTS>`, `<ELK_SSL>`, and `<ELK_USER>` to match the values for your environment.
	+ Change `<Log Home>` and `<Domain Home>` to match the Log Home and Domain Home returned earlier.
   + If your domainUID is anything other than `accessdomain`, change each instance of `accessdomain` to your domainUID.
   + If using API KEY for your ELK authentication, delete the `user` and `password` lines.
   + If using a password for ELK authentication, delete the `api_key` line.
   + If no authentication is used for ELK, delete the `user`, `password`, and `api_key` lines.
   
   For example:
   
   ```
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: oam-logstash-configmap
     namespace: oamns
   data:
     logstash.yml: |
     #http.host: "0.0.0.0"
     logstash-config.conf: |
       input {
        file {
           path => "/u01/oracle/user_projects/domains/logs/accessdomain/**/logs/AdminServer*.log"
           tags => "Adminserver_log"
           start_position => beginning
         }
         file {
           path => "/u01/oracle/user_projects/domains/logs/accessdomain/**/logs/oam_policy_mgr*.log"
           tags => "Policymanager_log"
           start_position => beginning
         }
         file {
           path => "/u01/oracle/user_projects/domains/logs/accessdomain/**/logs/oam_server*.log"
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
       hosts => ["https://elasticsearch.example.com:9200"]
       cacert => '/usr/share/logstash/config/certs/elk.crt'
       index => "oamlogs-000001"
       ssl => true
       ssl_certificate_verification => false
       user => "logstash_internal"
       password => "${ELASTICSEARCH_PASSWORD}"
         }
       }
   ```
   
   
   
1. Run the following command to create the configmap:

   ```
   $  kubectl apply -f logstash_cm.yaml
   ```
   
   The output will look similar to the following:
   
   ```
   configmap/oam-logstash-configmap created
   ```
   
#### Deploy the logstash pod

1. Navigate to the `$WORKDIR/kubernetes/elasticsearch-and-kibana` directory and create a `logstash.yaml` file as follows:

   ```
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: oam-logstash
     namespace: <ELKNS>
   spec:
     selector:
       matchLabels:
         k8s-app: logstash
     template: # create pods using pod definition in this template
       metadata:
        labels:
           k8s-app: logstash
       spec:
         imagePullSecrets:
         - name: dockercred
         containers:
         - command:
           - logstash
           image: logstash:<ELK_VER>
           imagePullPolicy: IfNotPresent
           name: oam-logstash
           env:
           - name: ELASTICSEARCH_PASSWORD
             valueFrom:
               secretKeyRef:
                 name: elasticsearch-pw-elastic
                 key: password
           resources:
           ports:
           - containerPort: 5044
             name: logstash
           volumeMounts:
           - mountPath: <mountPath>
             name: weblogic-domain-storage-volume
           - name: shared-logs
             mountPath: /shared-logs
           - mountPath: /usr/share/logstash/pipeline/
             name: oam-logstash-pipeline
           - mountPath: /usr/share/logstash/config/logstash.yml
             subPath: logstash.yml
             name: config-volume
           - mountPath: /usr/share/logstash/config/certs
             name: elk-cert
         volumes:
         - configMap:
             defaultMode: 420
             items:
             - key: elk.crt
               path: elk.crt
             name: elk-cert
           name: elk-cert
         - configMap:
             defaultMode: 420
             items:
             - key: logstash-config.conf
               path: logstash-config.conf
             name: oam-logstash-configmap
           name: oam-logstash-pipeline
         - configMap:
             defaultMode: 420
             items:
             - key: logstash.yml
               path: logstash.yml
             name: oam-logstash-configmap
           name: config-volume
         - name: weblogic-domain-storage-volume
           persistentVolumeClaim:
             claimName: accessdomain-domain-pvc
         - name: shared-logs
           emptyDir: {}
   ```
   
   + Change the `<ELKNS>`, `<ELK_VER>` to match the values for your environment
   + Change `<mountPath>` to match the `mountPath` returned earlier
   + Change the `claimName` value to match the `claimName` returned earlier
   + If your Kubernetes environment does not allow access to the internet to pull the logstash image, you must load the logstash image in your own container registry and change `image: logstash:<ELK_VER>` to the location of the image in your container registry e.g: `container-registry.example.com/logstash:8.3.1`
   
   
   For example:
   
   ```
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: oam-logstash
     namespace: oamns
   spec:
     selector:
       matchLabels:
         k8s-app: logstash
     template: # create pods using pod definition in this template
       metadata:
        labels:
           k8s-app: logstash
       spec:
         imagePullSecrets:
         - name: dockercred
         containers:
         - command:
           - logstash
           image: logstash:8.3.1
           imagePullPolicy: IfNotPresent
           name: oam-logstash
           env:
           - name: ELASTICSEARCH_PASSWORD
             valueFrom:
               secretKeyRef:
                 name: elasticsearch-pw-elastic
                 key: password
           resources:
           ports:
           - containerPort: 5044
             name: logstash
           volumeMounts:
           - mountPath: /u01/oracle/user_projects 
             name: weblogic-domain-storage-volume
           - name: shared-logs
             mountPath: /shared-logs
           - mountPath: /usr/share/logstash/pipeline/
             name: oam-logstash-pipeline
           - mountPath: /usr/share/logstash/config/logstash.yml
             subPath: logstash.yml
             name: config-volume
           - mountPath: /usr/share/logstash/config/certs
             name: elk-cert
         volumes:
         - configMap:
             defaultMode: 420
             items:
             - key: elk.crt
               path: elk.crt
             name: elk-cert
           name: elk-cert
         - configMap:
             defaultMode: 420
             items:
             - key: logstash-config.conf
               path: logstash-config.conf
             name: oam-logstash-configmap
           name: oam-logstash-pipeline
         - configMap:
             defaultMode: 420
             items:
             - key: logstash.yml
               path: logstash.yml
             name: oam-logstash-configmap
           name: config-volume
         - name: weblogic-domain-storage-volume
           persistentVolumeClaim:
             claimName: accessdomain-domain-pvc
         - name: shared-logs
           emptyDir: {}
   ```   

1. Deploy the `logstash` pod by executing the following command:
   
   ```bash
   $ kubectl create -f $WORKDIR/kubernetes/elasticsearch-and-kibana/logstash.yaml 
   ```
   
   The output will look similar to the following:
   
   ```
   deployment.apps/oam-logstash created
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
   accessdomain-oam-policy-mgr1                             1/1     Running     0          18h
   accessdomain-oam-server1                                 1/1     Running     1          18h
   nginx-ingress-ingress-nginx-controller-76fb7678f-k8rhq   1/1     Running     0          20h
   oam-logstash-bbbdf5876-85nkd                             1/1     Running     0          4m23s
   ```
   
   **Note**: Wait a couple of minutes to make sure the pod has not had any failures or restarts. If the pod fails you can view the pod log using:
   
   ```
   $ kubectl logs -f oam-logstash-<pod> -n oamns
   ```
   
   Most errors occur due to misconfiguration of the `logstash_cm.yaml` or `logstash.yaml`. This is usually because of an incorrect value set, or the certificate was not pasted with the correct indentation.
   
   If the pod has errors, delete the pod and configmap as follows:
   
   ```
   $ kubectl delete -f $WORKDIR/kubernetes/elasticsearch-and-kibana/logstash.yaml
   $ kubectl delete -f $WORKDIR/kubernetes/elasticsearch-and-kibana/logstash_cm.yaml
   ```
   
   Once you have resolved the issue in the yaml files, run the commands outlined earlier to recreate the configmap and logstash pod.
   
   
   
   
   

### Verify and access the Kibana console

To access the Kibana console you will need the Kibana URL as per [Installing Elasticsearch (ELK) Stack and Kibana](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html#GUID-C0013AA8-B229-4237-A1D8-8F38FA6E2CEC).


**For Kibana 7.7.x and below**:

1. Access the Kibana console with `http://<hostname>:<port>/app/kibana` and login with your username and password.

1. From the Navigation menu, navigate to **Management** > **Kibana** > **Index Patterns**.

1. In the **Create Index Pattern** page enter `oamlogs*` for the **Index pattern** and click **Next Step**.

1. In the **Configure settings** page, from the **Time Filter field name** drop down menu select `@timestamp` and click **Create index pattern**.

1. Once the index pattern is created click on **Discover** in the navigation menu to view the OAM logs.


**For  Kibana version 7.8.X and above**:

1. Access the Kibana console with `http://<hostname>:<port>/app/kibana` and login with your username and password.

1. From the Navigation menu, navigate to **Management** > **Stack Management**.

1. Click **Data Views** in the **Kibana** section.

1. Click **Create Data View** and enter the following information:

   + Name: `oamlogs*`
   + Timestamp: `@timestamp`
   
1. Click **Create Data View**.

1. From the Navigation menu, click **Discover** to view the log file entries.

1. From the drop down menu, select `oamlogs*` to view the log file entries.