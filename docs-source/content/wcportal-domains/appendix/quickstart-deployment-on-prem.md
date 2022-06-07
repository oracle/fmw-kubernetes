---
title: "Quick start deployment on-premise"
date: 2020-06-18T15:27:38-05:00
weight:  2
pre: "<b> </b>"
Description: "Describes how to quickly get an Oracle WebCenter Portal domain instance running (using the defaults, nothing special) for development and test purposes."
---

Use this Quick Start to create an Oracle WebCenter Portal domain deployment in a Kubernetes cluster (on-premise environments) with the WebLogic Kubernetes Operator. Note that this walkthrough is for demonstration purposes only, not for use in production.
These instructions assume that you are already familiar with Kubernetes. If you need more detailed instructions,
refer to the [Install Guide]({{< relref "/wcportal-domains/installguide/_index.md" >}}).


#### Hardware requirements

The Linux kernel supported for deploying and running Oracle WebCenter Portal domains with the operator is Oracle Linux 7 (UL6+) and Red Hat Enterprise Linux 7 (UL3+ only with standalone Kubernetes). Refer to the [prerequisites]({{< relref "/wcportal-domains/installguide/prerequisites/_index.md" >}}) for more details.

For this exercise, the minimum hardware requirements to create a single-node Kubernetes cluster and then deploy the domain type with one Managed Server along with Oracle Database running as a container are:

 Hardware|Size
 --|--
 RAM|32GB  
 Disk Space|250GB+
 CPU core(s)|6     

See [here]({{< relref "/wcportal-domains/appendix/wcp-cluster-sizing-info.md" >}}) for resource sizing information for Oracle WebCenter Portal domain set up on a Kubernetes cluster.

### Set up Oracle WebCenter Portal in an on-premise environment
Use the steps in this topic to create a single-instance on-premise Kubernetes cluster and then create an Oracle WebCenter Portal  domain.
* [Step 1 - Prepare a virtual machine for the Kubernetes cluster](#1-prepare-a-virtual-machine-for-the-kubernetes-cluster)
* [Step 2 - Set up a single instance Kubernetes cluster](#2-set-up-a-single-instance-kubernetes-cluster)
* [Step 3 - Get scripts and images](#3-get-scripts-and-images)
* [Step 4 - Install the WebLogic Kubernetes operator](#4-install-the-weblogic-kubernetes-operator)
* [Step 5 - Install the Traefik (ingress-based) load balancer](#5-install-the-traefik-ingress-based-load-balancer)
* [Step 6 - Create and configure an Oracle WebCenter Portal domain](#6-create-and-configure-an-oracle-webcenter-portal-domain)


### 1. Prepare a virtual machine for the Kubernetes cluster

For illustration purposes, these instructions are for Oracle Linux 7u6+.  If you are using a different flavor of Linux, you will need to adjust the steps accordingly.

{{% notice note %}} These steps must be run with the `root` user, unless specified otherwise.
Any time you see `YOUR_USERID` in a command, you should replace it with your actual `userid`.
{{% /notice %}}

####  1.1 Prerequisites

1. Choose the directories where your Docker and Kubernetes files will be stored.  The Docker directory should be on a disk with a lot of free space (more than 100GB) because it will be used for the Docker file system, which contains all of your images and containers. The Kubernetes directory is used for the `/var/lib/kubelet` file system and persistent volume storage.

    ```
    $ export docker_dir=/u01/docker
    $ export kubelet_dir=/u01/kubelet
    $ mkdir -p $docker_dir $kubelet_dir
    $ ln -s $kubelet_dir /var/lib/kubelet
    ```

1. Verify that IPv4 forwarding is enabled on your host.

    **Note**: Replace eth0 with the ethernet interface name of your compute resource if it is different.
    ```
    $ /sbin/sysctl -a 2>&1|grep -s 'net.ipv4.conf.docker0.forwarding'
    $ /sbin/sysctl -a 2>&1|grep -s 'net.ipv4.conf.eth0.forwarding'
    $ /sbin/sysctl -a 2>&1|grep -s 'net.ipv4.conf.lo.forwarding'
    $ /sbin/sysctl -a 2>&1|grep -s 'net.ipv4.ip_nonlocal_bind'
    ```

    For example: Verify that all are set to 1:
    ```
    $ net.ipv4.conf.docker0.forwarding = 1
    $ net.ipv4.conf.eth0.forwarding = 1
    $ net.ipv4.conf.lo.forwarding = 1
    $ net.ipv4.ip_nonlocal_bind = 1
    ```
    Solution: Set all values to 1 immediately:
    ```
    $ /sbin/sysctl net.ipv4.conf.docker0.forwarding=1
    $ /sbin/sysctl net.ipv4.conf.eth0.forwarding=1
    $ /sbin/sysctl net.ipv4.conf.lo.forwarding=1
    $ /sbin/sysctl net.ipv4.ip_nonlocal_bind=1
    ```
    
1. **To preserve the settings permanently**: Update the above values to 1 in files in ``/usr/lib/sysctl.d/``, ``/run/sysctl.d/``, and ``/etc/sysctl.d/``.

1. Verify the iptables rule for forwarding.

   Kubernetes uses iptables to handle many networking and port forwarding rules. A standard Docker installation may create a firewall rule that prevents forwarding.

    Verify if the iptables rule to accept forwarding traffic is set:
    ```
    $ /sbin/iptables -L -n | awk '/Chain FORWARD / {print $4}' | tr -d ")"
    ```

    If the output is "DROP", then run the following command:
    ```
    $ /sbin/iptables -P FORWARD ACCEPT
    ```

    Verify if the iptables rule is properly set to "ACCEPT":
    ```
    $ /sbin/iptables -L -n | awk '/Chain FORWARD / {print $4}' | tr -d ")"
    ```

1. Disable and stop `firewalld`:

    ```
    $ systemctl disable firewalld
    $ systemctl stop firewalld
    ```

#### 1.2 Install and configure Docker

> Note: If you have already installed Docker with version 18.03+ and configured the Docker daemon root to sufficient disk space along with proxy settings, continue to [Install and configure Kubernetes](#13-install-and-configure-kubernetes).

1. Make sure that you have the right operating system version:
    ```
    $ uname -a
    $ more /etc/oracle-release
    ```
    Example output:
    ```
    Linux xxxxxxx 4.1.12-124.27.1.el7uek.x86_64 #2 SMP Mon May 13 08:56:17 PDT 2019 x86_64 x86_64 x86_64 GNU/Linux
    Oracle Linux Server release 7.6
    ```

1. Install the latest `docker-engine` and start the Docker service:
    ```
    $ yum-config-manager --enable ol7_addons
    $ docker_version="19.03.11-ol"
    $ yum install docker-engine-$docker_version
    
    $ systemctl enable docker
    $ systemctl start docker
    ```

1. Add your user ID to the Docker group to allow you to run Docker commands without root access:
    ```
    $ /sbin/usermod -a -G docker <YOUR_USERID>
    ```

1. Check that your Docker version is at least 18.03:
    ```
    $ docker version
    ```
    Example output:
    ```
    Client: Docker Engine - Community
     Version:           19.03.11-ol
     API version:       1.40
     Go version:        go1.15.5
     Git commit:        748876d
     Built:             Thu Dec  3 19:36:03 2020
     OS/Arch:           linux/amd64
     Experimental:      false
    
    Server: Docker Engine - Community
     Engine:
      Version:          19.03.11-ol
      API version:      1.40 (minimum version 1.12)
      Go version:       go1.15.8
      Git commit:       f0aae77
      Built:            Wed Feb 10 16:13:32 2021
      OS/Arch:          linux/amd64
      Experimental:     false
      Default Registry: docker.io
     containerd:
      Version:          v1.3.9
      GitCommit:
     runc:
      Version:          1.0.0-rc5+dev
      GitCommit:        4bb1fe4ace1a32d3676bb98f5d3b6a4e32bf6c58
     docker-init:
      Version:          0.18.0
      GitCommit:        fec3683
    ```

1. Update the Docker engine configuration:
    ```
    $ mkdir -p /etc/docker

    $ cat <<EOF > /etc/docker/daemon.json
    {
       "group": "docker",
       "data-root": "/u01/docker"
    }
    EOF
    ```  

1. Configure proxy settings if you are behind an HTTP proxy:

   ```
    ### Create the drop-in file /etc/systemd/system/docker.service.d/http-proxy.conf that contains proxy details:     
    $ cat <<EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
    [Service]
    Environment="HTTP_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT"
    Environment="HTTPS_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT"
    Environment="NO_PROXY=localhost,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/docker.sock"
    EOF
    ```
    >Note: On some hosts `/etc/systemd/system/docker.service.d` may not be available. Create this directory if it is not available.

1. Restart the Docker daemon to load the latest changes:
    ```
    $ systemctl daemon-reload    
    $ systemctl restart docker
    ```

1. Verify that the proxy is configured with Docker:
    ```
    $ docker info|grep -i proxy
    ```
    Example output:   
    ```
    HTTP Proxy: http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    HTTPS Proxy: http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    No Proxy: localhost,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/docker.sock
    ```

1. Verify Docker installation:
    ```
    $ docker run hello-world     
    ```
    Example output:
    ```
    Hello from Docker!
    This message shows that your installation appears to be working correctly.
    To generate this message, Docker took the following steps:
    1. The Docker client contacted the Docker daemon.
    2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
       (amd64)
    3. The Docker daemon created a new container from that image which runs the
       executable that produces the output you are currently reading.
    4. The Docker daemon streamed that output to the Docker client, which sent it to your terminal.
    To try something more ambitious, you can run an Ubuntu container with:
     $ docker run -it ubuntu bash
    Share images, automate workflows, and more with a free Docker ID:
     https://hub.docker.com/
    For more examples and ideas, visit:
     https://docs.docker.com/get-started/
    ```

#### 1.3 Install and configure Kubernetes

1. Add the external Kubernetes repository:
    ```
    $ cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
    enabled=1
    gpgcheck=1
    repo_gpgcheck=1
    gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    exclude=kubelet kubeadm kubectl
    EOF

1. Set SELinux in permissive mode (effectively disabling it):
    ```
    $ export PATH=/sbin:$PATH
    $ setenforce 0
    $ sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    ```

1. Export proxy and install `kubeadm`, `kubelet`, and `kubectl`:
    ```
    ### Get the nslookup IP address of the master node to use with apiserver-advertise-address during setting up Kubernetes master
    ### as the host may have different internal ip (hostname -i) and nslookup $HOSTNAME
    $ ip_addr=`nslookup $(hostname -f) | grep -m2 Address | tail -n1| awk -F: '{print $2}'| tr -d " "`
    $ echo $ip_addr

    ### Set the proxies
    $ export NO_PROXY=localhost,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/docker.sock,$ip_addr
    $ export no_proxy=localhost,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/docker.sock,$ip_addr
    $ export http_proxy=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    $ export https_proxy=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    $ export HTTPS_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    $ export HTTP_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT

    ### install kubernetes 1.20.10
    $ VERSION=1.20.10
    $ yum install -y kubelet-$VERSION kubeadm-$VERSION kubectl-$VERSION --disableexcludes=kubernetes

    ### enable kubelet service so that it auto-restart on reboot
    $ systemctl enable --now kubelet
    ```

1. Ensure `net.bridge.bridge-nf-call-iptables` is set to 1 in your `sysctl` to avoid traffic routing issues:
    ```
    $ cat <<EOF >  /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    EOF
    $ sysctl --system
    ```

1. Disable swap check:
    ```
    $ sed -i 's/KUBELET_EXTRA_ARGS=/KUBELET_EXTRA_ARGS="--fail-swap-on=false"/' /etc/sysconfig/kubelet
    $ cat /etc/sysconfig/kubelet
    ### Reload and restart kubelet
    $ systemctl daemon-reload
    $ systemctl restart kubelet    
    ```

#### 1.4 Set up Helm

1. Install Helm v3.4+

   a. Download Helm from https://github.com/helm/helm/releases.

      For example, to download Helm v3.4.1:
      ```
      $ wget https://get.helm.sh/helm-v3.4.1-linux-amd64.tar.gz
      ```
   b. Unpack `tar.gz`:
      ```
      $ tar -zxvf helm-v3.4.1-linux-amd64.tar.gz
      ```
   c. Find the Helm binary in the unpacked directory, and move it to its desired destination:
      ```
      $ mv linux-amd64/helm /usr/bin/helm
      ```

1. Run `helm version` to verify its installation:
   ```
   $ helm version
     version.BuildInfo{Version:"v3.4.1", GitCommit:"0ad800ef43d3b826f31a5ad8dfbb4fe05d143688", GitTreeState:"clean", GoVersion:"go1.13.12"}
   ```

### 2. Set up a single instance Kubernetes cluster

>  **Notes:**
>  * These steps must be run with the `root` user, unless specified otherwise!
>  * If you choose to use a different CIDR block (that is, other than `10.244.0.0/16` for the `--pod-network-cidr=` in the `kubeadm init` command), then also update `NO_PROXY` and `no_proxy` with the appropriate value.
>     * Also make sure to update `kube-flannel.yaml` with the new value before deploying.
> * Replace the following with appropriate values:
>     *  `ADD-YOUR-INTERNAL-NO-PROXY-LIST`
>     *  `REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT`

#### 2.1 Set up the master node
1. Create a shell script that sets up the necessary environment variables. You can append this to the user’s `.bashrc` so that it will run at login. You must also configure your proxy settings here if you are behind an HTTP proxy:

    ```
    ## grab my IP address to pass into  kubeadm init, and to add to no_proxy vars
    ip_addr=`nslookup $(hostname -f) | grep -m2 Address | tail -n1| awk -F: '{print $2}'| tr -d " "`
    export pod_network_cidr="10.244.0.0/16"
    export service_cidr="10.96.0.0/12"
    export PATH=$PATH:/sbin:/usr/sbin

    ### Set the proxies
    export NO_PROXY=localhost,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/docker.sock,$ip_addr,$pod_network_cidr,$service_cidr
    export no_proxy=localhost,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/docker.sock,$ip_addr,$pod_network_cidr,$service_cidr
    export http_proxy=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    export https_proxy=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    export HTTPS_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    export HTTP_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    ```

1. Source the script to set up your environment variables:
    ```
    $ . ~/.bashrc
    ```

1. To implement command completion, add the following to the script:
    ```
    $ [ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
    $ source <(kubectl completion bash)
    ```
1. Run `kubeadm init` to create the master node:
   ```
   $ kubeadm init \
     --pod-network-cidr=$pod_network_cidr \
     --apiserver-advertise-address=$ip_addr \
     --ignore-preflight-errors=Swap  > /tmp/kubeadm-init.out 2>&1
   ```

1. Log in to the terminal with `YOUR_USERID:YOUR_GROUP`. Then set up the `~/.bashrc` similar to steps 1 to 3 with `YOUR_USERID:YOUR_GROUP`.

    > Note that from now on we will be using `YOUR_USERID:YOUR_GROUP` to execute any `kubectl` commands and not `root`.

1. Set up `YOUR_USERID:YOUR_GROUP` to access the Kubernetes cluster:
   ```
   $ mkdir -p $HOME/.kube
   $ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   $ sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```
1. Verify that `YOUR_USERID:YOUR_GROUP` is set up to access the Kubernetes cluster using the `kubectl` command:

   ```
   $ kubectl get nodes
   ```
   > Note: At this step, the node is not in ready state as we have not yet installed the pod network add-on. After the next step, the node will show status as Ready.

1. Install a pod network add-on (`flannel`) so that your pods can communicate with each other.

   > Note: If you are using a different CIDR block than `10.244.0.0/16`, then download and update `kube-flannel.yml` with the correct CIDR address before deploying into the cluster:
   ```
   $ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.12.0/Documentation/kube-flannel.yml
   ```

1. Verify that the master node is in Ready status:
   ```
   $ kubectl get nodes
   ```
   Sample output:
   ```
   NAME        STATUS   ROLES    AGE     VERSION
   mymasternode Ready    master   8m26s   v1.18.4
   ```
   or:
   ```
   $ kubectl get pods -n kube-system
   ```
   Sample output:
   ```
   NAME                                    READY       STATUS      RESTARTS    AGE
   pod/coredns-86c58d9df4-58p9f                1/1         Running         0       3m59s
   pod/coredns-86c58d9df4-mzrr5                1/1         Running         0       3m59s
   pod/etcd-mymasternode                       1/1         Running         0       3m4s
   pod/kube-apiserver-node                     1/1         Running         0       3m21s
   pod/kube-controller-manager-mymasternode    1/1         Running         0       3m25s
   pod/kube-flannel-ds-amd64-6npx4             1/1         Running         0       49s
   pod/kube-proxy-4vsgm                        1/1         Running         0       3m59s
   pod/kube-scheduler-mymasternode             1/1         Running         0       2m58s
   ```

1. To schedule pods on the master node, `taint` the node:
   ```
   $ kubectl taint nodes --all node-role.kubernetes.io/master-
   ```

Congratulations! Your Kubernetes cluster environment is ready to deploy your Oracle WebCenter Portal domain.

For additional references on Kubernetes cluster setup, check the [cheat sheet](https://oracle.github.io/weblogic-kubernetes-operator/userguide/overview/k8s-setup/).

### 3. Get scripts and images

#### 3.1 Set up the code repository to deploy Oracle WebCenter Portal

Follow [these steps]({{< relref "/wcportal-domains/installguide/prepare-your-environment/#set-up-the-code-repository-to-deploy-oracle-webcenter-portal-domain" >}}) to set up the source code repository required to deploy Oracle WebCenter Portal domain.

#### 3.2 Get required Docker images and add them to your local registry

1. Pull the operator image:

    ```
    $ docker pull ghcr.io/oracle/weblogic-kubernetes-operator:3.3.0
    ```

1. Obtain the Oracle Database image from the [Oracle Container Registry](https://container-registry.oracle.com):

    a. For first time users, to pull an image from the Oracle Container Registry, navigate to https://container-registry.oracle.com and log in using the Oracle Single Sign-On (SSO) authentication service. If you do not already have SSO credentials, you can create an Oracle Account using:  
    https://profile.oracle.com/myprofile/account/create-account.jspx.

    Use the web interface to accept the Oracle Standard Terms and Restrictions for the Oracle software images that you intend to deploy. Your acceptance of these terms are stored in a database that links the software images to your Oracle Single Sign-On login credentials.

     To obtain the image, log in to the Oracle Container Registry:
     ```
     $ docker login container-registry.oracle.com
     ```

    b. Find and then pull the Oracle Database image for 12.2.0.1:
     ```
     $ docker pull container-registry.oracle.com/database/enterprise:12.2.0.1-slim
     ```

    c. Build Oracle WebCenter Portal 12.2.1.4 Image by following steps from this [document]({{< relref "/wcportal-domains/create-or-update-image/">}}).


### 4. Install the WebLogic Kubernetes operator

#### 4.1 Prepare for the WebLogic Kubernetes operator.
1. Create a namespace `operator-ns` for the operator:
   ```
   $ kubectl create namespace operator-ns
   ```

1. Create a service account `operator-sa` for the operator in the operator’s namespace:
   ```
   $ kubectl create serviceaccount -n operator-ns operator-sa
   ```

#### 4.2 Install the WebLogic Kubernetes operator

Use Helm to install and start the operator from the directory you just cloned:

```
   $ cd ${WORKDIR}
   $ helm install weblogic-kubernetes-operator charts/weblogic-operator \
   --namespace operator-ns \
   --set image=oracle/weblogic-kubernetes-operator:3.3.0 \
   --set serviceAccount=operator-sa \
   --set "domainNamespaces={}" \
   --wait
```
#### 4.3 Verify the WebLogic Kubernetes operator

1. Verify that the operator’s pod is running by listing the pods in the operator’s namespace. You should see one for the operator:
   ```
   $ kubectl get pods -n operator-ns
   ```

1. Verify that the operator is up and running by viewing the operator pod's logs:
   ```
   $ kubectl logs -n operator-ns -c weblogic-operator deployments/weblogic-operator
   ```

The WebLogic Kubernetes operator v3.3.0 has been installed. Continue with the load balancer and Oracle WebCenter Portal domain setup.

### 5. Install the Traefik (ingress-based) load balancer

The WebLogic Kubernetes Operator supports three load balancers: Traefik, NGINX and Apache. Samples are provided in the documentation.

This Quick Start demonstrates how to install the Traefik ingress controller to provide load balancing for an Oracle WebCenter Portal domain.

1. Create a namespace for Traefik:
    ```
    $ kubectl create namespace traefik
    ```

1. Set up Helm for 3rd party services:
   ```
   $ helm repo add traefik https://containous.github.io/traefik-helm-chart
   ```

1. Install the Traefik operator in the `traefik` namespace with the provided sample values:
   ```
   $ cd ${WORKDIR}
   $ helm install traefik traefik/traefik \
    --namespace traefik \
    --values charts/traefik/values.yaml \
    --set "kubernetes.namespaces={traefik}" \
    --set "service.type=NodePort" \
    --wait
   ```

### 6. Create and configure an Oracle WebCenter Portal domain
#### 6.1 Prepare for an Oracle WebCenter Portal domain

1. Create a namespace that can host Oracle WebCenter Portal domain:
   ```
   $ kubectl create namespace wcpns
   ```

1. Use Helm to configure the operator to manage Oracle WebCenter Portal domain in this namespace:
   ```
   $ cd ${WORKDIR}
   $ helm upgrade weblogic-kubernetes-operator charts/weblogic-operator \
      --reuse-values \
      --namespace operator-ns \
      --set "domainNamespaces={wcpns}" \
      --wait
   ```

1. Create Kubernetes secrets.

   a. Create a Kubernetes secret for the domain in the same Kubernetes namespace as the domain. In this example, the username is `weblogic`, the password is `welcome1`, and the namespace is `wcpns`:

      ```
      $ cd ${WORKDIR}/create-weblogic-domain-credentials
      $ sh create-weblogic-credentials.sh -u weblogic -p welcome1 -n wcpns -d wcp-domain -s wcp-domain-domain-credentials
      ```

   b. Create a Kubernetes secret for the RCU in the same Kubernetes namespace as the domain:

     * Schema user          : `WCP1`
     * Schema password      : `Oradoc_db1`                  
     * DB sys user password : `Oradoc_db1`
     * Domain name          : `wcp-domain`
     * Domain Namespace     : `wcpns`
     * Secret name          : `wcp-domain-rcu-credentials`

     ```
     $ cd ${WORKDIR}/create-rcu-credentials
     $ sh create-rcu-credentials.sh -u WCP1 -p Oradoc_db1 -a sys -q Oradoc_db1 -n wcpns -d wcp-domain -s wcp-domain-rcu-credentials
      ```

1. Create the Kubernetes persistence volume and persistence volume claim.

   a. Create the Oracle WebCenter Portal domain home directory.
      Determine if a user already exists on your host system with `uid:gid` of `1000`:
      ```
      $ sudo getent passwd 1000
      ```

      If this command returns a username (which is the first field), you can skip the following `useradd` command. If not, create the oracle user with `useradd`:
      ```
      $ sudo useradd -u 1000 -g 1000 oracle
      ```

      Create the directory that will be used for the Oracle WebCenter Portal domain home:
      ```
      $ sudo mkdir /scratch/k8s_dir
      $ sudo chown -R 1000:1000 /scratch/k8s_dir
      ```

    b. Update `create-pv-pvc-inputs.yaml` with the following values:

      * baseName: `domain`
      * domainUID: `wcp-domain`
      * namespace: `wcpns`
      * weblogicDomainStoragePath: `/scratch/k8s_dir`

      ```
      $ cd ${WORKDIR}/create-weblogic-domain-pv-pvc
      $ cp create-pv-pvc-inputs.yaml create-pv-pvc-inputs.yaml.orig
      $ sed -i -e "s:baseName\: weblogic-sample:baseName\: domain:g" create-pv-pvc-inputs.yaml
      $ sed -i -e "s:domainUID\::domainUID\: wcp-domain:g" create-pv-pvc-inputs.yaml
      $ sed -i -e "s:namespace\: default:namespace\: wcpns:g" create-pv-pvc-inputs.yaml
      $ sed -i -e "s:#weblogicDomainStoragePath\: /scratch/k8s_dir:weblogicDomainStoragePath\: /scratch/k8s_dir:g" create-pv-pvc-inputs.yaml
      ```

    c. Run the `create-pv-pvc.sh` script to create the PV and PVC configuration files:
      ```
      $ ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output
      ```

    d. Create the PV and PVC using the configuration files created in the previous step:
      ```
        $ kubectl create -f output/pv-pvcs/wcp-domain-domain-pv.yaml
        $ kubectl create -f output/pv-pvcs/wcp-domain-domain-pvc.yaml
      ```

1. Install and configure the database for the Oracle WebCenter Portal domain.

   This step is required only when a standalone database is not already set up and you want to use the database in a container.

   {{% notice warning %}}
   The Oracle Database Docker images are supported only for non-production use. For more details, see My Oracle Support note: Oracle Support for Database Running on Docker (Doc ID 2216342.1). For production, it is suggested to use a standalone database. This example provides steps to create the database in a container.
   {{% /notice %}}

   a. Create a database in a container:

      ```
      $ cd ${WORKDIR}/create-oracle-db-service
      $ ./start-db-service.sh -i  container-registry.oracle.com/database/enterprise:12.2.0.1-slim -p none
      ```

      Once the database is successfully created, you can use the database connection string `oracle-db.default.svc.cluster.local:1521/devpdb.k8s` as an `rcuDatabaseURL` parameter in the `create-domain-inputs.yaml` file.

   b. Create Oracle WebCenter Portal schemas.

      To create the Oracle WebCenter Portal schemas, run the following commands:
      ```
        $ ./create-rcu-schema.sh \
          -s WCP1 \
          -t wcp \
          -d oracle-db.default.svc.cluster.local:1521/devpdb.k8s \
          -i oracle/wcportal:12.2.1.4\
          -n wcpns \
          -q Oradoc_db1 \
          -r welcome1 
      ```

Now the environment is ready to start the Oracle WebCenter Portal domain creation.


#### 6.2 Create an Oracle WebCenter Portal domain

1. The sample scripts for Oracle WebCenter Portal domain deployment are available at `create-wcp-domain`. You must edit `create-domain-inputs.yaml` (or a copy of it) to provide the details for your domain.

    Update `create-domain-inputs.yaml` with the following values for domain creation:

    *  `rcuDatabaseURL`: `oracle-db.default.svc.cluster.local:1521/devpdb.k8s`
     

1. Run the `create-domain.sh` script to create a domain:
    ```
    $ cd ${WORKDIR}/create-wcp-domain/domain-home-on-pv/
    $ ./create-domain.sh -i create-domain-inputs.yaml -o output
    ```

1. Create a Kubernetes domain object:

    Once the `create-domain.sh` is successful, it generates `output/weblogic-domains/wcp-domain/domain.yaml`, which you can use to create the Kubernetes resource domain to start the domain and servers:

    ```
    $ cd ${WORKDIR}/create-wcp-domain/domain-home-on-pv
    $ kubectl create -f output/weblogic-domains/wcp-domain/domain.yaml
    ```

1. Verify that the Kubernetes domain object named `wcp-domain` is created:
    ```
    $ kubectl get domain -n wcpns
    NAME       AGE
    wcp-domain   3m18s
    ```

1. Once you create the domain, the *introspect pod* is created. This inspects the domain home and then starts the `wcp-domain-adminserver` pod. Once the `wcp-domain-adminserver` pod starts successfully, the Managed Server pods are started in parallel.
Watch the `wcpns` namespace for the status of domain creation:
    ```
    $ kubectl get pods -n wcpns -w
    ```

1. Verify that the Oracle WebCenter Portal domain server pods and services are created and in Ready state:
    ```
    $ kubectl get all -n wcpns
    ```

#### 6.3 Configure Traefik to access Oracle WebCenter Portal domain services

1. Configure Traefik to manage ingresses created in the Oracle WebCenter Portal domain namespace (`wcpns`):
    ```
    $ helm upgrade traefik traefik/traefik \
      --reuse-values \
      --namespace traefik \
      --set "kubernetes.namespaces={traefik,wcpns}" \
      --wait
    ```

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart:
    ```
    $ cd ${WORKDIR}
    helm install wcp-traefik-ingress  \
    charts/ingress-per-domain \
    --namespace wcpns \
     --values charts/ingress-per-domain/values.yaml \
     --set "traefik.hostname=$(hostname -f)"
    ```
1. Verify the created ingress per domain details:
    ```
    $ kubectl describe ingress wcp-domain-traefik -n wcpns
    ```

#### 6.4 Verify that you can access the Oracle WebCenter Portal domain URL

1. Get the `LOADBALANCER_HOSTNAME` for your environment:
    ```
    export LOADBALANCER_HOSTNAME=$(hostname -f)
    ```
1. Verify the following URLs are available for Oracle WebCenter Portal domain.

    Credentials:

    *username*: `weblogic`
    *password*: `welcome1`

    ```
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/webcenter
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/console
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/em
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/rsscrawl
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/rest
    http://${LOADBALANCER_HOSTNAME}:${LOADBALANCER-Non-SSLPORT}/webcenterhelp
    ```
