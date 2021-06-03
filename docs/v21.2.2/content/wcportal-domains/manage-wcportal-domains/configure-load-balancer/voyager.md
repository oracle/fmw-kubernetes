+++
title = "Voyager"
date = 2019-02-22T15:44:42-05:00
draft = false
weight = 3
pre = "<b>c. </b>"
description = "Configure the ingress-based Voyager load balancer for an Oracle WebCenter Portal domain."
+++

*Voyager/HAProxy* is a popular ingress-based load balancer for production environments. 
You can install and configure *Voyager/HAProxy* to load balance Oracle WebCenter Portal domain clusters and configure it for non-SSL, SSL termination, and end-to-end SSL access of the application URL.
Follow these steps to set up Voyager as a load balancer for an Oracle WebCenter Portal domain in a Kubernetes cluster:

* [ Non-SSL and SSL termination](#non-ssl-and-ssl-termination)

  1. [Install the Voyager load balancer](#install-the-voyager-load-balancer)
  2. [Configure Voyager to manage ingresses](#configure-voyager-to-manage-ingresses)
  3. [Verify non-SSL and SSL access](#verify-non-ssl-and-ssl-access)

* [  End-to-end SSL configuration](#end-to-end-ssl-configuration)
  1. [Install Voyager load balancer for end-to-end SSL](#install-voyager-load-balancer-for-end-to-end-ssl)
  2. [Deploy tls to access the services](#deploy-tls-to-access-services)
  3. [Verify end-to-end SSL access](#verify-end-to-end-ssl-access)

####  Non-SSL and SSL termination

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
      > **NOTE**: After updating the Helm repository, the Voyager version listed may be newer that the one shown here. Check with the Voyager site for the latest supported versions.

1. Install the Voyager operator:

    > **NOTE**: The Voyager version you install must match the version found with the helm search.

      ```bash
      $ kubectl create namespace voyager
      $ helm install voyager-operator appscode/voyager --version 10.0.0 \
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

    See the official [installation document](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/charts/voyager/README.md#a-step-by-step-guide-to-install-the-voyager-operator) for more details.

1. Update the Voyager operator.
   Once the Voyager operator is installed, and it is running, upgrade it using the `helm upgrade` command. In this command, `voyager` is the Voyager namespace  and `wcpns` is the namespace of the domain.
   
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

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress. Sample values for default configuration are shown in the file `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/values.yaml`. By default, `type` is `TRAEFIK` , `tls` is `Non-SSL`. You can override these values by passing your values through the command line or edit the existing values in the sample `values.yaml` file.

   If needed, you can update the ingress yaml file to define more path rules (in the `spec.rules.host.http.paths` section) based on the domain application URLs that need to be accessed. You need to update the template yaml file for the Voyager (ingress-based) load balancer located at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/voyager-ingress.yaml`

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install wcp-voyager-ingress kubernetes/samples/charts/ingress-per-domain \
        --namespace wcpns \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
        --set type=VOYAGER
   ```
   {{%expand "Click here to check the output of the ingress per domain " %}}
   ```bash
    NAME: wcp-voyager-ingress
    LAST DEPLOYED: Mon Jul 20 08:20:27 2020
    NAMESPACE: wcpns
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
   ```
   {{% /expand %}}
1. For secured access (SSL) to the Oracle WebCenter Portal application, create a certificate and generate secrets:
   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
    $ kubectl -n wcpns create secret tls wcpinfra-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```
      >  Note: The value of `CN` is the host on which this ingress is to be deployed.

1. Deploy  `ingress-per-domain` using Helm for SSL configuration.

   If needed, you can update the ingress yaml file to define more path rules (in the `spec.rules.host.http.paths section`) based on the domain application URLs that need to be accessed. You need to update the template yaml file for the Voyager (ingress-based) load balancer located at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/voyager-ingress.yaml`

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install wcp-voyager-ingress kubernetes/samples/charts/ingress-per-domain \
        --namespace wcpns  \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
        --set type=VOYAGER \
        --set tls=SSL
   ```
    {{%expand "Click here to see the sample output of the above Commnad." %}}
   ```bash
    NAME: wcp-voyager-ingress
    LAST DEPLOYED: Mon Jul 20 08:20:27 2020
    NAMESPACE: wcpns
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
   ```
   {{% /expand %}}

1. For non-SSL access to the Oracle WebCenter Portal application, get the details of the services deployed by the above ingress:

   ```bash
   $ kubectl describe ingress.voyager.appscode.com/wcp-domain-voyager -n wcpns
   ```
   {{%expand "Click here to see the sample output of the services supported by the above deployed ingress." %}}
   Sample output:
   ```bash
   Name:         wcp-domain-voyager
   Namespace:    wcpns
   Labels:       app.kubernetes.io/managed-by=Helm
   Annotations:  ingress.appscode.com/affinity: cookie
                 ingress.appscode.com/stats: true
                 ingress.appscode.com/type: NodePort
                 meta.helm.sh/release-name: wcp-voyager-ingress
                 meta.helm.sh/release-namespace: wcpns
   API Version:  voyager.appscode.com/v1beta1
   Kind:         Ingress
   Metadata:
     Creation Timestamp:  2021-01-13T08:19:16Z
     Generation:          1
     Managed Fields:
       API Version:  voyager.appscode.com/v1beta1
       Fields Type:  FieldsV1
       fieldsV1:
         f:metadata:
           f:annotations:
             .:
             f:ingress.appscode.com/affinity:
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
       Manager:         Go-http-client
       Operation:       Update
       Time:            2021-01-13T08:19:16Z
     Resource Version:  340890
     Self Link:         /apis/voyager.appscode.com/v1beta1/namespaces/wcpns/ingresses/wcp-domain-voyager
     UID:               a06315c2-23ad-4916-a972-cd3555494eb8
   Spec:
     Rules:
       Host:  *
       Http:
         Node Port:  30305
         Paths:
           Backend:
             Service Name:  wcp-domain-cluster-wcp-cluster
             Service Port:  8888
           Path:            /webcenter
           Backend:
             Service Name:  wcp-domain-adminserver
             Service Port:  7001
           Path:            /console
           Backend:
             Service Name:  wcp-domain-cluster-wcp-cluster
             Service Port:  8888
           Path:            /rsscrawl
           Backend:
             Service Name:  wcp-domain-adminserver
             Service Port:  7001
           Path:            /em
   Events:
     Type    Reason                           Age   From              Message
     ----    ------                           ----  ----              -------
     Normal  ServiceReconcileSuccessful       62s   voyager-operator  Successfully created NodePort Service voyager-wcp-domain-voyager
     Normal  ConfigMapReconcileSuccessful     62s   voyager-operator  Successfully created ConfigMap voyager-wcp-domain-voyager
     Normal  RBACSuccessful                   62s   voyager-operator  Successfully created ServiceAccount voyager-wcp-domain-voyager
     Normal  RBACSuccessful                   62s   voyager-operator  Successfully created Role voyager-wcp-domain-voyager
     Normal  RBACSuccessful                   62s   voyager-operator  Successfully created RoleBinding voyager-wcp-domain-voyager
     Normal  DeploymentReconcileSuccessful    62s   voyager-operator  Successfully created HAProxy Deployment voyager-wcp-domain-voyager
     Normal  StatsServiceReconcileSuccessful  62s   voyager-operator  Successfully created stats Service voyager-wcp-domain-voyager-stats

   ```
   {{% /expand %}}

1. For SSL access to the Oracle WebCenter Portal application, get the details of the services by the above deployed ingress:

   ```bash
    $ kubectl describe ingress.voyager.appscode.com/wcp-domain-voyager -n wcpns
   ```
   {{%expand "Click here to see all  the services configured by the above deployed ingress." %}}

   ```bash
      Name:         wcp-domain-voyager
      Namespace:    wcpns
      Labels:       app.kubernetes.io/managed-by=Helm
      Annotations:  ingress.appscode.com/affinity: cookie
                    ingress.appscode.com/stats: true
                    ingress.appscode.com/type: NodePort
                    meta.helm.sh/release-name: wcp-domain-ingress
                    meta.helm.sh/release-namespace: wcpns
      API Version:  voyager.appscode.com/v1beta1
      Kind:         Ingress
      Metadata:
        Creation Timestamp:  2021-01-15T05:40:20Z
        Generation:          1
        Managed Fields:
          API Version:  voyager.appscode.com/v1beta1
          Fields Type:  FieldsV1
          fieldsV1:
            f:metadata:
              f:annotations:
                .:
                f:ingress.appscode.com/affinity:
                f:ingress.appscode.com/stats:
                f:ingress.appscode.com/type:
                f:meta.helm.sh/release-name:
                f:meta.helm.sh/release-namespace:
              f:labels:
                .:
                f:app.kubernetes.io/managed-by:
            f:spec:
              .:
              f:frontendRules:
              f:rules:
              f:tls:
          Manager:         Go-http-client
          Operation:       Update
          Time:            2021-01-15T05:40:20Z
        Resource Version:  704682
        Self Link:         /apis/voyager.appscode.com/v1beta1/namespaces/wcpns/ingresses/wcp-domain-voyager
        UID:               1e83c6a6-336f-4e29-b38a-023e00ca5cd5
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
                Service Name:  wcp-domain-cluster-wcp-cluster
                Service Port:  8888
              Path:            /webcenter
              Backend:
                Service Name:  wcp-domain-adminserver
                Service Port:  7001
              Path:            /console
              Backend:
                Service Name:  wcp-domain-cluster-wcp-cluster
                Service Port:  8888
              Path:            /rsscrawl
              Backend:
                 Service Name:  wcp-domain-cluster-wcp-cluster
                 Service Port:  8888
              Path:            /rest
              Backend:
                 Service Name:  wcp-domain-cluster-wcp-cluster
                 Service Port:  8888
              Path:            /webcenterhelp
              Backend:
                Service Name:  wcp-domain-adminserver
                Service Port:  7001
              Path:            /em
        Tls:
          Hosts:
            *
          Secret Name:  domain1-tls-cert
      Events:
        Type    Reason                           Age   From              Message
        ----    ------                           ----  ----              -------
        Normal  ServiceReconcileSuccessful       54s   voyager-operator  Successfully created NodePort Service voyager-wcp-domain-voyager
        Normal  ConfigMapReconcileSuccessful     54s   voyager-operator  Successfully created ConfigMap voyager-wcp-domain-voyager
        Normal  RBACSuccessful                   54s   voyager-operator  Successfully created ServiceAccount voyager-wcp-domain-voyager
        Normal  RBACSuccessful                   54s   voyager-operator  Successfully created Role voyager-wcp-domain-voyager
        Normal  RBACSuccessful                   54s   voyager-operator  Successfully created RoleBinding voyager-wcp-domain-voyager
        Normal  DeploymentReconcileSuccessful    54s   voyager-operator  Successfully created HAProxy Deployment voyager-wcp-domain-voyager
        Normal  StatsServiceReconcileSuccessful  54s   voyager-operator  Successfully created stats Service voyager-wcp-domain-voyager-stats

   ```
   {{% /expand %}}



##### Verify Non-SSL and SSL access

After setting up the Voyager (ingress-based) load balancer, verify that the Oracle WebCenter Portal domain applications are accessible through the load balancer port 30305 (both SSL and non-SSL). The application URLs for Oracle WebCenter Portal domain are:

>    Note: Port 30305 is the LOADBALANCER-Non-SSLPORT and LOADBALANCER-SSLPORT.

##### Non-SSL configuration

   ```bash
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/webcenter
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/rsscrawl
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/rest
    http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/webcenterhelp

   ```
##### SSL configuration

   ```bash
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenter
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/console
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/em
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/rsscrawl
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/rest
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenterhelp

   ```

##### Uninstall the chart

  To uninstall and delete the my-ingress deployment, enter the following command:

   ```bash
    $ helm delete wcp-voyager-ingress -n wcpns
    $  helm delete voyager-operator -n voyager

   ```

#### End-to-end SSL configuration

##### Install Voyager load balancer for end-to-end SSL

Install the Voyager load balancer as described [here](#install-the-voyager-load-balancer).

1. Check the status of the Voyager operator.

   ```bash
    $ kubectl get all -n voyager
   ```
   Sample output:

   ```bash
     NAME                                   READY   STATUS    RESTARTS   AGE
     pod/voyager-operator-b84f95f8f-4szhl   1/1     Running   0          43h

     NAME                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
     service/voyager-operator   ClusterIP   10.107.201.155   <none>        443/TCP,56791/TCP   43h

     NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
     deployment.apps/voyager-operator   1/1     1            1           43h

     NAME                                         DESIRED   CURRENT   READY   AGE
     replicaset.apps/voyager-operator-b84f95f8f   1         1         1       43h
   ```
1. For secured access (SSL) to the Oracle WebCenter Portal application, create a certificate and generate Kuberentes secrets:
   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
    $ kubectl -n wcpns create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```
##### Deploy tls to access services

1. Deploy tls to securely access the services. Only one application can be configured with ssl-passthrough. A sample tls file for Voyager is shown below for the service `wcp-domain-cluster-wcp-cluster` and port `8889`. All the applications running on port `8889` can be securely accessed through this ingress. For each backend service, create different ingresses as Voyager does not support multiple path/rules with annotation `ssl-passthrough`.

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/tls
   ```
   {{%expand "Click here to see the content of the file voyager-tls.yaml" %}}
   ```bash   
   apiVersion: voyager.appscode.com/v1beta1
   kind: Ingress
   metadata:
     name: voyager-ssl
     namespace: wcpns
     annotations:
       ingress.appscode.com/type: 'NodePort'
       ingress.appscode.com/stats: 'true'
       ingress.appscode.com/affinity: 'cookie'
       ingress.appscode.com/ssl-passthrough: "true"
   spec:
     tls:
       - secretName: domain1-tls-cert
         hosts:
           - '*'
     rules:
       - host: '*'
         http:
           nodePort: '31443'
           paths:
             - path: /
               backend:
                 serviceName: wcp-domain-cluster-wcp-cluster
                 servicePort: '8889'

   ```
   {{% /expand %}}
   ```bash
    $ kubectl create -f voyager-tls.yaml
   ```   
   {{%expand "Click here to see the services supported by the ingress" %}}
   ```bash
    kubectl describe ingress.voyager.appscode.com/voyager-ssl -n wcpns
    Name:         voyager-ssl
    Namespace:    wcpns
    Labels:       <none>
    Annotations:  ingress.appscode.com/affinity: cookie
              ingress.appscode.com/ssl-passthrough: true
              ingress.appscode.com/stats: true
              ingress.appscode.com/type: NodePort
    API Version:  voyager.appscode.com/v1beta1
    Kind:         Ingress
    Metadata:
    Creation Timestamp:  2020-07-20T04:34:05Z
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
      f:spec:
        .:
        f:rules:
        f:tls:
     Manager:         kubectl
     Operation:       Update
     Time:            2020-07-20T04:34:05Z
    Resource Version:  340071
    Self Link:         /apis/voyager.appscode.com/v1beta1/namespaces/wcpns/ingresses/voyager-ssl
    UID:               4a9b2e02-1593-45b3-8ac4-ae1ac0f2832c
   Spec:
    Rules:
      Host:  *
      Http:
        Node Port:  31443
        Paths:
         Backend:
          Service Name:  wcp-domain-cluster-wcp-cluster
          Service Port:  8889
        Path:            /
   Tls:
    Hosts:
      *
    Secret Name:  domain1-tls-cert
   Events:
   Type    Reason                           Age    From              Message
   ----    ------                           ----   ----              -------
   Normal  ServiceReconcileSuccessful       7m37s  voyager-operator  Successfully created NodePort Service voyager-voyager-ssl
   N ormal  ConfigMapReconcileSuccessful     7m37s  voyager-operator  Successfully created ConfigMap voyager-voyager-ssl
   Normal  RBACSuccessful                   7m37s  voyager-operator  Successfully created ServiceAccount voyager-voyager-ssl
   Normal  RBACSuccessful                   7m37s  voyager-operator  Successfully created Role voyager-voyager-ssl
   Normal  RBACSuccessful                   7m37s  voyager-operator  Successfully created RoleBinding voyager-voyager-ssl
   Normal  DeploymentReconcileSuccessful    7m37s  voyager-operator  Successfully created HAProxy Deployment voyager-voyager-ssl
   Normal  StatsServiceReconcileSuccessful  7m37s  voyager-operator  Successfully created stats Service voyager-voyager-ssl-stats
   Normal  DeploymentReconcileSuccessful    3m5s   voyager-operator  Successfully patched HAProxy Deployment voyager-voyager-ssl
   ```			 
  {{% /expand %}}

##### Verify end-to-end SSL access

Verify that the Oracle WebCenter Portal domain application URLs are accessible through the SSLPORT `31443`:
   ```bash
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenter
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/rsscrawl
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenterhelp
   https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/rest

   ```

##### Uninstall the Voyager tls

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/tls
    $ kubectl  delete -f voyager-tls.yaml
    $ helm delete voyager-operator -n voyager
   ```
