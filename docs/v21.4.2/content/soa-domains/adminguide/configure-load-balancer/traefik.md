---
title: "Traefik"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 1
pre: "<b>a. </b>"
description: "Configure the ingress-based Traefik load balancer for Oracle SOA Suite domains."
---

This section provides information about how to install and configure the ingress-based *Traefik* load balancer (version 2.2.1 or later for production deployments) to load balance Oracle SOA Suite domain clusters. You can configure Traefik for non-SSL, SSL termination, and end-to-end SSL access of the application URL.

Follow these steps to set up Traefik as a load balancer for an Oracle SOA Suite domain in a Kubernetes cluster:

  1. [Install the Traefik (ingress-based) load balancer](#install-the-traefik-ingress-based-load-balancer)
  2. [Create an Ingress for the domain](#create-an-ingress-for-the-domain)
  3. [Verify domain application URL access](#verify-domain-application-url-access)
  4. [Uninstall the Traefik ingress](#uninstall-the-traefik-ingress)
  5. [Uninstall Traefik](#uninstall-traefik)


#### Install the Traefik (ingress-based) load balancer

1. Use Helm to install the Traefik (ingress-based) load balancer.
Use the `values.yaml` file in the sample but set `kubernetes.namespaces` specifically.


   ```bash
    $ cd ${WORKDIR}
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
         --values charts/traefik/values.yaml \
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
   pod/traefik-5fc4947cf9-fbl9r   1/1     Running   5          7d17h

   NAME              TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                                          AGE
   service/traefik   NodePort   10.100.195.70   <none>        9000:31288/TCP,30305:30305/TCP,30443:30443/TCP   7d17h

   NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
   deployment.apps/traefik   1/1     1            1           7d17h

   NAME                                 DESIRED   CURRENT   READY   AGE
   replicaset.apps/traefik-5fc4947cf9   1         1         1       7d17h

   ```
   {{% /expand %}}

4. Access the Traefik dashboard through the URL `http://$(hostname -f):31288`, with the HTTP host `traefik.example.com`:

    ```bash
    $ curl -H "host: $(hostname -f)" http://$(hostname -f):31288/dashboard/
    ```
   >  Note: Make sure that you specify a fully qualified node name for `$(hostname -f)`

5. Configure Traefik to manage ingresses created in this namespace, where `traefik` is the Traefik namespace and `soans` is the namespace of the domain:
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
Sample values for default configuration are shown in the file `${WORKDIR}/charts/ingress-per-domain/values.yaml`.
By default, `type` is `TRAEFIK`, `sslType` is `NONSSL`, and `domainType` is `soa`. These values can be overridden by passing values through the command line or can be edited in the sample file `values.yaml` based on the type of configuration (NONSSL, SSL, and E2ESSL).  
If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. The template YAML file for the Traefik (ingress-based) load balancer is located at `${WORKDIR}/charts/ingress-per-domain/templates/traefik-ingress.yaml`.

> Note: See [here](https://github.com/oracle/fmw-kubernetes/blob/v21.4.2/OracleSOASuite/kubernetes/ingress-per-domain/README.md#configuration) for all the configuration parameters.

1. Install `ingress-per-domain` using Helm for `NONSSL` configuration:

   ```bash
    $ cd ${WORKDIR}
    $ helm install soa-traefik-ingress  \
        charts/ingress-per-domain \
        --namespace soans \
        --values charts/ingress-per-domain/values.yaml \
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

1. For secured access (`SSL` termination and `E2ESSL`) to the Oracle SOA Suite application, create a certificate, and generate a Kubernetes secret:

   ```bash
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls1.key -out /tmp/tls1.crt -subj "/CN=*"
    $ kubectl -n soans create secret tls soainfra-tls-cert --key /tmp/tls1.key --cert /tmp/tls1.crt
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

1. Install `ingress-per-domain` using Helm for `SSL` configuration.

   The Kubernetes secret name should be updated in the template file.

   The template file also contains the following annotations:

   ```bash    
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.middlewares: soans-wls-proxy-ssl@kubernetescrd
   ```

   The entry point for SSL termination access and the Middleware name should be updated in the annotation. The Middleware name should be in the form `<namespace>-<middleware name>@kubernetescrd`.

   ```bash
    $ cd ${WORKDIR}
    $ helm install soa-traefik-ingress  \
        charts/ingress-per-domain \
        --namespace soans \
        --values charts/ingress-per-domain/values.yaml \
        --set "traefik.hostname=$(hostname -f)" \
        --set sslType=SSL
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
1. Install `ingress-per-domain` using Helm for `E2ESSL` configuration.

   ```bash
    $ cd ${WORKDIR}
    $ helm install soa-traefik-ingress  \
        charts/ingress-per-domain \
        --namespace soans \
        --values charts/ingress-per-domain/values.yaml \
        --set sslType=E2ESSL
   ```
   Sample output:
   ```bash
    NAME: soa-traefik-ingress
    LAST DEPLOYED: Fri Apr  9 09:47:27 2021
    NAMESPACE: soans
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
   ```

1. For **NONSSL access** to the Oracle SOA Suite application, get the details of the services by the ingress:

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

1. For **E2ESSL access** to the Oracle SOA Suite application, get the details of the services by the above deployed ingress:

    ```bash
     $ kubectl describe IngressRouteTCP soainfra-traefik -n soans	 
    ```
   {{%expand "Click here to see all services supported by the above deployed ingress." %}}
      ```
      Name:         soa-cluster-routetcp
      Namespace:    soans
      Labels:       app.kubernetes.io/managed-by=Helm
      Annotations:  meta.helm.sh/release-name: soa-traefik-ingress
                    meta.helm.sh/release-namespace: soans
      API Version:  traefik.containo.us/v1alpha1
      Kind:         IngressRouteTCP
      Metadata:
      Creation Timestamp:  2021-04-09T09:47:27Z
      Generation:          1
      Managed Fields:
      API Version:  traefik.containo.us/v1alpha1
      Fields Type:  FieldsV1
      fieldsV1:
       f:metadata:
        f:annotations:
          .:
          f:meta.helm.sh/release-name:
          f:meta.helm.sh/release-namespace:
        f:labels:
          .:
          f:app.kubernetes.io/managed-by:
       f:spec:
        .:
        f:entryPoints:
        f:routes:
        f:tls:
          .:
          f:passthrough:
       Manager:         Go-http-client
       Operation:       Update
       Time:            2021-04-09T09:47:27Z
       Resource Version:  548305
       Self Link:         /apis/traefik.containo.us/v1alpha1/namespaces/soans/ingressroutetcps/soa-cluster-routetcp
       UID:               933e524c-b773-474b-a87f-560d69f08d4b
       Spec:
       Entry Points:
       websecure
       Routes:
         Match:  HostSNI(`HostName`)
         Services:
          Termination Delay:  400
         Name:               soainfra-adminserver
         Port:               7002
         Weight:             3
        Tls:
        Passthrough:  true
      Events:           <none>
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

##### For NONSSL configuration  

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
##### For E2ESSL configuration

After setting up the Traefik (ingress-based) load balancer, verify that the domain applications are accessible through the SSL load balancer port `30443` for HTTPS access.

   * To access the application URLs from the browser, update `/etc/hosts` on the browser host (in Windows, `C:\Windows\System32\Drivers\etc\hosts`) with the entries below

      ```
      X.X.X.X  admin.org
      X.X.X.X  soa.org
      X.X.X.X  osb.org
      ```  
      >  Note: The value of X.X.X.X is the host ipaddress on which this ingress is deployed.

      >  Note: If you are behind any corporate proxy, make sure to update the browser proxy settings appropriately to access the host names updated `/etc/hosts` file.

 The sample URLs for Oracle SOA Suite domain of type `soa` are:

```bash
  https://admin.org:${LOADBALANCER-SSLPORT}/weblogic/ready
  https://admin.org:${LOADBALANCER-SSLPORT}/console
  https://admin.org:${LOADBALANCER-SSLPORT}/em
  https://soa.org:${LOADBALANCER-SSLPORT}/soa-infra
  https://soa.org:${LOADBALANCER-SSLPORT}/soa/composer
  https://soa.org:${LOADBALANCER-SSLPORT}/integration/worklistapp
```
#### Uninstall the Traefik ingress

Uninstall and delete the ingress deployment:

```bash
$ helm delete soa-traefik-ingress  -n soans
```

#### Uninstall Traefik

   ```bash
   $ helm delete traefik -n traefik
   ```
