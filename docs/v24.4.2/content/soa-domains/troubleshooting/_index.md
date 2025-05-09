+++
title = "Troubleshooting"
weight = 10
pre = "<b>10. </b>"
description = "Describes common issues that may occur during Oracle SOA Suite deployment on Kubernetes and the steps to troubleshoot them."
+++

This document describes common issues that may occur during the deployment of Oracle SOA Suite on Kubernetes and the steps to troubleshoot them. Also refer to the [FAQs](https://oracle.github.io/fmw-kubernetes/soa-domains/faq/) page for frequent issues and steps to resolve them.

* [WebLogic Kubernetes Operator installation failure](#weblogic-kubernetes-operator-installation-failure)
* [RCU schema creation failure](#rcu-schema-creation-failure)
* [Domain creation failure](#domain-creation-failure)
* [Common domain creation issues](#common-domain-creation-issues)
* [Server pods not started after applying domain configuration file](#server-pods-not-started-after-applying-domain-configuration-file)
* [Ingress controller not serving the domain urls](#ingress-controller-not-serving-the-domain-urls)
* [Security warnings reported in WebLogic Administration console](#security-warnings-reported-in-weblogic-administration-console)
* [Disable Remote Anonymous RMI T3 and IIOP Requests](#disable-remote-anonymous-rmi-t3-and-iiop-requests)
* [Oracle Service Bus OWSM policy error](#oracle-service-bus-owsm-policy-error)

#### WebLogic Kubernetes Operator installation failure
If the WebLogic Kubernetes Operator installation failed with timing out:
   - Check the status of the operator Helm release using the command `helm ls -n <operator-namespace>`.
   - Check if the operator pod is successfully created in the operator namespace.
   - Describe the operator pod using `kubectl describe pod <operator-pod-name> -n <operator-namespace>` to identify any obvious errors.

#### RCU schema creation failure
When creating the RCU schema using `create-rcu-schema.sh`, the possible causes for RCU schema creation failure are:
   - Database is not up and running
   - Incorrect database connection URL used
   - Invalid database credentials used
   - Schema prefix already exists

Make sure that all the above causes are reviewed and corrected as needed.  
Also [drop the existing schema]({{< relref "/soa-domains/cleanup-domain-setup#drop-the-rcu-schemas" >}}) with the same prefix before rerunning the `create-rcu-schema.sh` with correct values.

#### Domain creation failure
If the Oracle SOA Suite domain creation fails when running `create-domain.sh`, perform the following steps to diagnose the issue:

1. Run the following command to diagnose the create domain job:

   ```bash
   $ kubectl logs jobs/<domain_job> -n <domain_namespace>
   ```

   For example:

   ```bash
   $ kubectl logs jobs/soainfra-create-soa-infra-domain-job -n soans
   ```

   Also run:

   ```bash
   $ kubectl describe pod <domain_job> -n <domain_namespace>
   ```   

   For example:

   ```bash
   $ kubectl describe pod soainfra-create-soa-infra-domain-job-mcc6v -n soans
   ```

   Use the output to diagnose the problem and resolve the issue.

1. Clean up the failed domain creation:
   1. Delete the failed domain creation job in the domain namespace using the command `kubectl delete job <domain-creation-job-name> -n <domain-namespace>`.
   1. [Delete the contents of the domain home directory]({{< relref "/soa-domains/cleanup-domain-setup#delete-the-domain-home" >}})
   1. [Drop the existing RCU schema]({{< relref "/soa-domains/cleanup-domain-setup#drop-the-rcu-schemas" >}})

1. Recreate the domain:
   1. [Recreate the RCU schema]({{< relref "/soa-domains/installguide/prepare-your-environment#run-the-repository-creation-utility-to-set-up-your-database-schemas" >}})
   1. Make sure the Persistent Volume and Persistent Volume Claim used for the domain are created with correct permissions and bound together.
   1. [Rerun the create domain script]({{< relref "/soa-domains/installguide/create-soa-domains/#run-the-create-domain-script" >}})

#### Common domain creation issues
A common domain creation issue is error `Failed to build JDBC Connection object` in the create domain job logs.

   {{%expand "Click here to see the error stack trace:" %}}
   ```
   Configuring the Service Table DataSource...
   fmwDatabase  jdbc:oracle:thin:@orclcdb.soainfra-domain-ns-293-10202010:1521/orclpdb1
   Getting Database Defaults...
   Error: getDatabaseDefaults() failed. Do dumpStack() to see details.
   Error: runCmd() failed. Do dumpStack() to see details.
   Problem invoking WLST - Traceback (innermost last):
   File "/u01/weblogic/..2021_10_20_20_29_37.256759996/createSOADomain.py", line 943, in ?
   File "/u01/weblogic/..2021_10_20_20_29_37.256759996/createSOADomain.py", line 75, in createSOADomain
   File "/u01/weblogic/..2021_10_20_20_29_37.256759996/createSOADomain.py", line 695, in extendSoaB2BDomain
   File "/u01/weblogic/..2021_10_20_20_29_37.256759996/createSOADomain.py", line 588, in configureJDBCTemplates
   File "/tmp/WLSTOfflineIni956349269221112379.py", line 267, in getDatabaseDefaults
   File "/tmp/WLSTOfflineIni956349269221112379.py", line 19, in command
   Failed to build JDBC Connection object:
      at com.oracle.cie.domain.script.jython.CommandExceptionHandler.handleException(CommandExceptionHandler.java:69)
      at com.oracle.cie.domain.script.jython.WLScriptContext.handleException(WLScriptContext.java:3085)
      at com.oracle.cie.domain.script.jython.WLScriptContext.runCmd(WLScriptContext.java:738)
      at sun.reflect.GeneratedMethodAccessor152.invoke(Unknown Source)
      at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
      at java.lang.reflect.Method.invoke(Method.java:498)
   com.oracle.cie.domain.script.jython.WLSTException: com.oracle.cie.domain.script.jython.WLSTException: Got exception when auto configuring the schema component(s) with data obtained from shadow table:
   Failed to build JDBC Connection object:
   ERROR: /u01/weblogic/create-domain-script.sh failed.
   ```   
   {{% /expand %}}

   This error is reported when there is an issue with database schema access during domain creation. The possible causes are:
   * Incorrect schema name specified in `create-domain-inputs.yaml`.
   * RCU schema credentials specified in the secret `soainfra-rcu-credentials` are different from the credentials specified while creating the RCU schema using `create-rcu-schema.sh`.

   To resolve these possible causes, check that the schema name and credentials used during the domain creation are the same as when the RCU schema was created.

#### Server pods not started after applying domain configuration file

When a domain configuration file (YAML) is deployed and no introspector or server pods are initiated, as well as there is no mention of the domain in the operator log, ensure that the domain's namespace has been configured to be managed by WebLogic Kubernetes Operator.

The `domainNamespaceSelectionStrategy` configuration in the operator installation Helm chart determines the namespaces managed by operators. The default value of the `domainNamespaceSelectionStrategy` Helm chart value was altered between versions 3.4 and 4.0. In version 3.4, the default value was `List` and in version 4.0, the default value is `LabelSelector`. Therefore, instead of managing the set of namespaces listed in the `domainNamespaces` Helm chart value, the operator now searches for namespaces with the label specified in the `domainNamespaceLabelSelector` Helm chart value, which defaults to `weblogic-operator=enabled`.

For operator versions 3.4 and lower, you can verify the configuration by running the command `helm get values  <operator-release> -n <operator-namespace>` and checking the values under the `domainNamespaces` section.

For example:
```
$ helm get values  weblogic-kubernetes-operator -n opns
USER-SUPPLIED VALUES:
domainNamespaces:
- soans
image: ghcr.io/oracle/weblogic-kubernetes-operator:3.4.4
javaLoggingLevel: FINE
serviceAccount: op-sa
$
```
If you don't see the domain namespace value under the `domainNamespaces` section, run the `helm upgrade` command in the operator namespace with appropriate values to configure the operator to manage the domain namespace.

```
$ helm upgrade --reuse-values --namespace opns --set "domainNamespaces={soans}" --wait weblogic-kubernetes-operator charts/weblogic-operator
```

For operator versions 4.0 and higher, verify if the label `weblogic-operator=enabled` is specified for domain namespace that is to be managed by the operator, by running the following command:

```
$ kubectl get ns --selector="weblogic-operator=enabled"
```
For example, if your domain namespace is `soans` and the preceding command did not list the `soans` namespace, then execute the following command for operator to manage the domain namespace:

```
$ kubectl label namespace soans weblogic-operator=enabled
```

#### Ingress controller not serving the domain URLs
To diagnose this issue:
1. Verify that the Ingress controller is installed successfully.  
   For example, to verify the `Traefik` Ingress controller status, run the following command:
   ```
   $ helm list -n traefik
   NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART               APP VERSION
   traefik                  traefik         2               2022-11-30 11:31:18.599876918 +0000 UTC deployed        traefik-20.5.3       v2.9.5
   $
   ```
1. Verify that the Ingress controller is setup to monitor the domain namespace.  
   For example, to verify the `Traefik` Ingress controller manages the `soans` domain namespace, run the following command and check the values under `namespaces` section.
   ```
   $ helm get values traefik-operator -n traefik
   USER-SUPPLIED VALUES:
   kubernetes:
      namespaces:
      - traefik
      - soans
   $
   ```
1. Verify that the Ingress chart is installed correctly in domain namespace. For example, run the following command:
   ```
   $ helm list -n soans
   NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                       APP VERSION
   soainfra-traefik        soans           1               2021-10-27 11:24:31.7572791 +0000 UTC   deployed        ingress-per-domain-0.1.0    1.0
   $
   ```
1. Verify that the Ingress URL paths and hostnames are configured correctly by running the following commands:
   {{%expand "Click here to see the sample commands and output" %}}
   ```
   $ kubectl get ingress soainfra-traefik -n soans
   NAME               CLASS    HOSTS                                                     ADDRESS   PORTS   AGE
   soainfra-traefik   <none>   <Hostname>             80      20h
   $
   $ kubectl describe ingress soainfra-traefik -n soans
   Name:             soainfra-traefik
   Namespace:        soans
   Address:
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
   Host                                                     Path  Backends
   ----                                                     ----  --------
   <Hostname>
                                                            /console                   soainfra-adminserver:7001 (10.244.0.123:7001)
                                                            /em                        soainfra-adminserver:7001 (10.244.0.123:7001)
                                                            /weblogic/ready            soainfra-adminserver:7001 (10.244.0.123:7001)
                                                            /soa-infra                 soainfra-cluster-soa-cluster:7003 (10.244.0.126:7003,10.244.0.127:7003)
                                                            /soa/composer              soainfra-cluster-soa-cluster:7003 (10.244.0.126:7003,10.244.0.127:7003)
                                                            /integration/worklistapp   soainfra-cluster-soa-cluster:7003 (10.244.0.126:7003,10.244.0.127:7003)
                                                            /EssHealthCheck            soainfra-cluster-soa-cluster:7003 (10.244.0.126:7003,10.244.0.127:7003)
   Annotations:                                               kubernetes.io/ingress.class: traefik
                                                            meta.helm.sh/release-name: soainfra-traefik
                                                            meta.helm.sh/release-namespace: soans
   Events:                                                    <none>
   $
   ```
   {{% /expand %}}


#### Security warnings reported in WebLogic Administration console

With the July 2021 PSU applied, WebLogic Server regularly validates your domain configuration settings against a set of security configuration guidelines to determine whether the domain meets key security guidelines recommended by Oracle. If your domain does not meet a recommendation for a security configuration setting, a warning is logged in the Security Warnings Report in the WebLogic Administration Console. 

See [Review Potential Security Issues](https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/lockd/secure.html#GUID-4148D1BE-2D54-4DA5-8E94-A35D48DCEF1D) in Securing a Production Environment for Oracle WebLogic Server for more information.

#### Disable Remote Anonymous RMI T3 and IIOP Requests

If you see security warning message that `Remote Anonymous RMI T3 or IIOP requests are enabled`, resolve this warning by setting RemoteAnonymousRMIT3Enabled and RemoteAnonymousRMIIIOPEnabled attributes to false in `domain.yaml` with `JAVA_OPTIONS` before starting the domain as shown below:

```
serverPod:
    # an (optional) list of environment variable to be set on the servers
    env:
    - name: JAVA_OPTIONS
      value: "-Dweblogic.StdoutDebugEnabled=false -Dweblogic.ssl.Enabled=true -Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.security.remoteAnonymousRMIT3Enabled=false -Dweblogic.security.remoteAnonymousRMIIIOPEnabled=false"
``` 

See [link](https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/lockd/secure.html#GUID-D053EEFA-7461-4A22-865A-1180A49CACCD) for more details.

#### Oracle Service Bus OWSM policy error
If you see error messages like 
`CannotCommit [OSB-387177]OWSM Policy oracle/xxxxxx is not supported` on Oracle Service Bus console and exceptions like `oracle.wsm.policymanager.PolicyManagerException: WSM-02141 : Unable to connect to the policy access service due to Oracle WSM policy manager host server being down` in Administration server logs, resolve this error by targeting the `wsm-pm` application to Administration server. See [link](https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/12.2.1.4/wlach/taskhelp/deployment/ChangeTargetServers.html) for details.
