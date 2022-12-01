---
title: "Frequently Asked Questions"
date: 2019-02-22T15:44:42-05:00
draft: false
weight: 8
pre : "<b>8. </b>"
description: "This section describes known issues for Oracle SOA Suite domain deployment on Kubernetes. It also provides answers to frequently asked questions."
---


#### Overriding tuning parameters is not supported using configuration overrides

The WebLogic Kubernetes Operator enables you to override some of the domain configuration using configuration overrides (also called situational configuration).
See [supported overrides](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/configoverrides/#typical-overrides). Overriding the tuning parameters such as **MaxMessageSize** and **PAYLOAD**,  for Oracle SOA Suite domains is not supported using the configuration overrides feature. However, you can override them using the following steps:

1. Specify the new value using the environment variable `K8S_REFCONF_OVERRIDES` in `serverPod.env` section in `domain.yaml` configuration file (example path: `<domain-creation-output-directory>/weblogic-domains/soainfra/domain.yaml`) based on the servers to which the changes are to be applied.

    For example, to override the value at the Administration Server pod level:
    ```bash
      spec:
        adminServer:
          serverPod:
            env:
            - name: K8S_REFCONF_OVERRIDES
              value: "-Dweblogic.MaxMessageSize=78787878"
            - name: USER_MEM_ARGS
              value: '-Djava.security.egd=file:/dev/./urandom -Xms512m -Xmx1024m '
          serverStartState: RUNNING
    ```

    For example, to override the value at a specific cluster level (`soa_cluster` or `osb_cluster`):
    ```bash
      - clusterName: soa_cluster
      serverService:
        precreateService: true
      serverStartState: "RUNNING"
      serverPod:
        env:
        - name: K8S_REFCONF_OVERRIDES
          value: "-Dsoa.payload.threshold.kb=102410"
    ```
    > Note: When multiple system properties are specified for `serverPod.env.value`, make sure each system property is separated by a space.

1. Apply the updated `domain.yaml` file:

    ``` bash
    $ kubectl apply -f domain.yaml
    ```
   > Note: The server pod(s) will be automatically restarted (rolling restart).

#### Deployments in the WebLogic Server Administration Console may display unexpected error

In an Oracle SOA Suite environment deployed using the operator, accessing **Deployments** from the WebLogic Server Administration Console home page may display the error message `Unexpected error encountered while obtaining monitoring information for applications`. This error does not have any functional impact and can be ignored. You can verify that the applications are in **Active** state from the **Control** tab in **Summary of deployments** page.


#### Enterprise Manager Console may display ADF_FACES-30200 error

In an Oracle SOA Suite environment deployed using the operator, the Enterprise Manager Console may intermittently display the following error when the domain servers are restarted:

``` bash
ADF_FACES-30200: For more information, please see the server's error log for an entry beginning with: The UIViewRoot is null. Fatal exception during PhaseId: RESTORE_VIEW 1.
```

You can refresh the Enterprise Manager Console URL to successfully log in to the Console.


#### Configure the external URL access for Oracle SOA Suite composite applications

For Oracle SOA Suite composite applications to access the external URLs over the internet (if your cluster is behind a http proxy server), you must configure the following proxy parameters for Administration Server and Managed Server pods.

``` bash
-Dhttp.proxyHost=www-your-proxy.com  
-Dhttp.proxyPort=proxy-port  
-Dhttps.proxyHost=www-your-proxy.com  
-Dhttps.proxyPort=proxy-port  
-Dhttp.nonProxyHosts="localhost|soainfra-adminserver|soainfra-soa-server1|soainfra-osb-server1|...soainfra-soa-serverN|*.svc.cluster.local|*.your.domain.com|/var/run/docker.sock"  
```
To do this, edit the `domain.yaml` configuration file and append the proxy parameters to the `spec.serverPod.env.JAVA_OPTIONS` environment variable value.

For example:
```bash
  serverPod:
    env:
    - name: JAVA_OPTIONS
      value: -Dweblogic.StdoutDebugEnabled=false -Dweblogic.ssl.Enabled=true -Dweblogic.security.SSL.ignoreHostnameVerification=true -Dhttp.proxyHost=www-your-proxy.com -Dhttp.proxyPort=proxy-port -Dhttps.proxyHost=www-your-proxy.com -Dhttps.proxyPort=proxy-port -Dhttp.nonProxyHosts="localhost|soainfra-adminserver|soainfra-soa-server1|soainfra-osb-server1|...soainfra-soa-serverN|*.svc.cluster.local|*.your.domain.com|/var/run/docker.sock"
    - name: USER_MEM_ARGS
      value: '-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx1024m '
    volumeMounts:
```

> Note: The `-Dhttp.nonProxyHosts` parameter must have the pod names of the Administration Server and each Managed Server. For example: `soainfra-adminserver`, `soainfra-soa-server1`, `soainfra-osb-server1`, and so on.

Apply the updated `domain.yaml` file:

``` bash
 $ kubectl apply -f domain.yaml
```
> Note: The server pod(s) will be automatically restarted (rolling restart).


#### Configure the external access for the Oracle Enterprise Scheduler WebServices WSDL URLs

In an Oracle SOA Suite domain deployed including the Oracle Enterprise Scheduler (ESS) component, the following ESS WebServices WSDL URLs shown in the table format in the `ess/essWebServicesWsdl.jsp` page are not reachable outside the Kubernetes cluster.

```bash
ESSWebService
EssAsyncCallbackService
EssWsJobAsyncCallbackService
```

Follow these steps to configure the external access for the Oracle Enterprise Scheduler WebServices WSDL URLs:

1. Log in to the Administration Console URL of the domain.  
   For example: `http://<LOADBALANCER-HOST>:<port>/console`
1. In the **Home** Page, click **Clusters**. Then click the **soa_cluster**.
1. Click the **HTTP** tab and then click **Lock & Edit** in the Change Center panel.
1. Update the following values:
   * **Frontend Host**: host name of the load balancer. For example, `domain1.example.com`.
   * **Frontend HTTP Port**: load balancer port. For example, `30305`.  
   * **Frontend HTTPS Port**: load balancer https port. For example, `30443`.
1. Click **Save**.
1. Click **Activate Changes** in the Change Center panel.
1. [Restart the servers](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-lifecycle/startup/#restart-all-the-servers-in-the-cluster) in the SOA cluster.

> Note: Do not restart servers from the Administration Console.

#### Missing gif images in Oracle Service Bus console pipeline configuration page

In an Oracle SOA Suite domain environment upgraded to the release 21.1.2, some gif images are not rendered in the Oracle Serice Bus console pipeline configuration page, as their corresponding url paths are not exposed via the Ingress path rules in the earlier releases (for Non-SSL and SSL termination). To resolve this issue, perform the following steps to apply the latest ingress configuration:

```
$ cd ${WORKDIR}
$ helm upgrade <helm_release_for_ingress> \
    charts/ingress-per-domain \
    --namespace <domain_namespace> \
    --reuse-values
```
>**Note**: `helm_release_for_ingress` is the ingress name used in the corresponding helm install command for the ingress installation.

For example, to upgrade the `NGINX` based ingress configuration:
```
$ cd ${WORKDIR}
$ helm upgrade soa-nginx-ingress \
    charts/ingress-per-domain \
    --namespace soans \
    --reuse-values
```

#### WebLogic Kubernetes Operator FAQs

See the general [frequently asked questions for using the WebLogic Kubernetes Operator](https://oracle.github.io/weblogic-kubernetes-operator/faq/).
