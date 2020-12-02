---
title: "Traefik"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 1
pre: "<b>a. </b>"
description: "Configure the ingress-based Traefik load balancer for Oracle SOA Suite domains."
---

This section provides information about how to install and configure the ingress-based *Traefik* load balancer (version 2.2.1 or later for production deployments) to load balance Oracle SOA Suite domain clusters. You can configure Traefik for non-SSL and SSL termination access of the application URL.

Follow these steps to set up Traefik as a load balancer for an Oracle SOA Suite domain in a Kubernetes cluster:

* [ Non-SSL and SSL termination](#non-ssl-and-ssl-termination)
  1. [Install the Traefik (ingress-based) load balancer](#install-the-traefik-ingress-based-load-balancer)
  2. [Configure Traefik to manage ingresses](#configure-traefik-to-manage-ingresses)
  3. [Create an Ingress for the domain](#create-an-ingress-for-the-domain)
  4. [Verify domain application URL access](#verify-domain-application-url-access)
  5. [Uninstall the Traefik ingress](#uninstall-the-traefik-ingress)

* [ End-to-end SSL configuration](#end-to-end-ssl-configuration)
   1. [Install the Traefik load balancer for End-to-end SSL](#install-the-traefik-load-balancer-for-end-to-end-ssl)
   2. [Configure Traefik to manage domain](#configure-traefik-to-manage-domain)
   3. [Create IngressRouteTCP](#[create-ingressroutetcp)
   4. [Verify end-to-end SSL access](#verify-end-to-end-ssl-access)
   5. [Uninstall Traefik](#uninstall-traefik)


### Non-SSL and SSL termination

#### Install the Traefik (ingress-based) load balancer

1. Use Helm to install the Traefik (ingress-based) load balancer.
Use the `values.yaml` file in the sample but set `kubernetes.namespaces` specifically.


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

    A sample `values.yaml` for deployment of Traefik 2.2.x:
   ```yaml
   image:
   name: traefik
   tag: 2.2.8
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
   ```

1. Verify the Traefik status and find the port number of the SSL and non-SSL services:
   ```bash
    $ kubectl get all -n traefik
   ```
    {{%expand "Click here to see the sample output." %}}
   ```bash

      NAME                           READY   STATUS    RESTARTS   AGE
      pod/traefik-845f5d6dbb-swb96   1/1     Running   0          32s

      NAME              TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                                          AGE
      service/traefik   LoadBalancer   10.99.52.249   <pending>     9000:31288/TCP,30305:30305/TCP,30443:30443/TCP   32s

      NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
      deployment.apps/traefik   1/1     1            1           33s

      NAME                                 DESIRED   CURRENT   READY   AGE
      replicaset.apps/traefik-845f5d6dbb   1         1         1       33s

   ```
   {{% /expand %}}

4. Access the Traefik dashboard through the URL `http://$(hostname -f):31288`, with the HTTP host `traefik.example.com`:

    ```bash
    $ curl -H "host: $(hostname -f)" http://$(hostname -f):31288/dashboard/
    ```
   >  Note: Make sure that you specify a fully qualified node name for `$(hostname -f)`

#### Configure Traefik to manage ingresses

Configure Traefik to manage ingresses created in this namespace, where `traefik` is the Traefik namespace and `soans` is the namespace of the domain:
  ```bash
      $ helm upgrade traefik traefik/traefik --namespace traefik     --reuse-values \
      --set "kubernetes.namespaces={traefik,soans}"
  ```
  {{%expand "Click here to see the sample output." %}}
  ```bash
      Release "traefik" has been upgraded. Happy Helming!
      NAME: traefik
      LAST DEPLOYED: Sun Sep 13 21:32:12 2020
      NAMESPACE: traefik
      STATUS: deployed
      REVISION: 2
      TEST SUITE: None
  ```
  {{% /expand %}}

#### Create an ingress for the domain

Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress.
Sample values for default configuration are shown in the file `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/values.yaml`.
By default, `type` is `TRAEFIK` , `tls` is `Non-SSL`, and `domainType` is `soa`. These values can be overridden by passing values through the command line or can be edited in the sample file `values.yaml` based on the type of configuration (non-SSL or SSL).
If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. The template YAML file for the Traefik (ingress-based) load balancer is located at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/traefik-ingress.yaml`

1. Install `ingress-per-domain` using Helm for non-SSL configuration:

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install soa-traefik-ingress  \
        kubernetes/samples/charts/ingress-per-domain \
        --namespace soans \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
        --set "traefik.hostname=$(hostname -f)"
   ```
   Sample output:
   ```bash
     NAME: soa-traefik-ingress
     LAST DEPLOYED: Mon Jul 20 11:44:13 2020
     NAMESPACE: soans
     STATUS: deployed
     REVISION: 1
     TEST SUITE: None
   ```

1. For secured access (SSL) to the Oracle SOA Suite application, create a certificate and generate a Kubernetes secret:

   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
    $ kubectl -n soans create secret tls soainfra-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
   ```

1. Create Traefik Middleware custom resource

   In case of SSL termination, Traefik must pass a custom header `WL-Proxy-SSL:true` to the WebLogic Server endpoints. Create the Middleware using the following command:
   ```bash
   $ cat <<EOF | kubectl apply -f -
   apiVersion: traefik.containo.us/v1alpha1
   kind: Middleware
   metadata:
     name: wls-proxy-ssl
     namespace: soans
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
     namespace: soans
   spec:
     defaultCertificate:
       secretName:  soainfra-tls-cert   
   EOF
   ```

1. Install `ingress-per-domain` using Helm for SSL configuration.

   The Kubernetes secret name should be updated in the template file.

   The template file also contains the following annotations:

   ```bash    
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.middlewares: soans-wls-proxy-ssl@kubernetescrd
   ```

   The entry point for SSL access and the Middleware name should be updated in the annotation. The Middleware name should be in the form `<namespace>-<middleware name>@kubernetescrd`.

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install soa-traefik-ingress  \
        kubernetes/samples/charts/ingress-per-domain \
        --namespace soans \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
        --set "traefik.hostname=$(hostname -f)" \
        --set tls=SSL
   ```
   Sample output:
   ```bash
     NAME: soa-traefik-ingress
     LAST DEPLOYED: Mon Jul 20 11:44:13 2020
     NAMESPACE: soans
     STATUS: deployed
     REVISION: 1
     TEST SUITE: None

   ```
1. For **non-SSL access** to the Oracle SOA Suite application, get the details of the services by the ingress:

   ```bash
     $ kubectl describe ingress soainfra-traefik -n soans
   ```
    {{%expand "Click here to see all services supported by the above deployed ingress." %}}

   ```bash
     Name:             soainfra-traefik
     Namespace:        soans
     Address:
     Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
     Rules:
        Host                                                   Path  Backends
        ----                                                   ----  --------
        www.example.com
                                                              /console                   soainfra-adminserver:7001 (10.244.0.45:7001)
                                                              /em                        soainfra-adminserver:7001 (10.244.0.45:7001)
                                                              /weblogic/ready            soainfra-adminserver:7001 (10.244.0.45:7001)
                                                                                         soainfra-cluster-soa-cluster:8001    (10.244.0.46:8001,10.244.0.47:8001)
                                                               /soa-infra                 soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
                                                               /soa/composer              soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
                                                               /integration/worklistapp   soainfra-cluster-soa-cluster:8001 (10.244.0.46:8001,10.244.0.47:8001)
       Annotations:                                             kubernetes.io/ingress.class: traefik
       Events:                                                  <none>

   ```
   {{% /expand %}}

1. For **SSL access** to the Oracle SOA Suite application, get the details of the services by the above deployed ingress:

    ```bash
     $ kubectl describe ingress soainfra-traefik -n soans
    ```
   {{%expand "Click here to see all services supported by the above deployed ingress." %}}
      ```
      Name:             soainfra-traefik
      Namespace:        soans
      Address:
      Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
      TLS:
      soainfra-tls-cert terminates www.example.com
      Rules:
      Host                    Path  Backends
      ----                    ----  --------
      www.example.com
                              /console                   soainfra-adminserver:7001 ()
                              /em                        soainfra-adminserver:7001 ()
                              /weblogic/ready            soainfra-adminserver:7001 ()
                                                         soainfra-cluster-soa-cluster:8001 ()
                              /soa-infra                 soainfra-cluster-soa-cluster:8001 ()
                              /soa/composer              soainfra-cluster-soa-cluster:8001 ()
                              /integration/worklistapp   soainfra-cluster-soa-cluster:8001 ()
      Annotations:              kubernetes.io/ingress.class: traefik
                              meta.helm.sh/release-name: soa-traefik-ingress
                              meta.helm.sh/release-namespace: soans
                              traefik.ingress.kubernetes.io/router.entrypoints: websecure
                              traefik.ingress.kubernetes.io/router.middlewares: soans-wls-proxy-ssl@kubernetescrd
                              traefik.ingress.kubernetes.io/router.tls: true
      Events:                   <none>
      ```
   {{% /expand %}}

1. To confirm that the load balancer noticed the new ingress and is successfully routing to the domain server pods, you can send a request to the URL for the "WebLogic ReadyApp framework", which should return an HTTP 200 status code, as follows:
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

After setting up the Traefik (ingress-based) load balancer, verify that the domain application URLs are accessible through the non-SSL load balancer port `30305` for HTTP access. The sample URLs for Oracle SOA Suite domain of type `soa` are:

```bash
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/weblogic/ready
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/soa-infra
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/soa/composer
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/integration/worklistapp
```

##### For SSL configuration

After setting up the Traefik (ingress-based) load balancer, verify that the domain applications are accessible through the SSL load balancer port `30443` for HTTPS access. The sample URLs for Oracle SOA Suite domain of type `soa` are:

```bash
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/weblogic/ready
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/console
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/em
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/soa-infra
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/soa/composer
    https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/integration/worklistapp
```

#### Uninstall the Traefik ingress

Uninstall and delete the ingress deployment:

```bash
$ helm delete soa-traefik-ingress  -n soans
```

###  End-to-end SSL configuration

#### Install the Traefik load balancer for end-to-end SSL

1. Use Helm to install the Traefik (ingress-based) load balancer.
Use the `values.yaml` file in the sample but set `kubernetes.namespaces` specifically.


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
    --values kubernetes/samples/charts/traefik/values.yaml \
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
      service/traefik   LoadBalancer   10.99.52.249   <pending>     9000:31288/TCP,30305:30305/TCP,30443:30443/TCP   32s

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

Configure Traefik to manage the domain application service created in this namespace, where `traefik` is the Traefik namespace and `soans` is the namespace of the domain:
```bash
      $ helm upgrade traefik traefik/traefik --namespace traefik     --reuse-values \
         --set "kubernetes.namespaces={traefik,soans}"
```
{{%expand "Click here to see the sample output." %}}
```bash
      Release "traefik" has been upgraded. Happy Helming!
      NAME: traefik
      LAST DEPLOYED: Sun Sep 13 21:32:12 2020
      NAMESPACE: traefik
      STATUS: deployed
      REVISION: 2
      TEST SUITE: None
```
{{% /expand %}}

#### Create IngressRouteTCP

1. To enable SSL passthrough in Traefik, you can configure a TCP router. A sample YAML for `IngressRouteTCP` is available at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/tls/traefik-tls.yaml`. The following should be updated in `traefik-tls.yaml`:
   * The service name and the SSL port should be updated in the Services.
   * The load balancer hostname should be updated in the `HostSNI` rule.

   Sample `traefik-tls.yaml`:
   ```yaml
   apiVersion: traefik.containo.us/v1alpha1
   kind: IngressRouteTCP
   metadata:
     name: soa-cluster-routetcp
     namespace: soans
   spec:
     entryPoints:
       - websecure
     routes:
     - match: HostSNI(`${LOADBALANCER_HOSTNAME}`)
       services:
       - name: soainfra-cluster-soa-cluster
         port: 8002
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

Verify the access to application URLs exposed through the configured service. Because the SOA cluster service is configured, you should be able to access the following SOA domain URLs:

   ```bash
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/soa-infra/
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/soa/composer
   https://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-SSLPORT}/integration/worklistapp
   ```

#### Uninstall Traefik

   ```bash
   $ helm delete traefik -n traefik
   ```
