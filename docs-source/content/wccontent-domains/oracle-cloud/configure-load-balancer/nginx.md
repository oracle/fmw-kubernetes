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

#### Contents
* [ Non-SSL and SSL termination](#non-ssl-and-ssl-termination)
  1. [Install the NGINX load balancer](#install-the-nginx-load-balancer)
  2. [Configure NGINX to manage ingresses](#configure-nginx-to-manage-ingresses)
  3. [Create a certificate and generate a Kubernetes secret](#create-a-certificate-and-generate-a-kubernetes-secret)
  4. [Install Ingress for SSL termination configuration](#install-ingress-for-ssl-termination-configuration)
  
* [ End-to-End SSL configuration](#end-to-end-ssl-configuration)
  1. [Install the NGINX load balancer for end-to-end SSL](#install-the-nginx-load-balancer-for-end-to-end-ssl)
  2. [Deploy tls to access individual Managed Servers](#deploy-tls-to-access-individual-managed-servers)
  3. [Deploy tls to access Administration Server](#deploy-tls-to-access-administration-server)
  4. [Uninstall ingress-nginx tls](#uninstall-ingress-nginx-tls)

* [ Create Oracle WebCenter Content domain](#create-oracle-webcenter-content-domain)

* [ Verify domain application URL access](#verify-domain-application-url-access)
   1. [Verify Non-SSL access](#verify-non-ssl-access)
   1. [Verify SSL termination and end-to-end SSL access](#verify-ssl-termination-and-end-to-end-ssl-access)

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
	       --set controller.service.type=LoadBalancer \
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

   Please note the EXTERNAL-IP of the nginx-controller service.
   This is the public IP address of the load balancer that you will use to access the WebLogic Server Administration Console and WebCenter Content URLs.
   >  Note: It may take a few minutes for the LoadBalancer IP(EXTERNAL-IP) to be available.
   ```bash
   $ kubectl --namespace wccns get services | grep ingress-nginx-controller
   ```
   Sample output:

   ```bash
   NAME                                   TYPE         CLUSTER-IP   EXTERNAL-IP     PORT(S)   
   nginx-ingress-ingress-nginx-controller LoadBalancer 10.96.180.215 144.24.xx.xx    80:31339/TCP,443:32278/TCP
   ```
   To print only the NGINX EXTERNAL-IP, execute this command:
   ```bash
   NGINX_PUBLIC_IP=`kubectl describe svc nginx-ingress-ingress-nginx-controller --namespace wccns | grep Ingress | awk '{print $3}'`
   
   $ echo $NGINX_PUBLIC_IP   
   144.24.xx.xx
   ```
   Verify the helm charts:
   ```bash
   $ helm list -A
   NAME          NAMESPACE REVISION  UPDATED      STATUS      CHART                APP VERSION
   nginx-ingress  wccns    1         2022-05-13  deployed   ingress-nginx-4.2.5   1.3.1
   ```

#### Configure NGINX to manage ingresses

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress. Sample values for default configuration are shown in the file `${WORKDIR}/charts/ingress-per-domain/values.yaml`. By default, `type` is `TRAEFIK`, `tls` is `Non-SSL`, and `domainType` is `wccinfra`. These values can be overridden by passing values through the command line or can be edited in the sample file `values.yaml`. If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. Update the template YAML file for the NGINX load balancer located at `${WORKDIR}/charts/ingress-per-domain/templates/nginx-ingress.yaml`

   Install `ingress-per-domain` using Helm for non-SSL configuration:
   ```bash
   $ export LB_HOSTNAME=<NGINX load balancer DNS name>
   
   #OR leave it empty to point to NGINX load-balancer IP, by default
   $ export LB_HOSTNAME=''
   ```
   >  Note: Make sure that you specify DNS name to point to the NGINX load balancer hostname,
or leave it empty to point to the NGINX load balancer IP.
   
   ```bash
    $ cd ${WORKDIR}
    $ helm install wccinfra-nginx-ingress charts/ingress-per-domain \
        --namespace wccns \
        --values charts/ingress-per-domain/values.yaml \
        --set "nginx.hostname=$LB_HOSTNAME" \
        --set type=NGINX \
        --set tls=NONSSL
   ```


   Sample output:
   ```bash
    NAME: wccinfra-nginx-ingress
    LAST DEPLOYED: Tue May 10 10:37:12 2022
    NAMESPACE: wccns
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
   ```

#### Create a certificate and generate a Kubernetes secret

1. For **secured access (SSL)** to the Oracle WebCenter Content application, create a certificate:
   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=<NGINX load balancer DNS name>"

    #OR use the following command if you chose to leave LB_HOSTNAME empty in the previous step
	
	$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
   ```
   >  Note: Make sure that you specify DNS name to point to the NGINX load balancer hostname.
   
1. Generate a Kubernetes secret:
   ```bash
   $ kubectl -n wccns create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt 
   ```
#### Install Ingress for SSL termination configuration    
1. Install `ingress-per-domain` using Helm for SSL configuration:

   ```bash
    $ cd ${WORKDIR}
    $ helm install wccinfra-nginx-ingress charts/ingress-per-domain \
        --namespace wccns \
        --values charts/ingress-per-domain/values.yaml \
        --set "nginx.hostname=$LB_HOSTNAME" \
		--set "nginx.hostnameorip=$NGINX_PUBLIC_IP" \
        --set type=NGINX --set tls=SSL
   ```
   Sample output:

   ```bash
    NAME: wccinfra-nginx-ingress
    LAST DEPLOYED: Tue May 10 10:37:12 2022
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
Address:          144.24.xx.xx
Default backend:  default-http-backend:80 (<none>)
Rules:
  Host  Path  Backends
  ----  ----  --------
  *
        /console                 wccinfra-adminserver:7001 (10.244.2.117:7001)
        /em                      wccinfra-adminserver:7001 (10.244.2.117:7001)
        /wls-exporter            wccinfra-adminserver:7001 (10.244.2.117:7001)
        /cs                      wccinfra-cluster-ucm-cluster:16200 (10.244.2.118:16200,10.244.2.120:16200)
        /adfAuthentication       wccinfra-cluster-ucm-cluster:16200 (10.244.2.118:16200,10.244.2.120:16200)
        /_ocsh                   wccinfra-cluster-ucm-cluster:16200 (10.244.2.118:16200,10.244.2.120:16200)
        /_dav                    wccinfra-cluster-ucm-cluster:16200 (10.244.2.118:16200,10.244.2.120:16200)
        /idcws                   wccinfra-cluster-ucm-cluster:16200 (10.244.2.118:16200,10.244.2.120:16200)
        /idcnativews             wccinfra-cluster-ucm-cluster:16200 (10.244.2.118:16200,10.244.2.120:16200)
        /wsm-pm                  wccinfra-cluster-ucm-cluster:16200 (10.244.2.118:16200,10.244.2.120:16200)
        /ibr                     wccinfra-cluster-ibr-cluster:16250 (10.244.2.119:16250)
        /ibr/adfAuthentication   wccinfra-cluster-ibr-cluster:16250 (10.244.2.119:16250)
        /weblogic/ready          wccinfra-cluster-ucm-cluster:16200 (10.244.2.118:16200,10.244.2.120:16200)
Annotations:
  nginx.ingress.kubernetes.io/affinity-mode:  persistent
  kubernetes.io/ingress.class:                nginx
  nginx.ingress.kubernetes.io/affinity:       cookie
Events:
  Type    Reason  Age                  From                      Message
  ----    ------  ----                 ----                      -------
  Normal  Sync    8m3s (x2 over 8m5s)  nginx-ingress-controller  Scheduled for sync
```
{{% /expand %}}

###  End-to-End SSL configuration

#### Install the NGINX load balancer for end-to-end SSL

1. For **secured access (SSL)** to the Oracle WebCenter Content application, create a certificate and generate secrets: [click here](#create-a-certificate-and-generate-a-kubernetes-secret)

1. Deploy the ingress-nginx controller by using Helm on the domain namespace:

    ```bash
    helm install nginx-ingress -n wccns \
    --set controller.extraArgs.default-ssl-certificate=wccns/domain1-tls-cert \
    --set controller.service.type=LoadBalancer \
    --set controller.admissionWebhooks.enabled=false \
    --set controller.extraArgs.enable-ssl-passthrough=true \
    ingress-nginx/ingress-nginx	 
	```	
   {{%expand "Click here to see the sample output." %}}
```bash
NAME: nginx-ingress
LAST DEPLOYED: Mon Sep 19 11:08:16 2022
NAMESPACE: wccns
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace wccns get services -o wide -w nginx-ingress-ingress-nginx-controller'
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
   NAME                                   TYPE         CLUSTER-IP   EXTERNAL-IP     PORT(S)   
   nginx-ingress-ingress-nginx-controller LoadBalancer 10.96.180.215 144.24.xx.xx    80:31339/TCP,443:32278/TCP
   ```
   To print only the NGINX EXTERNAL-IP, execute this command:
   ```bash
   NGINX_PUBLIC_IP=`kubectl describe svc nginx-ingress-ingress-nginx-controller --namespace wccns | grep Ingress | awk '{print $3}'`
   
   $ echo $NGINX_PUBLIC_IP   
   144.24.xx.xx
   ```

#### Deploy tls to access individual Managed Servers

1. Deploy tls to securely access the services. Only one application can be configured with `ssl-passthrough`. A sample tls file for NGINX is shown below for the service `wccinfra-cluster-ucm-cluster` and port `16201`. All the applications running on port `16201` can be securely accessed through this ingress. For each backend service, create different ingresses as NGINX does not support multiple path/rules with annotation `ssl-passthrough`. That is, for `wccinfra-cluster-ucm-cluster`, `wccinfra-cluster-ibr-cluster`, `wccinfra-cluster-ipm-cluster`, `wccinfra-cluster-capture-cluster`, `wccinfra-cluster-wccadf-cluster` and `wccinfra-adminserver`, different ingresses must be created.
   
   >  Note: There  is a limitation with load-balancer in end-to-end SSL configuration - accessing multiple types of servers (different Managed Servers and/or Administration Server) at the same time, is currently not supported. we can access only one managed server at a time.
  
   ```bash
   $ cd ${WORKDIR}/charts/ingress-per-domain/tls
   ```
Sample nginx-ucm-tls.yaml:
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
    - '$NGINX_PUBLIC_IP'
    secretName: domain1-tls-cert
  rules:
  - host: '<NGINX load balancer DNS name>'
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
>  Note: Make sure that you specify DNS name to point to the NGINX load balancer hostname.

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
    - '$NGINX_PUBLIC_IP'
    secretName: domain1-tls-cert
  rules:
  - host: '<NGINX load balancer DNS name>'
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
>  Note: Make sure that you specify DNS name to point to the NGINX load balancer hostname.

   ```bash
   $ cd ${WORKDIR}/charts/ingress-per-domain/tls
   $ kubectl create -f nginx-admin-tls.yaml
   ```

#### Uninstall ingress-nginx tls

  ```bash
  $ cd ${WORKDIR}/charts/ingress-per-domain/tls
  $ kubectl delete -f nginx-ucm-tls.yaml
  ```

### Create Oracle WebCenter Content domain
With the load-balancer configured, please create your domain by following the instructions documented in [Create Oracle WebCenter Content domains]({{< relref "/wccontent-domains/oracle-cloud/create-wccontent-domains" >}}), before verifying domain application URL access.

### Verify domain application URL access

#### Verify Non-SSL access
Verify that the Oracle WebCenter Content domain application URLs are accessible through the `LOADBALANCER-HOSTNAME`:

```bash
  http://${LOADBALANCER-HOSTNAME}/weblogic/ready
  http://${LOADBALANCER-HOSTNAME}/console
  http://${LOADBALANCER-HOSTNAME}/em
  http://${LOADBALANCER-HOSTNAME}/cs
  http://${LOADBALANCER-HOSTNAME}/ibr
  http://${LOADBALANCER_HOSTNAME}/imaging
  http://${LOADBALANCER_HOSTNAME}/dc-console
  http://${LOADBALANCER_HOSTNAME}/wcc  
```
#### Verify SSL termination and end-to-end SSL access
Verify that the Oracle WebCenter Content domain application URLs are accessible through the `LOADBALANCER-HOSTNAME`:

```bash
  https://${LOADBALANCER-HOSTNAME}/weblogic/ready
  https://${LOADBALANCER-HOSTNAME}/console
  https://${LOADBALANCER-HOSTNAME}/em
  https://${LOADBALANCER-HOSTNAME}/cs
  https://${LOADBALANCER-HOSTNAME}/ibr
  https://${LOADBALANCER_HOSTNAME}/imaging
  https://${LOADBALANCER_HOSTNAME}/dc-console
  https://${LOADBALANCER_HOSTNAME}/wcc
```

### Uninstall the NGINX

Uninstall and delete the `ingress-nginx` deployment:

```bash
//Uninstall and delete the `ingress-nginx` deployment
$ helm delete wccinfra-nginx-ingress -n wccns

//Uninstall NGINX
$ helm delete nginx-ingress -n wccns
```