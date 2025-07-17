---
title: "Prepare your environment"
weight: 4
pre : "<b>4. </b>"
description: "Prepare your environment for OHS on Kubernetes."
---
To prepare for Oracle HTTP Server (OHS) deployment in a Kubernetes environment, complete the following steps:

1. [Check the Kubernetes cluster is ready](#check-the-kubernetes-cluster-is-ready)
1. [Obtain the OHS container image](#obtain-the-ohs-container-image)
1. [Set up the code repository to deploy OHS](#set-up-the-code-repository-to-deploy-ohs)
1. [Prepare your OHS configuration files](#prepare-your-ohs-configuration-files)
1. [Create configmaps for the OHS configuration files](#create-configmaps-for-the-ohs-configuration-files)
1. [Create a namespace for OHS](#create-a-namespace-for-ohs)
1. [Create a Kubernetes secret for the container registry](#create-a-kubernetes-secret-for-the-container-registry)
1. [Prepare the ohs.yaml file](#prepare-the-ohs.yaml-file)


## Check the Kubernetes cluster is ready

As per the [Prerequisites](../prerequisites/#system-requirements-for-oam-domains) a Kubernetes cluster should have already been configured.

Check that all the nodes in the Kubernetes cluster are running.

1. Run the following command on the administrative host to check the cluster and worker nodes are running:
    
   ```bash
   $ kubectl get nodes,pods -n kube-system
   ```
	
    The output will look similar to the following:

   ```
    NAME                  STATUS   ROLES                  AGE   VERSION
    node/worker-node1     Ready    <none>                 17h   v1.30.3+1.el8
    node/worker-node2     Ready    <none>                 17h   v1.30.3+1.el8
    node/master-node      Ready    control-plane,master   23h   v1.30.3+1.el8

    NAME                                     READY   STATUS    RESTARTS   AGE
    pod/coredns-66bff467f8-fnhbq             1/1     Running   0          23h
    pod/coredns-66bff467f8-xtc8k             1/1     Running   0          23h
    pod/etcd-master                          1/1     Running   0          21h
    pod/kube-apiserver-master-node           1/1     Running   0          21h
    pod/kube-controller-manager-master-node  1/1     Running   0          21h
    pod/kube-flannel-ds-amd64-lxsfw          1/1     Running   0          17h
    pod/kube-flannel-ds-amd64-pqrqr          1/1     Running   0          17h
    pod/kube-flannel-ds-amd64-wj5nh          1/1     Running   0          17h
    pod/kube-proxy-2kxv2                     1/1     Running   0          17h
    pod/kube-proxy-82vvj                     1/1     Running   0          17h
    pod/kube-proxy-nrgw9                     1/1     Running   0          23h
    pod/kube-scheduler-master                1/1     Running   0          21h
   ```
	
## Obtain the OHS container image

The OHS Kubernetes deployment requires access to an OHS container image. The image can be obtained in the following ways:

- Prebuilt OHS container image
- Build your own OHS container image using WebLogic Image Tool

### Prebuilt OHS container image


The prebuilt OHS July 2025 container image can be downloaded from [Oracle Container Registry](https://container-registry.oracle.com). This image is prebuilt by Oracle and includes Oracle HTTP Server 12.2.1.4.0, the July 2025 Patch Set Update (PSU) and other fixes released with the Critical Patch Update (CPU) program.

**Note**: Before using this image you must login to [Oracle Container Registry](https://container-registry.oracle.com), navigate to `Middleware` > `ohs_cpu` and accept the license agreement.

You can use this image in the following ways:

- Pull the container image from the Oracle Container Registry automatically during the OHS Kubernetes deployment.
- Manually pull the container image from the Oracle Container Registry and then upload it to your own container registry.
- Manually pull the container image from the Oracle Container Registry and manually stage it on each worker node.

### Build your own OHS container image using WebLogic Image Tool

You can build your own OHS container image using the WebLogic Image Tool. This is recommended if you need to apply one off patches to a [Prebuilt OHS container image](#prebuilt-ohs-container-image). For more information about building your own container image with WebLogic Image Tool, see [Create or update image](../create-or-update-image/).

You can use an image built with WebLogic Image Tool in the following ways:

- Manually upload them to your own container registry. 
- Manually stage them on each worker node. 


**Note**: This documentation does not tell you how to pull or push the above images into a private container registry, or stage them on worker nodes. Details of this can be found in the [Enterprise Deployment Guide](https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/ikedg/procuring-software-enterprise-deployment.html).

In all the sections below, the commands are run from a server that has access to the Kubernetes cluster.

## Set up the code repository to deploy OHS

To deploy OHS you need to set up the code repository which provides sample deployment yaml files:

1. Create a directory to setup the source code.

   ```bash
   $ mkdir <ohsscripts>
   ```
   
   For example:
   ```bash
   $ mkdir -p /OHSK8S/OHSscripts
   ```
  
1. Download the latest OHS deployment scripts from the OHS repository.

   ```bash
   $ cd <ohsscripts>
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```
   
   For example:
   
   ```bash
   $ cd /OHSK8S/OHSscripts
   $ git clone https://github.com/oracle/fmw-kubernetes.git
   ```

1. Set the `$SCRIPTDIR` environment variable as follows:

   ```bash
   $ export SCRIPTDIR=<ohsscripts>/fmw-kubernetes/OracleHTTPServer/kubernetes
   ```

   For example:
   
   ```bash
   $ export SCRIPTDIR=/OHSK8S/OHSscripts/fmw-kubernetes/OracleHTTPServer/kubernetes
   ```
   
	
 
   
## Prepare your OHS configuration files

Before you deploy OHS, you must prepare your OHS configuration files. 

The steps below assume familiarity with on premises Oracle HTTP Server in terms of general configuration and use of Oracle WebGate.

**Note**: Administrators should be aware of the following:

   + If you do not specify configuration files beforehand, then the OHS container is deployed with a default configuration of Oracle HTTP Server.
   + The directories listed below are optional. For example, if you do not want to deploy WebGate then you do not need to create the `webgateConf` and `webgateWallet` directories. Similarly, if you do not want to copy files to `htdocs` then you do not need to create the `htdocs` directory.

1. Make a directory to store your OHS configuration files:
   
   ```
   mkdir -p <myohsfiles>
   ```
   
   For example:
	
   ```
   mkdir -p /OHSK8S/myOHSfiles
   ```
	
1. Set the `$MYOHSFILES` environment variable as follows:

   ```bash
   $ export MYOHSFILES=<myohsfiles>
   ```
	
   For example:

   ```bash
   $ export MYOHSFILES=/OHSK8S/myOHSfiles
   ```

1. Create the following directories for your OHS configuration:

   ```
   mkdir -p $MYOHSFILES/ohsConfig/httpconf
   mkdir -p $MYOHSFILES/ohsConfig/moduleconf 
   mkdir -p $MYOHSFILES/ohsConfig/htdocs
   mkdir -p $MYOHSFILES/ohsConfig/htdocs/myapp
   mkdir -p $MYOHSFILES/ohsConfig/webgate/config/wallet
   mkdir -p $MYOHSFILES/ohsConfig/wallet/mywallet
   ```

   Where:
  
   + `httpconf` - contains any configuration files you want to configure that are usually found in the `$OHS_DOMAIN_HOME/config/fmwconfig/components/OHS/ohs1` directory. For example `httpd.conf`, `ssl.conf` and `mod_wl_ohs.conf`. The `webgate.conf` does not need to be copied as this will get generated automatically if deploying with WebGate.
   + `moduleconf` - contains any additional config files, for example virtual host configuration files that you want to copy to the `$OHS_DOMAIN_HOME/config/fmwconfig/components/OHS/ohs1/moduleconf` folder in the container.
   + `htdocs` - contains any html files, or similar, that you want to copy to the `$OHS_DOMAIN_HOME/config/fmwconfig/components/OHS/ohs1/htdocs` folder in the container.
   + `htdocs/myapp` - `myapp` is an example directory name that exists under `htdocs`. If you need to copy any directories under `htdocs` above, then create the directories you require.
   + `webgate/config` - contains the extracted WebGate configuration. For example, when you download the `<agent>.zip` file from Oracle Access Management Console, you extract the zip file into this directory. If you are accessing OAM URL's via SSL, this directory must also contain the Certificate Authority `cacert.pem` file that signed the certificate of the OAM entry point. For example, if you will access OAM via a HTTPS Load Balancer URL, then `cacert.pem` is the CA certificate that signed the load balancer certificate.
   + `webgate/config/wallet` - contains the contents of the wallet directory extracted from the `<agent.zip>` file.
   + `wallet/mywallet` - If OHS is to be configured to use SSL, this directory contains the preconfigured OHS Wallet file `cwallet.sso`.
	
	
   **Note**: Administrators should be aware of the following if configuring OHS for SSL:
	
   + The wallet must contain a valid certificate.
   + Only auto-login-only wallets (`cwallet.sso` only) are supported. For example, wallets created with `orapki` using the `-auto-login-only` option. Password protected wallets (`ewallet.p12`) are not supported.
   + You must configure `ssl.conf` in `$WORKDIR/ohsConfig/httpconf` and set the directory for `SSLWallet` to: `SSLWallet "${ORACLE_INSTANCE}/config/fmwconfig/components/${COMPONENT_TYPE}/instances/${COMPONENT_NAME}/keystores/wallet/mywallet"`. 
			
   An example file system may contain the following:
    
   ```
   ls -R $MYOHSFILES/ohsConfig
   /OHSK8S/myOHSfiles/ohsConfig:
   htdocs  httpconf  moduleconf  wallet  webgate

   /OHSK8S/myOHSfiles/ohsConfig/htdocs:
   myapp  mypage.html

   /OHSK8S/myOHSfiles/ohsConfig/htdocs/myapp:
   index.html

   /OHSK8S/myOHSfiles/ohsConfig/httpconf:
   httpd.conf  mod_wl_ohs.conf  ssl.conf

   /OHSK8S/myOHSfiles/ohsConfig/moduleconf:
   vh.conf

   /OHSK8S/myOHSfiles/ohsConfig/wallet:
   mywallet

   /OHSK8S/myOHSfiles/ohsConfig/wallet/mywallet:
   cwallet.sso

   /OHSK8S/myOHSfiles/ohsConfig/webgate:
   config

   /OHSK8S/myOHSfiles/ohsConfig/webgate/config:
   cacert.pem  cwallet.sso  cwallet.sso.lck  ObAccessClient.xml  wallet

   /OHSK8S/myOHSfiles/ohsConfig/webgate/config/wallet:
   cwallet.sso  cwallet.sso.lck

   ```

	
### Set WLDNSRefreshInterval and WebLogicCluster directives

If your OHS deployment is configured to communicate with Oracle WebLogic Server, then you must set the `WLDNSRefreshInterval` and `WebLogicCluster` directives in your OHS configuration files appropriately.

In the file where your WLS location directives reside, you must set the following:

```
<IfModule weblogic_module>
WLDNSRefreshInterval 10
</IfModule>
```

For `WebLogicCluster`, the values to set depend on whether the WLS is deployed on-premises, on the same Kubernetes cluster as OHS, or on a different Kubernetes cluster to OHS. The following sections explain how to set the values in each case.


#### On-premises configuration

If OHS is connecting to a WebLogic Server deployed in an on-premises configuration (non-Kubernetes), then set:

```
WebLogicCluster <APPHOST1>:<PORT>,<APPHOST2>:<PORT>
```

For example, if you were connecting to the WebLogic Server Administration Server port:
	
   ```
    <Location /console>
      WLSRequest ON
      DynamicServerList OFF
      WLProxySSL ON
      WLProxySSLPassThrough ON
      WLCookieName OAMJSESSIONID
      WebLogicCluster APPHOST1.example.com:7001,APPHOST2.example.com:7001
    </Location>   
   ```


#### Oracle HTTP Server on a shared  Kubernetes Cluster

If OHS is connecting to a WebLogic Server deployed on the same Kubernetes cluster, then set the following depending on your environment:

```
WebLogicHost <service_name>.<namespace>.svc.cluster.local
WebLogicPort <port>
```

or:

```
WebLogicCluster <service_name>.<namespace>.svc.cluster.local:<port>
```



**Note**: You can get the `<service_name>` and `<port>` by running `kubectl get svc -n <namespace>` on your Kubernetes cluster.


The following shows an example when connecting to an Oracle Access Management (OAM) Administration Server cluster service and port:
	
   ```
   <Location /console>
      WLSRequest ON
      DynamicServerList OFF
      WLProxySSL ON
      WLProxySSLPassThrough ON
      WLCookieName OAMJSESSIONID
      WebLogicHost accessdomain-adminserver.oamns.svc.cluster.local
      WebLogicPort 7001
    </Location>
   ```
	
The following shows an example when connecting to an Oracle Access Management (OAM) Managed Server cluster service and port:

   ```
   <Location /oam>
   WLSRequest ON
   DynamicServerList OFF
   WLProxySSL ON
   WLProxySSLPassThrough ON
   WLCookieName OAMJSESSIONID
   WebLogicCluster accessdomain-cluster-oam-cluster.oamns.svc.cluster.local:14100
   ```
	
#### Oracle HTTP Server on an independent Kubernetes Cluster
	
If OHS is connecting to a WebLogic Server deployed on a separate Kubernetes cluster, then set:

   ```
   WebLogicCluster <K8S_WORKER_HOST1>:30777,<K8S_WORKER_HOST2>:30777,<K8S_WORKER_HOST3>:30777
   ```
	
   Where `<K8S_WORKER_HOSTX>` is your Kubernetes worker node `hostname.domain`, and `30777` is the HTTP port of the ingress controller.

   For example:
	
   ```
    <Location /console>
      WLSRequest ON
      DynamicServerList OFF
      WLProxySSL ON
      WLProxySSLPassThrough ON
      WLCookieName OAMJSESSIONID
      WebLogicCluster K8_WORKER_HOST1.example.com:30777,K8_WORKER_HOST2.example.com:30777,K8_WORKER_HOST3.example.com:30777
    </Location>
   ```

	
### Create a namespace for OHS

Run the following command to create a namespace for the OHS:

```bash
$ kubectl create namespace <namespace>
```
  
For example:
  
```bash
$ kubectl create namespace ohsns
```
  
The output will look similar to the following:
  
```
namespace/ohsns created
```

### Create configmaps for the OHS configuration files


**Note**: Before following this section, make sure you have created the directories and files as per [Prepare your OHS configuration files](#prepare-your-ohs-configuration-files).



1. Run the following commands to create the required configmaps for the OHS directories and files created in [Prepare your OHS configuration files](#prepare-your-ohs-configuration-files).

   ```
   cd $MYOHSFILES
   kubectl create cm -n ohsns ohs-config --from-file=ohsConfig/moduleconf
   kubectl create cm -n ohsns ohs-httpd --from-file=ohsConfig/httpconf
   kubectl create cm -n ohsns ohs-htdocs --from-file=ohsConfig/htdocs
   kubectl create cm -n ohsns ohs-myapp --from-file=ohsConfig/htdocs/myapp
   kubectl create cm -n ohsns webgate-config --from-file=ohsConfig/webgate/config
   kubectl create cm -n ohsns webgate-wallet --from-file=ohsConfig/webgate/config/wallet
   kubectl create cm -n ohsns ohs-wallet --from-file=ohsConfig/wallet/mywallet
   ```
	
   **Note**: Only create the configmaps for directories that you want to copy to OHS.
	
### Create a Kubernetes secret for the container registry

In this section you create a secret that stores the credentials for the container registry where the OHS image is stored.

If you are not using a container registry and have loaded the images on each of the worker nodes, then there is no need to create the registry secret.

1. Run the following command to create the secret:

   ```
   $ kubectl create secret docker-registry "regcred" --docker-server=<CONTAINER_REGISTRY> \
   --docker-username="<USER_NAME>" \
   --docker-password=<PASSWORD> --docker-email=<EMAIL_ID> \
   --namespace=<domain_namespace>
   ```
	
   For example, if using Oracle Container Registry:
	
   ```
   $ kubectl create secret docker-registry "regcred" --docker-server=container-registry.oracle.com \
   --docker-username="user@example.com" \
   --docker-password=password --docker-email=user@example.com \
   --namespace=ohsns
   ```
	
   Replace `<USER_NAME>` and `<PASSWORD>` with the credentials for the registry with the following caveats:

   If using Oracle Container Registry to pull the OHS container image, this is the username and password used to login to Oracle Container Registry. Before you can use this image you must login to [Oracle Container Registry](https://container-registry.oracle.com/) , navigate to `Middleware` > `ohs_cpu` and accept the license agreement.

   If using your own container registry to store the OHS container image, this is the username and password (or token) for your container registry.

   The output will look similar to the following:

   ```
   secret/regcred created
   ```
	
### Create a Kubernetes secret for the OHS domain credentials

In this section you create a secret that stores the credentials for the OHS domain.

1. Run the following command to create the secret:

   ```
   $ kubectl create secret generic ohs-secret -n <namespace> --from-literal=username=weblogic --from-literal=password='<password>'
   ```
   
	For example:
	
   ```
   $ kubectl create secret generic ohs-secret -n ohsns --from-literal=username=weblogic --from-literal=password='<password>`
   ```
	
	Replace `<password>` with a password of your choice.
	
	The output will look similar to the following:
	
   ```
   secret/ohs-secret created
   ```
	
	
	
## Prepare the ohs.yaml file

In this section you prepare the `ohs.yaml` file ready for OHS deployment.

1. Copy the sample yaml files to `$MYOHSFILES`:

   ```
   $ cd $MYOHSFILES
   $ cp $SCRIPTDIR/*.yaml .
   ```


1. Edit the `$MYOHSFILES/ohs.yaml` and change the following parameters to match your installation:

   **Note**:
	
   + `<NAMESPACE> ` to your namespace, for example `ohsns`.
   + `<IMAGE_NAME>` to the correct image tag on Oracle Container Registry. If you are using your own container registry for the image, you will need to change the `image` location appropriately. If your own container registry is open, you do not need the `imagePullSecrets`.
   + During the earlier creation of the configmaps, and secret, if you changed the names from the given examples, then you will need to update the values accordingly.
   + All configMaps are shown for completeness. Remove any configMaps that you are not using, for example if you don't require `htdocs` then remove the `ohs-htdocs` configMap. If you are not deploying webgate then remove the `webgate-config` and `webgate-wallet` configMaps, and so forth.
   + If you have created any additional directories under `htdocs`, then add the additional entries in that match the configmap and directory names.
   + All configMaps used must mount to the directories stated.
   + Ports can be changed if required.
   + Set `DEPLOY_WG` to `true` or `false` depending on whether webgate is to be deployed.
   + If using SSL change `<WALLET_NAME>` to the wallet directory created under `ohsConfig/webgate/config/wallet`, for example `mywallet`.
   + `initialDelaySeconds` may need to be changed to 10 on slower systems. See, [Issues with LivenessProbe](../troubleshooting/#issues-with-livenessprobe).
	
	
   {{%expand "Click here to see an example ohs.yaml:" %}}
   ```
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: ohs-script-configmap
     namespace: ohsns
   data:
     ohs-script.sh: |
       #!/bin/bash
       mkdir -p /u01/oracle/bootdir /u01/oracle/config /u01/oracle/config/moduleconf /u01/oracle/config/webgate/config
       { echo -en "username=" && cat /ohs-config/username && echo -en "\npassword=" && cat /ohs-config/password; } > /u01/oracle/bootdir/domain.properties
       /u01/oracle/provisionOHS.sh
    
    
   ---
    
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: ohs-domain
     namespace: ohsns
   spec:
     progressDeadlineSeconds: 600
     replicas: 1
     selector:
       matchLabels:
         oracle: ohs
     template:
       metadata:
         labels:
           oracle: ohs
       spec:
         containers:
         - name: ohs
           image: container-registry.oracle.com/middleware/ohs_cpu:12.2.1.4-db19-jdk8-ol8-<July'25>
           env:
             - name: DEPLOY_WG
               value: "true"
           ports:
           - name: clear
             containerPort: 7777
           - name: https
             containerPort: 4443
           resources:
             requests:
               cpu: 1000m
               memory: 1Gi
           securityContext:
             allowPrivilegeEscalation: false
             capabilities:
               drop:
               - ALL
             privileged: false
             runAsNonRoot: true
             runAsUser: 1000
           livenessProbe:
             exec:
               command:
               - /bin/bash
               - -c
               - pgrep httpd
             initialDelaySeconds: 10 
             periodSeconds: 5
           readinessProbe:
             httpGet:
               port: 7777
               path: /helloWorld.html
           volumeMounts:
             - name: ohs-secret
               mountPath: /ohs-config
             - name: ohs-config
               mountPath: /u01/oracle/config/moduleconf
             - name: ohs-htdocs
               mountPath: /u01/oracle/config/htdocs
             - name: ohs-myapp
               mountPath: /u01/oracle/config/htdocs/myapp
             - name: ohs-httpd
               mountPath: /u01/oracle/config/httpd
             - name: webgate-config
               mountPath: /u01/oracle/config/webgate/config
             - name: webgate-wallet
               mountPath: /u01/oracle/config/webgate/config/wallet
             - name: ohs-wallet
               mountPath: /u01/oracle/config/wallet/mywallet
             - name: script-volume
               mountPath: /ohs-bin
               readOnly: true
           command: ["/ohs-bin/ohs-script.sh"]
         imagePullSecrets:
         - name: regcred		  
         affinity:
           podAntiAffinity:
             preferredDuringSchedulingIgnoredDuringExecution:
             - weight: 100
               podAffinityTerm:
                 labelSelector:
                   matchExpressions:
                   - key: oracle
                     operator: In
                     values:
                     - ohs
                 topologyKey: "kubernetes.io/hostname"
         restartPolicy: Always
         securityContext:
           seccompProfile:
             type: RuntimeDefault
         terminationGracePeriodSeconds: 30
         volumes:
         - name: ohs-secret
           secret:
             defaultMode: 0444
             secretName: ohs-secret
         - name: script-volume
           configMap:
              defaultMode: 0555
              name: ohs-script-configmap
         - name: ohs-config
           configMap:
             defaultMode: 0555
             name: ohs-config
         - name: ohs-httpd
              configMap:
             defaultMode: 0555
             name: ohs-httpd
         - name: ohs-htdocs
           configMap:
             defaultMode: 0555
             name: ohs-htdocs
         - name: ohs-myapp
           configMap:
             defaultMode: 0555
             name: ohs-myapp
         - name: webgate-config
           configMap:
             defaultMode: 0555
             name: webgate-config
         - name: webgate-wallet
           configMap:
             defaultMode: 0555
             name: webgate-wallet
         - name: ohs-wallet
           configMap:
             defaultMode: 0555
             name: ohs-wallet
     strategy:
       type: RollingUpdate
       rollingUpdate:
         maxUnavailable: 1
   ```
   {{% /expand %}}
	
 
### Next Steps

You are now ready to create the OHS container, see [Create the OHS Container and Nodeport](../create-ohs-container).
