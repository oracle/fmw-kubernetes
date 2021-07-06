+++
title = "NGINX"
date = 2019-02-22T15:44:42-05:00
draft = false
weight = 2
pre = "<b>b. </b>"
description = "Configure the ingress-based NGINX load balancer for an Oracle WebCenter Portal domain."
+++

To load balance Oracle WebCenter Portal domain clusters, you can install the ingress-based *NGINX* load balancer and configure NGINX for non-SSL, SSL termination, and end-to-end SSL access of the application URL.
Follow these steps to set up NGINX as a load balancer for an Oracle WebCenter Portal domain in a Kubernetes cluster:

 See the official [installation document](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx#prerequisites) for prerequisites.
 
* [ Non-SSL and SSL termination](#non-ssl-and-ssl-termination)
  1. [Install the NGINX load balancer](#install-the-nginx-load-balancer)
  2. [Configure NGINX to manage ingresses](#configure-nginx-to-manage-ingresses)
  3. [Verify non-SSL and SSL termination access](#verify-non-ssl-and-ssl-termination-access)

* [ End-to-end SSL configuration](#end-to-end-ssl-configuration)
  1. [Install the NGINX load balancer for End-to-end SSL](#install-the-nginx-load-balancer-for-end-to-end-ssl)
  2. [Deploy tls to access the services](#deploy-tls-to-access-services)
  3. [Verify end-to-end SSL access](#verify-end-to-end-ssl-access)
 
### Non-SSL and SSL termination 
 To get repository information, enter the following Helm commands:

   ```bash
     $ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
     $ helm repo update
   ```

#### Install the NGINX load balancer

1. Deploy the `ingress-nginx` controller by using Helm on the domain namespace:

   ```bash
   $ helm install nginx-ingress ingress-nginx/ingress-nginx -n wcpns \
   --set controller.service.type=NodePort \
   --set controller.admissionWebhooks.enabled=false 
   ```
    {{%expand "Click here to see the sample output." %}}
      NAME: nginx-ingress
      LAST DEPLOYED: Tue Jan 12 21:13:54 2021
      NAMESPACE: wcpns
      STATUS: deployed
      REVISION: 1
      TEST SUITE: None
      NOTES:
      The ingress-nginx controller has been installed.
      Get the application URL by running these commands:
        export HTTP_NODE_PORT=30305
        export HTTPS_NODE_PORT=$(kubectl --namespace wcpns get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller)
        export NODE_IP=$(kubectl --namespace wcpns get nodes -o jsonpath="{.items[0].status.addresses[1].address}")
      
        echo "Visit http://$NODE_IP:$HTTP_NODE_PORT to access your application via HTTP."
        echo "Visit https://$NODE_IP:$HTTPS_NODE_PORT to access your application via HTTPS."
      
      An example Ingress that makes use of the controller:
      
        apiVersion: networking.k8s.io/v1beta1
        kind: Ingress
        metadata:
          annotations:
            kubernetes.io/ingress.class: nginx
          name: example
          namespace: foo
        spec:
          rules:
            - host: www.example.com
              http:
                paths:
                  - backend:
                      serviceName: exampleService
                      servicePort: 80
                    path: /
          # This section is only required if TLS is to be enabled for the Ingress
          tls:
              - hosts:
                  - www.example.com
                secretName: example-tls
      
      If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:
      
        apiVersion: v1
        kind: Secret
        metadata:
          name: example-tls
          namespace: foo
        data:
          tls.crt: <base64 encoded cert>
          tls.key: <base64 encoded key>
        type: kubernetes.io/tls

    {{% /expand %}}

1. Check the status of the deployed ingress controller:
   ```bash
   $ kubectl --namespace wcpns get services | grep ingress-nginx-controller
   ```
   Sample output:
   ```bash
   nginx-ingress-ingress-nginx-controller   NodePort       10.101.123.106   <none>        80:30305/TCP,443:31856/TCP   2m12s
   ```

#### Configure NGINX to manage ingresses

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress. Sample values for default configuration are shown in the file `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/values.yaml`. By default, `type` is `TRAEFIK`, `tls` is `Non-SSL`. You can override these values by passing values through the command line or edit them in the sample `values.yaml` file. If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. Update the template YAML file for the NGINX load balancer located at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/nginx-ingress.yaml`

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install wcp-nginx-ingress  kubernetes/samples/charts/ingress-per-domain \
        --namespace wcpns \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
        --set "nginx.hostname=$(hostname -f)" \
        --set type=NGINX
    ```

    Sample output:
    ```bash
    NAME: wcp-nginx-ingress
    LAST DEPLOYED: Fri Jul 24 09:34:03 2020
    NAMESPACE: wcpns
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    ```
1. For secured access (SSL) to the Oracle WebCenter Portal application, create a certificate and generate a Kubernetes secret:

   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
    $ kubectl -n wcpns create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```
1. Install `ingress-per-domain` using Helm for SSL configuration:
   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install wcp-nginx-ingress  kubernetes/samples/charts/ingress-per-domain \
        --namespace wcpns \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
        --set "nginx.hostname=$(hostname -f)" \
        --set type=NGINX --set tls=SSL
    ```
1. For non-SSL access to the Oracle WebCenter Portal application, get the details of the services by the ingress:

   ```bash
    $ kubectl describe ingress wcp-domain-ingress -n wcpns
    ```
    {{%expand "Click here to see the sample output of the services supported by the above deployed ingress." %}}
     Name:             wcp-domain-ingress
     Namespace:        wcpns
     Address:          10.101.123.106
     Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
     Rules:
       Host        Path  Backends
       ----        ----  --------
       *
                   /webcenter   wcp-domain-cluster-wcp-cluster:8888 (10.244.0.52:8888,10.244.0.53:8888)
                   /console     wcp-domain-adminserver:7001 (10.244.0.51:7001)
                   /rsscrawl    wcp-domain-cluster-wcp-cluster:8888 (10.244.0.53:8888)
                   /rest    wcp-domain-cluster-wcp-cluster:8888 (10.244.0.53:8888)
                   /webcenterhelp    wcp-domain-cluster-wcp-cluster:8888 (10.244.0.53:8888)
                   /em          wcp-domain-adminserver:7001 (10.244.0.51:7001)
     Annotations:  meta.helm.sh/release-name: wcp-nginx-ingress
                   meta.helm.sh/release-namespace: wcpns
                   nginx.com/sticky-cookie-services: serviceName=wcp-domain-cluster-wcp-cluster srv_id expires=1h path=/;
                   nginx.ingress.kubernetes.io/proxy-connect-timeout: 1800
                   nginx.ingress.kubernetes.io/proxy-read-timeout: 1800
                   nginx.ingress.kubernetes.io/proxy-send-timeout: 1800
     Events:
       Type    Reason  Age                From                      Message
       ----    ------  ----               ----                      -------
       Normal  Sync    48m (x2 over 48m)  nginx-ingress-controller  Scheduled for sync

    {{% /expand %}}
 1. For SSL access to the Oracle WebCenter Portal application, get the details of the services by the above deployed ingress:
  
    ```bash
     $ kubectl describe ingress wcp-domain-ingress -n wcpns
     ```
    {{%expand "Click here to see the sample output of the services supported by the above deployed ingress." %}}
    Name:             wcp-domain-ingress
    Namespace:        wcpns
    Address:          10.106.220.140
    Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
    TLS:
      domain1-tls-cert terminates mydomain.com
    Rules:
      Host        Path  Backends
      ----        ----  --------
      *
                  /webcenter   wcp-domain-cluster-wcp-cluster:8888 (10.244.0.43:8888,10.244.0.44:8888)
                  /console     wcp-domain-adminserver:7001 (10.244.0.42:7001)
                  /rsscrawl    wcp-domain-cluster-wcp-cluster:8888 (10.244.0.43:8888,10.244.0.44:8888)
                  /webcenterhelp   wcp-domain-cluster-wcp-cluster:8888 (10.244.0.43:8888,10.244.0.44:8888)
                  /rest     wcp-domain-cluster-wcp-cluster:8888 (10.244.0.43:8888,10.244.0.44:8888)
                  /em          wcp-domain-adminserver:7001 (10.244.0.42:7001)
    Annotations:  kubernetes.io/ingress.class: nginx
                  meta.helm.sh/release-name: wcp-nginx-ingress
                  meta.helm.sh/release-namespace: wcpns
                  nginx.ingress.kubernetes.io/affinity: cookie
                  nginx.ingress.kubernetes.io/affinity-mode: persistent
                  nginx.ingress.kubernetes.io/configuration-snippet:
                    more_set_input_headers "X-Forwarded-Proto: https";
                    more_set_input_headers "WL-Proxy-SSL: true";
                  nginx.ingress.kubernetes.io/ingress.allow-http: false
                  nginx.ingress.kubernetes.io/proxy-connect-timeout: 1800
                  nginx.ingress.kubernetes.io/proxy-read-timeout: 1800
                  nginx.ingress.kubernetes.io/proxy-send-timeout: 1800
                  nginx.ingress.kubernetes.io/session-cookie-expires: 172800
                  nginx.ingress.kubernetes.io/session-cookie-max-age: 172800
                  nginx.ingress.kubernetes.io/session-cookie-name: stickyid
                  nginx.ingress.kubernetes.io/ssl-redirect: false
    Events:       <none>
   {{% /expand %}}
#### Verify non-SSL and SSL termination access
Verify that the Oracle WebCenter Portal domain application URLs are accessible through the  ngnix NodePort `LOADBALANCER-NODEPORT` `30305`:

```bash
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-NODEPORT}/console
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-NODEPORT}/em
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-NODEPORT}/webcenter
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-NODEPORT}/rsscrawl
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-NODEPORT}/rest
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-NODEPORT}/webcenterhelp

```



####  Uninstall the ingress

Uninstall and delete the `ingress-nginx` deployment:

```bash
  $ helm delete   wcp-nginx-ingress -n wcpns
  $  helm delete nginx-ingress -n wcpns
```


###  End-to-end SSL configuration

#### Install the NGINX load balancer for End-to-end SSL

1. For secured access (SSL) to the Oracle WebCenter Portal application, create a certificate and generate secrets:

   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=domain1.org"
    $ kubectl -n wcpns create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```
   >  Note: The value of `CN` is the host on which this ingress is to be deployed.

1. Deploy the ingress-nginx controller by using Helm on the domain namespace:
    ```bash
     $ helm install nginx-ingress -n wcpns \
           --set controller.extraArgs.default-ssl-certificate=wcpns/domain1-tls-cert \
           --set controller.service.type=NodePort \
           --set controller.admissionWebhooks.enabled=false \
           --set controller.extraArgs.enable-ssl-passthrough=true  \
            ingress-nginx/ingress-nginx
    ```
   {{%expand "Click here to see the sample output." %}}
  ```bash
      NAME: nginx-ingress
      LAST DEPLOYED: Tue Sep 15 08:40:47 2020
      NAMESPACE: wcpns
      STATUS: deployed
      REVISION: 1
      TEST SUITE: None
      NOTES:
      The ingress-nginx controller has been installed.
      Get the application URL by running these commands:
      export HTTP_NODE_PORT=$(kubectl --namespace wcpns get services -o jsonpath="{.spec.ports[0].nodePort}" nginx-ingress-ingress-nginx-controller)
      export HTTPS_NODE_PORT=$(kubectl --namespace wcpns get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller)
      export NODE_IP=$(kubectl --namespace wcpns get nodes -o jsonpath="{.items[0].status.addresses[1].address}")

      echo "Visit http://$NODE_IP:$HTTP_NODE_PORT to access your application via HTTP."
      echo "Visit https://$NODE_IP:$HTTPS_NODE_PORT to access your application via HTTPS."

      An example Ingress that makes use of the controller:

        apiVersion: networking.k8s.io/v1beta1
        kind: Ingress
        metadata:
          annotations:
            kubernetes.io/ingress.class: nginx
          name: example
          namespace: foo
        spec:
          rules:
          - host: www.example.com
            http:
            paths:
              - backend:
                serviceName: exampleService
                servicePort: 80
              path: /
       # This section is only required if TLS is to be enabled for the Ingress
       tls:
        - hosts:
            - www.example.com
          secretName: example-tls

       If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:
      apiVersion: v1
      kind: Secret
      metadata:
        name: example-tls
        namespace: foo
      data:
       tls.crt: <base64 encoded cert>
       tls.key: <base64 encoded key>
      type: kubernetes.io/tls
  ```
  {{% /expand %}}

1. Check the status of the deployed ingress controller:
   ```bash
    $ kubectl --namespace wcpns get services | grep ingress-nginx-controller
   ```
    Sample output:

   ```bash
     nginx-ingress-ingress-nginx-controller   NodePort    10.96.177.215    <none>        80:32748/TCP,443:31940/TCP   23s
   ```

#### Deploy tls to access services

1. Deploy tls to securely access the services. Only one application can be configured with `ssl-passthrough`. A sample tls file for NGINX is shown below for the service `wcp-domain-cluster-wcp-cluster` and port `8889`. All the applications running on port `8889` can be securely accessed through this ingress.

1. For each backend service, create different ingresses, as NGINX does not support multiple paths or rules with annotation `ssl-passthrough`. For example, for `wcp-domain-adminserver` and `wcp-domain-cluster-wcp-cluster,` different ingresses must be created.

1. As `ssl-passthrough` in NGINX works on the clusterIP of the backing service instead of individual endpoints, you must expose `wcp-domain-cluster-wcp-cluster` created by the operator with clusterIP.

    For example:  
    a. Get the name of wcp-domain cluster service:
    ```bash
      $ kubectl get svc  -n wcpns | grep  wcp-domain-cluster-wcp-cluster 
    ```
    Sample output:
    ```bash
        wcp-domain-cluster-wcp-cluster           ClusterIP   10.102.128.124   <none>        8888/TCP,8889/TCP            62m
    ```
1. Deploy the secured ingress:

   ```bash
   $ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/tls
   $ kubectl create -f nginx-tls.yaml
   ```
   > Note: The default `nginx-tls.yaml` contains the backend for WebCenter Portal service with domainUID `wcp-domain`. You need to create similar tls configuration YAML files separately for each backend service.

   {{%expand "Click here to check the content of the file nginx-tls.yaml" %}}

        apiVersion: extensions/v1beta1
        kind: Ingress
        metadata:
          name: wcpns-ingress
          namespace: wcpns
          annotations:
            kubernetes.io/ingress.class: nginx
            nginx.ingress.kubernetes.io/ssl-passthrough: "true"
        spec:
          tls:
            - hosts:
                - domain1.org
              secretName: domain1-tls-cert
          rules:
            - host: domain1.org
              http:
                paths:
                  - path:
                    backend:
                      serviceName: wcp-domain-cluster-wcp-cluster
                      servicePort: 8889
        
        

    {{% /expand %}}

   >  Note: Host is the server on which this ingress is deployed.


1. Check the services supported by the ingress:
   ```bash
   $ kubectl describe ingress  wcpns-ingress -n wcpns
   ```
#### Verify end-to-end SSL access

Verify that the Oracle WebCenter Portal domain application URLs are accessible through the `LOADBALANCER-SSLPORT` `30233`:
   ```bash
     https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenter
     https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/rsscrawl
     https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenterhelp
     https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/rest

   ```

#### Uninstall ingress-nginx tls

  ```bash
    $ cd weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/tls
    $ kubectl  delete -f nginx-tls.yaml
    $ helm delete nginx-ingress -n wcpns
  ```
