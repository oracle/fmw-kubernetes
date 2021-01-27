---
title: "Frequently Asked Questions"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 7
pre : "<b>7. </b>"
description: "This section describes known issues for Oracle WebCenter Sites domains deployment on Kubernetes. Also, provides answers to frequently asked questions."
---


#### Configure the external URL access for Oracle WebCenter Sites composite applications

For Oracle WebCenter Sites composite applications to access the external URLs over the internet (if your cluster is behind a http proxy server), you must configure the following proxy parameters for Administration Server and Managed Server pods.

``` bash
-Dhttp.proxyHost=www-your-proxy.com  
-Dhttp.proxyPort=proxy-port  
-Dhttps.proxyHost=www-your-proxy.com  
-Dhttps.proxyPort=proxy-port  
-Dhttp.nonProxyHosts="localhost|wcsitesinfra-adminserver|wcsitesinfra-wcsites-server1|*.svc.cluster.local|*.your.domain.com|/var/run/docker.sock"  
```
To do this, edit the `domain.yaml` configuration file and append the proxy parameters to the `spec.serverPod.env.JAVA_OPTIONS` environment variable value.

For example:
```bash
  serverPod:
    env:
    - name: JAVA_OPTIONS
      value: -Dweblogic.StdoutDebugEnabled=false -Dweblogic.ssl.Enabled=true -Dweblogic.security.SSL.ignoreHostnameVerification=true -Dhttp.proxyHost=www-your-proxy.com -Dhttp.proxyPort=proxy-port -Dhttps.proxyHost=www-your-proxy.com -Dhttps.proxyPort=proxy-port -Dhttp.nonProxyHosts="localhost|wcsitesinfra-adminserver|wcsitesinfra-wcsites-server1|*.svc.cluster.local|*.your.domain.com|/var/run/docker.sock"
    - name: USER_MEM_ARGS
      value: '-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m '
    volumeMounts:
```

> Note: The `-Dhttp.nonProxyHosts` parameter must have the pod names of the Administration Server and each Managed Server. For example: `wcsitesinfra-adminserver`, `wcsitesinfra-wcsites-server1`, and so on.

Apply the updated `domain.yaml` file:

``` bash
 $ kubectl apply -f domain.yaml
```
> Note: The server pod(s) will be automatically restarted (rolling restart).


#### Oracle WebLogic Server Kubernetes Operator FAQs

See the general [frequently asked questions for using the Oracle WebLogic Server Kubernetes operator](https://oracle.github.io/weblogic-kubernetes-operator/faq/).
