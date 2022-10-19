---
title: "b) Logging and Visualization for Helm Chart oud-ds-rs Deployment"
description: "Describes the steps for logging and visualization with Elasticsearch and Kibana."
---

1. [Introduction](#introduction)
1. [Install Elasticsearch and Kibana](#install-elasticsearch-and-kibana)
1. [Create a Kubernetes secret](#create-a-kubernetes-secret)
1. [Enable Logstash](#enable-logstash)
	1. [Upgrade OUD deployment with ELK configuration](#upgrade-oud-deployment-with-elk-configuration)
	1. [Verify the pods](#verify-the-pods)
1. [Verify and access the Kibana console](#verify-and-access-the-kibana-console)

### Introduction

This section describes how to install and configure logging and visualization for the [oud-ds-rs](../../create-oud-instances) Helm chart deployment.

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
| `<ELK_CERT>` | `MIIDVjCCAj6gAwIBAgIRAOqQ3Gy75..etc...P9ovZ/EKPpE6Gq`  | If `ELK_SSL=true`, this is the BASE64 version of the certificate. This is the Certificate Authority (CA) certificate(s), that signed the certificate of the Elasticsearch server. If using a self-signed certificate, this is the self signed certificate of the Elasticserver server. See [Copying the Elasticsearch Certificate](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html#GUID-C1FC1063-FA76-48AD-AE3D-A39390874C74) for details on how to get the correct certificate.|
| `<ELK_HOSTS>` | `https://elasticsearch.example.com:9200` | The URL for sending logs to Elasticsearch. HTTP if NON-SSL is used.|
| `<ELK_USER>` | `logstash_internal` | The name of the user for logstash to access Elasticsearch.|
| `<ELK_PASSWORD>` |  `password` | The password for ELK_USER.|
| `<ELK_APIKEY>` | `apikey` | The API key details.|



#### Create a kubernetes secret

1. Create a Kubernetes secret for Elasticsearch using the API Key or Password.

   a) If ELK uses an API Key for authentication:

   ```
   $ kubectl create secret generic elasticsearch-pw-elastic -n <domain_namespace> --from-literal password=<ELK_APIKEY>
   ```

   For example:
   
   ```
   $ kubectl create secret generic elasticsearch-pw-elastic -n oudns --from-literal password=<ELK_APIKEY>
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
   $ kubectl create secret generic elasticsearch-pw-elastic -n oudns --from-literal password=<ELK_PASSWORD>
   ```
   
   The output will look similar to the following:
   
   ```
   secret/elasticsearch-pw-elastic created
   ```

     
   **Note**: It is recommended that the ELK Stack is created with authentication enabled. If no authentication is enabled you may create a secret using the values above.
   
   
1. Check that the `dockercred` secret that was created previously in [Create a Kubernetes secret for cronjob images](../../create-oud-instances/#create-a-kubernetes-secret-for-cronjob-images) exists:

   ```bash
   $ kubectl get secret -n <domain_namespace> | grep dockercred
   ```
   
   For example,
   
   ```bash
   $ kubectl get secret -n oudns | grep dockercred
   ```

   The output will look similar to the following:
   
   ```bash
   dockercred                        kubernetes.io/dockerconfigjson        1      149m
   ```
   
   If the secret does not exist, create it as per [Create a Kubernetes secret for cronjob images](../../create-oud-instances/#create-a-kubernetes-secret-for-cronjob-images).


#### Enable logstash

1. Navigate to the `$WORKDIR/kubernetes/helm` directory and create a `logging-override-values.yaml` file as follows:
   
   ```
   elk:
     imagePullSecrets:
       - name: dockercred
     IntegrationEnabled: true
     logStashImage: logstash:<ELK_VER>
     logstashConfigMap: false
     esindex: oudlogs-00001
     sslenabled: <ELK_SSL>
     eshosts: <ELK_HOSTS>
     # Note: We need to provide either esuser,espassword or esapikey
     esuser: <ELK_USER>
     espassword: elasticsearch-pw-elastic
     esapikey: elasticsearch-pw-elastic
     escert: |
       -----BEGIN CERTIFICATE-----
       <ELK_CERT>
       -----END CERTIFICATE-----
   ```
   
   + Change the `<ELK_VER>`, `<ELK_SSL>`, `<ELK_HOSTS>`, `<ELK_USER>`, and `<ELK_CERT>` to match the values for your environment.
   + If using SSL, make sure the value for <ELK_CERT> is indented correctly. You can use the command: `sed 's/^/   /' elk.crt` to output the certificate with the correct indentation.
   + If not using SSL, delete the `<ELK_CERT>` line, but leave the `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`.
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
     esindex: oudlogs-00001
     sslenabled: true   
     eshosts: https://elasticsearch.example.com:9200
     # Note: We need to provide either esuser,espassword or esapikey
     esuser: logstash_internal
     espassword: elasticsearch-pw-elastic
     esapikey:
     escert: |
       -----BEGIN CERTIFICATE-----
       MIIDVjCCAj6gAwIBAgIRAOqQ3Gy75NvPPQUN5kXqNQUwDQYJKoZIhvcNAQELBQAw
       NTEWMBQGA1UECxMNZWxhc3RpY3NlYXJjaDEbMBkGA1UEAxMSZWxhc3RpY3NlYXJj
       aC1odHRwMB4XDTIyMDgyNDA1MTU1OVoXDTIzMDgyNDA1MjU1OVowNTEWMBQGA1UE
       CxMNZWxhc3RpY3NlYXJjaDEbMBkGA1UEAxMSZWxhc3RpY3NlYXJjaC1odHRwMIIB
       IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsQOnxUm9uF32+lyc9SA3WcMZ
       P1X7TbHMDuO/l3UHBUf5F/bt2m3YkGw+enIos9wzuUNpjIwVt8q4WrRCMl80nAQ0
       yCXrfLSI9zaHxEC8Ht7V0U+7Sgu5uysD4tyZ9T0Q5zjvkWS6oBPxhfri3OQfPvUW
       gQ6wJaPGDteYZAwiBMvPEkmh0VUTBTXjToHrtrT7pzmz5BBWnUzdf+jv0+nEfedm
       mMWw/8jqyqid7bu7bo6gKBZ8zk06n2iMaXzmGW34QlYRLXCgbThhxyDE7joZ4NTA
       UFEJecZR2fccmpN8CNkT9Ex4Hq88nh2OP5XKKPNF4kLh2u6F4auF7Uz42jwvIwID
       AQABo2EwXzAOBgNVHQ8BAf8EBAMCAoQwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsG
       AQUFBwMCMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFLQb/IjHHkSmHgKSPY7r
       zBIJZMbdMA0GCSqGSIb3DQEBCwUAA4IBAQA01qY0tGIPsKNkn7blxRjEYkTg59Z5
       vi6MCpGtdoyZeJgH621IpwyB34Hpu1RQfyg1aNgmOtIK9cvQZRl008DHF4AiHYhU
       6xe3cjI/QxDXwitoBgWl+a0mkwhSmzJt7TuzImq7RMO4ws3M/nGeNUwFjwsQu86+
       N/Y3RuuUVbK1xy8Jdz3FZADIgHVPN6GQwYKEpWrZNapKBXjunjCZmpBFxqGMRF44
       fcSKFlFkwjyTq4kgq44NPv18NMfKCYZcK7ttRTiep77vKB7No/TM69Oz5ZHhQ+2Q
       pSGg3QF+1fOCFCgWXFEOle6lQ5i8a/GihY0FuphrZxP9ovZ/EKPpE6Gq
       -----END CERTIFICATE-----
   ```
   
   
   
#### Upgrade OUD deployment with ELK configuration

1. Run the following command to upgrade the OUD deployment with the ELK configuration:

   ```
   $ helm upgrade --namespace <namespace> --values <valuesfile.yaml> <releasename> oud-ds-rs --reuse-values
   ```
   
   For example:

   ```
   $ helm upgrade --namespace oudns --values logging-override-values.yaml oud-ds-rs oud-ds-rs --reuse-values
   ```
   
   The output should look similar to the following:
   
   ```
   Release "oud-ds-rs" has been upgraded. Happy Helming!
   NAME: oud-ds-rs
   LAST DEPLOYED: <DATE>
   NAMESPACE: oudns
   STATUS: deployed
   REVISION: 2
   NOTES:
   #
   # Copyright (c) 2020, 2022, Oracle and/or its affiliates.
   #
   # Licensed under the Universal Permissive License v 1.0 as shown at
   # https://oss.oracle.com/licenses/upl
   #
   #
   Since "nginx" has been chosen, follow the steps below to configure nginx ingress controller.
   Add Repo reference to helm for retriving/installing Chart for nginx-ingress implementation.
   command-# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

   Command helm install to install nginx-ingress related objects like pod, service, deployment, etc.
   # helm install --namespace <namespace for ingress> --values nginx-ingress-values-override.yaml lbr-nginx ingress-nginx/ingress-nginx

   For details of content of nginx-ingress-values-override.yaml refer README.md file of this chart.

   Run these commands to check port mapping and services:
   # kubectl --namespace <namespace for ingress> get services -o wide -w lbr-nginx-ingress-controller
   # kubectl describe --namespace <namespace for oud-ds-rs chart> ingress.extensions/oud-ds-rs-http-ingress-nginx
   # kubectl describe --namespace <namespace for oud-ds-rs chart> ingress.extensions/oud-ds-rs-admin-ingress-nginx

   Accessible interfaces through ingress:
    (External IP Address for LoadBalancer NGINX Controller can be determined through details associated with lbr-nginx-ingress-controller)

   1. OUD Admin REST:
      Port: http/https

   2. OUD Data REST:
      Port: http/https

   3. OUD Data SCIM:
      Port: http/https

   4. OUD LDAP/LDAPS:
      Port: ldap/ldaps

   5. OUD Admin LDAPS:
      Port: ldaps

   Please refer to README.md from Helm Chart to find more details about accessing interfaces and configuration parameters.


   Accessible interfaces through ingress:

   1. OUD Admin REST:
      Port: http/https

   2. OUD Data REST:
      Port: http/https

   3. OUD Data SCIM:
      Port: http/https

   Please refer to README.md from Helm Chart to find more details about accessing interfaces and configuration parameters.
   ```
 
#### Verify the pods
   
1. Run the following command to check the `logstash` pod is created correctly:
   
   ```bash
   $ kubectl get pods -n <namespace>
   ```
  
   For example:
   
   ```bash
   $ kubectl get pods -n oudns
   ```
   
   The output should look similar to the following:
   
   ```
   NAME                                  READY   STATUS      RESTARTS   AGE
   oud-ds-rs-0                           1/1     Running     0          150m
   oud-ds-rs-1                           1/1     Running     0          143m
   oud-ds-rs-2                           1/1     Running     0          137m
   oud-ds-rs-logstash-5dc8d94597-knk8g   1/1     Running     0          2m12s
   oud-pod-cron-job-27758370-wpfq7       0/1     Completed   0          66m
   oud-pod-cron-job-27758400-kd6pn       0/1     Completed   0          36m
   oud-pod-cron-job-27758430-ndmgj       0/1     Completed   0          6m33s
   ```
   
   **Note**: Wait a couple of minutes to make sure the pod has not had any failures or restarts. If the pod fails you can view the pod log using:
   
   ```
   $ kubectl logs -f oud-ds-rs-logstash-<pod> -n oudns
   ```
    
   Most errors occur due to misconfiguration of the `logging-override-values.yaml`. This is usually because of an incorrect value set, or the certificate was not pasted with the correct indentation.	
	
   If the pod has errors, view the helm history to find the last working revision, for example:
   
   ```
   $ helm history oud-ds-rs -n oudns
   ```
   
   The output will look similar to the following:
   
   ```
   REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
   1               Tue Oct 11 14:06:01 2022        superseded      oud-ds-rs-0.2   12.2.1.4.0      Install complete
   2               Tue Oct 11 16:34:21 2022        deployed        oud-ds-rs-0.2   12.2.1.4.0      Upgrade complete
   ```
   
   Rollback to the previous working revision by running:
   
   ```
   $ helm rollback <release> <revision> -n <domain_namespace>
   ```
   
   For example:
   
   ```
   helm rollback oud-ds-rs 1 -n oudns
   ```
   
   Once you have resolved the issue in the yaml files, run the `helm upgrade` command outlined earlier to recreate the logstash pod.
   

### Verify and access the Kibana console

To access the Kibana console you will need the Kibana URL as per [Installing Elasticsearch (ELK) Stack and Kibana](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/installing-monitoring-and-visualization-software.html#GUID-C0013AA8-B229-4237-A1D8-8F38FA6E2CEC).


**For Kibana 7.7.x and below**:

1. Access the Kibana console with `http://<hostname>:<port>/app/kibana` and login with your username and password.

1. From the Navigation menu, navigate to **Management** > **Kibana** > **Index Patterns**.

1. In the **Create Index Pattern** page enter `oudlogs*` for the **Index pattern** and click **Next Step**.

1. In the **Configure settings** page, from the **Time Filter field name** drop down menu select `@timestamp` and click **Create index pattern**.

1. Once the index pattern is created click on **Discover** in the navigation menu to view the OIG logs.


**For  Kibana version 7.8.X and above**:

1. Access the Kibana console with `http://<hostname>:<port>/app/kibana` and login with your username and password.

1. From the Navigation menu, navigate to **Management** > **Stack Management**.

1. Click **Data Views** in the **Kibana** section.

1. Click **Create Data View** and enter the following information:

   + Name: `oudlogs*`
   + Timestamp: `@timestamp`
   
1. Click **Create Data View**.

1. From the Navigation menu, click **Discover** to view the log file entries.

1. From the drop down menu, select `oudlogs*` to view the log file entries.