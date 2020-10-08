---
title: "a. Using Traefik Loadbalancer"
description: "Steps to set up Traefik as a loadbalancer for the WebCenter Sites domain."
---

### Setting Up Loadbalancer Traefik for the WebCenter Sites Domain on K8S

The Oracle WebLogic Server Kubernetes Operator supports three load balancers: Traefik, Voyager, and Apache. Follow these steps to set up Traefik as a loadbalancer for the WebCenter Sites domain:


1. [Install the Traefik Load Balancer](#install-the-traefik-load-balancer)
2. [Configure Traefik to Manage Ingresses](#configure-traefik-to-manage-ingresses)
3. [Create an Ingress for the Domain](#create-an-ingress-for-the-domain)
2. [Verify that You can Access the Domain URL](#verify-that-you-can-access-the-domain-url)


#### Install the Traefik Load Balancer

1. Use helm to install the Traefik load balancer. For detailed information, see [this document](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/charts/traefik/README.md).
Use the values.yaml file in the sample but set `kubernetes.namespaces` specifically.


    > Install Traefik
     
    ```bash
    $ cd weblogic-kubernetes-operator
    $ helm install stable/traefik --name traefik-operator \
        --namespace traefik --values kubernetes/samples/charts/traefik/values.yaml \
        --set "dashboard.domain=$(hostname -f),kubernetes.namespaces={traefik}"
    ```    
    > Output 
    
    ```bash
    $ cd weblogic-kubernetes-operator
     
    $ helm install stable/traefik --name traefik-operator --namespace traefik --values kubernetes/samples/charts/traefik/values.yaml --set  "dashboard.domain=$(hostname -f),kubernetes.namespaces={traefik}" --wait
	NAME:   traefik-operator
	LAST DEPLOYED: Sat Mar 14 13:53:16 2020
	NAMESPACE: traefik
	STATUS: DEPLOYED
	
	RESOURCES:
	==> v1/Service
	NAME                        TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)                     AGE
	traefik-operator-dashboard  ClusterIP  10.108.89.215  <none>       80/TCP                      0s
	traefik-operator            NodePort   10.99.75.162   <none>       443:30443/TCP,80:30305/TCP  0s
	
	==> v1/Secret
	NAME                           TYPE    DATA  AGE
	traefik-operator-default-cert  Opaque  2     0s
	
	==> v1/ServiceAccount
	NAME              SECRETS  AGE
	traefik-operator  1        0s
	
	==> v1/RoleBinding
	NAME              AGE
	traefik-operator  0s
	
	==> v1beta1/Ingress
	NAME                        HOSTS                   ADDRESS  PORTS  AGE
	traefik-operator-dashboard  abc.def.com  80       0s
	
	==> v1/Pod(related)
	NAME                               READY  STATUS             RESTARTS  AGE
	traefik-operator-844859fdd6-prh55  0/1    ContainerCreating  0         0s
	
	==> v1/ConfigMap
	NAME              DATA  AGE
	traefik-operator  1     0s
	
	==> v1/Role
	NAME              AGE
	traefik-operator  0s
	
	==> v1/Deployment
	NAME              DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
	traefik-operator  1        1        1           0          0s
	
	
	NOTES:
	
	1. Traefik is listening on the following ports on the host machine:
	
		http - 30305
		https - 30443
	
	2. Configure DNS records corresponding to Kubernetes ingress resources to point to the NODE_IP/NODE_HOST
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


> helm upgrade for traefik
 
```bash
$ helm upgrade --reuse-values --set "kubernetes.namespaces={traefik,wcsites-ns}" --wait traefik-operator stable/traefik
Release "traefik-operator" has been upgraded. Happy Helming!
LAST DEPLOYED: Sat Mar 14 13:58:03 2020
NAMESPACE: traefik
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME              DATA  AGE
traefik-operator  1     5m2s

==> v1/ClusterRole
NAME              AGE
traefik-operator  14s

==> v1/Service
NAME                        TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)                     AGE
traefik-operator-dashboard  ClusterIP  10.108.89.215  <none>       80/TCP                      5m2s
traefik-operator            NodePort   10.99.75.162   <none>       443:30443/TCP,80:30305/TCP  5m2s

==> v1/Deployment
NAME              DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
traefik-operator  1        1        1           1          5m2s

==> v1/Secret
NAME                           TYPE    DATA  AGE
traefik-operator-default-cert  Opaque  2     5m2s

==> v1/ServiceAccount
NAME              SECRETS  AGE
traefik-operator  1        5m2s

==> v1/ClusterRoleBinding
NAME              AGE
traefik-operator  14s

==> v1beta1/Ingress
NAME                        HOSTS                   ADDRESS  PORTS  AGE
traefik-operator-dashboard  abc.def.com  80       5m2s

==> v1/Pod(related)
NAME                               READY  STATUS       RESTARTS  AGE
traefik-operator-844699994b-ttfb6  1/1    Running      0         14s
traefik-operator-844859fdd6-prh55  0/1    Terminating  0         5m2s


NOTES:

1. Traefik is listening on the following ports on the host machine:

     http - 30305
     https - 30443

2. Configure DNS records corresponding to Kubernetes ingress resources to point to the NODE_IP/NODE_HOST
```

#### Create an Ingress for the Domain

1. Create an Ingress for the domain (`ingress-per-domain-wcsites`), in the domain namespace by using the sample Helm chart.
Here we are using the path-based routing for ingress. For detailed instructions about ingress, see [this page](https://oracle.github.io/weblogic-kubernetes-operator/userguide/managing-domains/ingress/)).

    For now, you can update the `kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain/values.yaml` with appropriate values. Sample values are shown below:
    
    ```bash
	$ cat kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain/values.yaml
	
	# Copyright 2020, Oracle Corporation and/or its affiliates.
	# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
	
	# Default values for ingress-per-domain.
	# This is a YAML-formatted file.
	# Declare variables to be passed into your templates.
	
	# Load balancer type.  Supported values are: TRAEFIK, VOYAGER
	type: TRAEFIK
	#type: VOYAGER
	
	# WLS domain as backend to the load balancer
	wlsDomain:
	domainUID: wcsitesinfra
	adminServerName: adminserver
	adminServerPort: 7001
	wcsitesClusterName: wcsites_cluster
	wcsitesManagedServerPort: 8001
	
	# Voyager specific values
	voyager:
	# web port
	webPort: 30305
	# stats port
	statsPort: 30317   
    ```

1. Update the `kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain/templates/traefik-ingress.yaml` with the url routes to be load balanced.
    
    Below are the defined ingress rules:
    
    NOTE: This is not an exhaustive list of rules. You can enhance it based on the application urls that need to be accessed externally. These rules hold good for domain type `WCSITES`.
    ```bash
	$ vi kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain/templates/traefik-ingress.yaml
	
    # Copyright 2020, Oracle Corporation and/or its affiliates.
	# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

	{{- if eq .Values.type "TRAEFIK" }}
	---
	apiVersion: extensions/v1beta1
	kind: Ingress
	metadata:
	  name: {{ .Values.wlsDomain.domainUID }}-traefik
	  namespace: {{ .Release.Namespace }}
	  labels:
		weblogic.resourceVersion: domain-v2
	spec:
	  annotations:
		kubernetes.io/ingress.class: traefik
	  rules:
	  - host: '{{ .Values.traefik.hostname }}'
		http:
		  paths:
		  - path: /console
			backend:
			  serviceName: '{{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}'
			  servicePort: {{ .Values.wlsDomain.adminServerPort }}
		  - path: /em
			backend:
			  serviceName: '{{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}'
			  servicePort: {{ .Values.wlsDomain.adminServerPort }}
		  - path: /wls-exporter
			backend:
			  serviceName: '{{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}'
			  servicePort: {{ .Values.wlsDomain.adminServerPort }}
		  - path: /weblogic
			backend:
			  serviceName: '{{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}'
			  servicePort: {{ .Values.wlsDomain.adminServerPort }}
		  - path: /sbconsole
			backend:
			  serviceName: '{{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}'
			  servicePort: {{ .Values.wlsDomain.adminServerPort }}
		  - path: /sites
			backend:
			  serviceName: '{{ .Values.wlsDomain.domainUID }}-cluster-{{ .Values.wlsDomain.wcsitesClusterName | lower | replace "_" "-" }}'
			  servicePort: {{ .Values.wlsDomain.wcsitesManagedServerPort }}
		  - path: /cas
			backend:
			  serviceName: '{{ .Values.wlsDomain.domainUID }}-cluster-{{ .Values.wlsDomain.wcsitesClusterName | lower | replace "_" "-" }}'
			  servicePort: {{ .Values.wlsDomain.wcsitesManagedServerPort }}
		  - path: /wls-exporter
			backend:
			  serviceName: '{{ .Values.wlsDomain.domainUID }}-cluster-{{ .Values.wlsDomain.wcsitesClusterName | lower | replace "_" "-" }}'
			  servicePort: {{ .Values.wlsDomain.wcsitesManagedServerPort }}
	 #     - path: /wls-cat
	 #       backend:
	 #         serviceName: '{{ .Values.wlsDomain.domainUID }}-cluster-{{ .Values.wlsDomain.wcsitesClusterName | lower | replace "_" "-" }}'
	 #         servicePort: {{ .Values.wlsDomain.wcsitesManagedServerPort }}
	 #     - path:
	 #       backend:
	 #         serviceName: '{{ .Values.wlsDomain.domainUID }}-cluster-{{ .Values.wlsDomain.wcsitesClusterName | lower | replace "_" "-" }}'
	 #         servicePort: {{ .Values.wlsDomain.wcsitesManagedServerPort }}
	{{- end }}

    ```

1. Install "ingress-per-domain" using helm.

    ```bash
    bash-4.2$ cd weblogic-kubernetes-operator
     
    bash-4.2$ helm install kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain \
        --name wcsitesinfra-ingress --namespace wcsites-ns \
        --values kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain/values.yaml \
        --set "traefik.hostname=$(hostname -f)"
      
    NAME:   wcsitesinfra-ingress
	LAST DEPLOYED: Sat Mar 14 14:03:22 2020
	NAMESPACE: wcsites-ns
	STATUS: DEPLOYED

	RESOURCES:
	==> v1beta1/Ingress
	NAME                  HOSTS        ADDRESS  PORTS  AGE
	wcsitesinfra-traefik  abc.def.com  80       0s
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