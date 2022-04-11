---
title: "Voyager"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 3
pre: "<b>c. </b>"
description: "Configure the ingress-based Voyager load balancer for Oracle SOA Suite domains."
---

*Voyager/HAProxy* is a popular ingress-based load balancer for production environments. This section provides information about how to install and configure *Voyager/HAProxy* to load balance Oracle SOA Suite domain clusters. You can configure Voyager for non-SSL, SSL termination, and end-to-end SSL access of the application URL.

Follow these steps to set up Voyager as a load balancer for an Oracle SOA Suite domain in a Kubernetes cluster:

  1. [Install the Voyager load balancer](#install-the-voyager-load-balancer)
  2. [Configure Voyager to manage ingresses](#configure-voyager-to-manage-ingresses)
  3. [Verify domain application URL access](#verify-domain-application-url-access)
  4. [Uninstalling Voyager Ingress](#uninstalling-voyager-ingress)
  5. [Uninstall Voyager](#uninstall-voyager)


##### Install the Voyager load balancer

1. Add the AppsCode chart repository:

      ```bash
      $ helm repo add appscode https://charts.appscode.com/stable/
      $ helm repo update
      ```
1. Verify that the chart repository has been added:

      ```bash
      $ helm search repo appscode/voyager
      ```
      > **NOTE**: After updating the Helm repository, the Voyager version listed may be newer that the one appearing here. Check with the Voyager site for the latest supported versions.

1. Install the Voyager operator:

    > **NOTE**: The Voyager version used for the install should match the version found with `helm search`.

      ```bash
      $ kubectl create ns voyager
      $ helm install voyager-operator appscode/voyager --version 12.0.0 \
        --namespace voyager \
        --set cloudProvider=baremetal \
        --set apiserver.enableValidatingWebhook=false
      ```

      Wait until the Voyager operator is running.

1. Check the status of the Voyager operator:
    ```bash
    $ kubectl get all -n voyager
    ```
      {{%expand "Click here to see the sample output." %}}

      NAME                                   READY   STATUS    RESTARTS   AGE
      pod/voyager-operator-b84f95f8f-4szhl   1/1     Running   0          43h

      NAME                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
      service/voyager-operator   ClusterIP   10.107.201.155   <none>        443/TCP,56791/TCP   43h

      NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
      deployment.apps/voyager-operator   1/1     1            1           43h

      NAME                                         DESIRED   CURRENT   READY   AGE
      replicaset.apps/voyager-operator-b84f95f8f   1         1         1       43h  

      {{% /expand %}}

    See the official [installation document](https://github.com/oracle/weblogic-kubernetes-operator/blob/main/kubernetes/samples/charts/voyager/README.md#a-step-by-step-guide-to-install-the-voyager-operator) for more details.

1. Update the Voyager operator

   After the Voyager operator is installed and running, upgrade the Voyager operator using the `helm upgrade` command, where `voyager` is the Voyager namespace and `soans` is the namespace of the domain.
    ```bash
      $ helm upgrade voyager-operator appscode/voyager --namespace voyager
    ```
   {{%expand "Click here to see the sample output." %}}
    Release "voyager-operator" has been upgraded. Happy Helming!
    NAME: voyager-operator
    LAST DEPLOYED: Mon Sep 28 11:53:43 2020
    NAMESPACE: voyager
    STATUS: deployed
    REVISION: 2
    TEST SUITE: None
    NOTES:
    Set cloudProvider for installing Voyager

    To verify that Voyager has started, run:

    kubectl get deployment --namespace voyager -l "app.kubernetes.io/name=voyager,app.kubernetes.io/instance=voyager-operator"

   {{% /expand %}}

##### Configure Voyager to manage ingresses

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress. Sample values for default configuration are shown in the file `${WORKDIR}/charts/ingress-per-domain/values.yaml`. By default, `type` is `TRAEFIK` , `sslType` is `NONSSL`, and `domainType` is `soa`. These values can be overridden by passing values through the command line or can be edited on the sample file `values.yaml`.

    > Note: See [here](https://github.com/oracle/fmw-kubernetes/blob/v21.3.2/OracleSOASuite/kubernetes/ingress-per-domain/README.md#configuration) for all the configuration parameters.

   If needed, you can update the ingress yaml file to define more path rules (in the `spec.rules.host.http.paths` section) based on the domain application URLs that need to be accessed. You need to update the template yaml file for the Voyager (ingress-based) load balancer located at `${WORKDIR}/charts/ingress-per-domain/templates/voyager-ingress.yaml`

   ```bash
    $ cd ${WORKDIR}
    $ helm install soa-voyager-ingress charts/ingress-per-domain \
        --namespace soans \
        --values charts/ingress-per-domain/values.yaml \
        --set type=VOYAGER
   ```
   {{%expand "Click here to check the output of the ingress per domain " %}}
   ```bash
    NAME: soa-voyager-ingress
    LAST DEPLOYED: Mon Jul 20 08:20:27 2020
    NAMESPACE: soans
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
   ```
   {{% /expand %}}
1. To secure access (`SSL` and `E2ESSL`) to the Oracle SOA Suite application, create a certificate and generate secrets:
   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
    $ kubectl -n soans create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```

1. Deploy  `ingress-per-domain` using Helm for SSL termination configuration.

   ```bash
    $ cd ${WORKDIR}
    $ helm install soa-voyager-ingress charts/ingress-per-domain \
        --namespace soans  \
        --values charts/ingress-per-domain/values.yaml \
        --set type=VOYAGER \
        --set sslType=SSL
   ```
    {{%expand "Click here to see the sample output of the above Commnad." %}}
   ```bash
    NAME: soa-voyager-ingress
    LAST DEPLOYED: Mon Jul 20 08:20:27 2020
    NAMESPACE: soans
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
   ```
   {{% /expand %}}

1. Deploy  `ingress-per-domain` using Helm for `E2ESSL` configuration.

   ```bash
    $ cd ${WORKDIR}
    $ helm install soa-voyager-ingress charts/ingress-per-domain \
        --namespace soans  \
        --values charts/ingress-per-domain/values.yaml \
        --set type=VOYAGER \
        --set sslType=E2ESSL
   ```
    {{%expand "Click here to see the sample output of the above Commnad." %}}
   ```bash
    NAME: soa-voyager-ingress
    LAST DEPLOYED: Mon Apr 20 08:20:27 2021
    NAMESPACE: soans
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
   ```
   {{% /expand %}}

1. For `NONSSL` access to the Oracle SOA Suite application, get the details of the services deployed by the above ingress:

   ```bash
   $ kubectl describe ingress.voyager.appscode.com/soainfra-voyager -n soans
   ```
   {{%expand "Click here to see the sample output of the services supported by the above deployed ingress." %}}
   Sample output:
   ```bash
   Name:         soainfra-voyager
   Namespace:    soans
   Labels:       <none>
   Annotations:  ingress.appscode.com/affinity: cookie
                 ingress.appscode.com/default-timeout: {"connect": "1800s", "server": "1800s"}
                 ingress.appscode.com/stats: true
                 ingress.appscode.com/type: NodePort
    API Version:  voyager.appscode.com/v1beta1
    Kind:         Ingress
    Metadata:
      Creation Timestamp:  2020-07-20T08:20:28Z
      Generation:          1
      Managed Fields:
        API Version:  voyager.appscode.com/v1beta1
        Fields Type:  FieldsV1
        fieldsV1:
           f:metadata:
              f:annotations:
              .:
              f:ingress.appscode.com/affinity:
              f:ingress.appscode.com/default-timeout:
              f:ingress.appscode.com/stats:
              f:ingress.appscode.com/type:
        f:spec:
           .:
          f:rules:
       Manager:         Go-http-client
       Operation:       Update
       Time:            2020-07-20T08:20:28Z
     Resource Version:  370484
     Self Link:         /apis/voyager.appscode.com/v1beta1/namespaces/soans/ingresses/soainfra-voyager
     UID:               bb756966-cd7f-40a5-b08c-79f69e2b9440
    Spec:
      Rules:
       Host:  *
       Http:
       Node Port:  30305
       Paths:
         Backend:
           Service Name:  soainfra-adminserver
           Service Port:  7001
         Path:            /console
         Backend:
           Service Name:  soainfra-adminserver
           Service Port:  7001
         Path:            /em
         Backend:
           Service Name:  soainfra-adminserver
           Service Port:  7001
         Path:            /weblogic/ready
         Backend:
           Service Name:  soainfra-cluster-soa-cluster
           Service Port:  8001
         Path:            /
         Backend:
           Service Name:  soainfra-cluster-soa-cluster
           Service Port:  8001
         Path:            /soa-infra
         Backend:
           Service Name:  soainfra-cluster-soa-cluster
           Service Port:  8001
         Path:            /soa/composer
         Backend:
           Service Name:  soainfra-cluster-soa-cluster
           Service Port:  8001
         Path:            /integration/worklistapp
    Events:
    Type    Reason                           Age    From              Message
    ----    ------                           ----   ----              -------
    Normal  ServiceReconcileSuccessful       4m30s  voyager-operator  Successfully created NodePort Service voyager-soainfra-voyager
    Normal  ConfigMapReconcileSuccessful     4m30s  voyager-operator  Successfully created ConfigMap voyager-soainfra-voyager
    Normal  RBACSuccessful                   4m30s  voyager-operator  Successfully created ServiceAccount voyager-soainfra-voyager
    Normal  RBACSuccessful                   4m30s  voyager-operator  Successfully created Role voyager-soainfra-voyager
    Normal  RBACSuccessful                   4m30s  voyager-operator  Successfully created RoleBinding voyager-soainfra-voyager
    Normal  DeploymentReconcileSuccessful    4m30s  voyager-operator  Successfully created HAProxy Deployment voyager-soainfra-voyager
    Normal  StatsServiceReconcileSuccessful  4m30s  voyager-operator  Successfully created stats Service voyager-soainfra-voyager-stats
   ```
   {{% /expand %}}

1. For `SSL` access to the Oracle SOA Suite application, get the details of the services by the above deployed ingress:

   ```bash
    $ kubectl describe ingress.voyager.appscode.com/soainfra-voyager -n soans
   ```
   {{%expand "Click here to see all  the services configured by the above deployed ingress." %}}

   ```bash
    Name:         soainfra-voyager
    Namespace:    soans
    Labels:       <none>
    Annotations:  ingress.appscode.com/affinity: cookie
                  ingress.appscode.com/default-timeout: {"connect": "1800s", "server": "1800s"}
                  ingress.appscode.com/stats: true
                  ingress.appscode.com/type: NodePort
    API Version:  voyager.appscode.com/v1beta1
    Kind:         Ingress
    Metadata:
      Creation Timestamp:  2020-07-20T08:20:28Z
      Generation:          1
      Managed Fields:
        API Version:  voyager.appscode.com/v1beta1
        Fields Type:  FieldsV1
        fieldsV1:
           f:metadata:
              f:annotations:
              .:
              f:ingress.appscode.com/affinity:
              f:ingress.appscode.com/default-timeout:
              f:ingress.appscode.com/stats:
              f:ingress.appscode.com/type:
        f:spec:
           .:
          f:rules:
       Manager:         Go-http-client
       Operation:       Update
       Time:            2020-07-20T08:20:28Z
      Resource Version:  370484
      Self Link:         /apis/voyager.appscode.com/v1beta1/namespaces/soans/ingresses/soainfra-voyager
      UID:               bb756966-cd7f-40a5-b08c-79f69e2b9440
    Spec:
      Frontend Rules:
      Port:  443
      Rules:
        http-request set-header WL-Proxy-SSL true
      Rules:
       Host:  *
       Http:
       Node Port:  30305
         Paths:
           Backend:
             Service Name:  soainfra-adminserver
             Service Port:  7001
           Path:            /console
           Backend:
             Service Name:  soainfra-adminserver
             Service Port:  7001
           Path :            /em
           Backend:
             Service Name:  soainfra-adminserver
             Service Port:  7001
           Path:            /weblogic/ready
           Backend:
             Service Name:  soainfra-cluster-soa-cluster
             Service Port:  8001
           Path:            /
           Backend:
             Service Name:  soainfra-cluster-soa-cluster
            Service Port:  8001
           Path:            /soa-infra
           Backend:
             Service Name:  soainfra-cluster-soa-cluster
             Service Port:  8001
           Path:            /soa/composer
           Backend:
             Service Name:  soainfra-cluster-soa-cluster
             Service Port:  8001
           Path:            /integration/worklistapp
        Tls:
         Hosts:
          *
        Secret Name:  domain1-tls-cert
    Events:
    Type    Reason                           Age   From              Message
    ----    ------                           ----  ----              -------
    Normal  ServiceReconcileSuccessful       22s   voyager-operator  Successfully created NodePort Service voyager-soainfra-voyager
    Normal  ConfigMapReconcileSuccessful     21s   voyager-operator  Successfully created ConfigMap voyager-soainfra-voyager
    Normal  RBACSuccessful                   21s   voyager-operator  Successfully created ServiceAccount voyager-soainfra-voyager
    Normal  RBACSuccessful                   21s   voyager-operator  Successfully created Role voyager-soainfra-voyager
    Normal  RBACSuccessful                   21s   voyager-operator  Successfully created RoleBinding voyager-soainfra-voyager
    Normal  DeploymentReconcileSuccessful    21s   voyager-operator  Successfully created HAProxy Deployment voyager-soainfra-voyager
    Normal  StatsServiceReconcileSuccessful  21s   voyager-operator  Successfully created stats Service voyager-soainfra-voyager-stats
   ```
   {{% /expand %}}
1. For `E2ESSL` access to the Oracle SOA Suite application, get the details of the services by the above deployed ingress:

   ```bash
    $ kubectl describe ingress.voyager.appscode.com/soainfra-voyager-e2essl-admin -n soans
   ```
   {{%expand "Click here to see all  the services configured by the above deployed ingress." %}}

   ```bash
        Name:         soainfra-voyager-e2essl
    Namespace:    soans
    Labels:       app.kubernetes.io/managed-by=Helm
    Annotations:  ingress.appscode.com/affinity: cookie
              ingress.appscode.com/ssl-passthrough: true
              ingress.appscode.com/stats: true
              ingress.appscode.com/type: NodePort
              meta.helm.sh/release-name: soa-voyager-ingress
              meta.helm.sh/release-namespace: soans
   API Version:  voyager.appscode.com/v1beta1
   Kind:         Ingress
   Metadata:
     Creation Timestamp:  2021-04-09T07:04:07Z
     Generation:          1
     Managed Fields:
       API Version:  voyager.appscode.com/v1beta1
       Fields Type:  FieldsV1
       fieldsV1:
        f:metadata:
        f:annotations:
          .:
          f:ingress.appscode.com/affinity:
          f:ingress.appscode.com/ssl-passthrough:
          f:ingress.appscode.com/stats:
          f:ingress.appscode.com/type:
          f:meta.helm.sh/release-name:
          f:meta.helm.sh/release-namespace:
        f:labels:
          .:
          f:app.kubernetes.io/managed-by:
      f:spec:
        .:
        f:rules:
        f:tls:
    Manager:         Go-http-client
    Operation:       Update
    Time:            2021-04-09T07:04:07Z
  Resource Version:  526406
  Self Link:         /apis/voyager.appscode.com/v1beta1/namespaces/soans/ingresses/soainfra-voyager-e2essl
  UID:               0d315fa3-893e-4cde-b589-f87f5d5fd8ce
   Spec:
     Rules:
       Host:  *
       Http:
         Node Port:  30443
         Paths:
         Backend:
           Service Name:  soainfra-adminserver
           Service Port:  7002
         Path:            /
    Tls:
     Hosts:
       *
    Secret Name:  domain1-tls-cert
   Events:
    Type    Reason                           Age    From              Message
    ----    ------                           ----   ----              -------
    Normal  ServiceReconcileSuccessful       3m16s  voyager-operator  Successfully created NodePort Service voyager-soainfra-voyager-e2essl
    Normal  ConfigMapReconcileSuccessful     3m16s  voyager-operator  Successfully created ConfigMap voyager-soainfra-voyager-e2essl
    Normal  RBACSuccessful                   3m16s  voyager-operator  Successfully created ServiceAccount voyager-soainfra-voyager-e2essl
    Normal  RBACSuccessful                   3m16s  voyager-operator  Successfully created Role voyager-soainfra-voyager-e2essl
    Normal  RBACSuccessful                   3m16s  voyager-operator  Successfully created RoleBinding voyager-soainfra-voyager-e2essl
    Normal  DeploymentReconcileSuccessful    3m16s  voyager-operator  Successfully created HAProxy Deployment voyager-soainfra-voyager-e2essl
    Normal  StatsServiceReconcileSuccessful  3m16s  voyager-operator  Successfully created stats Service voyager-soainfra-voyager-e2essl-stats
   ```
   {{% /expand %}}

1. To confirm that the load balancer noticed the new ingress and is successfully routing to the domain's server pods, you can send a request to the URL for the "WebLogic ReadyApp framework" which should return a HTTP 200 status code, as follows:

   ```bash
   $ curl -v http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/weblogic/ready
   * About to connect() to localhost port 30305 (#0)
   * Trying 127.0.0.1...
   * Connected to localhost (127.0.0.1) port 30305 (#0)
   > GET /weblogic/ready HTTP/1.1
   > User-Agent: curl/7.29.0
   > Accept: */*
   > host: *****.com
   >
   < HTTP/1.1 200 OK
   < Content-Length: 0
   < Date: Thu, 12 Mar 2020 10:16:43 GMT
   < Vary: Accept-Encoding
   <
   * Connection #0 to host localhost left intact
   ```

##### Verify domain application URL access

After setting up the Voyager (ingress-based) load balancer, verify that the Oracle SOA Suite domain applications are accessible through the load balancer port 30305 for `NONSSL`, 30443 for `SSL` and on ports 30445(`admin`), 30447(`soa`) and 30449(`osb`) for `E2ESSL`. The application URLs for Oracle SOA Suite domain of type `soa` are:

>    Note: Port 30305 is the LOADBALANCER-Non-SSLPORT and 30443 is LOADBALANCER-SSLPORT.

##### NONSSL configuration

   ```bash
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/weblogic/ready
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/soa-infra
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/soa/composer
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/integration/worklistapp
   ```
##### SSL configuration

   ```bash
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/weblogic/ready
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/console
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/em
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/soa-infra
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/soa/composer
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/integration/worklistapp
   ```
##### E2ESSL configuration

   ```bash
   https://${LOADBALANCER-HOSTNAME}:30445/weblogic/ready
   https://${LOADBALANCER-HOSTNAME}:30445/console
   https://${LOADBALANCER-HOSTNAME}:30445/em
   https://${LOADBALANCER-HOSTNAME}:30447/soa-infra
   https://${LOADBALANCER-HOSTNAME}:30447/soa/composer
   https://${LOADBALANCER-HOSTNAME}:30447/integration/worklistapp
   ```

#### Uninstalling Voyager ingress

  To uninstall and delete the ingress deployment, enter the following command:

   ```bash
    $ helm delete soa-voyager-ingress -n soans
   ```
#### Uninstall Voyager

   ```bash
   $ helm delete voyager-operator  -n voyager
   ```
