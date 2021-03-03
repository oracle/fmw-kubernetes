---
title: "Enable additional URL access"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 2
pre: "<b> </b>"
description: "Extend an existing ingress to enable additional application URL access for Oracle SOA Suite domains."
---

This section provides information about how to extend an existing ingress (Non-SSL and SSL termination) to enable additional application URL access for Oracle SOA Suite domains.

The ingress per domain created in the steps in [Set up a load balancer]({{< relref "/soa-domains/adminguide/configure-load-balancer/" >}}) exposes the application paths defined in template YAML files present at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/`.

To extend an existing ingress with additional application URL access:

1. Update the template YAML file at `${WORKDIR}/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain/templates/` to define additional path rules.

   For example, to extend an existing NGINX-based ingress with additional paths `/path1` and `/path2` of an Oracle SOA Suite cluster, update `nginx-ingress.yaml` with additional paths:

   ```
   # Copyright (c) 2020, 2021, Oracle and/or its affiliates.
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
   {{- if eq .Values.type "NGINX" }}
   ---
   apiVersion: extensions/v1beta1
   kind: Ingress
   .
   .
   spec:
     rules:
     - host: '{{ .Values.nginx.hostname }}'
       http:
         paths:
         # Add new paths -- start  
         - path: /path1
           backend:
             serviceName: '{{ .Values.wlsDomain.domainUID }}-cluster-{{ .Values.wlsDomain.soaClusterName | lower | replace "_" "-" }}'
             servicePort: {{ .Values.wlsDomain.soaManagedServerPort  }}
         - path: /path2
           backend:
             serviceName: '{{ .Values.wlsDomain.domainUID }}-cluster-{{ .Values.wlsDomain.soaClusterName | lower | replace "_" "-" }}'
             servicePort: {{ .Values.wlsDomain.soaManagedServerPort  }}
         # Add new paths -- end
         - path: /console
           backend:
             serviceName: '{{ .Values.wlsDomain.domainUID }}-{{ .Values.wlsDomain.adminServerName | lower | replace "_" "-" }}'
             servicePort: {{ .Values.wlsDomain.adminServerPort }}
   .
   .
   {{- end }}
   ```     

1. Get the Helm release name for the ingress installed in your domain namespace:
   ```
   $ helm ls -n <domain_namespace>
   ```

   For example, in the `soans` namespace:
   ```
   $ helm ls -n soans
   ```

   Sample output, showing the Helm release name for a NGINX-based ingress as `soa-nginx-ingress`:

   ```
   NAME                  NAMESPACE       REVISION        UPDATED                               STATUS        CHART                 APP VERSION
   soa-nginx-ingress     soans            1        2021-02-17 13:42:03.252742314 +0000 UTC  deployed  ingress-per-domain-0.1.0     1.0
   $
   ```

1. To extend the existing ingress per domain with additional paths defined in the template YAML, use the `helm upgrade` command:
   ```
   $ cd ${WORKDIR}/weblogic-kubernetes-operator
   $ helm upgrade <helm_release_for_ingress> \
       kubernetes/samples/charts/ingress-per-domain \
       --namespace <domain_namespace> \
       --reuse-values
   ```
   >**Note**: `helm_release_for_ingress` is the ingress name used in the corresponding helm install command for the ingress installation.

   Sample command for a NGINX-based ingress `soa-nginx-ingress` in the `soans` namespace:
   ```
   $ cd ${WORKDIR}/weblogic-kubernetes-operator
   $ helm upgrade soa-nginx-ingress \
       kubernetes/samples/charts/ingress-per-domain \
       --namespace soans \
       --reuse-values
   ```

   This will upgrade the existing ingress to pick up the additional paths updated in the template YAML.

1. Verify that additional paths are updated into the existing ingress.

   a. Get the existing ingress deployed in the domain namespace:  
      ```
      $ kubectl get ingress -n <domain_namespace>
      ```

      For example, in the `soans` namespace:  
      ```
      $ kubectl get ingress -n soans
      ```

      Sample output, showing the existing ingress as `soainfra-nginx`:  
      ```
      NAME               CLASS    HOSTS         ADDRESS        PORTS     AGE
      soainfra-nginx   <none>   domain1.org  10.109.211.160   80, 443    xxd
      ```

   b. Describe the ingress object and verify that new paths are available and pointing to desired backends.

      Sample command and output, showing path and backend details for `/path1` and `/path2`:

      ```
      $ kubectl describe ingress soainfra-nginx -n soans|grep path
                                           /path1                     soainfra-cluster-soa-cluster:8001 (172.17.0.19:8001,172.17.0.20:8001)
                                           /path2                     soainfra-cluster-soa-cluster:8001 (172.17.0.19:8001,172.17.0.20:8001)
      ```
