---
title: "Traefik"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 1
pre: "<b>a. </b>"
description: "Configure the ingress-based Traefik load balancer for Oracle WebCenter Sites domains."
---

This section provides information about how to install and configure the ingress-based *Traefik* load balancer (version 2.2.1 or later for production deployments) to load balance Oracle WebCenter Sites domain clusters. You can configure Traefik for access of the application URL.

Follow these steps to set up Traefik as a load balancer for an Oracle WebCenter Sites domain in a Kubernetes cluster:

### Setting Up Loadbalancer Traefik for the WebCenter Sites Domain on K8S

 Follow these steps to set up Traefik as a loadbalancer for the Oracle WebCenter Sites domain:


1. [Install the Traefik Load Balancer](#install-the-traefik-load-balancer)
2. [Configure Traefik to Manage Ingresses](#configure-traefik-to-manage-ingresses)
3. [Create an Ingress for the Domain](#create-an-ingress-for-the-domain)
2. [Verify that You can Access the Domain URL](#verify-that-you-can-access-the-domain-url)


#### Install the Traefik Load Balancer

1. Use helm to install the Traefik load balancer. For detailed information, see [this document](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/charts/traefik/README.md).
Use the values.yaml file in the sample but set `kubernetes.namespaces` specifically.

    > Add the repo
    ```bash
	$ cd ${WORKDIR}/weblogic-kubernetes-operator
 	$ kubectl create namespace traefik
 	$ helm repo add traefik https://containous.github.io/traefik-helm-chart
    ```
    
    > Update the repo
    ```bash
	$ helm repo update
    ```

    > Helm Install for Traefik

    ```bash
    $ helm install traefik  traefik/traefik \
        --namespace traefik \
        --values kubernetes/charts/traefik/values.yaml \
        --set  "kubernetes.namespaces={traefik}" \
        --set "service.type=NodePort" --wait 

    NAME:traefik-operator
	LAST DEPLOYED: Fri Jun 19 00:17:57 2020
	NAMESPACE: traefik
	STATUS: deployed
	REVISION: 1
	TEST SUITE: None
    ```

1. Access the Traefik dashboard through the URL `http://$(hostname -f):30305`, with the HTTP host `traefik.example.com`.
NOTE: Make sure you specify full qualified node name for `$(hostname -f)`.

    ```bash
    $ curl -H 'host: $(hostname -f)' http://$(hostname -f):30305/
    <a href="/dashboard/">Found</a>.
    $
    ```

#### Configure Traefik to Manage Ingresses

Configure Traefik to manage Ingresses created in this namespace:
Note: Here traefik is the Traefik namespace, `wcsites-ns` is the namespace of the domain.


> Helm upgrade for traefik

```bash
$ helm upgrade traefik traefik/traefik --namespace traefik --reuse-values \
    --set "kubernetes.namespaces={traefik,wcsites-ns}"
 
 
NAME:traefik-operator
LAST DEPLOYED: Fri Jun 19 00:18:50 2020
NAMESPACE: traefik
STATUS: deployed
REVISION: 2
TEST SUITE: None
``` 

#### Create an Ingress for the Domain

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress.
Sample values for default configuration are shown in the file `${WORKDIR}/kubernetes/charts/ingress-per-domain/values.yaml`.
By default, `type` is `TRAEFIK`, `sslType` is `NONSSL`, and `domainType` is `wcs`. These values can be overridden by passing values through the command line or can be edited in the sample file `values.yaml`.  
If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. The template YAML file for the Traefik (ingress-based) load balancer is located at `${WORKDIR}/kubernetes/charts/ingress-per-domain/templates/traefik-ingress.yaml`.

	For detailed instructions about ingress, see [this page](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/ingress/).

    For now, you can update the `kubernetes/charts/ingress-per-domain/values.yaml` with appropriate values.
    

1. Update the `kubernetes/charts/ingress-per-domain/templates/traefik-ingress.yaml` with the url routes to be load balanced.
    
    NOTE: This is not an exhaustive list of rules. You can enhance it based on the application urls that need to be accessed externally. These rules hold good for domain type `wcs`.


1. Install "ingress-per-domain" using helm.

    > Helm Install ingress-per-domain

    ```bash
    $ helm install wcsitesinfra-ingress kubernetes/charts/ingress-per-domain \
		--namespace wcsites-ns \
		--values kubernetes/charts/ingress-per-domain/values.yaml \
		--set "traefik.hostname=$(hostname -f)"

    NAME: wcsitesinfra-ingress
	LAST DEPLOYED: Fri Jun 19 00:18:50 2020
	NAMESPACE: wcsites-ns
	STATUS: deployed
	REVISION: 1
	TEST SUITE: None
    ```


1. To confirm that the load balancer noticed the new Ingress and is successfully routing to the domain's server pods, you can send a request to the URL for the "WebLogic ReadyApp framework" which should return a HTTP 200 status code, as shown in the example below:
```bash
-bash-4.2$ curl -v http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/weblogic/ready
*   Trying 149.87.129.203...
> GET http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/weblogic/ready HTTP/1.1
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
#### Verify that You can Access the Domain URL

After setting up the Traefik loadbalancer, verify that the domain applications are accessible through the loadbalancer port 30305.
Through load balancer `(Traefik port 30305)`, the following URLs are available for setting up domains of WebCenter Sites domain types:

```bash
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/weblogic/ready
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/console
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/em
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/sites/version.jsp
```
