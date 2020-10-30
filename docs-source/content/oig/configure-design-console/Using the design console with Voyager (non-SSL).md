+++
title = "a. Using Design Console with Voyager(non-SSL)"
description = "Configure Design Console with Voyager(non-SSL)."
+++

Configure a Voyager ingress (non-SSL) to allow Design Console to connect to your Kubernetes cluster.

{{% notice note %}}
Design Console is not installed as part of the OAM Kubernetes cluster so must be installed on a seperate client before following the steps below.
{{% /notice %}}


### Add the Voyager ingress using helm

**Note**: If already using Voyager with non-SSL for OIG you can skip this section:

1. Add the Helm chart repository for Voyager using the following command:

   ```bash
   $ helm repo add appscode https://charts.appscode.com/stable
   ```
   
   The output will look similar to the following:

   ```bash
   "appscode" has been added to your repositories
   ```
1. Update the repository using the following command:

   ```bash
   $ helm repo update
   ```
   
   The output will look similar to the following:

   ```bash
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "appscode" chart repository
   Update Complete. Happy Helming!
   ```

1. Create a namespace for Voyager:

   ```
   $ kubectl create namespace voyager
   ```
   
   The output will look similar to the following:
   
   ```
   namespace/voyager created
   ```  

### Install Voyager ingress using helm

```
   $ helm install voyager-designconsole-operator appscode/voyager --version v12.0.0-rc.1 --namespace voyager --set cloudProvider=baremetal --set apiserver.enableValidatingWebhook=false
   ```

   **Note**: For bare metal Kubernetes use `--set cloudProvider=baremetal`. If using a managed Kubernetes service then the value should be set for your specific service as per the [Voyager](https://voyagermesh.com/docs/6.0.0/setup/install/) install guide.

   The output will look similar to the following:
   
   ```
   NAME: voyager-designconsole-operator
   LAST DEPLOYED: Wed Oct 21 08:31:32 2020
   NAMESPACE: voyager
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   Set cloudProvider for installing Voyager

   To verify that Voyager has started, run:

     kubectl --namespace=voyager get deployments -l "release=voyager-designconsole-operator, app=voyager"
   ```

### Setup Routing Rules for the Design Console ingress

1. Setup routing rules by running the following commands:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/design-console-ingress
   $ cp values.yaml values.yaml.orig
   $ vi values.yaml
   ```

   Edit `values.yaml` and ensure that `type=VOYAGER` and `tls=NONSSL` are set, and that `webPort` and `statsPort` are set to free ports, for example:
   
   ```
   $ cat values.yaml
   # Copyright 2020 Oracle Corporation and/or its affiliates.
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

   # Default values for design-console-ingress.
   # This is a YAML-formatted file.
   # Declare variables to be passed into your templates.

   # Load balancer type.  Supported values are: VOYAGER, NGINX
   type: VOYAGER
   # Type of Configuration Supported Values are : NONSSL,SSL
   # tls: NONSSL
   tls: NONSSL
   # TLS secret name if the mode is SSL
   secretName: dc-tls-cert


   # WLS domain as backend to the load balancer
   wlsDomain:
     domainUID: oimcluster
     oimClusterName: oim_cluster
     oimServerT3Port: 14001

   # Voyager specific values
   voyager:
     # web port
     webPort: 30325
     # stats port
     statsPort: 30326
   ```

### Create the ingress

1. Run the following command to create the ingress:
   
   ```
   $ cd <work directory>/weblogic-kubernetes-operator
   $ helm install oimcluster-voyager-designconsole kubernetes/samples/charts/design-console-ingress  --namespace oimcluster  --values kubernetes/samples/charts/design-console-ingress/values.yaml
   ```
  
   For example:
   
   ```
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator
   $ helm install oimcluster-voyager-designconsole kubernetes/samples/charts/design-console-ingress  --namespace oimcluster  --values kubernetes/samples/charts/design-console-ingress/values.yaml
   ```
   
   The output will look similar to the following:

   ```
   NAME: oimcluster-voyager-designconsole
   LAST DEPLOYED: Wed Oct 21 08:36:03 2020
   NAMESPACE: oimcluster
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None

   ```

1. Run the following command to show the ingress is created successfully:

   ```
   $ kubectl get ingress.voyager.appscode.com -n <domain_namespace>
   ```
   
   For example:
   
   ```
   $ kubectl get ingress.voyager.appscode.com -n oimcluster
   ```
   
   The output will look similar to the following:

   ```  
   NAME                               HOSTS   LOAD_BALANCER_IP   AGE
   oimcluster-voyager-designconsole   *                          10s
   ```
   
1. Return details of the ingress using the following command:

   ```
   $ kubectl describe ingress.voyager.appscode.com oimcluster-voyager-designconsole -n oimcluster
   ```
   
   The output will look similar to the following:
   
   ```
   Name:         oimcluster-voyager-designconsole
   Namespace:    oimcluster
   Labels:       app.kubernetes.io/managed-by=Helm
                 weblogic.resourceVersion=domain-v2
   Annotations:  ingress.appscode.com/affinity: cookie
                 ingress.appscode.com/stats: true
                 ingress.appscode.com/type: NodePort
                 meta.helm.sh/release-name: oimcluster-voyager-designconsole
                 meta.helm.sh/release-namespace: oimcluster
   API Version:  voyager.appscode.com/v1beta1
   Kind:         Ingress
   Metadata:
     Creation Timestamp:  2020-10-21T15:46:29Z
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
           f:frontendRules:
           f:rules:
           f:tls:
       Manager:         Go-http-client
       Operation:       Update
       Time:            2020-10-21T15:46:29Z
     Resource Version:  6082128
     Self Link:         /apis/voyager.appscode.com/v1beta1/namespaces/oimcluster/ingresses/oimcluster-voyager-designconsole
     UID:               a4968c01-28eb-4e4a-ac31-d60cfcd8705f
   Spec:
     Frontend Rules:
       Port:  443
       Rules:
         http-request set-header WL-Proxy-SSL true
      Rules:
       Host:  *
       Http:
         Node Port:  30325
         Paths:
           Backend:
             Service Name:  oimcluster-cluster-oim-cluster
             Service Port:  14001
           Path:            /
     Tls:
       Hosts:
         *
       Secret Name:  oimcluster-tls-cert
   Events:
     Type     Reason                           Age   From              Message
     ----     ------                           ----  ----              -------
     Normal  DeploymentReconcileSuccessful  55m   voyager-operator  Successfully patched HAProxy Deployment voyager-oimcluster-voyager-designconsole
     Normal  DeploymentReconcileSuccessful  45m   voyager-operator  Successfully patched HAProxy Deployment voyager-oimcluster-voyager-designconsole
   ```   
   
#### Login to the Design Console

1. Launch the Design Console and in the Oracle Identity Manager Design Console login page enter the following details: 

   Enter the following details and click Login:
   * `Server URL`: `<url>`
   * `User ID`: `xelsysadm`
   * `Password`: `<password>`.

   where `<url>` is `http://<masternode.example.com>:<NodePort>`
   
   `<NodePort>` is the value passed for webPort in the `values.yaml earlier, for example: 30325
   

1. If successful the Design Console will be displayed. If the VNC session disappears then the connection failed so double check the connection details and try again.

