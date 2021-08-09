---
title: "NGINX"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 2
pre: "<b>b. </b>"
description: "Configure the ingress-based NGINX load balancer for Oracle SOA Suite domains."
---

This section provides information about how to install and configure the ingress-based *NGINX* load balancer to load balance Oracle SOA Suite domain clusters. You can configure NGINX for non-SSL, SSL termination, and end-to-end SSL access of the application URL.


Follow these steps to set up NGINX as a load balancer for an Oracle SOA Suite domain in a Kubernetes cluster:

 See the official [installation document](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx#prerequisites) for prerequisites.

  1. [Install the NGINX load balancer for non-SSL and SSL termination configuration](#install-the-nginx-load-balancer-for-non-ssl-and-ssl-termination-configuration)
  2. [Generate secret for SSL access](#generate-secret-for-ssl-access)
  3. [Install NGINX load balancer for end-to-end SSL configuration](#install-nginx-load-balancer-for-end-to-end-ssl-configuration)
  4. [Configure NGINX to manage ingresses](#configure-nginx-to-manage-ingresses)
  5. [Verify domain application URL access](#verify-domain-application-url-access)
  6. [Uninstall NGINX ingress](#uninstall-nginx-ingress)
  7. [Uninstall NGINX](#uninstall-nginx)


 To get repository information, enter the following Helm commands:

   ```bash
     $ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
     $ helm repo update
   ```
#### Install the NGINX load balancer for non-SSL and SSL termination configuration

1. Deploy the `ingress-nginx` controller by using Helm on the domain namespace:

   ```bash
    $ helm install nginx-ingress -n soans \
           --set controller.service.type=NodePort \
           --set controller.admissionWebhooks.enabled=false \
	   ingress-nginx/ingress-nginx
   ```
    {{%expand "Click here to see the sample output." %}}
      NAME: nginx-ingress
      LAST DEPLOYED: Tue Sep 15 08:40:47 2020
      NAMESPACE: soans
      STATUS: deployed
      REVISION: 1
      TEST SUITE: None
      NOTES:
      The ingress-nginx controller has been installed.
      Get the application URL by running these commands:
      export HTTP_NODE_PORT=$(kubectl --namespace soans get services -o jsonpath="{.spec.ports[0].nodePort}" nginx-ingress-ingress-nginx-controller)
      export HTTPS_NODE_PORT=$(kubectl --namespace soans get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller)
      export NODE_IP=$(kubectl --namespace soans get nodes -o jsonpath="{.items[0].status.addresses[1].address}")

      echo "Visit http://$NODE_IP:$HTTP_NODE_PORT to access your application via HTTP."
      echo "Visit https://$NODE_IP:$HTTPS_NODE_PORT to access your application via HTTPS."

      An example ingress that makes use of the controller:

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
       # This section is only required if TLS is to be enabled for the ingress
       tls:
        - hosts:
            - www.example.com
          secretName: example-tls

       If TLS is enabled for the ingress, a secret containing the certificate and key must also be provided:

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

#### Generate secret for SSL access
1. For **secured access (SSL and E2ESSL)** to the Oracle SOA Suite application, create a certificate and generate secrets:

   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=domain1.org"
    $ kubectl -n soans create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```
   >  Note: The value of `CN` is the host on which this ingress is to be deployed.


#### Install NGINX load balancer for end-to-end SSL configuration

1. Deploy the ingress-nginx controller by using Helm on the domain namespace:
    ```bash
     $ helm install nginx-ingress -n soans \
           --set controller.extraArgs.default-ssl-certificate=soans/domain1-tls-cert \
           --set controller.service.type=NodePort \
           --set controller.admissionWebhooks.enabled=false \
           --set controller.extraArgs.enable-ssl-passthrough=true  \
            ingress-nginx/ingress-nginx
    ```
   {{%expand "Click here to see the sample output." %}}
  ```bash
      NAME: nginx-ingress
      LAST DEPLOYED: Tue Sep 15 08:40:47 2020
      NAMESPACE: soans
      STATUS: deployed
      REVISION: 1
      TEST SUITE: None
      NOTES:
      The ingress-nginx controller has been installed.
      Get the application URL by running these commands:
      export HTTP_NODE_PORT=$(kubectl --namespace soans get services -o jsonpath="{.spec.ports[0].nodePort}" nginx-ingress-ingress-nginx-controller)
      export HTTPS_NODE_PORT=$(kubectl --namespace soans get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller)
      export NODE_IP=$(kubectl --namespace soans get nodes -o jsonpath="{.items[0].status.addresses[1].address}")

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
   $ kubectl --namespace soans get services | grep ingress-nginx-controller
   ```
   Sample output:

   ```bash
    nginx-ingress-ingress-nginx-controller   NodePort    10.106.186.235   <none>        80:32125/TCP,443:31376/TCP   19m
   ```

#### Configure NGINX to manage ingresses

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress. Sample values for default configuration are shown in the file `${WORKDIR}/charts/ingress-per-domain/values.yaml`. By default, `type` is `TRAEFIK` , `sslType` is `NONSSL`, and `domainType` is `soa`. These values can be overridden by passing values through the command line or can be edited in the sample file `values.yaml`.   
If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. Update the template YAML file for the NGINX load balancer located at `${WORKDIR}/charts/ingress-per-domain/templates/nginx-ingress.yaml`.

    > Note: See [here](https://github.com/oracle/fmw-kubernetes/blob/v21.3.2/OracleSOASuite/kubernetes/ingress-per-domain/README.md#configuration) for all the configuration parameters.

   ```bash
    $ cd ${WORKDIR}
    $ helm install soa-nginx-ingress  charts/ingress-per-domain \
        --namespace soans \
        --values charts/ingress-per-domain/values.yaml \
        --set "nginx.hostname=$(hostname -f)" \
        --set type=NGINX
    ```

    Sample output:
    ```bash
    NAME: soa-nginx-ingress
    LAST DEPLOYED: Fri Jul 24 09:34:03 2020
    NAMESPACE: soans
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    ```
1. Install `ingress-per-domain` using Helm for SSL termination configuration:

   ```bash
    $ cd ${WORKDIR}
    $ helm install soa-nginx-ingress  charts/ingress-per-domain \
        --namespace soans \
        --values charts/ingress-per-domain/values.yaml \
        --set "nginx.hostname=$(hostname -f)" \
        --set type=NGINX --set sslType=SSL
   ```
   Sample output:

   ```bash
    NAME: soa-nginx-ingress
    LAST DEPLOYED: Fri Jul 24 09:34:03 2020
    NAMESPACE: soans
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
   ```
1. Install `ingress-per-domain` using Helm for `E2ESSL` configuration.

   ```bash
    $ cd ${WORKDIR}
    $ helm install soa-nginx-ingress  charts/ingress-per-domain \
        --namespace soans \
        --values charts/ingress-per-domain/values.yaml \
        --set type=NGINX --set sslType=E2ESSL
   ```
   Sample output:

   ```bash
    NAME: soa-nginx-ingress
    LAST DEPLOYED: Fri Jul 24 09:34:03 2020
    NAMESPACE: soans
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
   ```


1. For **NONSSL access** to the Oracle SOA Suite application, get the details of the services by the ingress:

    ```bash
    $ kubectl describe ingress soainfra-nginx -n soans
    ```
    {{%expand "Click here to see the sample output of the services supported by the above deployed ingress." %}}

    Name:             soainfra-nginx
    Namespace:        soans
    Address:          100.111.150.225
    Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
    Rules:
    Host                                                   Path  Backends
    ----                                                   ----  --------
    domain1.org
                                                         /console                   soainfra-adminserver:7001 (10.244.0.45:7001)
                                                         /em                        soainfra-adminserver:7001 (10.244.0.45:7001)
                                                         /weblogic/ready            soainfra-adminserver:7001 (10.244.0.45:7001)
                                                         /                          soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
                                                         /soa-infra                 soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
                                                         /soa/composer              soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
                                                         /integration/worklistapp   soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
    Annotations:                                             <none>
    Events:
    Type    Reason  Age    From                      Message
    ----    ------  ----   ----                      -------
    Normal  CREATE  2m32s  nginx-ingress-controller  Ingress soans/soainfra-nginx
    Normal  UPDATE  94s    nginx-ingress-controller  Ingress soans/soainfra-nginx

    {{% /expand %}}

1. For SSL access to the Oracle SOA Suite application, get the details of the services by the above deployed ingress:

    ```bash
     $ kubectl describe ingress soainfra-nginx -n soans
    ```
    {{%expand "Click here to see the sample output of the services supported by the above deployed ingress." %}}

     Name:             soainfra-nginx
     Namespace:        soans
     Address:          100.111.150.225
     Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
     TLS:
       domain1-tls-cert terminates domain1.org
     Rules:
        Host                                                   Path  Backends
        ----                                                   ----  --------
         domain1.org
                                                          /console                   soainfra-adminserver:7001 (10.244.0.45:7001)
                                                          /em                        soainfra-adminserver:7001 (10.244.0.45:7001)
                                                          /weblogic/ready            soainfra-adminserver:7001 (10.244.0.45:7001)
                                                          /                          soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
                                                          /soa-infra                 soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
                                                          /soa/composer              soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
                                                          /integration/worklistapp   soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
     Annotations:                                             kubernetes.io/ingress.class: nginx
                                                              nginx.ingress.kubernetes.io/configuration-snippet:
                                                              more_set_input_headers "X-Forwarded-Proto: https";
                                                              more_set_input_headers "WL-Proxy-SSL: true";
                                                              nginx.ingress.kubernetes.io/ingress.allow-http: false
     Events:
       Type    Reason  Age    From                      Message
       ----    ------  ----   ----                      -------
       Normal  CREATE  3m47s  nginx-ingress-controller  Ingress soans/soainfra-nginx
       Normal  UPDATE  3m25s  nginx-ingress-controller  Ingress soans/soainfra-nginx

  {{% /expand %}}
1. For E2ESSL access to the Oracle SOA Suite application, get the details of the services by the above deployed ingress:

    ```bash
     $  kubectl describe ingress  soainfra-nginx-e2essl -n soans
    ```
    {{%expand "Click here to see the sample output of the services supported by the above deployed ingress." %}}

     Name:             soainfra-nginx-e2essl-admin
     Namespace:        soans
     Address:
     Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
     TLS:
      domain1-tls-cert terminates admin.org
     Rules:
       Host        Path  Backends
       ----        ----  --------
       admin.org
                           soainfra-adminserver-nginx-ssl:7002 (10.244.0.247:7002)
      Annotations:  kubernetes.io/ingress.class: nginx
                    meta.helm.sh/release-name: soa-nginx-ingress
                    meta.helm.sh/release-namespace: soans
                    nginx.ingress.kubernetes.io/ssl-passthrough: true
     Events:
     Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  Sync    4s    nginx-ingress-controller  Scheduled for sync

     Name:             soainfra-nginx-e2essl-soa
     Namespace:        soans
     Address:
     Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
     TLS:
      domain1-tls-cert terminates soa.org
     Rules:
      Host        Path  Backends
      ----        ----  --------
      soa.org
                     /   soainfra-cluster-soa-cluster:8002 (10.244.0.249:8002)
     Annotations:  kubernetes.io/ingress.class: nginx
                   meta.helm.sh/release-name: soa-nginx-ingress
                   meta.helm.sh/release-namespace: soans
                   nginx.ingress.kubernetes.io/ssl-passthrough: true
    Events:
       Type    Reason  Age   From                      Message
      ----    ------  ----  ----                      -------
     Normal  Sync    4s    nginx-ingress-controller  Scheduled for sync
    {{% /expand %}}

#### Verify domain application URL access

##### NONSSL configuration

Verify that the Oracle SOA Suite domain application URLs are accessible through the `LOADBALANCER-Non-SSLPORT` `32125`:

```bash
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/weblogic/ready
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/soa-infra
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/soa/composer
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/integration/worklistapp
```

##### SSL configuration

Verify that the Oracle SOA Suite domain application URLs are accessible through the `LOADBALANCER-SSLPORT` `30233`:

```bash
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/weblogic/ready
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/console
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/em
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/soa-infra
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/soa/composer
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/integration/worklistapp
```

##### E2ESSL configuration

Before accessing the SOA Suite domain application URLs, update the system host config file with the IP address of the host on which the ingress is deployed.

   * To access the application URLs from the browser, update `/etc/hosts` on the browser host (in Windows, `C:\Windows\System32\Drivers\etc\hosts`) with the entries below

     ```
     X.X.X.X  admin.org
     X.X.X.X  soa.org
     X.X.X.X  osb.org
     ```
      >  Note: The value of X.X.X.X is the host IP address on which this ingress is deployed.

      >  Note: If you are behind any corporate proxy, make sure to update the browser proxy settings appropriately to access the host names updated `/etc/hosts` file.

Verify that the Oracle SOA Suite domain application URLs are accessible through `LOADBALANCER-E2ESSLPORT` `30233`:


  ```bash
  https://admin.org:${LOADBALANCER-SSLPORT}/weblogic/ready
  https://admin.org:${LOADBALANCER-SSLPORT}/console
  https://admin.org:${LOADBALANCER-SSLPORT}/em
  https://soa.org:${LOADBALANCER-SSLPORT}/soa-infra
  https://soa.org:${LOADBALANCER-SSLPORT}/soa/composer
  https://soa.org:${LOADBALANCER-SSLPORT}/integration/worklistapp

  ```
>  Note: This is the default host name. If you have updated the host name in `value.yaml`, then use the updated values.

####  Uninstall NGINX ingress
Uninstall and delete the `ingress-nginx` deployment:

  ```bash
  $ helm delete soa-nginx-ingress  -n soans
  ```
#### Uninstall NGINX

   ```bash
   $ helm delete nginx-ingress -n soans
   ```
