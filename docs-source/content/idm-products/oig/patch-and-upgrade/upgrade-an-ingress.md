---
title: "c. Upgrade Ingress"
description: "Instructions on how to upgrade the ingress."
---

This section shows how to upgrade the ingress.

To determine if this step is required for the version you are upgrading to, refer to the [Release Notes](../../release-notes).


### Upgrading the ingress

To upgrade the existing ingress rules, follow the steps below:

1. List the existing ingress:

   ```
   $ helm list -n <domain_namespace>
   ```
   
   For example:
   
   ```
   $ helm list -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                        NAMESPACE       REVISION        UPDATED    STATUS      CHART                           APP VERSION
   governancedomain-nginx      oigns           1               <DATE>     deployed    ingress-per-domain-0.1.0        1.0
   ```

1. Make sure you have downloaded the latest code as per [Download the latest code repository](../patch-an-image/#download-the-latest-code-repository).

1. Edit the `$WORKDIR/kubernetes/charts/ingress-per-domain/values.yaml` and change the `domainUID` parameter to match your domainUID, for example `domainUID: governancedomain`. Change `sslType` to `NONSSL` or `SSL` depending on your existing configuration. For example:

   ```
   # Load balancer type. Supported values are: NGINX
   type: NGINX

   # SSL configuration Type. Supported Values are : NONSSL,SSL
   sslType: SSL

   # domainType. Supported values are: oim
   domainType: oim

   #WLS domain as backend to the load balancer
   wlsDomain:
     domainUID: governancedomain
     adminServerName: AdminServer
     adminServerPort: 7001
     adminServerSSLPort:
     soaClusterName: soa_cluster
     soaManagedServerPort: 8001
     soaManagedServerSSLPort:
     oimClusterName: oim_cluster
     oimManagedServerPort: 14000
     oimManagedServerSSLPort:


   # Host  specific values
   hostName:
     enabled: false
     admin:
     runtime:
     internal:

   # Ngnix specific values
   nginx:
     nginxTimeOut: 180
   ```

1. Upgrade the `governancedomain-nginx` with the following command:

   ```
   $ cd $WORKDIR
   $ helm upgrade <ingress> kubernetes/charts/ingress-per-domain/ --namespace <domain_namespace> --values kubernetes/charts/ingress-per-domain/values.yaml --reuse-values
   ```
   
   For example:
   
   ```
   $ cd $WORKDIR
   $ helm upgrade governancedomain-nginx kubernetes/charts/ingress-per-domain/ --namespace oigns --values kubernetes/charts/ingress-per-domain/values.yaml --reuse-values
   ```
   
   The output will look similar to the following:
   
   ```
   Release "governancedomain-nginx" has been upgraded. Happy Helming!
   NAME: governancedomain-nginx
   LAST DEPLOYED: <DATE>
   NAMESPACE: oigns
   STATUS: deployed
   REVISION: 2
   TEST SUITE: None
   ```


1. List the ingress:

   ```
   $ kubectl get ing -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                       CLASS    HOSTS   ADDRESS        PORTS   AGE
   governancedomain-nginx     <none>   *       10.107.182.40  80      18s
   ```

1. Describe the ingress and make sure all the listed paths are accessible:

   ```
   $ kubectl describe ing governancedomain-nginx -n oigns
   ```
   
   The output will look similar to the following:
   
   ```
   Name:             governancedomain-nginx
   Namespace:        oigns
   Address:          10.107.182.40
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                 /console                        governancedomain-adminserver:7001 (10.244.4.240:7001)
                 /consolehelp                    governancedomain-adminserver:7001 (10.244.4.240:7001)
                 /em                             governancedomain-adminserver:7001 (10.244.4.240:7001)
                 /ws_utc                         governancedomain-cluster-soa-cluster:8001 (10.244.4.242:8001)
                 /soa                            governancedomain-cluster-soa-cluster:8001 (10.244.4.242:8001)
                 /integration                    governancedomain-cluster-soa-cluster:8001 (10.244.4.242:8001)
                 /soa-infra                      governancedomain-cluster-soa-cluster:8001 (10.244.4.242:8001)
                 /identity                       governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /admin                          governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /oim                            governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /sysadmin                       governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /workflowservice                governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /callbackResponseService        governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /spml-xsd                       governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /HTTPClnt                       governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /reqsvc                         governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /iam                            governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /provisioning-callback          governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /CertificationCallbackService   governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /ucs                            governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /FacadeWebApp                   governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /OIGUI                          governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
                 /weblogic                       governancedomain-cluster-oim-cluster:14000 (10.244.4.241:14000)
   Annotations:  kubernetes.io/ingress.class: nginx
                 meta.helm.sh/release-name: governancedomain-nginx
                 meta.helm.sh/release-namespace: oigns
                 nginx.ingress.kubernetes.io/affinity: cookie
                 nginx.ingress.kubernetes.io/affinity-mode: persistent
                 nginx.ingress.kubernetes.io/configuration-snippet:
                   more_clear_input_headers "WL-Proxy-Client-IP" "WL-Proxy-SSL";
                   more_set_input_headers "X-Forwarded-Proto: https";
                   more_set_input_headers "WL-Proxy-SSL: true";
                 nginx.ingress.kubernetes.io/enable-access-log: false
                 nginx.ingress.kubernetes.io/ingress.allow-http: false
                 nginx.ingress.kubernetes.io/proxy-buffer-size: 2000k
                 nginx.ingress.kubernetes.io/proxy-read-timeout: 180
                 nginx.ingress.kubernetes.io/proxy-send-timeout: 180
                 nginx.ingress.kubernetes.io/session-cookie-name: sticky
   Events:
     Type    Reason  Age                From                      Message
     ----    ------  ----               ----                      -------
     Normal  Sync    51m (x3 over 54m)  nginx-ingress-controller  Scheduled for sync
   ```   