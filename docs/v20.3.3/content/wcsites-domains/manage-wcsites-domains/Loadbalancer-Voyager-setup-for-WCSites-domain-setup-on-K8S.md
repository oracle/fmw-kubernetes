---
title: "b. Using Voyager Loadbalancer"
description: "Steps to set up Voyager as a loadbalancer for the WebCenter Sites domain."
---

### Setting Up Loadbalancer Voyager for the WebCenter Sites Domain on K8S

The Oracle WebLogic Server Kubernetes Operator supports three load balancers: Traefik, Voyager, and Apache. Follow these steps to set up Voyager as a loadbalancer for the WebCenter Sites domain:


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
    -bash-4.2$ cat kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain/values.yaml
     
    type: VOYAGER
     
    # Copyright 2020, Oracle Corporation and/or its affiliates.
    # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
     
    # Default values for ingress-per-domain.
    # This is a YAML-formatted file.
    # Declare variables to be passed into your templates.
     
    # Load balancer type.  Supported values are: TRAEFIK, VOYAGER
    #type: TRAEFIK
    type: VOYAGER
     
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

    ```bash
     bash-4.2$ cd weblogic-kubernetes-operator
     
    -bash-4.2$ helm install kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain \
     --name wcsitesinfra-voyager-ingress --namespace wcsites-ns \
     --values kubernetes/samples/scripts/create-wcsites-domain/ingress-per-domain/values.yaml
     
     
    NAME:   wcsitesinfra-voyager-ingress
    LAST DEPLOYED: Fri Feb 14 13:20:17 2020
    NAMESPACE: wcsites-ns
    STATUS: DEPLOYED
     
    RESOURCES:
    ==> v1/Service
    NAME                        TYPE      CLUSTER-IP     EXTERNAL-IP  PORT(S)          AGE
    wcsitesinfra-voyager-stats  NodePort  10.101.94.249  <none>       56789:30317/TCP  0s
     
    ==> v1beta1/Ingress
    NAME                  HOSTS                         ADDRESS  PORTS  AGE
    wcsitesinfra-ingress  yourcompany-loadbalancer.com  80       0s
     
    NAME                  AGE
    wcsitesinfra-voyager  0s
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

After setting up the Traefik loadbalancer, verify that the domain applications are accessible through the loadbalancer port 30305.
Through load balancer (Traefik port 30305), the following URLs are available for setting up domains of WebCenter Sites domain types:

```bash
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/weblogic/ready
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/console
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/em
http://${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}/sites/version.jsp
```