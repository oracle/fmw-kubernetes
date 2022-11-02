---
title: "NGINX"
date: 2020-12-22T15:44:42-05:00
draft: false
weight: 2
pre: "<b>b. </b>"
description: "Configure the ingress-based NGINX load balancer for Oracle WebCenter Content domain."
---

This section provides information about how to install and configure the ingress-based *NGINX* load balancer to load balance Oracle WebCenter Content domain clusters. You can configure NGINX for non-SSL, SSL termination, and end-to-end SSL access of the application URL.


Follow these steps to set up NGINX as a load balancer for an Oracle WebCenter Content domain in a Kubernetes cluster:

 See the official [installation document](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx#prerequisites) for prerequisites.

* [ Non-SSL and SSL termination](#non-ssl-and-ssl-termination)
  1. [Install the NGINX load balancer](#install-the-nginx-load-balancer)
  2. [Configure NGINX to manage ingresses](#configure-nginx-to-manage-ingresses)
  3. [Verify non-SSL and SSL termination access](#verify-non-ssl-and-ssl-termination-access)

* [ End-to-end SSL configuration](#end-to-end-ssl-configuration)
  1. [Install the NGINX load balancer for End-to-end SSL](#install-the-nginx-load-balancer-for-end-to-end-ssl)
  2. [Deploy tls to access individual Managed Servers](#deploy-tls-to-access-individual-managed-servers)
  3. [Deploy tls to access Administration Server](#deploy-tls-to-access-administration-server)
  4. [Uninstall ingress-nginx tls](#uninstall-ingress-nginx-tls)

* [ Uninstall the NGINX](#uninstall-the-nginx)

 To get repository information, enter the following Helm commands:

   ```bash
     $ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
     $ helm repo update
   ```
### Non-SSL and SSL termination

#### Install the NGINX load balancer

1. Deploy the `ingress-nginx` controller by using Helm on the domain namespace:
   
   ```bash
    $ helm install nginx-ingress -n wccns \
	       --set controller.service.type=NodePort \
           --set controller.admissionWebhooks.enabled=false \
	         ingress-nginx/ingress-nginx 
   ```
   {{%expand "Click here to see the sample output." %}}
```bash
NAME: nginx-ingress
LAST DEPLOYED: Fri Jul 29 00:14:19 2022
NAMESPACE: wccns
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
Get the application URL by running these commands:
  export HTTP_NODE_PORT=$(kubectl --namespace wccns get services -o jsonpath="{.spec.ports[0].nodePort}" nginx-ingress-ingress-nginx-controller)
  export HTTPS_NODE_PORT=$(kubectl --namespace wccns get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller)
  export NODE_IP=$(kubectl --namespace wccns get nodes -o jsonpath="{.items[0].status.addresses[1].address}")
  echo "Visit http://$NODE_IP:$HTTP_NODE_PORT to access your application via HTTP."
  echo "Visit https://$NODE_IP:$HTTPS_NODE_PORT to access your application via HTTPS."
An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
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
   $ kubectl --namespace wccns get services | grep ingress-nginx-controller
   ```
   Sample output:

   ```bash
    nginx-ingress-ingress-nginx-controller    NodePort    10.97.189.122    <none>            80:30993/TCP,443:30232/TCP    7d2h
   ```

#### Configure NGINX to manage ingresses

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress. Sample values for default configuration are shown in the file `${WORKDIR}/charts/ingress-per-domain/values.yaml`. By default, `type` is `TRAEFIK`, `tls` is `Non-SSL`, and `domainType` is `wccinfra`. These values can be overridden by passing values through the command line or can be edited in the sample file `values.yaml`. If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. Update the template YAML file for the NGINX load balancer located at `${WORKDIR}/charts/ingress-per-domain/templates/nginx-ingress.yaml`

   ```bash
   $ cd ${WORKDIR}
   $ helm install wccinfra-nginx-ingress charts/ingress-per-domain \
   --namespace wccns \
   --values charts/ingress-per-domain/values.yaml \
   --set "nginx.hostname=$(hostname -f)" \
   --set type=NGINX \
   --set tls=NONSSL
   ```

   Sample output:
   ```bash
   NAME: wccinfra-nginx-ingress
   LAST DEPLOYED: Sun Feb  7 23:52:38 2021
   NAMESPACE: wccns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```

1. For **secured access (SSL)** to the Oracle WebCenter Content application, create a certificate and generate a Kubernetes secret:
   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
    $ kubectl -n wccns create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```   

1. Install `ingress-per-domain` using Helm for SSL configuration:

   ```bash
    $ cd ${WORKDIR}
    $ helm install wccinfra-nginx-ingress charts/ingress-per-domain \
        --namespace wccns \
        --values charts/ingress-per-domain/values.yaml \
        --set "nginx.hostname=$(hostname -f)" \
		--set "nginx.hostnameorip=$(hostname -f)" \
        --set type=NGINX --set tls=SSL
   ```
   Sample output:

   ```bash
    NAME: wccinfra-nginx-ingress
    LAST DEPLOYED: Mon Feb  8 00:01:13 2021
    NAMESPACE: wccns
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
   ```

1. For **non-SSL access or SSL** to the Oracle WebCenter Content application, get the details of the services by the ingress:

    ```bash
 	  $ kubectl describe ingress wccinfra-nginx  -n wccns
    ```
   {{%expand "Click here to see the sample output of the services supported by the above deployed ingress." %}}
```bash
Name:             wccinfra-nginx
Namespace:        wccns
Address:          10.97.189.122
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
TLS:
  domain1-tls-cert terminates domain1.org
Rules:
  Host                                        Path  Backends
  ----                                        ----  --------
  domain1.org
                                              /console                 wccinfra-adminserver:7001 (10.244.0.58:7001)
                                              /em                      wccinfra-adminserver:7001 (10.244.0.58:7001)
                                              /servicebus              wccinfra-adminserver:7001 (10.244.0.58:7001)
                                              /cs                      wccinfra-cluster-ucm-cluster:16200 (10.244.0.60:16200,10.244.0.61:16200)
                                              /adfAuthentication       wccinfra-cluster-ucm-cluster:16200 (10.244.0.60:16200,10.244.0.61:16200)
                                              /ibr                     wccinfra-cluster-ibr-cluster:16250 (10.244.0.59:16250)
                                              /ibr/adfAuthentication   wccinfra-cluster-ibr-cluster:16250 (10.244.0.59:16250)
                                              /weblogic/ready          wccinfra-cluster-ucm-cluster:16200 (10.244.0.60:16200,10.244.0.61:16200)
                                              /imaging                 wccinfra-cluster-ipm-cluster:16000 (10.244.0.206:16000,10.244.0.209:16000,10.244.0.213:16000)
                                              /dc-console              wccinfra-cluster-capture-cluster:16400 (10.244.0.204:16400,10.244.0.208:16400,10.244.0.212:16400)
                                              /dc-client               wccinfra-cluster-capture-cluster:16400 (10.244.0.204:16400,10.244.0.208:16400,10.244.0.212:16400)
                                              /wcc                     wccinfra-cluster-wccadf-cluster:16225 (10.244.0.205:16225,10.244.0.210:16225,10.244.0.214:16225)
Annotations:                                  kubernetes.io/ingress.class: nginx
                                              meta.helm.sh/release-name: wccinfra-nginx-ingress
                                              meta.helm.sh/release-namespace: wccns
                                              nginx.ingress.kubernetes.io/configuration-snippet:
                                                more_set_input_headers "X-Forwarded-Proto: https";
                                                more_set_input_headers "WL-Proxy-SSL: true";
                                              nginx.ingress.kubernetes.io/ingress.allow-http: false
Events:                                       <none>

```
{{% /expand %}}


#### Verify non-SSL and SSL termination access

##### Non-SSL configuration

Verify that the Oracle WebCenter Content domain application URLs are accessible through the `LOADBALANCER-Non-SSLPORT`:

```bash
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/weblogic/ready
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/cs
  http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/ibr
  http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/imaging
  http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/dc-console
  http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/wcc  
```

##### SSL configuration

Verify that the Oracle WebCenter Content domain application URLs are accessible through the `LOADBALANCER-SSLPORT`:

```bash
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/weblogic/ready
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/console
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/em
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/cs
  https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/ibr
  https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/imaging
  https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/dc-console
  https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/wcc
```

####  Uninstall the ingress

Uninstall and delete the `ingress-nginx` deployment:

```bash
  $ helm delete wccinfra-nginx -n wccns
```

###  End-to-end SSL configuration

#### Install the NGINX load balancer for End-to-end SSL

1. For **secured access (SSL)** to the Oracle WebCenter Content application, create a certificate and generate secrets:
 
   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
    $ kubectl -n wccns create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```   

1. Deploy the ingress-nginx controller by using Helm on the domain namespace:

    ```bash
     $ helm install nginx-ingress -n wccns \	 
	 --set controller.extraArgs.default-ssl-certificate=wccns/domain1-tls-cert \
	 --set controller.service.type=NodePort \
	 --set controller.admissionWebhooks.enabled=false \
	 --set controller.extraArgs.enable-ssl-passthrough=true \
	 ingress-nginx/ingress-nginx
	```   
   {{%expand "Click here to see the sample output." %}}
```bash

NAME: nginx-ingress
LAST DEPLOYED: Thu Sep  8 23:59:54 2022
NAMESPACE: wccns
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
Get the application URL by running these commands:
  export HTTP_NODE_PORT=$(kubectl --namespace wccns get services -o jsonpath="{.spec.ports[0].nodePort}" nginx-ingress-ingress-nginx-controller)
  export HTTPS_NODE_PORT=$(kubectl --namespace wccns get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-ingress-ingress-nginx-controller)
  export NODE_IP=$(kubectl --namespace wccns get nodes -o jsonpath="{.items[0].status.addresses[1].address}")
  echo "Visit http://$NODE_IP:$HTTP_NODE_PORT to access your application via HTTP."
  echo "Visit https://$NODE_IP:$HTTPS_NODE_PORT to access your application via HTTPS."
An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
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
    $ kubectl --namespace wccns get services | grep ingress-nginx-controller
   ```
    Sample output:

   ```bash
     nginx-ingress-ingress-nginx-controller   NodePort    10.97.189.122    <none>            80:30993/TCP,443:30232/TCP    168m
   ```

#### Deploy tls to access individual Managed Servers

1. Deploy tls to securely access the services. Only one application can be configured with `ssl-passthrough`. A sample tls file for NGINX is shown below for the service `wccinfra-cluster-ucm-cluster` and port `16201`. All the applications running on port `16201` can be securely accessed through this ingress. For each backend service, create different ingresses as NGINX does not support multiple path/rules with annotation `ssl-passthrough`. That is, for `wccinfra-cluster-ucm-cluster`, `wccinfra-cluster-ibr-cluster`, `wccinfra-cluster-ipm-cluster`, `wccinfra-cluster-capture-cluster`, `wccinfra-cluster-wccadf-cluster` and `wccinfra-adminserver`, different ingresses must be created.

   >  Note: There  is a limitation with load-balancer in end-to-end SSL configuration - accessing multiple types of servers (different Managed Servers and/or Administration Server) at the same time, is currently not supported. We can access only one Managed Server at a time.

   ```bash
    $ cd ${WORKDIR}/charts/ingress-per-domain/tls
   ```
   Sample nginx-ucm-tls.yaml:
   
{{%expand "Click here to see the content of the file nginx-ucm-tls.yaml" %}}   
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wcc-ucm-ingress
  namespace: wccns
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  tls:
  - hosts:
    - 'your_host_name'
    secretName: domain1-tls-cert
  rules:
  - host: 'your_host_name'
    http:
      paths:
      - path:
        pathType: ImplementationSpecific
        backend:
          service:
            name: wccinfra-cluster-ucm-cluster
            port: 
              number: 16201
```
{{% /expand %}}
  
   >  Note: host is the server on which this ingress is deployed.
   
1. Deploy the secured ingress:

   ```bash
   $ cd ${WORKDIR}/charts/ingress-per-domain/tls
   $ kubectl create -f nginx-ucm-tls.yaml
   ```

1. Check the services supported by the ingress:
   ```bash
   $ kubectl describe ingress wcc-ucm-ingress -n wccns
   ```
   
   {{%expand "Click here check the services supported by the ingress." %}}  
```bash
Name:             wcc-ucm-ingress
Namespace:        wccns
Address:          10.102.97.237
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
TLS:
  domain1-tls-cert terminates domain1.org
Rules:
  Host                                         Path  Backends
  ----                                         ----  --------
  domain1.org
                                                  wccinfra-cluster-ucm-cluster:16201 (10.244.238.136:16201,10.244.253.132:16201)
Annotations:                                   kubernetes.io/ingress.class: nginx
                                               nginx.ingress.kubernetes.io/ssl-passthrough: true
Events:
  Type    Reason  Age                 From                      Message
  ----    ------  ----                ----                      -------
  Normal  Sync    62s (x2 over 106s)  nginx-ingress-controller  Scheduled for sync
```
   {{% /expand %}}

#### Verify end-to-end SSL access

Verify that the Oracle WebCenter Content domain application URLs are accessible through the `LOADBALANCER-SSLPORT`:
   ```bash     
      https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/cs
   ```

#### Deploy tls to access Administration Server

1. As `ssl-passthrough` in NGINX works on the clusterIP of the backing service instead of individual endpoints, you must expose `adminserver service` created by the WebLogic Kubernetes Operator with clusterIP.

    For example:
	
    a. Get the name of Administration Server service:
    ```bash
      $ kubectl get svc -n wccns | grep wccinfra-adminserver
    ```
    Sample output:
    ```bash
      wccinfra-adminserver  ClusterIP   None  <none>   7001/TCP,7002/TCP  7
    ```

    b. Expose the Administration Server service `wccinfra-adminserver` and use the new service name `wccinfra-adminserver-nginx-ssl`:
    ```bash
     $ kubectl expose svc wccinfra-adminserver -n wccns --name=wccinfra-adminserver-nginx-ssl --port=7002
    ```
    c. Deploy the secured ingress:
	
    Sample nginx-admin-tls.yaml:

    {{%expand "Click here to see the content of the file nginx-admin-tls.yaml" %}}
```yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wcc-admin-ingress
  namespace: wccns
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  tls:
  - hosts:
    - 'your_host_name'
    secretName: domain1-tls-cert
  rules:
  - host: 'your_host_name'
    http:
      paths:
      - path:
        pathType: ImplementationSpecific
        backend:
          service:
            name: wccinfra-adminserver-nginx-ssl
            port:
              number: 7002

```
    {{% /expand %}}

    >  Note: host is the server on which this ingress is deployed.
   
    ```bash
     $ cd ${WORKDIR}/charts/ingress-per-domain/tls
     $ kubectl create -f nginx-admin-tls.yaml
    ```
#### Verify end-to-end SSL access

Verify that the Oracle WebCenter Content Administration Server URL is accessible through the `LOADBALANCER-SSLPORT`:
```bash     
https://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-SSLPORT}/console
```
#### Uninstall ingress-nginx tls

```bash
$ cd ${WORKDIR}/charts/ingress-per-domain/tls
$ kubectl  delete -f nginx-ucm-tls.yaml
```
####  Uninstall the NGINX

```bash
//Uninstall and delete the `ingress-nginx` deployment
$ helm delete wccinfra-nginx-ingress -n wccns
  
//Uninstall NGINX
$ helm delete nginx-ingress -n wccns
```  
