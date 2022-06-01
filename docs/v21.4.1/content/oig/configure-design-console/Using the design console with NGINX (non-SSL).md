---
title: "a. Using Design Console with NGINX(non-SSL)"
weight: 1
description: "Configure Design Console with NGINX(non-SSL)."
---

Configure an NGINX ingress (non-SSL) to allow Design Console to connect to your Kubernetes cluster.

{{% notice note %}}
Design Console is not installed as part of the OIG Kubernetes cluster so must be installed on a seperate client before following the steps below.
{{% /notice %}}


### Add the NGINX ingress using helm

**Note**: If already using NGINX with non-SSL for OIG you can skip this section:

1. Add the Helm chart repository for NGINX using the following command:

   ```bash
   $ helm repo add stable https://kubernetes.github.io/ingress-nginx
   ```
   
   The output will look similar to the following:

   ```bash
   "stable" has been added to your repositories
   ```
1. Update the repository using the following command:

   ```bash
   $ helm repo update
   ```
   
   The output will look similar to the following:

   ```bash
   Hang tight while we grab the latest from your chart repositories...
   ...Successfully got an update from the "stable" chart repository
   Update Complete. Happy Helming!
   ```

1. Create a Kubernetes namespace for NGINX by running the following command:

   ```bash
   $ kubectl create namespace nginx
   ```
   
   The output will look similar to the following:

   ```bash
   namespace/nginx created
   ```

### Install NGINX ingress using helm

Install a NGINX ingress for the Design Console:

If you can connect directly to the master node IP address from a browser, then install NGINX with the `--set controller.service.type=NodePort` parameter.

If you are using a Managed Service for your Kubernetes cluster,for example Oracle Kubernetes Engine (OKE) on Oracle Cloud Infrastructure (OCI), and connect from a browser to the Load Balancer IP address, then use the `--set controller.service.type=LoadBalancer` parameter. This instructs the Managed Service to setup a Load Balancer to direct traffic to the NGINX ingress.

1. To install NGINX use the following helm command depending on if you are using `NodePort` or `LoadBalancer`:

   a) Using NodePort

   ```
   $ helm install nginx-dc-operator stable/ingress-nginx -n nginx --set controller.service.type=NodePort --set controller.admissionWebhooks.enabled=false --set controller.service.nodePorts.http=30315 --set controller.ingressClass=nginx-designconsole --version=3.34.0
   ```    

   The output will look similar to the following:
   
   ```
   NAME: nginx-dc-operator
   LAST DEPLOYED: Tue Oct 20 07:31:08 2020
   NAMESPACE: nginx
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The ingress-nginx controller has been installed.
   Get the application URL by running these commands:
     export HTTP_NODE_PORT=30315
     export HTTPS_NODE_PORT=$(kubectl --namespace nginx get services -o jsonpath="{.spec.ports[1].nodePort}" nginx-dc-operator-ingress-nginx-controller)
     export NODE_IP=$(kubectl --namespace nginx get nodes -o jsonpath="{.items[0].status.addresses[1].address}")

     echo "Visit http://$NODE_IP:$HTTP_NODE_PORT to access your application via HTTP."
     echo "Visit https://$NODE_IP:$HTTPS_NODE_PORT to access your application via HTTPS."

   An example Ingress that makes use of the controller:
 
     apiVersion: networking.k8s.io/v1beta1
     kind: Ingress
     metadata:
       annotations:
      kubernetes.io/ingress.class: nginx-designconsole
    name: example
    namespace: foo
     spec:
       rules:
         - host: www.example.com
           http:
             paths:
               - backend:
                   serviceName: exampleService
                   servicePort: 80
                 path: /
       # This section is only required if TLS is to be enabled for the Ingress
       tls:
          - hosts:
               - www.example.com
             secretName: example-tls

   If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

     apiVersion: v1
     kind: Secret
     metadata:
       name: example-tls
       namespace: foo
     data:
       tls.crt: <base64 encoded cert>
       tls.key: <base64 encoded key>
     type: kubernetes.io/tls
   ```

   b) Using LoadBalancer

   ```
   $ helm install nginx-dc-operator stable/ingress-nginx -n nginx --set controller.service.type=LoadBalancer --set controller.admissionWebhooks.enabled=false --version=3.34.0
   ```

   The output will look similar to the following:

   ```
   LAST DEPLOYED: Tue Oct 20 07:39:27 2020
   NAMESPACE: nginx
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   NOTES:
   The ingress-nginx controller has been installed.
   It may take a few minutes for the LoadBalancer IP to be available.
   You can watch the status by running 'kubectl --namespace nginx get services -o wide -w nginx-dc-operator-ingress-nginx-controller'

   An example Ingress that makes use of the controller:

     apiVersion: networking.k8s.io/v1beta1
     kind: Ingress
     metadata:
       annotations:
        kubernetes.io/ingress.class: nginx
       name: example
       namespace: foo
     spec:
       rules:
         - host: www.example.com
           http:
             paths:
               - backend:
                   serviceName: exampleService
                   servicePort: 80
                 path: /
       # This section is only required if TLS is to be enabled for the Ingress
       tls:
           - hosts:
            - www.example.com
             secretName: example-tls

   If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

     apiVersion: v1
     kind: Secret
     metadata:
       name: example-tls
       namespace: foo
     data:
       tls.crt: <base64 encoded cert>
       tls.key: <base64 encoded key>
     type: kubernetes.io/tls
   ```

### Setup Routing Rules for the Design Console ingress

1. Setup routing rules by running the following commands:

   ```
   $ cd <work directory>/weblogic-kubernetes-operator/kubernetes/samples/charts/design-console-ingress
   $ cp values.yaml values.yaml.orig
   $ vi values.yaml
   ```

   Edit `values.yaml` and ensure that `type: NGINX`, `tls: NONSSL`  and `domainUID: governancedomain` are set, for example:
   
   ```
   $ cat values.yaml
   # Copyright 2020 Oracle Corporation and/or its affiliates.
   # Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

   # Default values for design-console-ingress.
   # This is a YAML-formatted file.
   # Declare variables to be passed into your templates.

   # Load balancer type.  Supported values are: VOYAGER, NGINX
   type: NGINX
   # Type of Configuration Supported Values are : NONSSL,SSL
   # tls: NONSSL
   tls: NONSSL
   # TLS secret name if the mode is SSL
   secretName: dc-tls-cert


   # WLS domain as backend to the load balancer
   wlsDomain:
     domainUID: governancedomain
     oimClusterName: oim_cluster
     oimServerT3Port: 14001

   # Voyager specific values
   voyager:
     # web port
     webPort: 30320
     # stats port
     statsPort: 30321
   ```

### Create the ingress

1. Run the following command to create the ingress:
   
   ```
   $ cd <work directory>/weblogic-kubernetes-operator
   $ helm install governancedomain-nginx-designconsole kubernetes/samples/charts/design-console-ingress  --namespace oigns  --values kubernetes/samples/charts/design-console-ingress/values.yaml
   ```
  
   For example:
   
   ```
   $ cd /scratch/OIGDockerK8S/weblogic-kubernetes-operator
   $ helm install governancedomain-nginx-designconsole kubernetes/samples/charts/design-console-ingress  --namespace oigns  --values kubernetes/samples/charts/design-console-ingress/values.yaml
   ```
   
   The output will look similar to the following:

   ```
   NAME: governancedomain-nginx-designconsole
   LAST DEPLOYED: Tue Oct 20 08:01:47 2020
   NAMESPACE: oigns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```

1. Run the following command to show the ingress is created successfully:

   ```
   $ kubectl describe ing governancedomain-nginx-designconsole -n <domain_namespace>
   ```
   
   For example:
   
   ```
   $ kubectl describe ing governancedomain-nginx-designconsole -n oigns
   ```
   
   The output will look similar to the following:

   ```  
   Name:             governancedomain-nginx-designconsole
   Namespace:        oigns
   Address:          10.99.240.21
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                    governancedomain-cluster-oim-cluster:14001 ()
   Annotations:  kubernetes.io/ingress.class: nginx-designconsole
                 meta.helm.sh/release-name: governancedomain-nginx-designconsole
                 meta.helm.sh/release-namespace: oigns
                 nginx.ingress.kubernetes.io/affinity: cookie
                 nginx.ingress.kubernetes.io/enable-access-log: false
   Events:
     Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  CREATE  117s  nginx-ingress-controller  Ingress oigns/governancedomain-nginx-designconsole
     Normal  UPDATE  64s   nginx-ingress-controller  Ingress oigns/governancedomain-nginx-designconsole
   ```

   
### Design Console Client

It is possible to use Design Console from an on-premises install, or from a container image.

#### Using an on-premises installed Design Console

1. Install Design Console on an on-premises machine

1. Follow [Login to the Design Console](../using-the-design-console-with-nginx-ssl/#login-to-the-design-console).

#### Using a container image for Design Console

The Design Console can be run from a container using X windows emulation.

1. On the parent machine where the Design Console is to be displayed, run `xhost+`.

1. Execute the following command to start a container to run Design Console:

   ```
   $ docker run -u root --name oigdcbase -it <image> bash
   ```
   
   For example:
   
   ```
   $ docker run -u root -it --name oigdcbase oracle/oig:12.2.1.4.0 bash
   ```

   This will take you into a bash shell inside the container:
   
   ```
   bash-4.2#
   ```
   
1. Inside the container set the proxy, for example:

   ```
   bash-4.2# export https_proxy=http://proxy.example.com:80
   ```

1. Install the relevant X windows packages in the container:

   ```
   bash-4.2# yum install libXext libXrender libXtst
   ```
   
1. Execute the following outside the container to create a new Design Console image from the container:

   ```
   $ docker commit <container_name> <design_console_image_name>
   ```
   
   For example:
   
   ```
   $ docker commit oigdcbase oigdc
   ```
   
1. Exit the container bash session:

   ```
   bash-4.2# exit
   ```
   
1. Start a new container using the Design Console image:

   ```
   $ docker run --name oigdc -it oigdc /bin/bash
   ```
   
   This will take you into a bash shell for the container:
   
   ```
   bash-4.2#
   ```
   
1. In the container run the following to export the DISPLAY:

   ```
   $ export DISPLAY=<parent_machine_hostname:1>
   ```   

1. Start the Design Console from the container:

   ```
   bash-4.2# cd idm/designconsole
   bash-4.2# sh xlclient.sh
   ```
   
   The Design Console login should be displayed. Now follow [Login to the Design Console](../using-the-design-console-with-nginx-ssl/#login-to-the-design-console).   
   
### Login to the Design Console

1. Launch the Design Console and in the Oracle Identity Manager Design Console login page enter the following details: 

   Enter the following details and click Login:
   * `Server URL`: `<url>`
   * `User ID`: `xelsysadm`
   * `Password`: `<password>`.

    where `<url>` is as per the following:
	
   a) For NodePort: `http://<masternode.example.com>:<NodePort>`
   
   where `<NodePort>` is the value passed in the command earlier, for example: `--set controller.service.nodePorts.http=30315`
   
   b) For LoadBalancer: `http://<loadbalancer.example.com>:<LBRPort>`
   
   

1. If successful the Design Console will be displayed. If the VNC session disappears then the connection failed so double check the connection details and try again.


