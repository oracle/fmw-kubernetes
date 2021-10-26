---
title: "c. Using an Ingress with Voyager (non-SSL)"
description: "Steps to set up an Ingress for Voyager to direct traffic to the OIG domain (non-SSL)."
---

### Setting Up an Ingress for Voyager for the OIG Domain on Kubernetes

The instructions below explain how to set up Voyager as an Ingress for the OIG domain with non-SSL termination.

**Note**: All the steps below should be performed on the **master** node.

1. [Install Voyager](#install-voyager)
    1. [Configure the repository](#configure-the-repository)
	1. [Create Namespace and Install Voyager](#create-namespace-and-install-voyager)
	1. [Setup Routing Rules for the Domain](#setup-routing-rules-for-the-domain)
1. [Create an Ingress for the Domain](#create-an-ingress-for-the-domain)
1. [Verify that You can Access the Domain URL](#verify-that-you-can-access-the-domain-url)
1. [Cleanup](#cleanup)

### Install Voyager

Use Helm to install Voyager. For detailed information, see [this document](https://github.com/oracle/weblogic-kubernetes-operator/blob/master/kubernetes/samples/charts/voyager/README.md).

#### Configure the repository

1. Add the Helm chart repository for installing Voyager using the following command:

   ```
   $ helm repo add appscode https://charts.appscode.com/stable
   ```
   
   The output will look similar to the following:
   
   ```
   "appscode" has been added to your repositories
   ```

1. Update the repository using the following command:

   ```
   $ helm repo update
   ```
   
   The output will look similar to the following:
   
   ```
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "appscode" chart repository
   Update Complete. Happy Helming!
   ```
   
1. Run the following command to show the Voyager chart was added successfully.

   ```
   $ helm search repo appscode/voyager
   ```
   
   The output will look similar to the following:
   
   ```
   NAME                    CHART VERSION   APP VERSION     DESCRIPTION
   appscode/voyager        v12.0.0         v12.0.0         Voyager by AppsCode - Secure HAProxy Ingress Co...
   ```

#### Create Namespace and Install Voyager
 
1. Create a namespace for Voyager:

   ```
   $ kubectl create namespace voyager
   ```
   
   The output will look similar to the following:
   
   ```
   namespace/voyager created
   ```  

1. Install Voyager using the following Helm command:

   ```
   $ helm install voyager-ingress appscode/voyager --version 12.0.0 --namespace voyager --set cloudProvider=baremetal --set apiserver.enableValidatingWebhook=false
   ```

   **Note**: For bare metal Kubernetes use `--set cloudProvider=baremetal`. If using a managed Kubernetes service then the value should be set for your specific service as per the [Voyager](https://voyagermesh.com/docs/6.0.0/setup/install/) install guide.

   The output will look similar to the following:
   
   ```
   NAME: voyager-ingress
   LAST DEPLOYED: Tue Sep 29 09:23:22 2020
   NAMESPACE: voyager
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   Set cloudProvider for installing Voyager

   To verify that Voyager has started, run:

      $ kubectl get deployment --namespace voyager -l "app.kubernetes.io/name=voyager,app.kubernetes.io/instance=voyager-ingress"
   ```

1. Verify the ingress has started by running the following command:

   ```
   $ kubectl get deployment --namespace voyager -l "app.kubernetes.io/name=voyager,app.kubernetes.io/instance=voyager-ingress"
   ```

   The output will look similar to the following:

   ```
   NAME              READY   UP-TO-DATE   AVAILABLE   AGE
   voyager-ingress   1/1     1            1           89s
   ```

#### Setup Routing Rules for the Domain

1. Setup routing rules using the following commands:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/ingress-per-domain
   $ cp values.yaml values.yaml.orig
   $ vi values.yaml
   ```

   Edit `values.yaml` and ensure that the values `type=VOYAGER` and `tls=NONSSL` are set. Also change `domainUID` to the value for your domain e.g (`governancedomain`), for example:

   ```
   $ cat values.yaml
   # Copyright 2020 Oracle Corporation and/or its affiliates. 
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


   # Default values for ingress-per-domain.
   # This is a YAML-formatted file.
   # Declare variables to be passed into your templates.

   # Load balancer type.  Supported values are: VOYAGER, NGINX
   type: VOYAGER
   # Type of Configuration Supported Values are : NONSSL,SSL
   # tls: NONSSL
   tls: NONSSL
   # TLS secret name if the mode is SSL
   secretName: domain1-tls-cert


   # WLS domain as backend to the load balancer
   wlsDomain:
     domainUID: governancedomain
     oimClusterName: oim_cluster
     soaClusterName: soa_cluster
     soaManagedServerPort: 8001
     oimManagedServerPort: 14000
     adminServerName: adminserver
     adminServerPort: 7001

   # Voyager specific values
   voyager:
     # web port
     webPort: 30305
     # stats port
     statsPort: 30315
   ```

### Create an Ingress for the Domain

1. Create an Ingress for the domain (`governancedomain-voyager`), in the domain namespace by using the sample Helm chart:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator
   $ helm install governancedomain-voyager kubernetes/samples/charts/ingress-per-domain  --namespace <namespace>  --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   ```

   For example:
   
   ```
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator
   $ helm install governancedomain-voyager kubernetes/samples/charts/ingress-per-domain  --namespace oigns  --values kubernetes/samples/charts/ingress-per-domain/values.yaml
   ```

   The output will look similar to the following:

   ```
   NAME: governancedomain-voyager
   LAST DEPLOYED: Tue Sep 29 09:28:12 2020
   NAMESPACE: oigns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```
   
1. Run the following command to show the ingress is created successfully:

   ```
   $ kubectl get ingress.voyager.appscode.com -n oigns
   ```
   
   The output will look similar to the following:

   ```
   NAME                 HOSTS   LOAD_BALANCER_IP   AGE
   governancedomain-voyager   *                          78s
   ```
   
1. Return details of the ingress using the following command:

   ```
   $ kubectl describe ingress.voyager.appscode.com governancedomain-voyager -n oigns
   ```
   
   The output will look similar to the following:

   ```
   Name:         governancedomain-voyager
   Namespace:    oigns
   Labels:       app.kubernetes.io/managed-by=Helm
                 weblogic.resourceVersion=domain-v2
   Annotations:  ingress.appscode.com/affinity: cookie
                 ingress.appscode.com/stats: true
                 ingress.appscode.com/type: NodePort
                 meta.helm.sh/release-name: governancedomain-voyager
                 meta.helm.sh/release-namespace: oigns
   API Version:  voyager.appscode.com/v1beta1
   Kind:         Ingress
   Metadata:
     Creation Timestamp:  2020-09-29T09:28:12Z
     Generation:          1
     Managed Fields:
       API Version:  voyager.appscode.com/v1beta1
       Fields Type:  FieldsV1
       fieldsV1:
         f:metadata:
           f:annotations:
             .:
             f:ingress.appscode.com/affinity:
             f:ingress.appscode.com/stats:
             f:ingress.appscode.com/type:
             f:meta.helm.sh/release-name:
             f:meta.helm.sh/release-namespace:
           f:labels:
             .:
             f:app.kubernetes.io/managed-by:
             f:weblogic.resourceVersion:
         f:spec:
           .:
           f:rules:
       Manager:         Go-http-client
       Operation:       Update
       Time:            2020-09-29T09:28:12Z
     Resource Version:  4168835
     Self Link:         /apis/voyager.appscode.com/v1beta1/namespaces/oigns/ingresses/governancedomain-voyager
     UID:               2ea71f79-6836-4df2-8200-8418abf6ad9f
   Spec:
     Rules:
       Host:  *
       Http:
         Node Port:  30305
         Paths:
           Backend:
             Service Name:  governancedomain-adminserver
             Service Port:  7001
           Path:            /console
           Backend:
             Service Name:  governancedomain-adminserver
             Service Port:  7001
           Path:            /em
           Backend:
             Service Name:  governancedomain-cluster-soa-cluster
             Service Port:  8001
           Path:            /soa-infra
		   Backend:
             Service Name:  governancedomain-cluster-soa-cluster
             Service Port:  8001
           Path:            /integration
           Backend:
             Service Name:  governancedomain-cluster-oim-cluster
             Service Port:  14000
           Path:            /
   Events:
     Type    Reason                           Age    From              Message
     ----    ------                           ----   ----              -------
     Normal  ServiceReconcileSuccessful       5m22s  voyager-operator  Successfully created NodePort Service voyager-governancedomain-voyager
     Normal  ConfigMapReconcileSuccessful     5m22s  voyager-operator  Successfully created ConfigMap voyager-governancedomain-voyager
     Normal  RBACSuccessful                   5m22s  voyager-operator  Successfully created ServiceAccount voyager-governancedomain-voyager
     Normal  RBACSuccessful                   5m22s  voyager-operator  Successfully created Role voyager-governancedomain-voyager
     Normal  RBACSuccessful                   5m22s  voyager-operator  Successfully created RoleBinding voyager-governancedomain-voyager
     Normal  DeploymentReconcileSuccessful    5m22s  voyager-operator  Successfully created HAProxy Deployment voyager-governancedomain-voyager
     Normal  StatsServiceReconcileSuccessful  5m22s  voyager-operator  Successfully created stats Service voyager-governancedomain-voyager-stats
   ```

1. Find the NodePort of Voyager using the following command:

   ```
   $ kubectl get svc -n oigns
   ```

   The output will look similar to the following:

   ```
   NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)           AGE
   governancedomain-adminserver             ClusterIP   None             <none>        7001/TCP          19h
   governancedomain-cluster-oim-cluster     ClusterIP   10.97.121.159    <none>        14000/TCP         19h
   governancedomain-cluster-soa-cluster     ClusterIP   10.111.231.242   <none>        8001/TCP          19h
   governancedomain-oim-server1             ClusterIP   None             <none>        14000/TCP         19h
   governancedomain-oim-server2             ClusterIP   10.108.139.30    <none>        14000/TCP         19h
   governancedomain-oim-server3             ClusterIP   10.97.170.104    <none>        14000/TCP         19h
   governancedomain-oim-server4             ClusterIP   10.99.82.214     <none>        14000/TCP         19h
   governancedomain-oim-server5             ClusterIP   10.98.75.228     <none>        14000/TCP         19h
   governancedomain-soa-server1             ClusterIP   None             <none>        8001/TCP          19h
   governancedomain-soa-server2             ClusterIP   10.107.232.220   <none>        8001/TCP          19h
   governancedomain-soa-server3             ClusterIP   10.108.203.6     <none>        8001/TCP          19h
   governancedomain-soa-server4             ClusterIP   10.96.178.0      <none>        8001/TCP          19h
   governancedomain-soa-server5             ClusterIP   10.107.83.62     <none>        8001/TCP          19h
   governancedomain-voyager-stats           NodePort    10.99.34.145     <none>        56789:30315/TCP   3m36s
   voyager-governancedomain-voyager         NodePort    10.106.40.20     <none>        80:30305/TCP      3m36s
   voyager-governancedomain-voyager-stats   ClusterIP   10.100.89.234    <none>        56789/TCP         3m30s
   ```

   Identify the service `voyager-governancedomain-voyager` in the above output and get the `NodePort` which corresponds to port `80`. In this example it will be `30305`.
  
1. To confirm that the new Ingress is successfully routing to the domain's server pods, run the following command to send a request to the URL for the "WebLogic ReadyApp framework":

   ```
   $ curl -v http://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/weblogic/ready
   ```
   
   For example:
   
   ```
   $ curl -v http://masternode.example.com:30305/weblogic/ready
   ```
   
   The output will look similar to the following:
   
   ```
   $ curl -v -k http://masternode.example.com:30305/weblogic/ready
   * About to connect() to masternode.example.com port 30305 (#0)
   *   Trying 12.345.67.890...
   * Connected to masternode.example.com (12.345.67.890) port 30305 (#0)
   > GET /weblogic/ready HTTP/1.1
   > User-Agent: curl/7.29.0
   > Host: masternode.example.com:30305
   > Accept: */*
   >
   < HTTP/1.1 200 OK
   < Date: Wed, 29 Sep 2020 09:30:56 GMT
   < Content-Length: 0
   < Set-Cookie: SERVERID=pod-governancedomain-oim-server1; path=/
   < Cache-control: private
   <
   * Connection #0 to host masternode.example.com left intact
   ```
   
### Verify that You can Access the Domain URL

After setting up the Voyager ingress, verify that the domain applications are accessible through the Voyager ingress port (for example 30305) as per [Validate Domain URLs ]({{< relref "/oig/validate-domain-urls" >}})


#### Cleanup

If you need to remove the Voyager Ingress (for example to setup Voyager with SSL) then remove the ingress with the following commands:

```
$ helm delete governancedomain-voyager -n oigns
$ helm delete voyager-ingress -n voyager
$ kubectl delete namespace voyager
```

The output will look similar to the following:

```
$ helm delete governancedomain-voyager -n oigns
release "governancedomain-voyager" uninstalled

$ helm delete voyager-ingress -n voyager
release "voyager-ingress" uninstalled

$ kubectl delete namespace voyager
namespace "voyager" deleted
```