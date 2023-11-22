---
title: "b) Logging and Visualization for Helm Chart oudsm Deployment"
description: "Describes the steps for logging and visualization with Elasticsearch and Kibana."
---

### Introduction

This section describes how to install and configure logging and visualization for the [oudsm](../../create-oudsm-instances) Helm chart deployment.

The ELK stack consists of Elasticsearch, Logstash, and Kibana. Using ELK you can gain insights in real-time from the log data from your applications.

* Elasticsearch is a distributed, RESTful search and analytics engine capable of solving a growing number of use cases. As the heart of the Elastic Stack, it centrally stores your data so you can discover the expected and uncover the unexpected.
* Logstash is an open source, server-side data processing pipeline that ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite “stash.”
* Kibana lets you visualize your Elasticsearch data and navigate the Elastic Stack. It gives you the freedom to select the way you give shape to your data. And you don’t always have to know what you're looking for.

### Install Elasticsearch and Kibana

If you do not already have a centralized Elasticsearch (ELK) stack then you must configure this first. For details on how to configure the ELK stack, follow
[Installing Elasticsearch (ELK) Stack and Kibana](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html)


### Create the logstash pod

#### Variables used in this chapter

In order to create the logstash pod, you must create a yaml file. This file contains variables which you must substitute with variables applicable to your ELK environment. 

Most of the values for the variables will be based on your ELK deployment as per [Installing Elasticsearch (ELK) Stack and Kibana](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html).

The table below outlines the variables and values you must set:

| Variable | Sample Value | Description |
| --- | --- | --- |
| `<ELK_VER>` | `8.3.1` | The version of logstash you want to install.|
| `<ELK_SSL>` | `true` | If SSL is enabled for ELK set the value to `true`, or if NON-SSL set to `false`. This value must be lowercase.|
| `<ELK_HOSTS>` | `https://elasticsearch.example.com:9200` | The URL for sending logs to Elasticsearch. HTTP if NON-SSL is used.|
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
   $ kubectl create secret generic elasticsearch-pw-elastic -n oudsmns --from-literal password=<ELK_APIKEY>
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
   $ kubectl create secret generic elasticsearch-pw-elastic -n oudsmns --from-literal password=<ELK_PASSWORD>
   ```
   
   The output will look similar to the following:
   
   ```
   secret/elasticsearch-pw-elastic created
   ```

     
   **Note**: It is recommended that the ELK Stack is created with authentication enabled. If no authentication is enabled you may create a secret using the values above.
   
   
1. Create a Kubernetes secret to access the required images on [hub.docker.com](https://hub.docker.com): 

   **Note:** You must first have a user account on [hub.docker.com](https://hub.docker.com):

   ```bash
   $ kubectl create secret docker-registry "dockercred" --docker-server="https://index.docker.io/v1/" --docker-username="<docker_username>" --docker-password=<password> --docker-email=<docker_email_credentials> --namespace=<domain_namespace>
   ```   
   
   For example:
   
   ```
   $ kubectl create secret docker-registry "dockercred" --docker-server="https://index.docker.io/v1/" --docker-username="username" --docker-password=<password> --docker-email=user@example.com --namespace=oudsmns
   ```
   
   The output will look similar to the following:
   
   ```bash
   secret/dockercred created
   ```  



#### Enable logstash

1. Navigate to the `$WORKDIR/kubernetes/helm` directory and create a `logging-override-values.yaml` file as follows:
   
   ```
   elk:
     imagePullSecrets:
       - name: dockercred
     IntegrationEnabled: true
     logStashImage: logstash:<ELK_VER>
     logstashConfigMap: false
     esindex: oudsmlogs-00001
     sslenabled: <ELK_SSL>
     eshosts: <ELK_HOSTS>
     # Note: We need to provide either esuser,espassword or esapikey
     esuser: <ELK_USER>
     espassword: elasticsearch-pw-elastic
     esapikey: elasticsearch-pw-elastic
   ```
   
   + Change the `<ELK_VER>`, `<ELK_SSL>`, `<ELK_HOSTS>`, and `<ELK_USER>`, to match the values for your environment.
   + If using SSL, replace the `elk.crt` in `$WORKDIR/kubernetes/helm/oudsm/certs/` with the `elk.crt` for your ElasticSearch server.
   + If using API KEY for your ELK authentication, leave both `esuser:` and `espassword:` with no value.
   + If using a password for ELK authentication, leave `esapi_key:` but delete `elasticsearch-pw-elastic`.
   + If no authentication is used for ELK, leave `esuser`, `espassword`, and `esapi_key` with no value assigned.
   + The rest of the lines in the yaml file should not be changed.
   
   For example:
   
   ```
   elk:
     imagePullSecrets:
       - name: dockercred
     IntegrationEnabled: true
     logStashImage: logstash:8.3.1
     logstashConfigMap: false
     esindex: oudsmlogs-00001
     sslenabled: true   
     eshosts: https://elasticsearch.example.com:9200
     # Note: We need to provide either esuser,espassword or esapikey
     esuser: logstash_internal
     espassword: elasticsearch-pw-elastic
     esapikey:
   ```
   
   
   
#### Upgrade oudsm deployment with ELK configuration

1. Run the following command to upgrade the oudsm deployment with the ELK configuration:

   ```
   $ helm upgrade --namespace <namespace> --values <valuesfile.yaml> <releasename> oudsm --reuse-values
   ```
   
   For example:

   ```
   $ helm upgrade --namespace oudsmns --values logging-override-values.yaml oudsm oudsm --reuse-values
   ```
   
   The output should look similar to the following:
   
   ```
   Release "oudsm" has been upgraded. Happy Helming!
   NAME: oudsm
   LAST DEPLOYED: <DATE>
   NAMESPACE: oudsmns
   STATUS: deployed
   REVISION: 2
   TEST SUITE: None
   ```
 
#### Verify the pods
   
1. Run the following command to check the `logstash` pod is created correctly:
   
   ```bash
   $ kubectl get pods -n <namespace>
   ```
  
   For example:
   
   ```bash
   $ kubectl get pods -n oudsmns
   ```
   
   The output should look similar to the following:
   
   ```
   NAME                              READY   STATUS    RESTARTS   AGE
   oudsm-1                           1/1     Running   0          51m
   oudsm-logstash-56dbcc6d9f-mxsgj   1/1     Running   0          2m7s
   ```
   
   **Note**: Wait a couple of minutes to make sure the pod has not had any failures or restarts. If the pod fails you can view the pod log using:
   
   ```
   $ kubectl logs -f oudsm-logstash-<pod> -n oudsmns
   ```
    
   Most errors occur due to misconfiguration of the `logging-override-values.yaml`. This is usually because of an incorrect value set, or the certificate was not pasted with the correct indentation.	
	
   If the pod has errors, view the helm history to find the last working revision, for example:
   
   ```
   $ helm history oudsm -n oudsmns
   ```
   
   The output will look similar to the following:
   
   ```
   REVISION        UPDATED       STATUS          CHART           APP VERSION     DESCRIPTION
   1               <DATE>        superseded      oudsm-0.1       12.2.1.4.0      Install complete
   2               <DATE>        deployed        oudsm-0.1       12.2.1.4.0      Upgrade complete
   ```
   
   Rollback to the previous working revision by running:
   
   ```
   $ helm rollback <release> <revision> -n <domain_namespace>
   ```
   
   For example:
   
   ```
   helm rollback oudsm 1 -n oudsmns
   ```
   
   Once you have resolved the issue in the yaml files, run the `helm upgrade` command outlined earlier to recreate the logstash pod.
   

### Verify and access the Kibana console

To access the Kibana console you will need the Kibana URL as per [Installing Elasticsearch (ELK) Stack and Kibana](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html#GUID-C0013AA8-B229-4237-A1D8-8F38FA6E2CEC).


**For Kibana 7.7.x and below**:

1. Access the Kibana console with `http://<hostname>:<port>/app/kibana` and login with your username and password.

1. From the Navigation menu, navigate to **Management** > **Kibana** > **Index Patterns**.

1. In the **Create Index Pattern** page enter `oudsmlogs*` for the **Index pattern** and click **Next Step**.

1. In the **Configure settings** page, from the **Time Filter field name** drop down menu select `@timestamp` and click **Create index pattern**.

1. Once the index pattern is created click on **Discover** in the navigation menu to view the OUDSM logs.


**For  Kibana version 7.8.X and above**:

1. Access the Kibana console with `http://<hostname>:<port>/app/kibana` and login with your username and password.

1. From the Navigation menu, navigate to **Management** > **Stack Management**.

1. Click **Data Views** in the **Kibana** section.

1. Click **Create Data View** and enter the following information:

   + Name: `oudsmlogs*`
   + Timestamp: `@timestamp`
   
1. Click **Create Data View**.

1. From the Navigation menu, click **Discover** to view the log file entries.

1. From the drop down menu, select `oudsmlogs*` to view the log file entries.
