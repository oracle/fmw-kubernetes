---
title: "Voyager"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 3
pre: "<b>c. </b>"
description: "Configure the ingress-based Voyager load balancer for Oracle WebCenter Sites domains."
---

*Voyager/HAProxy* is a popular ingress-based load balancer for production environments. This section provides information about how to install and configure *Voyager/HAProxy* to load balance Oracle WebCenter Sites domain clusters. You can configure Voyager for access of the application URL.

Follow these steps to set up Voyager as a load balancer for an Oracle WebCenter Sites domain in a Kubernetes cluster:


1. [Install the Voyager Load Balancer](#install-the-voyager-load-balancer)
2. [Configure Voyager to Manage Ingresses](#configure-voyager-to-manage-ingresses)
3. [Verify that You can Access the Domain URL](#verify-that-you-can-access-the-domain-url)


#### Install the Voyager Load Balancer

See the official installation document and follow step 1 and 2 [here](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/charts/voyager/README.md#a-step-by-step-guide-to-install-the-voyager-operator).

#### Configure Voyager to Manage Ingresses

1. Create an Ingress for the domain (`ingress-per-domain`) in the domain namespace, by using the sample Helm chart. 

    Here we are using the path based routing for ingress. For detailed instructions about ingress, refer this [page](https://github.com/oracle/weblogic-kubernetes-operator/tree/master/kubernetes/samples/charts/voyager#install-a-path-routing-ingress).

    For this update the `kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain/values.yaml` with appropriate values, sample values are shown below:
    
    ```bash
    # Copyright 2020, Oracle Corporation and/or its affiliates.
    # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

    # Default values for ingress-per-domain.
    # This is a YAML-formatted file.
    # Declare variables to be passed into your templates.

    apiVersion: networking.k8s.io/v1beta1

    # Load balancer type.  Supported values are: TRAEFIK, VOYAGER
    #type: TRAEFIK
    type: VOYAGER
    #type: NGINX

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


    # Ngnix specific values
    ngnix:
      #connect timeout
      connectTimeout: 1800s
      #read timeout
      readTimeout: 1800s
      #send timeout
      sendTimeout: 1800s
    ```

1. Update the `kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain/templates/voyager-ingress.yaml` with the url routes to be load balanced.
    
    Below are the ingress rules defined:

    NOTE: These are not the exhausted list of rules. These can be enhanced based on the application urls that needs to be accessed externally.

    Below rules hold good for domain type WCSITES.

    ```bash
    # Copyright 2020, Oracle Corporation and/or its affiliates.
    # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
     
    {{- if eq .Values.type "VOYAGER" }}
    ---
    apiVersion: voyager.appscode.com/v1beta1
    kind: Ingress
    metadata:
      name: {{ .Values.wlsDomain.domainUID }}-voyager
      namespace: {{ .Release.Namespace }}
      annotations:
        ingress.appscode.com/type: 'NodePort'
        ingress.appscode.com/stats: 'true'
        ingress.appscode.com/affinity: 'cookie'
		ingress.appscode.com/default-timeout: '{"connect": "1800s", "server": "1800s"}'
    spec:
      rules:
      - host: '*'
        http:
          nodePort: {{ .Values.voyager.webPort }}
          paths:
          - path: /console
            backend:
              serviceName: {{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}
              servicePort: {{ .Values.wlsDomain.adminServerPort }}
          - path: /em
            backend:
              serviceName: {{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}
              servicePort: {{ .Values.wlsDomain.adminServerPort }}
    #      - path: /wls-exporter
    #        backend:
    #          serviceName: {{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}
    #          servicePort: {{ .Values.wlsDomain.adminServerPort }}
          - path: /weblogic
            backend:
              serviceName: {{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}
              servicePort: {{ .Values.wlsDomain.adminServerPort }}
          - path: /sbconsole
            backend:
              serviceName: {{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}
              servicePort: {{ .Values.wlsDomain.adminServerPort }}
          - path: /sites
            backend:
              serviceName: {{ .Values.wlsDomain.domainUID }}-cluster-{{ .Values.wlsDomain.wcsitesClusterName | lower | replace "_" "-" }}
              servicePort: {{ .Values.wlsDomain.wcsitesManagedServerPort }}
          - path: /cas
            backend:
              serviceName: {{ .Values.wlsDomain.domainUID }}-cluster-{{ .Values.wlsDomain.wcsitesClusterName | lower | replace "_" "-" }}
              servicePort: {{ .Values.wlsDomain.wcsitesManagedServerPort }}
    #      - path: /wls-exporter
    #        backend:
    #          serviceName: {{ .Values.wlsDomain.domainUID }}-cluster-{{ .Values.wlsDomain.wcsitesClusterName | lower | replace "_" "-" }}
    #          servicePort: {{ .Values.wlsDomain.wcsitesManagedServerPort }}
     
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: {{ .Values.wlsDomain.domainUID }}-voyager-stats
      namespace: {{ .Release.Namespace }}
    spec:
      type: NodePort
      ports:
        - name: client
          protocol: TCP
          port: 56789
          targetPort: 56789
          nodePort: {{ .Values.voyager.statsPort }}
      selector:
        origin: voyager
        origin-name: {{ .Values.wlsDomain.domainUID }}-voyager
    {{- end }}
    ```

1. Install `ingress-per-domain` using helm.

    > Helm Install ingress-per-domain

    ```bash
    $ helm install wcsitesinfra-voyager-ingress kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain --namespace wcsites-ns --values kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain/values.yaml

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
* About to connect() to localhost port 30305 (#0)
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 30305 (#0)
> GET /weblogic/ready HTTP/1.1
> User-Agent: curl/7.29.0
> Accept: */*
> host: *****.com
>
< HTTP/1.1 200 OK
< Content-Length: 0
< Date: Thu, 12 Mar 2020 10:16:43 GMT
< Vary: Accept-Encoding
<
* Connection #0 to host localhost left intact
```

#### Verify that You can Access the Domain URL

After setting up the Voyager loadbalancer, verify that the domain applications are accessible through the loadbalancer port 30305.
Through load balancer (Voyager port 30305), the following URLs are available for setting up domains of WebCenter Sites domain types:

```bash
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/weblogic/ready
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/console
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/em
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/sites/version.jsp
```