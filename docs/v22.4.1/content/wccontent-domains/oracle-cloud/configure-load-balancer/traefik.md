---
title: "Traefik"
date: 2020-12-3T15:44:42-05:00
draft: false
weight: 1
pre: "<b>a. </b>"
description: "Configure the ingress-based Traefik load balancer for Oracle WebCenter Content domains."
---

This section provides information about how to install and configure the ingress-based *Traefik* load balancer (version 2.6.0 or later for production deployments) to load balance Oracle WebCenter Content domain clusters.

Follow these steps to set up Traefik as a load balancer for an Oracle WebCenter Content	domain in a Kubernetes cluster:

#### Contents
* [ Non-SSL and SSL termination](#non-ssl-and-ssl-termination)
  1. [Install the Traefik (ingress-based) load balancer](#install-the-traefik-ingress-based-load-balancer)
  1. [Configure Traefik to manage ingresses](#configure-traefik-to-manage-ingresses)
  1. [Create an Ingress for the domain](#create-an-ingress-for-the-domain)
  1. [Create a certificate and generate a Kubernetes secret](#create-a-certificate-and-generate-a-kubernetes-secret)
  1. [Create Traefik custom resource](#create-traefik-custom-resource)
  1. [Install Ingress for SSL termination configuration](#install-ingress-for-ssl-termination-configuration)
  
* [ End-to-End SSL configuration](#end-to-end-ssl-configuration)
   1. [Install the Traefik load balancer for end-to-end SSL](#install-the-traefik-load-balancer-for-end-to-end-ssl)
   1. [Configure Traefik to manage the domain](#configure-traefik-to-manage-the-domain)
   1. [Create IngressRouteTCP](#create-ingressroutetcp)

* [ Create Oracle WebCenter Content domain](#create-oracle-webcenter-content-domain)
   
* [ Verify domain application URL access](#verify-domain-application-url-access)
   1. [Verify Non-SSL access](#verify-non-ssl-access)
   1. [Verify SSL termination and end-to-end SSL access](#verify-ssl-termination-and-end-to-end-ssl-access)

* [ Uninstall Traefik](#uninstall-traefik)  


### Non-SSL and SSL termination

#### Install the Traefik (ingress-based) load balancer

1. Use Helm to install the Traefik (ingress-based) load balancer. For detailed information, see [here](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/charts/traefik/README.md).
Use the `values.yaml` file in the sample but set `kubernetes.namespaces` specifically.


   ```bash
    $ cd ${WORKDIR}
    $ kubectl create namespace traefik
    $ helm repo add traefik https://helm.traefik.io/traefik --force-update
   ```
    Sample output:
   ```bash
    "traefik" has been added to your repositories
   ```
2. Install Traefik:

   ```bash
    $ cd ${WORKDIR}
    $ helm install traefik  traefik/traefik \
         --namespace traefik \
         --values charts/traefik/values.yaml \
         --set  "kubernetes.namespaces={traefik}" \
         --set "service.type=LoadBalancer" --wait
   ```    
   {{%expand "Click here to see the sample output." %}}
   ```bash
NAME: traefik-operator
LAST DEPLOYED: Mon Jun  1 19:31:20 2020
NAMESPACE: traefik
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get Traefik load balancer IP or hostname:
 
     NOTE: It may take a few minutes for this to become available.
 
     You can watch the status by running:
 
         $ kubectl get svc traefik-operator --namespace traefik -w
 
     Once 'EXTERNAL-IP' is no longer '<pending>':
 
         $ kubectl describe svc traefik-operator --namespace traefik | grep Ingress | awk '{print $3}'
 
2. Configure DNS records corresponding to Kubernetes ingress resources to point to the load balancer IP or hostname found in step 1  
   ```
    {{% /expand %}}


   A sample `values.yaml` for deployment of Traefik 2.6.0:
   {{%expand "Click here to see values.yaml" %}}
   ```yaml
   image:
   name: traefik
   tag: 2.6.0
   pullPolicy: IfNotPresent
   ingressRoute:
   dashboard:
      enabled: true
      # Additional ingressRoute annotations (e.g. for kubernetes.io/ingress.class)
      annotations: {}
      # Additional ingressRoute labels (e.g. for filtering IngressRoute by custom labels)
      labels: {}
   providers:
   kubernetesCRD:
      enabled: true
   kubernetesIngress:
      enabled: true
      # IP used for Kubernetes Ingress endpoints
   ports:
   traefik:
      port: 9000
      expose: true
      # The exposed port for this service
      exposedPort: 9000
      # The port protocol (TCP/UDP)
      protocol: TCP
   web:
      port: 8000
      # hostPort: 8000
      expose: true
      exposedPort: 30305
      nodePort: 30305
      # The port protocol (TCP/UDP)
      protocol: TCP
      # Use nodeport if set. This is useful if you have configured Traefik in a
      # LoadBalancer
      # nodePort: 32080
      # Port Redirections
      # Added in 2.2, you can make permanent redirects via entrypoints.
      # https://docs.traefik.io/routing/entrypoints/#redirection
      # redirectTo: websecure
   websecure:
      port: 8443
   #    # hostPort: 8443
      expose: true
      exposedPort: 30443
      # The port protocol (TCP/UDP)
      protocol: TCP
      nodePort: 30443
   additionalArguments:
     - "--log.level=INFO"
   ```
   {{% /expand %}}
   

3. Verify the Traefik (load balancer) services:

   Please note the EXTERNAL-IP of the traefik-operator service.
   This is the public IP address of the load balancer that you will use to access the WebLogic Server Administration Console and WebCenter Content URLs.
   ```bash
   $ kubectl get service -n traefik
   NAME      TYPE           CLUSTER-IP   EXTERNAL-IP     PORT(S)                                          AGE
   traefik   LoadBalancer   10.96.8.30   123.456.xx.xx   9000:30734/TCP,30305:30305/TCP,30443:30443/TCP   6d23h
   ```
   To print only the Traefik EXTERNAL-IP, execute this command:
   ```bash
   $ TRAEFIK_PUBLIC_IP=`kubectl describe svc traefik --namespace traefik | grep Ingress | awk '{print $3}'`
   $ echo $TRAEFIK_PUBLIC_IP
   123.456.xx.xx
   ```
   Verify the helm charts:
   ```bash
   $ helm list -n traefik
   NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
   traefik traefik         2               2022-09-11 12:22:41.122310912 +0000 UTC deployed        traefik-10.24.3    2.8.5
   ```
      
   Verify the Traefik status and find the port number
   ```bash
    $ kubectl get all -n traefik
   ```
    {{%expand "Click here to see the sample output." %}}
   ```bash
   NAME                          READY   STATUS    RESTARTS   AGE
   pod/traefik-f9cf58697-xjhpl   1/1     Running   0          7d


   NAME              TYPE           CLUSTER-IP   EXTERNAL-IP     PORT(S)                                          AGE
   service/traefik   LoadBalancer   10.96.8.30   123.456.xx.xx   9000:30734/TCP,30305:30305/TCP,30443:30443/TCP   7d


   NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
   deployment.apps/traefik   1/1     1            1           7d

   NAME                                DESIRED   CURRENT   READY   AGE
   replicaset.apps/traefik-f9cf58697   1         1         1       7d 
   ```
   {{% /expand %}}


#### Configure Traefik to manage ingresses

Configure Traefik to manage ingresses created in this namespace, where `traefik` is the Traefik namespace and `wccns` is the namespace of the domain:
  ```bash
  $ helm upgrade traefik traefik/traefik --namespace traefik --reuse-values \
  --set "kubernetes.namespaces={traefik,wccns}"
  ```
  {{%expand "Click here to see the sample output." %}}
  ```bash
      Release "traefik" has been upgraded. Happy Helming!
      NAME: traefik
      LAST DEPLOYED: Sun Jan 17 23:43:02 2021
      NAMESPACE: traefik
      STATUS: deployed
      REVISION: 2
      TEST SUITE: None
  ```
  {{% /expand %}}

#### Create an ingress for the domain

Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress.
Sample values for default configuration are shown in the file `${WORKDIR}/charts/ingress-per-domain/values.yaml`.
By default, `type` is `TRAEFIK` , `tls` is `Non-SSL`, and `domainType` is `wccinfra`. These values can be overridden by passing values through the command line or can be edited in the sample file `values.yaml` based on the type of configuration (non-SSL or SSL).
If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. The template YAML file for the Traefik (ingress-based) load balancer is located at `${WORKDIR}/charts/ingress-per-domain/templates/traefik-ingress.yaml`

1. Install `ingress-per-domain` using Helm for non-SSL configuration:
   
   ```bash
   $ export LB_HOSTNAME=<Traefik load balancer DNS name>
   
   #OR leave it empty to point to Traefik load-balancer IP, by default
   $ export LB_HOSTNAME=''
   ```
   >  Note: Make sure that you specify DNS name to point to the Traefik load balancer hostname,
or leave it empty to point to the Traefik load-balancer IP.
   
   ```bash
    $ cd ${WORKDIR}
    $ helm install wcc-traefik-ingress  \
        charts/ingress-per-domain \
        --set type=TRAEFIK \
        --namespace wccns \
        --values charts/ingress-per-domain/values.yaml \
        --set "traefik.hostname=$LB_HOSTNAME" \
        --set tls=NONSSL
   ```
   Sample output:
   ```bash
     NAME: wcc-traefik-ingress
     LAST DEPLOYED: Sun Jan 17 23:49:09 2021
     NAMESPACE: wccns
     STATUS: deployed
     REVISION: 1
     TEST SUITE: None
   ```
#### Create a certificate and generate a Kubernetes secret
1. For secured access (SSL) to the Oracle WebCenter Content application, create a certificate :

   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=<Traefik load balancer DNS name>"
    
	#OR use the following command if you chose to leave LB_HOSTNAME empty in the previous step
    
	$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
   ```
   >  Note: Make sure that you specify DNS name to point to the Traefik load balancer hostname.
   
1. Generate a Kubernetes secret:
   ```bash
   $ kubectl -n wccns create secret tls domain1-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt 
   ```
#### Create Traefik custom resource
1. Create Traefik Middleware custom resource

   In case of SSL termination, Traefik must pass a custom header `WL-Proxy-SSL:true` to the WebLogic Server endpoints. Create the Middleware using the following command:
   ```bash
   $ cat <<EOF | kubectl apply -f -
   apiVersion: traefik.containo.us/v1alpha1
   kind: Middleware
   metadata:
     name: wls-proxy-ssl
     namespace: wccns
   spec:
     headers:
       customRequestHeaders:
          WL-Proxy-SSL: "true"
   EOF
   ```

1. Create the Traefik TLSStore custom resource.

   In case of SSL termination, Traefik should be configured to use the user-defined SSL certificate. If the user-defined SSL certificate is not configured, Traefik will create a default SSL certificate. To configure a  user-defined SSL certificate for Traefik, use the TLSStore custom resource. The Kubernetes secret created with the SSL certificate should be referenced in the TLSStore object. Run the following command to create the TLSStore:

   ```bash
   $ cat <<EOF | kubectl apply -f -
   apiVersion: traefik.containo.us/v1alpha1
   kind: TLSStore
   metadata:
     name: default
     namespace: wccns
   spec:
     defaultCertificate:
       secretName:  domain1-tls-cert   
   EOF
   ```
#### Install Ingress for SSL termination configuration
1. Install `ingress-per-domain` using Helm for SSL configuration.

   The Kubernetes secret name should be updated in the template file.

   The template file also contains the following annotations:

   ```bash    
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.middlewares: wccns-wls-proxy-ssl@kubernetescrd
   ```

   The entry point for SSL access and the Middleware name should be updated in the annotation. The Middleware name should be in the form `<namespace>-<middleware name>@kubernetescrd`.

   ```bash
    $ cd ${WORKDIR}
    $ helm install wcc-traefik-ingress  \
        charts/ingress-per-domain \
        --set type=TRAEFIK \
        --namespace wccns \
        --values charts/ingress-per-domain/values.yaml \
        --set "traefik.hostname=$LB_HOSTNAME" \
		--set "traefik.hostnameorip=$TRAEFIK_PUBLIC_IP" \
        --set tls=SSL
   ```
   Sample output:
   ```bash
     NAME: wcc-traefik-ingress
     LAST DEPLOYED: Mon Jul 20 11:44:13 2020
     NAMESPACE: wccns
     STATUS: deployed
     REVISION: 1
     TEST SUITE: None

   ```
1. Get the details of the services by the above deployed ingress:

    ```bash
     $ kubectl describe  ingress wccinfra-traefik  -n wccns
    ```   
1. To confirm that the load balancer noticed the new ingress and is successfully routing to the domain server pods, you can send a request to the URL for the "WebLogic ReadyApp framework", which should return an HTTP 200 status code, as follows:
    ```bash
     $ curl -v http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER_PORT}/weblogic/ready
     * About to connect() to abc.com port 30305 (#0)
     *   Trying 100.111.156.246...
     * Connected to abc.com (100.111.156.246) port 30305 (#0)
     > GET /weblogic/ready HTTP/1.1
     > User-Agent: curl/7.29.0
     > Host: domain1.org:30305
     > Accept: */*
     >
     < HTTP/1.1 200 OK
     < Content-Length: 0
     < Date: Thu, 03 Dec 2020 13:16:19 GMT
     < Vary: Accept-Encoding
     <
     * Connection #0 to host abc.com left intact

   ```

###  End-to-End SSL configuration

#### Install the Traefik load balancer for end-to-end SSL

1. Use Helm to install the Traefik (ingress-based) load balancer. For detailed information, see [here](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/charts/traefik/README.md).
Use the `values.yaml` file in the sample but set `kubernetes.namespaces` specifically.


   ```bash
    $ cd ${WORKDIR}
    $ kubectl create namespace traefik
    $ helm repo add traefik https://helm.traefik.io/traefik --force-update
   ```
    Sample output:
   ```bash
    "traefik" has been added to your repositories
   ```
1. Install Traefik:

   ```bash   
	$ cd ${WORKDIR}
    $ helm install traefik  traefik/traefik \
         --namespace traefik \
         --values charts/traefik/values.yaml \
         --set  "kubernetes.namespaces={traefik}" \
		 --set "service.type=LoadBalancer" \
         --wait
   ``` 
 
   {{%expand "Click here to see the sample output." %}}
   ```bash
       NAME: traefik
       LAST DEPLOYED: Sun Jan 17 23:30:20 2021
       NAMESPACE: traefik
       STATUS: deployed
       REVISION: 1
       TEST SUITE: None
   ```
    {{% /expand %}}

1. Verify the Traefik operator status and find the port number of the SSL and non-SSL services:
   ```bash
    $ kubectl get all -n traefik
   ```
    {{%expand "Click here to see the sample output." %}}
   ```bash

      NAME                                    READY   STATUS    RESTARTS   AGE
      pod/traefik-operator-676fc64d9c-skppn   1/1     Running   0          78d

      NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
      service/traefik-operator             NodePort    10.109.223.59   <none>        443:30443/TCP,80:30305/TCP   78d
      service/traefik-operator-dashboard   ClusterIP   10.110.85.194   <none>        80/TCP                       78d

      NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
      deployment.apps/traefik-operator   1/1     1            1           78d

      NAME                                          DESIRED   CURRENT   READY   AGE
      replicaset.apps/traefik-operator-676fc64d9c   1         1         1       78d
      replicaset.apps/traefik-operator-cb78c9dc9    0         0         0       78d

   ```
   {{% /expand %}}

#### Configure Traefik to manage the domain

Configure Traefik to manage the domain application service created in this namespace, where `traefik` is the Traefik namespace and `wccns` is the namespace of the domain:

```bash
$ helm upgrade traefik traefik/traefik --namespace traefik --reuse-values \
--set "kubernetes.namespaces={traefik,wccns}"
```
{{%expand "Click here to see the sample output." %}}
```bash
      Release "traefik" has been upgraded. Happy Helming!
      NAME: traefik
      LAST DEPLOYED: Sun Jan 17 23:43:02 2021
      NAMESPACE: traefik
      STATUS: deployed
      REVISION: 2
      TEST SUITE: None
```
{{% /expand %}}

#### Create IngressRouteTCP

1. To enable SSL passthrough in Traefik, you can configure a TCP router. 
   A sample YAML for `IngressRouteTCP` is available at `${WORKDIR}/charts/ingress-per-domain/tls/traefik-tls.yaml`. 
   
   >  Note: There  is a limitation with load-balancer in end-to-end SSL configuration - accessing multiple types of servers (different Managed Servers and/or Administration Server) at the same time, is currently not supported. we can access only one managed server at a time.
   
   The following should be updated in `traefik-tls.yaml`:
   * The service name and the SSL port should be updated in the Services.
   * The load balancer hostname(DNS name) should be updated in the `HostSNI` rule.

   Sample `traefik-tls.yaml`:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: wcc-ucm-routetcp
  namespace: wccns
spec:
  entryPoints:
    - websecure
  routes:
  - match: HostSNI(`<Traefik load balancer DNS name>`)
    services:
    - name: wccinfra-cluster-ucm-cluster
      port: 16201
      weight: 3
      terminationDelay: 400
  tls:
    passthrough: true   
```
>  Note: Make sure that you specify DNS name to point to the Traefik load balancer hostname,
or specify '*' to point to the Traefik load balancer IP.


1. Create the IngressRouteTCP:
```bash
cd ${WORKDIR}/charts/ingress-per-domain/tls

$ kubectl apply -f traefik-tls.yaml
```

### Create Oracle WebCenter Content domain
With the load-balancer configured, please create your domain by following the instructions documented in [Create Oracle WebCenter Content domains]({{< relref "/wccontent-domains/oracle-cloud/create-wccontent-domains" >}}), before verifying domain application URL access.

### Verify domain application URL access

#### Verify Non-SSL access

After setting up the Traefik (ingress-based) load balancer, verify that the domain application URLs are accessible through the load balancer port `30305` for HTTP access. The sample URLs for Oracle WebCenter Content domain of type `wcc` are:

```bash
http://${TRAEFIK_PUBLIC_IP}:30305/weblogic/ready
http://${TRAEFIK_PUBLIC_IP}:30305/console
http://${TRAEFIK_PUBLIC_IP}:30305/cs
http://${TRAEFIK_PUBLIC_IP}:30305/ibr
http://${TRAEFIK_PUBLIC_IP}:30305/imaging
http://${TRAEFIK_PUBLIC_IP}:30305/dc-console
http://${TRAEFIK_PUBLIC_IP}:30305/wcc

```

#### Verify SSL termination and end-to-end SSL access

After setting up the Traefik (ingress-based) load balancer, verify that the domain applications are accessible through the SSL load balancer port `30443` for HTTPS access. The sample URLs for Oracle WebCenter Content domain are:

LOADBALANCER-SSLPORT is 30443

   ```bash
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/console
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/cs
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/ibr
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/imaging
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/dc-console
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/wcc
   ```

### Uninstall Traefik

   ```bash
   $ helm delete wcc-traefik-ingress -n wccns
   
   $ helm delete traefik -n wccns
   
   $ kubectl delete namespace traefik
   ```

