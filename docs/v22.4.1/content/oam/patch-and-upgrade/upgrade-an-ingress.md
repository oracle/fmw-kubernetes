---
title: "c. Upgrade Ingress"
description: "Instructions on how to upgrade the ingress."
---

This section shows how to upgrade the ingress.

To determine if this step is required for the version you are upgrading to, refer to the [Release Notes](../../release-notes).

### Download the latest code repository

Download the latest code repository as follows:

1. Create a working directory to setup the source code.
   ```bash
   $ mkdir <workdir>
   ```
   
   For example:
   ```bash
   $ mkdir /scratch/OAMK8Slatest
   ```
   
1. Download the latest OAM deployment scripts from the OAM repository.

   ```bash
   $ cd <workdir>
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/22.4.1
   ```
   
   For example:
   
   ```bash
   $ cd /scratch/OAMK8Slatest
   $ git clone https://github.com/oracle/fmw-kubernetes.git --branch release/22.4.1
   ```

1. Set the `$WORKDIR` environment variable as follows:

   ```bash
   $ export WORKDIR=<workdir>/fmw-kubernetes/OracleAccessManagement
   ```

   For example:
   
   ```bash
   $ export WORKDIR=/scratch/OAMK8Slatest/fmw-kubernetes/OracleAccessManagement
   ```

### Upgrading the ingress

To upgrade the existing ingress rules, follow the steps below: 

1. List the existing ingress:

   ```
   $ helm list -n oamns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME            NAMESPACE       REVISION        UPDATED     STATUS          CHART                       APP VERSION
   nginx-ingress   oamns           1               <DATE>      deployed        ingress-nginx-4.3.0         1.4.0
   oam-nginx       oamns           1               <DATE>      deployed        ingress-per-domain-0.1.0    1.0
   ```

1. Edit the `$WORKDIR/kubernetes/charts/ingress-per-domain/values.yaml` and change the `domainUID` parameter to match your domainUID, for example `domainUID: accessdomain`. For example:

   ```
   # Load balancer type. Supported values are: NGINX
   type: NGINX

   # SSL configuration Type. Supported Values are : NONSSL,SSL
   sslType: SSL

   # domainType. Supported values are: oam
   domainType: oam

   #WLS domain as backend to the load balancer
   wlsDomain:
     domainUID: accessdomain
     adminServerName: AdminServer
     adminServerPort: 7001
     adminServerSSLPort:
     oamClusterName: oam_cluster
     oamManagedServerPort: 14100
     oamManagedServerSSLPort:
     policyClusterName: policy_cluster
     policyManagedServerPort: 15100
     policyManagedServerSSLPort:


   # Host  specific values
   hostName:
     enabled: false
     admin:
     runtime:
   ```
   
1. Upgrade the `oam-nginx` with the following command:

   ```
   $ helm upgrade oam-nginx kubernetes/charts/ingress-per-domain/ --namespace oamns --values kubernetes/charts/ingress-per-domain/values.yaml --reuse-values
   ```
   
   The output will look similar to the following:
   
   ```
   Release "oam-nginx" has been upgraded. Happy Helming!
   NAME: oam-nginx
   LAST DEPLOYED: <DATE>
   NAMESPACE: oamns
   STATUS: deployed
   REVISION: 2
   TEST SUITE: None
   ```


1. List the ingress:

   ```
   $ kubectl get ing -n oamns
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                 CLASS    HOSTS   ADDRESS        PORTS   AGE
   accessdomain-nginx   <none>   *       10.99.189.61   80      18s
   ```

1. Describe the ingress and make sure all the listed paths are accessible:

   ```
   $ kubectl describe ing accessdomain-nginx -n oamns
   ```
   
   The output will look similar to the following:
   
   ```
   Name:             accessdomain-nginx
   Labels:           app.kubernetes.io/managed-by=Helm
   Namespace:        oamns
   Address:          10.99.189.61
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                 /console                        accessdomain-adminserver:7001 (10.244.1.224:7001)
                 /consolehelp                    accessdomain-adminserver:7001 (10.244.1.224:7001)
                 /rreg/rreg                      accessdomain-adminserver:7001 (10.244.1.224:7001)
                 /em                             accessdomain-adminserver:7001 (10.244.1.224:7001)
                 /oamconsole                     accessdomain-adminserver:7001 (10.244.1.224:7001)
                 /dms                            accessdomain-adminserver:7001 (10.244.1.224:7001)
                 /oam/services/rest              accessdomain-adminserver:7001 (10.244.1.224:7001)
                 /iam/admin/config               accessdomain-adminserver:7001 (10.244.1.224:7001)
                 /iam/admin/diag                 accessdomain-adminserver:7001 (10.244.1.224:7001)
                 /iam/access                     accessdomain-cluster-oam-cluster:14100 (10.244.1.225:14100)
                 /oam/admin/api                  accessdomain-adminserver:7001 (10.244.1.224:7001)
                 /oam/services/rest/access/api   accessdomain-cluster-oam-cluster:14100 (10.244.1.225:14100)
                 /access                         accessdomain-cluster-policy-cluster:15100 (10.244.1.226:15100)
                 /                               accessdomain-cluster-oam-cluster:14100 (10.244.1.225:14100)
   Annotations:  kubernetes.io/ingress.class: nginx
                 meta.helm.sh/release-name: oam-nginx
                 meta.helm.sh/release-namespace: oamns
                 nginx.ingress.kubernetes.io/configuration-snippet:
                   more_clear_input_headers "WL-Proxy-Client-IP" "WL-Proxy-SSL";
                   more_set_input_headers "X-Forwarded-Proto: https";
                   more_set_input_headers "WL-Proxy-SSL: true";
                 nginx.ingress.kubernetes.io/enable-access-log: false
                 nginx.ingress.kubernetes.io/ingress.allow-http: false
                 nginx.ingress.kubernetes.io/proxy-buffer-size: 2000k
   Events:
     Type    Reason  Age                From                      Message
     ----    ------  ----               ----                      -------
     Normal  Sync    55s (x2 over 63s)  nginx-ingress-controller  Scheduled for sync
   ```   
