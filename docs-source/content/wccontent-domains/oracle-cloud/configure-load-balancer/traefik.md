---
title: "Traefik"
date: 2020-12-3T15:44:42-05:00
draft: false
weight: 1
pre: "<b>a. </b>"
description: "Configure the ingress-based Traefik load balancer for Oracle WebCenter Content domains."
---

This section provides information about how to install and configure the ingress-based *Traefik* load balancer (version 2.2.8 or later for production deployments) to load balance Oracle WebCenter Content domain clusters.

Follow these steps to set up Traefik as a load balancer for an Oracle WebCenter Content	domain in a Kubernetes cluster:

#### Contents
1. [Install the Traefik (ingress-based) load balancer](#install-the-traefik-ingress-based-load-balancer)
1. [Configure Traefik to manage ingresses](#configure-traefik-to-manage-ingresses)
1. [Create an Ingress for the domain](#create-an-ingress-for-the-domain)
1. [Verify domain application URL access](#verify-domain-application-url-access)
1. [Uninstall the Traefik ingress](#uninstall-the-traefik-ingress)



#### Install the Traefik (ingress-based) load balancer

1. Use Helm to install the Traefik (ingress-based) load balancer. For detailed information, see [here](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/charts/traefik/README.md).
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
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install traefik  traefik/traefik \
         --namespace traefik \
         --values kubernetes/samples/scripts/charts/traefik/values.yaml \
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


   A sample `values.yaml` for deployment of Traefik 2.2.x:
   {{%expand "Click here to see values.yaml" %}}
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
1. Verify the helm charts:
   ```bash
   $ helm list -n traefik
   NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
   traefik traefik         2               2021-10-11 12:22:41.122310912 +0000 UTC deployed        traefik-9.1.1   2.2.8
   ```
      
1. Verify the Traefik status and find the port number
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
Sample values for default configuration are shown in the file `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/values.yaml`.
By default, `type` is `TRAEFIK` , `tls` is `Non-SSL`, and `domainType` is `wccinfra`. These values can be overridden by passing values through the command line or can be edited in the sample file `values.yaml` based on the type of configuration (non-SSL or SSL).
If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. The template YAML file for the Traefik (ingress-based) load balancer is located at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/traefik-ingress.yaml`

1. Install `ingress-per-domain` using Helm for non-SSL configuration:

   ```bash
    $ cd ${WORKDIR}/weblogic-kubernetes-operator
    $ helm install wcc-traefik-ingress  \
        kubernetes/samples/charts/ingress-per-domain \
        --set type=TRAEFIK \
        --namespace wccns \
        --values kubernetes/samples/charts/ingress-per-domain/values.yaml \
        --set "traefik.hostname=" \
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

#### Verify domain application URL access

After setting up the Traefik (ingress-based) load balancer, verify that the domain application URLs are accessible through the load balancer port `30305` for HTTP access. The sample URLs for Oracle WebCenter Content domain of type `wcc` are:

```bash
http://${TRAEFIK_PUBLIC_IP}:30305/weblogic/ready
http://${TRAEFIK_PUBLIC_IP}:30305/console
http://${TRAEFIK_PUBLIC_IP}:30305/cs
http://${TRAEFIK_PUBLIC_IP}:30305/ibr	
```

#### Uninstall the Traefik ingress

Uninstall and delete the ingress deployment:

```bash
$ helm delete wcc-traefik-ingress  -n wccns
```


