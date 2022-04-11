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

* [ Non-SSL and SSL termination](#non-ssl-and-ssl-termination)
  1. [Install the NGINX load balancer](#install-the-nginx-load-balancer)
  2. [Configure NGINX to manage ingresses](#configure-nginx-to-manage-ingresses)
  3. [Verify non-SSL and SSL termination access](#verify-non-ssl-and-ssl-termination-access)

* [ End-to-end SSL configuration](#end-to-end-ssl-configuration)
  1. [Install the NGINX load balancer for End-to-end SSL](#install-the-nginx-load-balancer-for-end-to-end-ssl)
  2. [Deploy tls to access the services](#deploy-tls-to-access-services)
  3. [Verify end-to-end SSL access](#verify-end-to-end-ssl-access)


 To get repository information, enter the following Helm commands:

   ```bash
     $ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
     $ helm repo update
   ```
### Non-SSL and SSL termination

#### Install the NGINX load balancer

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

1. Check the status of the deployed ingress controller:
   ```bash
   $ kubectl --namespace soans get services | grep ingress-nginx-controller
   ```
   Sample output:

   ```bash
    nginx-ingress-ingress-nginx-controller   NodePort    10.106.186.235   <none>        80:32125/TCP,443:31376/TCP   19m
   ```

#### Configure NGINX to manage ingresses

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress. Sample values for default configuration are shown in the file `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/values.yaml`. By default, `type` is `TRAEFIK`, `tls` is `Non-SSL`, and `domainType` is `soa`. These values can be overridden by passing values through the command line or can be edited in the sample file `values.yaml`. If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. Update the template YAML file for the NGINX load balancer located at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/nginx-ingress.yaml`

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install soa-nginx-ingress  kubernetes/samples/charts/ingress-per-domain \
        --namespace soans \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
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
1. For **secured access (SSL)** to the Oracle SOA Suite application, create a certificate and generate a Kubernetes secret:
   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=domain1.org"
    $ kubectl -n soans create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```
   >  Note: Value of  CN is the hostname on which this ingress is to be deployed.

1. Install `ingress-per-domain` using Helm for SSL configuration:

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install soa-nginx-ingress  kubernetes/samples/charts/ingress-per-domain \
        --namespace soans \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
        --set "nginx.hostname=$(hostname -f)" \
        --set type=NGINX --set tls=SSL
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

1. For **non-SSL access** to the Oracle SOA Suite application, get the details of the services by the ingress:

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

#### Verify non-SSL and SSL termination access

##### Non-SSL configuration

Verify that the Oracle SOA Suite domain application URLs are accessible through the `LOADBALANCER-Non-SSLPORT` `30017`:

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

####  Uninstall the ingress

Uninstall and delete the `ingress-nginx` deployment:

```bash
  $ helm delete   soa-nginx-ingress  -n soans
```

###  End-to-end SSL configuration

#### Install the NGINX load balancer for End-to-end SSL

1. For **secured access (SSL)** to the Oracle SOA Suite application, create a certificate and generate secrets:

   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=domain1.org"
    $ kubectl -n soans create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```
   >  Note: The value of `CN` is the host on which this ingress is to be deployed.

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
     nginx-ingress-ingress-nginx-controller   NodePort    10.96.177.215    <none>        80:32748/TCP,443:31940/TCP   23s
   ```

#### Deploy tls to access services

1. Deploy tls to securely access the services. Only one application can be configured with `ssl-passthrough`. A sample tls file for NGINX is shown below for the service `soainfra-cluster-soa-cluster` and port `8002`. All the applications running on port `8002` can be securely accessed through this ingress.

1. For each backend service, create different ingresses, as NGINX does not support multiple paths or rules with annotation `ssl-passthrough`. For example, for `soainfra-adminserver-nginx-ssl`, `soainfra-cluster-soa-cluster`, and `soainfra-cluster-osb-cluster`, different ingresses must be created.

1. As `ssl-passthrough` in NGINX works on the clusterIP of the backing service instead of individual endpoints, you must expose `adminserver service` created by the operator with clusterIP.

    For example:  
    a. Get the name of Administration Server service:
    ```bash
      $ kubectl get svc  -n soans | grep    soainfra-adminserver  
    ```
    Sample output:
    ```bash
      soainfra-adminserver   ClusterIP   None    <none> 7001/TCP,7002/TCP      1s
    ```

    b. Expose the Administration Server service `soainfra-adminserver` and use the new service name `soainfra-adminserver-nginx-ssl`:
    ```bash     
     $ kubectl expose svc soainfra-adminserver -n soans --name=soainfra-adminserver-nginx-ssl --port=7002	 
    ```

1.  See the sample backend services for domainUID `soainfra`:
    ```bash
    # Backend for Oracle SOA Suite service with domainUID "soainfra"
        backend:
          serviceName: soainfra-cluster-soa-cluster
          servicePort: 8002

    # Backend for Oracle Service Bus service with domainUID "soainfra"
        backend:
          serviceName: soainfra-cluster-osb-cluster
          servicePort: 9002

    # Backend for Administration Server service with domainUID "soainfra"
       backend:
         serviceName: soainfra-adminserver-nginx-ssl
         servicePort: 7002
    ```

1. Deploy the secured ingress:

   ```bash
   $ cd ${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/tls
   $ kubectl create -f nginx-tls.yaml
   ```
   > Note: The default `nginx-tls.yaml` contains the backend for Oracle SOA Suite service with domainUID `soainfra`. You need to create similar tls configuration YAML files separately for each backend service.

   {{%expand "Click here to check the content of the file `nginx-tls.yaml`" %}}

      apiVersion: extensions/v1beta1
      kind: Ingress
      metadata:
        name: soang-ingress
        namespace: soans
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
                serviceName: soainfra-cluster-soa-cluster
                servicePort: 8002

    {{% /expand %}}

   >  Note: host is the server on which this ingress is deployed.


1. Check the services supported by the ingress:
   ```bash
   $ kubectl describe ingress  soang-ingress -n soans
   ```
   {{%expand "Click here check the services supported by the ingress." %}}  

      Name:             soang-ingress
      Namespace:        soans
      Address:          100.111.150.225
      Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
      TLS:
        domain1-tls-cert terminates  domain1.org
      Rules:
        Host                                                   Path  Backends
          ----                                                   ----  --------
       domain1.org
                                                                  soainfra-cluster-soa-cluster:8002 (10.244.0.105:8002,10.244.0.106:8002)
        Annotations:                                             kubernetes.io/ingress.class: nginx
                                                                nginx.ingress.kubernetes.io/ssl-passthrough: true
        Events:                                                  <none>

   {{% /expand %}}

#### Verify end-to-end SSL access

Verify that the Oracle SOA Suite domain application URLs are accessible through the `LOADBALANCER-SSLPORT` `30233`:
   ```bash
     https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/soa-infra
     https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/soa/composer
     https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/integration/worklistapp
   ```

#### Uninstall ingress-nginx tls

  ```bash
    $ cd weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/tls
    $ kubectl  delete -f nginx-tls.yaml
  ```
