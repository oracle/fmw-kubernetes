---
title: "NGINX"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 2
pre: "<b>b. </b>"
description: "Configure the ingress-based NGINX load balancer for Oracle WebCenter Sites domains."
---

This section provides information about how to install and configure the ingress-based *NGINX* load balancer to load balance Oracle WebCenter Sites domain clusters. You can configure NGINX for access of the application URL.


Follow these steps to set up NGINX as a load balancer for an Oracle WebCenter Sites domain in a Kubernetes cluster:

 See the official [installation document](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx#prerequisites) for prerequisites.


#### Add the Helm repos (if not added)

Add following Helm repos

```bash
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
$ helm repo update
```

#### Install the NGINX load balancer

Here is the helm install command with the default value for http port. 

	```bash
	$ helm install nginx-ingress -n wcsites-ns \
		--set controller.service.type=NodePort \
		--set controller.admissionWebhooks.enabled=false \ 
		--set controller.service.nodePorts.http=30305 \
		ingress-nginx/ingress-nginx 
	```

#### Create an Ingress for the Domain

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart. Here path-based routing is used for ingress. Sample values for default configuration are shown in the file `${WORKDIR}/kubernetes/charts/ingress-per-domain/values.yaml`. By default, `type` is `TRAEFIK` , `sslType` is `NONSSL`, and `domainType` is `wcs`. These values can be overridden by passing values through the command line or can be edited in the sample file `values.yaml`.   
If needed, you can update the ingress YAML file to define more path rules (in section `spec.rules.host.http.paths`) based on the domain application URLs that need to be accessed. Update the template YAML file for the NGINX load balancer located at `${WORKDIR}/kubernetes/charts/ingress-per-domain/templates/nginx-ingress.yaml`.

	For detailed instructions about ingress, see [this page](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/ingress/).

    For now, you can update the `kubernetes/charts/ingress-per-domain/values.yaml` with appropriate values.
    


1. Update the `kubernetes/charts/ingress-per-domain/templates/nginx-ingress.yaml` with the url routes to be load balanced.
    
    NOTE: This is not an exhaustive list of rules. You can enhance it based on the application urls that need to be accessed externally. These rules hold good for domain type `wcs`.

    
1. Install "ingress-per-domain" using helm.

    > Helm Install ingress-per-domain

    ```bash
    $ helm install wcsitesinfra-ingress kubernetes/charts/ingress-per-domain \
		--namespace wcsites-ns \
		--values kubernetes/charts/ingress-per-domain/values.yaml \
		--set "nginx.hostname=$(hostname -f)" \
		--set type=NGINX

    NAME: wcsitesinfra-ingress
	LAST DEPLOYED: Fri July 9 00:18:50 2020
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

After setting up the nginx loadbalancer, verify that the domain applications are accessible through the loadbalancer port 30305.
Through load balancer `(nginx port 30305)`, the following URLs are available for setting up domains of WebCenter Sites domain types:

```bash
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/weblogic/ready
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/console
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/em
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/sites/version.jsp
```
