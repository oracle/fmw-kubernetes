+++
title = "Traefik"
date = 2019-02-22T15:44:42-05:00
draft = false
weight = 1
pre = "<b>a. </b>"
description = "Configure the ingress-based Traefik load balancer for an Oracle WebCenter Portal domain."
+++

To load balance Oracle WebCenter Portal domain clusters, you can install the ingress-based *Traefik* load balancer (version 2.2.1 or later for production deployments) and configure it for non-SSL, SSL termination, and end-to-end SSL access of the application URL. Follow these steps to set up Traefik as a load balancer for an Oracle WebCenter Portal domain in a Kubernetes cluster:

* [ Non-SSL and SSL termination](#non-ssl-and-ssl-termination)
  1. [Install the Traefik (ingress-based) load balancer](#install-the-traefik-ingress-based-load-balancer)
  2. [Configure Traefik to manage ingresses](#configure-traefik-to-manage-ingresses)
  3. [Create an Ingress for the domain](#create-an-ingress-for-the-domain)
  4. [Verify domain application URL access](#verify-domain-application-url-access)
  5. [Uninstall the Traefik ingress](#uninstall-the-traefik-ingress)
  
* [ End-to-end SSL configuration](#end-to-end-ssl-configuration)
   1. [Install the Traefik load balancer for End-to-end SSL](#install-the-traefik-load-balancer-for-end-to-end-ssl)
   2. [Configure Traefik to manage domain](#configure-traefik-to-manage-the-domain)
   3. [Create IngressRouteTCP](#create-ingressroutetcp)
   4. [Verify end-to-end SSL access](#verify-end-to-end-ssl-access)
   5. [Uninstall Traefik](#uninstall-traefik)  

### Non-SSL and SSL termination

#### Install the Traefik (ingress-based) load balancer

1. Use Helm to install the Traefik (ingress-based) load balancer.
You can use the following `values.yaml` sample file  and set kubernetes.namespaces as required.

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ kubectl create namespace traefik
    $ helm repo add traefik https://containous.github.io/traefik-helm-chart
   ```
    Sample output:
   ```bash
    "traefik" has been added to your repositories
   ```
2. Install Traefik:

   ```bash
    $ helm install traefik  traefik/traefik \
         --namespace traefik \
         --values kubernetes/samples/scripts/charts/traefik/values.yaml \
         --set  "kubernetes.namespaces={traefik}" \
         --set "service.type=NodePort" --wait
   ```    
   {{%expand "Click here to see the sample output." %}}
   ```bash
       LAST DEPLOYED: Sun Sep 13 21:32:00 2020
       NAMESPACE: traefik
       STATUS: deployed
       REVISION: 1
       TEST SUITE: None
   ```
    {{% /expand %}}

    A sample `values.yaml` for deployment of Traefik 2.2.x looks like this:
    ```yaml
    image:
       name: traefik
       tag: 2.2.8
       pullPolicy: IfNotPresent
    ingressRoute:
      dashboard:
         enabled: true
         annotations: {}
         labels: {}
    providers:
      kubernetesCRD:
         enabled: true
      kubernetesIngress:
         enabled: true
    ports:
      traefik:
         port: 9000
         expose: true
         exposedPort: 9000
         protocol: TCP
      web:
         port: 8000
         expose: true
         exposedPort: 30305
         nodePort: 30305
         protocol: TCP
      websecure:
         port: 8443
         expose: true
         exposedPort: 30443
         protocol: TCP
         nodePort: 30443   
    ```

1. Verify the Traefik status and find the port number of the SSL and non-SSL services:
   ```bash
    $ kubectl get all -n traefik
   ```
    {{%expand "Click here to see the sample output." %}}
 ```bash
NAME                          READY   STATUS    RESTARTS   AGE
pod/traefik-f9cf58697-29dlx   1/1     Running   0          35s

NAME              TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                                          AGE
service/traefik   NodePort   10.100.113.37   <none>        9000:30070/TCP,30305:30305/TCP,30443:30443/TCP   35s

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/traefik   1/1     1            1           36s

NAME                                DESIRED   CURRENT   READY   AGE
replicaset.apps/traefik-f9cf58697   1         1         1       36s

```
   {{% /expand %}}

4. Access the Traefik dashboard through the URL `http://$(hostname -f):30070`, with the HTTP host `traefik.example.com`:

    ```bash
    $ curl -H "host: $(hostname -f)" http://$(hostname -f):30070/dashboard/
    ```
   >  Note: Make sure that you specify a fully qualified node name for `$(hostname -f)`

#### Configure Traefik to manage ingresses

Configure Traefik to manage ingresses created in this namespace. In the following sample, `traefik` is the Traefik namespace and `wcpns` is the namespace of the domain:
```bash
$ helm upgrade traefik traefik/traefik \
--reuse-values \
--namespace traefik \
--set "kubernetes.namespaces={traefik,wcpns}" \
--wait
```
  {{%expand "Click here to see the sample output." %}}
```bash
Release "traefik" has been upgraded. Happy Helming!
NAME: traefik
LAST DEPLOYED: Tue Jan 12 04:33:15 2021
NAMESPACE: traefik
STATUS: deployed
REVISION: 2
TEST SUITE: None
```
  {{% /expand %}}

#### Create an ingress for the domain

Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress.
Sample values for default configuration are shown in the file `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/values.yaml`.
By default, `type` is `TRAEFIK` , `tls` is `Non-SSL`. You can override these values by passing values through the command line or edit them in the sample `values.yaml` file based on the type of configuration (non-SSL or SSL).
If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. The template YAML file for the Traefik (ingress-based) load balancer is located at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/traefik-ingress.yaml`

1. Install `ingress-per-domain` using Helm for non-SSL configuration:

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install wcp-traefik-ingress  \
        kubernetes/samples/charts/ingress-per-domain \
        --namespace wcpns \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
        --set "traefik.hostname=$(hostname -f)"
   ```
   Sample output:
   ```bash
     NAME: wcp-traefik-ingress
     LAST DEPLOYED: Mon Jul 20 11:44:13 2020
     NAMESPACE: wcpns
     STATUS: deployed
     REVISION: 1
     TEST SUITE: None
   ```

1. For secured access (SSL) to the Oracle WebCenter Portal application, create a certificate and generate a Kubernetes secret:

   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
    $ kubectl -n wcpns create secret tls wcpinfra-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```
   >  Note: The value of `CN` is the host on which this ingress is to be deployed.

1. Create a Traefik Middleware custom resource

   In case of SSL termination, Traefik must pass a custom header `WL-Proxy-SSL:true` to the WebLogic Server endpoints. Create the Middleware using the following command:
   ```bash
   $ cat <<EOF | kubectl apply -f -
   apiVersion: traefik.containo.us/v1alpha1
   kind: Middleware
   metadata:
     name: wls-proxy-ssl
     namespace: wcpns
   spec:
     headers:
       customRequestHeaders:
          WL-Proxy-SSL: "true"
   EOF
   ```

1. Create the Traefik TLSStore custom resource.

   In case of SSL termination, Traefik should be configured to use the user-defined SSL certificate. If the user-defined SSL certificate is not configured, Traefik creates a default SSL certificate. To configure a  user-defined SSL certificate for Traefik, use the TLSStore custom resource. The Kubernetes secret created with the SSL certificate should be referenced in the TLSStore object. Run the following command to create the TLSStore:

   ```bash
   $ cat <<EOF | kubectl apply -f -
   apiVersion: traefik.containo.us/v1alpha1
   kind: TLSStore
   metadata:
     name: default
     namespace: wcpns
   spec:
     defaultCertificate:
       secretName:  wcpinfra-tls-cert   
   EOF
   ```
1. Install `ingress-per-domain` using Helm for SSL configuration.

   The Kubernetes secret name should be updated in the template file.

   The template file also contains the following annotations:

   ```bash    
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.middlewares: wcpns-wls-proxy-ssl@kubernetescrd
   ```

   The entry point for SSL access and the Middleware name should be updated in the annotation. The Middleware name should be in the form `<namespace>-<middleware name>@kubernetescrd`.

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install wcp-traefik-ingress  \
        kubernetes/samples/charts/ingress-per-domain \
        --namespace wcpns \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
        --set "traefik.hostname=$(hostname -f)" \
        --set tls=SSL
   ```
   Sample output:
   ```bash
     NAME: wcp-traefik-ingress
     LAST DEPLOYED: Mon Jul 20 11:44:13 2020
     NAMESPACE: wcpns
     STATUS: deployed
     REVISION: 1
     TEST SUITE: None

   ```
1. For non-SSL access to the Oracle WebCenter Portal application, get the details of the services by the ingress:

   ```bash
     $ kubectl describe ingress wcp-domain-traefik -n wcpns
   ```
    {{%expand "Click here to see all services supported by the above deployed ingress." %}}

  ```bash
 Name:             wcp-domain-traefik
 Namespace:        wcpns
 Address:
 Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
 Rules:
   Host                                          Path  Backends
   ----                                          ----  --------
  www.example.com
                                                 /webcenter   wcp-domain-cluster-wcp-cluster:8888 (10.244.0.52:8888,10.244.0.53:8888)
                                                 /console     wcp-domain-adminserver:7001 (10.244.0.51:7001)
                                                 /rsscrawl    wcp-domain-cluster-wcp-cluster:8888 (10.244.0.52:8888,10.244.0.53:8888)
                                                 /rest        wcp-domain-cluster-wcp-cluster:8888 (10.244.0.52:8888,10.244.0.53:8888)
                                                 /webcenterhelp    wcp-domain-cluster-wcp-cluster:8888 (10.244.0.52:8888,10.244.0.53:8888)        
                                                 /em          wcp-domain-adminserver:7001 (10.244.0.51:7001)
 Annotations:                                    kubernetes.io/ingress.class: traefik
                                                 meta.helm.sh/release-name: wcp-traefik-ingress
                                                 meta.helm.sh/release-namespace: wcpns
 Events:                                         <none>
  ```
   {{% /expand %}}

1. For SSL access to the Oracle WebCenter Portal application, get the details of the services by the above deployed ingress:

    ```bash
     $ kubectl describe ingress wcp-domain-traefik -n wcpns
    ```
    {{%expand "Click here to see all services supported by the above deployed ingress." %}}
 ```
Name:             wcp-domain-traefik
Namespace:        wcpns
Address:
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
TLS:
  wcpinfra-tls-cert terminates www.example.com
Rules:
  Host                                          Path  Backends
  ----                                          ----  --------
  www.example.com
                                                /webcenter   wcp-domain-cluster-wcp-cluster:8888 (10.244.0.52:8888,10.244.0.53:8888)
                                                /console     wcp-domain-adminserver:7001 (10.244.0.51:7001)
                                                /rsscrawl    wcp-domain-cluster-wcp-cluster:8888 (10.244.0.52:8888,10.244.0.53:8888)
                                                /rest        wcp-domain-cluster-wcp-cluster:8888 (10.244.0.52:8888,10.244.0.53:8888)
                                                /webcenterhelp    wcp-domain-cluster-wcp-cluster:8888 (10.244.0.52:8888,10.244.0.53:8888)
                                                /em          wcp-domain-adminserver:7001 (10.244.0.51:7001)
Annotations:                                    kubernetes.io/ingress.class: traefik
                                                meta.helm.sh/release-name: wcp-traefik-ingress
                                                meta.helm.sh/release-namespace: wcpns
                                                traefik.ingress.kubernetes.io/router.entrypoints: websecure
                                                traefik.ingress.kubernetes.io/router.middlewares: wcpns-wls-proxy-ssl@kubernetescrd
                                                traefik.ingress.kubernetes.io/router.tls: true
Events:                                         <none>
```
 {{% /expand %}}

1. To confirm that the load balancer noticed the new ingress and is successfully routing to the domain server pods, you can send a request to the URL for the WebLogic ReadyApp framework, which should return an HTTP 200 status code, as follows:
    ```bash
     $ curl -v http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER_PORT}/weblogic/ready
     *   Trying 149.87.129.203...
     > GET http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER_PORT}/weblogic/ready HTTP/1.1
     > User-Agent: curl/7.29.0
     > Accept: */*
     > Proxy-Connection: Keep-Alive
     > host: $(hostname -f)
     >
     < HTTP/1.1 200 OK
     < Date: Sat, 14 Mar 2020 08:35:03 GMT
     < Vary: Accept-Encoding
     < Content-Length: 0
     < Proxy-Connection: Keep-Alive
     <
     * Connection #0 to host localhost left intact
   ```
#### Verify domain application URL access

##### For non-SSL configuration  

After setting up the Traefik (ingress-based) load balancer, verify that the domain application URLs are accessible through the non-SSL load balancer port `30305` for HTTP access. The sample URLs for Oracle WebCenter Portal domain  are:

```bash
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/webcenter
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/rsscrawl
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/rest
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/webcenterhelp

```

##### For SSL configuration

After setting up the Traefik (ingress-based) load balancer, verify that the domain applications are accessible through the SSL load balancer port `30443` for HTTPS access. The sample URLs for Oracle WebCenter Portal domain  are:

```bash
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenter
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/console
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/em
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/rsscrawl
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/rest
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenterhelp

```

#### Uninstall the Traefik ingress

Uninstall and delete the ingress deployment:

```bash
$ helm delete wcp-traefik-ingress  -n wcpns
```


###  End-to-end SSL configuration

#### Install the Traefik load balancer for end-to-end SSL

1. Use Helm to install the Traefik (ingress-based) load balancer. You can use the `values.yaml` sample file and set kubernetes.namespaces as required.

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ kubectl create namespace traefik
    $ helm repo add traefik https://containous.github.io/traefik-helm-chart
   ```
    Sample output:
   ```bash
    "traefik" has been added to your repositories
   ```
1. Install Traefik:

   ```bash
   $ helm install traefik  traefik/traefik \
    --namespace traefik \
    --values kubernetes/samples/scripts/charts/traefik/values.yaml \
    --set  "kubernetes.namespaces={traefik}" \
    --set "service.type=NodePort" --wait
   ```    
   {{%expand "Click here to see the sample output." %}}
   ```bash
       LAST DEPLOYED: Sun Sep 13 21:32:00 2020
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

      NAME                           READY   STATUS    RESTARTS   AGE
      pod/traefik-845f5d6dbb-swb96   1/1     Running   0          32s

      NAME              TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                                          AGE
      service/traefik   NodePort       10.99.52.249   <none>        9000:31288/TCP,30305:30305/TCP,30443:30443/TCP   32s

      NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
      deployment.apps/traefik   1/1     1            1           33s

      NAME                                 DESIRED   CURRENT   READY   AGE
      replicaset.apps/traefik-845f5d6dbb   1         1         1       33s

   ```
   {{% /expand %}}

1. Access the Traefik dashboard through the URL `http://$(hostname -f):31288`, with the HTTP host `traefik.example.com`:

    ```bash
    $ curl -H "host: $(hostname -f)" http://$(hostname -f):31288/dashboard/
    ```
   >  Note: Make sure that you specify a fully qualified node name for `$(hostname -f)`.

#### Configure Traefik to manage the domain

Configure Traefik to manage the domain application service created in this namespace. In the following sample, `traefik` is the Traefik namespace and `wcpns` is the namespace of the domain:
```bash
$ helm upgrade traefik traefik/traefik --namespace traefik --reuse-values \
--set "kubernetes.namespaces={traefik,wcpns}"
```
  {{%expand "Click here to see the sample output." %}}
    Release "traefik" has been upgraded. Happy Helming!
    NAME: traefik
    LAST DEPLOYED: Sun Sep 13 21:32:12 2020
    NAMESPACE: traefik
    STATUS: deployed
    REVISION: 2
    TEST SUITE: None
    
  {{% /expand %}}

#### Create IngressRouteTCP
1. For each backend service, create different ingresses, as Traefik does not support multiple paths or rules with annotation `ssl-passthrough`. For example, for `wcp-domain-adminserver` and `wcp-domain-cluster-wcp-cluster,` different ingresses must be created.
1. To enable SSL passthrough in Traefik, you can configure a TCP router. A sample YAML for `IngressRouteTCP` is available at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/tls/traefik-tls.yaml`. The following should be updated in `traefik-tls.yaml`:
   * The service name and the SSL port should be updated in the `services`.
   * The load balancer host name should be updated in the `HostSNI` rule.

   Sample `traefik-tls.yaml`:
   ```yaml
   apiVersion: traefik.containo.us/v1alpha1
   kind: IngressRouteTCP
   metadata:
     name: wcp-domain-cluster-routetcp
     namespace: wcpns
   spec:
     entryPoints:
       - websecure
     routes:
     - match: HostSNI(`${LOADBALANCER_HOSTNAME}`)
       services:
       - name: wcp-domain-cluster-wcp-cluster
         port: 8888
         weight: 3
         TerminationDelay: 400
     tls:
       passthrough: true
   ```
1. Create the IngressRouteTCP:
   ```bash
   $ kubectl apply -f traefik-tls.yaml
   ```

#### Verify end-to-end SSL access

Verify the access to application URLs exposed through the configured service. The configured WCP cluster service enables you to access the following WCP domain URLs:
   ```bash
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenter
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/rsscrawl
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/rest
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/webcenterhelp

   ```

#### Uninstall Traefik

   ```bash
   $ helm delete traefik -n traefik
   $ cd weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/tls
   $ kubectl delete -f traefik-tls.yaml
   ```
