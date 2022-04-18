---
title: "a. Using Design Console with NGINX(non-SSL)"
weight: 1
description: "Configure Design Console with NGINX(non-SSL)."
---

Configure an NGINX ingress (non-SSL) to allow Design Console to connect to your Kubernetes cluster.

1. [Prerequisites](#prerequisites)
1. [Setup routing rules for the Design Console ingress](#setup-routing-rules-for-the-design-console-ingress)
1. [Create the ingress](#create-the-ingress)
1. [Update the T3 channel](#update-the-t3-channel)
1. [Restart the OIG Managed Server](#restart-the-oig-managed-server)
1. [Design Console client](#design-console-client)
   
   a. [Using an on-premises installed Design Console](#using-an-on-premises-installed-design-console)
   
   b. [Using a container image for Design Console](#using-a-container-image-for-design-console)

1. [Login to the Design Console](#login-to-the-design-console)

### Prerequisites

If you haven't already configured an NGINX ingress controller (Non-SSL) for OIG, follow [Using an Ingress with NGINX (non-SSL)]({{< relref "/oig/configure-ingress/ingress-nginx-setup-for-oig-domain-setup-on-K8S">}}).

Make sure you know the master hostname and ingress port for NGINX before proceeding e.g `http://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}`.

**Note**: In all steps below if you are using a load balancer for your ingress instead of NodePort then replace `${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}` with `${LOADBALANCER-HOSTNAME}:${LOADBALANCER-PORT}.

### Setup routing rules for the Design Console ingress

1. Setup routing rules by running the following commands:

   ```bash
   $ cd $WORKDIR/kubernetes/design-console-ingress
   ```
   
   Edit `values.yaml` and ensure that `tls: NONSSL`  and `domainUID: governancedomain` are set, for example:
   
   ```
   # Load balancer type.  Supported values are: NGINX
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
     oimServerT3Port: 14002
   ```

### Create the ingress

1. Run the following command to create the ingress:
   
   ```bash
   $ cd $WORKDIR
   $ helm install governancedomain-nginx-designconsole kubernetes/design-console-ingress  --namespace oigns  --values kubernetes/design-console-ingress/values.yaml
   ```
  
   For example:
   
   The output will look similar to the following:

   ```
   NAME: governancedomain-nginx-designconsole
   LAST DEPLOYED: Thu Mar 10 14:32:16 2022
   NAMESPACE: oigns
   STATUS: deployed
   REVISION: 1
   TEST SUITE: None
   ```

1. Run the following command to show the ingress is created successfully:

   ```bash
   $ kubectl describe ing governancedomain-nginx-designconsole -n <domain_namespace>
   ```
   
   For example:
   
   ```bash
   $ kubectl describe ing governancedomain-nginx-designconsole -n oigns
   ```
   
   The output will look similar to the following:

   ```
   Name:             governancedomain-nginx-designconsole
   Namespace:        oigns
   Address:
   Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
   Rules:
     Host        Path  Backends
     ----        ----  --------
     *
                    governancedomain-cluster-oim-cluster:14002 (10.244.1.25:14002)
   Annotations:  kubernetes.io/ingress.class: nginx
                 meta.helm.sh/release-name: governancedomain-nginx-designconsole
                 meta.helm.sh/release-namespace: oigns
                 nginx.ingress.kubernetes.io/affinity: cookie
                 nginx.ingress.kubernetes.io/enable-access-log: false
   Events:
     Type    Reason  Age   From                      Message
     ----    ------  ----  ----                      -------
     Normal  Sync    13s   nginx-ingress-controller  Scheduled for sync
   ```

### Update the T3 channel

1. Log in to the WebLogic Console using `http://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}/console`.

1. Navigate to **Environment**, click **Servers**, and then select **oim_server1**.

1. Click **Protocols**, and then **Channels**.

1. Click the default T3 channel called **T3Channel**.

1. Click **Lock and Edit**.

1. Set the **External Listen Address** to the ingress controller hostname `${MASTERNODE-HOSTNAME}`.

1. Set the **External Listen Port** to the ingress controller port `${MASTERNODE-PORT}`. 

1. Click **Save**.

1. Click **Activate Changes.**


### Restart the OIG Managed Server

Restart the OIG Managed Server for the above changes to take effect:

```bash
$ cd $WORKDIR/kubernetes/domain-lifecycle
$ ./restartServer.sh -s oim_server1 -d <domain_uid> -n <domain_namespace>
```

For example:

```bash
$ cd $WORKDIR/kubernetes/domain-lifecycle
./restartServer.sh -s oim_server1 -d governancedomain -n oigns
```

Make sure the `<domain_uid>-oim-server1` has a `READY` status of `1/1` before continuing:
   
```bash
$ kubectl get pods -n oigns | grep oim-server1   
```

The output will look similar to the following:
   
```
governancedomain-oim-server1                                1/1     Running     0          8m
```

### Design Console client

It is possible to use Design Console from an on-premises install, or from a container image.

#### Using an on-premises installed Design Console

1. Install Design Console on an on-premises machine

1. Follow [Login to the Design Console](#login-to-the-design-console).

#### Using a container image for Design Console

##### Using Docker

The Design Console can be run from a container using X windows emulation.

1. On the parent machine where the Design Console is to be displayed, run `xhost +`.

1. Find which worker node the `<domain>-oim-server1` pod is running. For example:

   ```
   $ kubectl get pods -n oigns -o wide | grep governancedomain-oim-server1 
   ```
   
   The output will look similar to the following:
   
   ```
   governancedomain-oim-server1                                1/1     Running     0          31m     10.244.2.98   worker-node2   <none>           <none>
   ```


1. On the worker node returned above e.g `worker-node2`, execute the following command to find the OIG container image name:

   ```bash
   $ docker images
   ```

   Then execute the following command to start a container to run Design Console:

   ```bash
   $ docker run -u root --name oigdcbase -it <image> bash
   ```
   
   For example:
   
   ```bash
   $ docker run -u root -it --name oigdcbase container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol7-220120.1359 bash
   ```

   This will take you into a bash shell inside the container:
   
   ```bash
   bash-4.2#
   ```
   
1. Inside the container set the proxy, for example:

   ```bash
   bash-4.2# export https_proxy=http://proxy.example.com:80
   ```

1. Install the relevant X windows packages in the container:

   ```bash
   bash-4.2# yum install libXext libXrender libXtst
   ```
   
1. Execute the following outside the container to create a new Design Console image from the container:

   ```bash
   $ docker commit <container_name> <design_console_image_name>
   ```
   
   For example:
   
   ```bash
   $ docker commit oigdcbase oigdc
   ```
   
1. Exit the container bash session:

   ```bash
   bash-4.2# exit
   ```
   
1. Start a new container using the Design Console image:

   ```bash
   $ docker run --name oigdc -it oigdc /bin/bash
   ```
   
   This will take you into a bash shell for the container:
   
   ```bash
   bash-4.2#
   ```
   
1. In the container run the following to export the DISPLAY:

   ```bash
   $ export DISPLAY=<parent_machine_hostname:1>
   ```   

1. Start the Design Console from the container:

   ```bash
   bash-4.2# cd idm/designconsole
   bash-4.2# sh xlclient.sh
   ```
   
   The Design Console login should be displayed. Now follow [Login to the Design Console](#login-to-the-design-console).   
   
   
##### Using podman

1. On the parent machine where the Design Console is to be displayed, run `xhost +`.

1. Find which worker node the `<domain>-oim-server1` pod is running. For example:

   ```
   $ kubectl get pods -n oigns -o wide | grep governancedomain-oim-server1 
   ```
   
   The output will look similar to the following:
   
   ```
   governancedomain-oim-server1                                1/1     Running     0          31m     10.244.2.98   worker-node2   <none>           <none>
   ```

1. On the worker node returned above e.g `worker-node2`, execute the following command to find the OIG container image name:

   ```bash
   $ podman images
   ```

   Then execute the following command to start a container to run Design Console:

   ```bash
   $ podman run -u root --name oigdcbase -it <image> bash
   ```
   
   For example:
   
   ```bash
   $ podman run -u root -it --name oigdcbase container-registry.oracle.com/middleware/oig_cpu:12.2.1.4-jdk8-ol7-220120.1359 bash
   ```

   This will take you into a bash shell inside the container:
   
   ```bash
   bash-4.2#
   ```
   
1. Inside the container set the proxy, for example:

   ```bash
   bash-4.2# export https_proxy=http://proxy.example.com:80
   ```

1. Install the relevant X windows packages in the container:

   ```bash
   bash-4.2# yum install libXext libXrender libXtst
   ```
   
1. Execute the following outside the container to create a new Design Console image from the container:

   ```bash
   $ podman commit <container_name> <design_console_image_name>
   ```
   
   For example:
   
   ```bash
   $ podman commit oigdcbase oigdc
   ```
   
1. Exit the container bash session:

   ```bash
   bash-4.2# exit
   ```
   
1. Start a new container using the Design Console image:

   ```bash
   $ podman run --name oigdc -it oigdc /bin/bash
   ```
   
   This will take you into a bash shell for the container:
   
   ```bash
   bash-4.2#
   ```
   
1. In the container run the following to export the DISPLAY:

   ```bash
   $ export DISPLAY=<parent_machine_hostname:1>
   ```   

1. Start the Design Console from the container:

   ```bash
   bash-4.2# cd idm/designconsole
   bash-4.2# sh xlclient.sh
   ```
   
   The Design Console login should be displayed. Now follow [Login to the Design Console](#login-to-the-design-console).
   
### Login to the Design Console

1. Launch the Design Console and in the Oracle Identity Manager Design Console login page enter the following details: 

   Enter the following details and click Login:
   * `Server URL`: `<url>`
   * `User ID`: `xelsysadm`
   * `Password`: `<password>`.

    where `<url>` is `http://${MASTERNODE-HOSTNAME}:${MASTERNODE-PORT}`

1. If successful the Design Console will be displayed.


