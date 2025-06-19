---
title: "Quick start deployment on-premise"
date: 2020-06-18T15:27:38-05:00
weight:  2
pre: "<b> </b>"
Description: "Describes how to quickly get an Oracle SOA Suite domain instance running (using the defaults, nothing special) for development and test purposes."
---

Use this Quick Start to create an Oracle SOA Suite domain deployment in a Kubernetes cluster (on-premise environments) with the WebLogic Kubernetes Operator. Note that this walkthrough is for demonstration purposes only, not for use in production.
These instructions assume that you are already familiar with Kubernetes. If you need more detailed instructions,
refer to the [Install Guide]({{< relref "/soa-domains/installguide/_index.md" >}}).


#### Hardware requirements

The Linux kernel supported for deploying and running Oracle SOA Suite domains with the operator is Oracle Linux 8 and Red Hat Enterprise Linux 8. Refer to the [prerequisites]({{< relref "/soa-domains/installguide/prerequisites/_index.md" >}}) for more details.

For this exercise, the minimum hardware requirements to create a single-node Kubernetes cluster and then deploy the `soaosb` (Oracle SOA Suite, Oracle Service Bus, and Enterprise Scheduler (ESS)) domain type with one Managed Server for Oracle SOA Suite and one for the Oracle Service Bus cluster, along with Oracle Database running as a container are:

 Hardware|Size
 --|--
 RAM|32GB
 Disk Space|250GB+
 CPU core(s)|6

See [here]({{< relref "/soa-domains/appendix/soa-cluster-sizing-info.md" >}}) for resource sizing information for Oracle SOA Suite domains set up on a Kubernetes cluster.

### Set up Oracle SOA Suite in an on-premise environment
Use the steps in this topic to create a single-instance on-premise Kubernetes cluster and then create an Oracle SOA Suite `soaosb` domain type, which deploys a domain with Oracle SOA Suite, Oracle Service Bus, and Oracle Enterprise Scheduler (ESS).

* [Step 1 - Prepare a virtual machine for the Kubernetes cluster](#1-prepare-a-virtual-machine-for-the-kubernetes-cluster)
* [Step 2 - Set up a single instance Kubernetes cluster](#2-set-up-a-single-instance-kubernetes-cluster)
* [Step 3 - Get scripts and images](#3-get-scripts-and-images)
* [Step 4 - Install the WebLogic Kubernetes Operator](#4-install-the-weblogic-kubernetes-operator)
* [Step 5 - Install the Traefik (ingress-based) load balancer](#5-install-the-traefik-ingress-based-load-balancer)
* [Step 6 - Create and configure an Oracle SOA Suite domain](#6-create-and-configure-an-oracle-soa-suite-domain)


### 1. Prepare a virtual machine for the Kubernetes cluster

For illustration purposes, these instructions are for Oracle Linux 8.  If you are using a different flavor of Linux, you will need to adjust the steps accordingly.

{{% notice note %}} These steps must be run with the `root` user, unless specified otherwise.
Any time you see `YOUR_USERID` in a command, you should replace it with your actual `userid`.
{{% /notice %}}

####  1.1 Prerequisites

1. Choose the directories where your Kubernetes files will be stored. The Kubernetes directory is used for the `/var/lib/kubelet` file system and persistent volume storage.

    ```shell
    $ export kubelet_dir=/u01/kubelet
    $ mkdir -p $kubelet_dir
    $ ln -s $kubelet_dir /var/lib/kubelet
    ```

1. Verify that IPv4 forwarding is enabled on your host.

    **Note**: Replace eth0 with the ethernet interface name of your compute resource if it is different.
    ```shell
    $ /sbin/sysctl -a 2>&1|grep -s 'net.ipv4.conf.eth0.forwarding'
    $ /sbin/sysctl -a 2>&1|grep -s 'net.ipv4.conf.lo.forwarding'
    $ /sbin/sysctl -a 2>&1|grep -s 'net.ipv4.ip_nonlocal_bind'
    ```

    For example: Verify that all are set to 1:
    ```shell
    $ net.ipv4.conf.eth0.forwarding = 1
    $ net.ipv4.conf.lo.forwarding = 1
    $ net.ipv4.ip_nonlocal_bind = 1
    ```
    Solution: Set all values to 1 immediately:
    ```shell
    $ /sbin/sysctl net.ipv4.conf.eth0.forwarding=1
    $ /sbin/sysctl net.ipv4.conf.lo.forwarding=1
    $ /sbin/sysctl net.ipv4.ip_nonlocal_bind=1
    ```

1. **To preserve the settings permanently**: Update the above values to 1 in files in ``/usr/lib/sysctl.d/``, ``/run/sysctl.d/``, and ``/etc/sysctl.d/``.

1. Verify the iptables rule for forwarding.

   Kubernetes uses iptables to handle many networking and port forwarding rules. A standard container installation may create a firewall rule that prevents forwarding.

    Verify if the iptables rule to accept forwarding traffic is set:
    ```shell
    $ /sbin/iptables -L -n | awk '/Chain FORWARD / {print $4}' | tr -d ")"
    ```

    If the output is "DROP", then run the following command:
    ```shell
    $ /sbin/iptables -P FORWARD ACCEPT
    ```

    Verify if the iptables rule is properly set to "ACCEPT":
    ```shell
    $ /sbin/iptables -L -n | awk '/Chain FORWARD / {print $4}' | tr -d ")"
    ```

1. Disable and stop `firewalld`:

    ```shell
    $ systemctl disable firewalld
    $ systemctl stop firewalld
    ```

#### 1.2 Install CRI-O and Podman

> Note: If you have already configured CRI-O and Podman, continue to [Install and configure Kubernetes](#13-install-and-configure-kubernetes).

1. Make sure that you have the right operating system version:
    ```shell
    $ uname -a
    $ more /etc/oracle-release
    ```
    Example output:
    ```shell
    Linux xxxxxx 5.15.0-100.96.32.el8uek.x86_64 #2 SMP Tue Feb 27 18:08:15 PDT 2024 x86_64 x86_64 x86_64 GNU/Linux
    Oracle Linux Server release 8.6
    ```

1. Installing CRI-O:

    ```shell
    ### Add OLCNE( Oracle Cloud Native Environment ) Repository and  KVM repository to the dnf config-manager. This allows dnf to install "qemu-kvm-core" packages and any other additional packages required for CRI-O installation. 
    ## For OL8
    $ dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL8/olcne18/x86_64
    $ dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL8/kvm/appstream/x86_64

    ## For OL9
    $ dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL9/olcne18/x86_64
    $ dnf config-manager --add-repo https://yum.oracle.com/repo/OracleLinux/OL9/kvm/appstream/x86_64
    
    ### Installing cri-o
    $ dnf install -y cri-o
    ```

    > Note: To install a different version of CRI-O or on a different operating system, see [CRI-O Installation Instructions](https://github.com/cri-o/cri-o/blob/main/install.md).      

1. Start the CRI-O service:

    Set up Kernel Modules and Proxies
    ```shell
    ### Enable kernel modules overlay and br_netfilter which are required for Kubernetes Container Network Interface (CNI) plugins
    $ modprobe overlay
    $ modprobe br_netfilter

    ### To automatically load these modules at system start up create config as below
    $ cat <<EOF > /etc/modules-load.d/crio.conf
    overlay
    br_netfilter
    EOF
    $ sysctl --system

    ### Set the environmental variable CONTAINER_RUNTIME_ENDPOINT to crio.sock to use crio as the container runtime
    $ export CONTAINER_RUNTIME_ENDPOINT=unix:///var/run/crio/crio.sock

    ### Setup Proxy for CRIO service
    $ cat <<EOF > /etc/sysconfig/crio
    http_proxy=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    https_proxy=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    HTTPS_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    HTTP_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    no_proxy=localhost,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/crio/crio.sock
    NO_PROXY=localhost,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/crio/crio.sock
    EOF
    ```
    
    Set the runtime for CRI-O
    ```shell
    ### Setting the runtime for crio
    ## Update crio.conf
    $ vi /etc/crio/crio.conf
    ## Append following under [crio.runtime]
    conmon_cgroup = "kubepods.slice"
    cgroup_manager = "systemd"
    ## Uncomment following under [crio.network]
    network_dir="/etc/cni/net.d"
    plugin_dirs=[
        "/opt/cni/bin",
        "/usr/libexec/cni",
    ]
    ```

    Start the CRI-O Service
    ```shell
    ## Restart crio service
    $ systemctl restart crio.service
    $ systemctl enable --now crio
    ```
1. Installing Podman:
        
    On Oracle Linux 8, if podman is not available, then install Podman and related tools with following command syntax:
    ```shell
    $ sudo dnf module install container-tools:ol8
    ```

    On Oracle Linux 9, if podman is not available, then install Podman and related tools with following command syntax:
    ```shell
    $ sudo dnf install container-tools
    ```

    Since the setup uses "docker" CLI commands, on Oracle Linux 8/9, install the podman-docker package if not available, that effectively aliases the docker command to podman,with following command syntax:
    ```shell
    $ sudo dnf install podman-docker
    ```

1. Configure Podman rootless:

    For using podman with your User ID (Rootless environment), Podman requires the user running it to have a range of UIDs listed in the files /etc/subuid and /etc/subgid. Rather than updating the files directly, the usermod program can be used to assign UIDs and GIDs to a user with the following commands:

    ```shell
    $ sudo /sbin/usermod --add-subuids 100000-165535 --add-subgids 100000-165535 <REPLACE_USER_ID>
    $ podman system migrate
    ```
    > Note: The above "podman system migrate" need to be executed with your User ID and not root.

    Verify the user-id addition
    ```shell
    $ cat /etc/subuid
    $ cat /etc/subgid
    ```

    Expected similar output
    ```shell
    opc:100000:65536
    <user-id>:100000:65536
    ```

#### 1.3 Install and Configure Kubernetes

1. Set SELinux in permissive mode (effectively disabling it):
    ```shell
    $ export PATH=/sbin:$PATH
    $ setenforce 0
    $ sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    ```

1. Export proxy and enable `kubelet`:
    ```shell
    ### Get the nslookup IP address of the master node to use with apiserver-advertise-address during setting up Kubernetes master
    ### as the host may have different internal ip (hostname -i) and nslookup $HOSTNAME
    $ ip_addr=`nslookup $(hostname -f) | grep -m2 Address | tail -n1| awk -F: '{print $2}'| tr -d " "`
    $ echo $ip_addr

    ### Set the proxies
    $ export NO_PROXY=localhost,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/crio/crio.sock,$ip_addr,.svc
    $ export no_proxy=localhost,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/crio/crio.sock,$ip_addr,.svc
    $ export http_proxy=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    $ export https_proxy=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    $ export HTTPS_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    $ export HTTP_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT

    ### Install the kubernetes components and enable the kubelet service so that it automatically restarts on reboot
    $ dnf install -y kubeadm kubelet kubectl
    $ systemctl enable --now kubelet
    ```

1. Ensure `net.bridge.bridge-nf-call-iptables` is set to 1 in your `sysctl` to avoid traffic routing issues:
    ```shell
    $ cat <<EOF >  /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
    EOF
    $ sysctl --system
    ```

1. Disable swap check:
    ```shell
    $ sed -i 's/KUBELET_EXTRA_ARGS=/KUBELET_EXTRA_ARGS="--fail-swap-on=false"/' /etc/sysconfig/kubelet
    $ cat /etc/sysconfig/kubelet
    ### Reload and restart kubelet
    $ systemctl daemon-reload
    $ systemctl restart kubelet
    ```

1. Pull the images using crio:
    ```shell
    kubeadm config images pull --cri-socket unix:///var/run/crio/crio.sock
    ```

#### 1.4 Set up Helm

1. Install Helm v3.10.2+.

   a. Download Helm from https://github.com/helm/helm/releases.

      For example, to download Helm v3.10.2:
      ```shell
      $ wget https://get.helm.sh/helm-v3.10.2-linux-amd64.tar.gz
      ```
   b. Unpack `tar.gz`:
      ```shell
      $ tar -zxvf helm-v3.10.2-linux-amd64.tar.gz
      ```
   c. Find the Helm binary in the unpacked directory, and move it to its desired destination:
      ```shell
      $ mv linux-amd64/helm /usr/bin/helm
      ```

1. Run `helm version` to verify its installation:
   ```shell
   $ helm version
     version.BuildInfo{Version:"v3.10.2", GitCommit:"50f003e5ee8704ec937a756c646870227d7c8b58", GitTreeState:"clean", GoVersion:"go1.18.8"}
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

    ```shell
    ## grab my IP address to pass into  kubeadm init, and to add to no_proxy vars
    ip_addr=`nslookup $(hostname -f) | grep -m2 Address | tail -n1| awk -F: '{print $2}'| tr -d " "`
    export pod_network_cidr="10.244.0.0/16"
    export service_cidr="10.96.0.0/12"
    export PATH=$PATH:/sbin:/usr/sbin

    ### Set the proxies
    export NO_PROXY=localhost,.svc,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/crio/crio.sock,$ip_addr,$pod_network_cidr,$service_cidr
    export no_proxy=localhost,.svc,127.0.0.0/8,ADD-YOUR-INTERNAL-NO-PROXY-LIST,/var/run/crio/crio.sock,$ip_addr,$pod_network_cidr,$service_cidr
    export http_proxy=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    export https_proxy=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    export HTTPS_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    export HTTP_PROXY=http://REPLACE-WITH-YOUR-COMPANY-PROXY-HOST:PORT
    ```

1. Source the script to set up your environment variables:
    ```shell
    $ . ~/.bashrc
    ```

1. To implement command completion, add the following to the script:
    ```shell
    $ [ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
    $ source <(kubectl completion bash)
    ```
1. Run `kubeadm init` to create the master node:
   ```shell
   $ kubeadm init \
     --pod-network-cidr=$pod_network_cidr \
     --apiserver-advertise-address=$ip_addr \
     --ignore-preflight-errors=Swap  > /tmp/kubeadm-init.out 2>&1
   ```

1. Log in to the terminal with `YOUR_USERID:YOUR_GROUP`. Then set up the `~/.bashrc` similar to steps 1 to 3 with `YOUR_USERID:YOUR_GROUP`.

    > Note that from now on we will be using `YOUR_USERID:YOUR_GROUP` to execute any `kubectl` commands and not `root`.

1. Set up `YOUR_USERID:YOUR_GROUP` to access the Kubernetes cluster:
   ```shell
   $ mkdir -p $HOME/.kube
   $ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   $ sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```
1. Verify that `YOUR_USERID:YOUR_GROUP` is set up to access the Kubernetes cluster using the `kubectl` command:

   ```shell
   $ kubectl get nodes
   ```
   > Note: At this step, the node is not in ready state as we have not yet installed the pod network add-on. After the next step, the node will show status as Ready.

1. Install a pod network add-on (`flannel`) so that your pods can communicate with each other.

   > Note: If you are using a different CIDR block than `10.244.0.0/16`, then download and update `kube-flannel.yml` with the correct CIDR address before deploying into the cluster:
   ```shell
   $ wget https://github.com/flannel-io/flannel/releases/download/v0.25.1/kube-flannel.yml
   $ ### Update the CIDR address if you are using a CIDR block other than the default 10.244.0.0/16
   $ kubectl apply -f kube-flannel.yml
   ```

1. Verify that the master node is in Ready status:
   ```shell
   $ kubectl get nodes
   ```
   Sample output:
   ```shell
   NAME              STATUS      ROLES        AGE   VERSION
   mymasternode      Ready    control-plane   12h   v1.27.2
   ```
   or:
   ```shell
   $ kubectl get pods -n kube-system
   ```
   Sample output:
   ```shell
   NAME                                    READY       STATUS      RESTARTS    AGE
   pod/coredns-86c58d9df4-58p9f                1/1         Running         0       3m59s
   pod/coredns-86c58d9df4-mzrr5                1/1         Running         0       3m59s
   pod/etcd-mymasternode                       1/1         Running         0       3m4s
   pod/kube-apiserver-node                     1/1         Running         0       3m21s
   pod/kube-controller-manager-mymasternode    1/1         Running         0       3m25s
   pod/kube-flannel-ds-6npx4                   1/1         Running         0       49s
   pod/kube-proxy-4vsgm                        1/1         Running         0       3m59s
   pod/kube-scheduler-mymasternode             1/1         Running         0       2m58s
   ```

1. To schedule pods on the master node, `taint` the node:
   ```shell
   $ kubectl taint nodes --all node-role.kubernetes.io/control-plane-
   ```

Congratulations! Your Kubernetes cluster environment is ready to deploy your Oracle SOA Suite domain.

Refer to the official [documentation](https://kubernetes.io/docs/setup/#production-environment) to set up a Kubernetes cluster.

### 3. Get scripts and images

#### 3.1 Set up the source code repository to deploy Oracle SOA Suite domains

1. Create a working directory to set up the source code:
    ```bash
    $ mkdir $HOME/soa_24.4.2
    $ cd $HOME/soa_24.4.2
    ```

1. Download the WebLogic Kubernetes Operator source code and  Oracle SOA Suite Kubernetes deployment scripts from the SOA [repository](https://github.com/oracle/fmw-kubernetes.git). Required artifacts are available at `OracleSOASuite/kubernetes`.

    ``` bash
    $ git clone https://github.com/oracle/fmw-kubernetes.git
    $ export WORKDIR=$HOME/soa_24.4.2/fmw-kubernetes/OracleSOASuite/kubernetes
    ```

#### 3.2 Get required Docker images and add them to your local registry

1. Pull the WebLogic Kubernetes Operator image:

    ```shell
    $ podman pull ghcr.io/oracle/weblogic-kubernetes-operator:4.2.9
    ```

1. Obtain the Oracle Database image and Oracle SOA Suite Docker image from the [Oracle Container Registry](https://container-registry.oracle.com):

    a. For first time users, to pull an image from the Oracle Container Registry, navigate to https://container-registry.oracle.com and log in using the Oracle Single Sign-On (SSO) authentication service. If you do not already have SSO credentials, you can create an Oracle Account using:
    https://profile.oracle.com/myprofile/account/create-account.jspx.

    Use the web interface to accept the Oracle Standard Terms and Restrictions for the Oracle software images that you intend to deploy. Your acceptance of these terms are stored in a database that links the software images to your Oracle Single Sign-On login credentials.

     To obtain the image, log in to the Oracle Container Registry:
     ```shell
     $ podman login container-registry.oracle.com
     ```

    b. Find and then pull the Oracle Database image for 12.2.0.1:
     ```shell
     $ podman pull container-registry.oracle.com/database/enterprise:12.2.0.1-slim
     ```

    c. Find and then pull the prebuilt Oracle SOA Suite image 12.2.1.4 install image:

     ```shell
     $ podman pull container-registry.oracle.com/middleware/soasuite:12.2.1.4
     ```
     > Note: This image does not contain any Oracle SOA Suite product patches and can only be used for test and development purposes.

### 4. Install the WebLogic Kubernetes Operator

#### 4.1 Prepare for the WebLogic Kubernetes Operator.
1. Create a namespace `opns` for the operator:
   ```shell
   $ kubectl create namespace opns
   ```

1. Create a service account `op-sa` for the operator in the operator’s namespace:
   ```shell
   $ kubectl create serviceaccount -n opns op-sa
   ```

#### 4.2 Install the WebLogic Kubernetes Operator

1. Set up Helm with the location of the WebLogic Operator Helm Chart:
   ```shell
   $ helm repo add weblogic-operator https://oracle.github.io/weblogic-kubernetes-operator/charts --force-update
   ```

1. Use Helm to install and start the operator:
   ```shell
   $ helm install weblogic-kubernetes-operator weblogic-operator/weblogic-operator \
     --namespace opns \
     --version 4.2.9 \
     --set serviceAccount=op-sa \
     --wait
   ```

#### 4.3 Verify the WebLogic Kubernetes Operator

1. Verify that the operator’s pod is running by listing the pods in the operator’s namespace. You should see one for the operator:
   ```shell
   $ kubectl get pods -n opns
   ```

1. Verify that the operator is up and running by viewing the operator pod's logs:
   ```shell
   $ kubectl logs -n opns -c weblogic-operator deployments/weblogic-operator
   ```

The WebLogic Kubernetes Operator v4.2.9 has been installed. Continue with the load balancer and Oracle SOA Suite domain setup.

### 5. Install the Traefik (ingress-based) load balancer

The WebLogic Kubernetes Operator supports these load balancers: Traefik, NGINX, and Apache. Samples are provided in the documentation.

This Quick Start demonstrates how to install the Traefik ingress controller to provide load balancing for an Oracle SOA Suite domain.

1. Create a namespace for Traefik:
    ```shell
    $ kubectl create namespace traefik
    ```

1. Set up Helm for 3rd party services:
   ```shell
   $ helm repo add traefik https://helm.traefik.io/traefik --force-update
   ```

1. Install the Traefik operator in the `traefik` namespace with the provided sample values:
   ```shell
   $ cd ${WORKDIR}
   $ helm install traefik traefik/traefik \
    --namespace traefik \
    --values charts/traefik/values.yaml \
    --set "kubernetes.namespaces={traefik}" \
    --set "service.type=NodePort" \
    --wait
   ```

### 6. Create and configure an Oracle SOA Suite domain
#### 6.1 Prepare for an Oracle SOA Suite domain

1. Create a namespace that can host Oracle SOA Suite domains. Label the namespace with `weblogic-operator=enabled` to manage the domain.

   ```
   $ kubectl create namespace soans
   $ kubectl label namespace soans weblogic-operator=enabled
   ```

1. Create Kubernetes secrets.

   a. Create a Kubernetes secret for the domain in the same Kubernetes namespace as the domain. In this example, the username is `weblogic`, the password is `Welcome1`, and the namespace is `soans`:

      ```shell
      $ cd ${WORKDIR}/create-weblogic-domain-credentials
      $ ./create-weblogic-credentials.sh \
           -u weblogic \
           -p Welcome1 \
           -n soans    \
           -d soainfra \
           -s soainfra-domain-credentials
      ```

   b. Create a Kubernetes secret for the RCU in the same Kubernetes namespace as the domain:

      * Schema user          : `SOA1`
      * Schema password      : `Oradoc_db1`
      * DB sys user password : `Oradoc_db1`
      * Domain name          : `soainfra`
      * Domain Namespace     : `soans`
      * Secret name          : `soainfra-rcu-credentials`

      ```shell
      $ cd ${WORKDIR}/create-rcu-credentials
      $ ./create-rcu-credentials.sh \
            -u SOA1 \
            -p Oradoc_db1 \
            -a sys \
            -q Oradoc_db1 \
            -d soainfra \
            -n soans \
            -s soainfra-rcu-credentials
      ```

1. Create the Kubernetes persistence volume and persistence volume claim.

   a. Create the Oracle SOA Suite domain home directory.
      Determine if a user already exists on your host system with `uid:gid` of `1000:0`:
      ```shell
      $ sudo getent passwd 1000
      ```

      If this command returns a username (which is the first field), you can skip the following `useradd` command. If not, create the oracle user with `useradd`:
      ```shell
      $ sudo useradd -u 1000 -g 0 oracle
      ```

      Create the directory that will be used for the Oracle SOA Suite domain home:
      ```shell
      $ sudo mkdir /scratch/k8s_dir
      $ sudo chown -R 1000:0 /scratch/k8s_dir
      ```

    b. The `create-pv-pvc-inputs.yaml` has the following values by default:

      * baseName: `domain`
      * domainUID: `soainfra`
      * namespace: `soans`
      * weblogicDomainStoragePath: `/scratch/k8s_dir`

      Review and update if any changes required.

      ```shell
      $ cd ${WORKDIR}/create-weblogic-domain-pv-pvc
      $ vim create-pv-pvc-inputs.yaml
      ```

    c. Run the `create-pv-pvc.sh` script to create the PV and PVC configuration files:
      ```shell
      $ cd ${WORKDIR}/create-weblogic-domain-pv-pvc
      $ ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output
      ```

    d. Create the PV and PVC using the configuration files created in the previous step:
      ```shell
      $ kubectl create -f  output/pv-pvcs/soainfra-domain-pv.yaml
      $ kubectl create -f  output/pv-pvcs/soainfra-domain-pvc.yaml
      ```

1. Install and configure the database for the Oracle SOA Suite domain.

   This step is required only when a standalone database is not already set up and you want to use the database in a container.

   {{% notice warning %}}
   The Oracle Database Docker images are supported only for non-production use. For more details, see My Oracle Support note: Oracle Support for Database Running on Docker (Doc ID 2216342.1). For production, it is suggested to use a standalone database. This example provides steps to create the database in a container.
   {{% /notice %}}

   a. Create a secret with your desired password (for example, `Oradoc_db1`):

      ```shell
      $ kubectl create secret generic oracle-db-secret --from-literal='password=Oradoc_db1'
      ```

   b. Create a database in a container:

      ```shell
      $ cd ${WORKDIR}/create-oracle-db-service
      $ ./start-db-service.sh -a oracle-db-secret -i  container-registry.oracle.com/database/enterprise:12.2.0.1-slim -p none
      ```

      Once the database is successfully created, you can use the database connection string `oracle-db.default.svc.cluster.local:1521/devpdb.k8s` as an `rcuDatabaseURL` parameter in the `create-domain-inputs.yaml` file.

   c. Create Oracle SOA Suite schemas for the domain type (for example, `soaosb`).

      Create a secret that contains the database's SYSDBA username and password.

      ```shell
      $ kubectl -n default create secret generic oracle-rcu-secret \
         --from-literal='sys_username=sys' \
         --from-literal='sys_password=Oradoc_db1' \
         --from-literal='password=Oradoc_db1'
      ```

      To install the Oracle SOA Suite schemas, run the `create-rcu-schema.sh` script with the following inputs:

      *  `-s <RCU PREFIX>`
      *  `-t <SOA domain type>`
      *  `-d <Oracle Database URL>`
      *  `-i <SOASuite image>`
      *  `-n <Namespace>`
      *  `-c <Name of credentials secret containing SYSDBA username and password and RCU schema owner password>`
      *  `-r <Comma-separated variables>`
      *  `-l <Timeout limit in seconds. (optional). (default: 300)>`

      For example:

      ```shell
      $ cd ${WORKDIR}/create-rcu-schema
      $ ./create-rcu-schema.sh \
	  -s SOA1 \
	  -t soaosb \
 	  -d oracle-db.default.svc.cluster.local:1521/devpdb.k8s \
	  -i container-registry.oracle.com/middleware/soasuite:12.2.1.4 \
	  -n default \
 	  -c oracle-rcu-secret \
	  -r SOA_PROFILE_TYPE=SMALL,HEALTHCARE_INTEGRATION=NO
      ```

Now the environment is ready to start the Oracle SOA Suite domain creation.


#### 6.2 Create an Oracle SOA Suite domain

1. The sample scripts for Oracle SOA Suite domain deployment are available at `${WORKDIR}/create-soa-domain/domain-home-on-pv`. You must edit `create-domain-inputs.yaml` (or a copy of it) to provide the details for your domain.

    Update `create-domain-inputs.yaml` with the following values for domain creation:

    *  `domainType`: `soaosb`
    *  `initialManagedServerReplicas`: `1`

    ```shell
    $ cd ${WORKDIR}/create-soa-domain/domain-home-on-pv/

    $ cp create-domain-inputs.yaml create-domain-inputs.yaml.orig

    $ sed -i -e "s:domainType\: soa:domainType\: soaosb:g" create-domain-inputs.yaml
    $ sed -i -e "s:initialManagedServerReplicas\: 2:initialManagedServerReplicas\: 1:g" create-domain-inputs.yaml
    $ sed -i -e "s:image\: soasuite\:12.2.1.4:image\: container-registry.oracle.com/middleware/soasuite\:12.2.1.4:g" create-domain-inputs.yaml
    ```

1. Run the `create-domain.sh` script to create a domain:
    ```shell
    $ cd ${WORKDIR}/create-soa-domain/domain-home-on-pv/
    $ ./create-domain.sh -i create-domain-inputs.yaml -o output
    ```

1. Create a Kubernetes domain object:

    Once the `create-domain.sh` is successful, it generates `output/weblogic-domains/soainfra/domain.yaml`, which you can use to create the Kubernetes resource domain to start the domain and servers:

    ```shell
    $ cd ${WORKDIR}/create-soa-domain/domain-home-on-pv
    $ kubectl create -f output/weblogic-domains/soainfra/domain.yaml
    ```

1. Verify that the Kubernetes domain object named `soainfra` is created:
    ```shell
    $ kubectl get domain -n soans
    NAME       AGE
    soainfra   3m18s
    ```

1. Once you create the domain, the *introspect pod* is created. This inspects the domain home and then starts the `soainfra-adminserver` pod. Once the `soainfra-adminserver` pod starts successfully, the Managed Server pods are started in parallel.
Watch the `soans` namespace for the status of domain creation:
    ```shell
    $ kubectl get pods -n soans -w
    ```

1. Verify that the Oracle SOA Suite domain server pods and services are created and in Ready state:
    ```shell
    $ kubectl get all -n soans
    ```

#### 6.3 Configure Traefik to access Oracle SOA Suite domain services

1. Configure Traefik to manage ingresses created in the Oracle SOA Suite domain namespace (`soans`):
    ```shell
    $ helm upgrade traefik traefik/traefik \
      --reuse-values \
      --namespace traefik \
      --set "kubernetes.namespaces={traefik,soans}" \
      --wait
    ```

1. Create an ingress for the domain in the domain namespace by using the sample Helm chart:
    ```shell
    $ cd ${WORKDIR}
    $ export LOADBALANCER_HOSTNAME=$(hostname -f)
    $ helm install soa-traefik-ingress charts/ingress-per-domain \
    --namespace soans \
    --values charts/ingress-per-domain/values.yaml \
    --set "traefik.hostname=${LOADBALANCER_HOSTNAME}" \
    --set domainType=soaosb
    ```

1. Verify the created ingress per domain details:
    ```shell
    $ kubectl describe ingress soainfra-traefik -n soans
    ```

#### 6.4 Verify that you can access the Oracle SOA Suite domain URL

1. Get the `LOADBALANCER_HOSTNAME` for your environment:
    ```shell
    $ export LOADBALANCER_HOSTNAME=$(hostname -f)
    ```
1. Verify the following URLs are available for Oracle SOA Suite domains of domain type `soaosb`:

    Credentials:

    *username*: `weblogic`
    *password*: `Welcome1`

    ```shell
    http://${LOADBALANCER_HOSTNAME}:30305/console
    http://${LOADBALANCER_HOSTNAME}:30305/em
    http://${LOADBALANCER_HOSTNAME}:30305/servicebus
    http://${LOADBALANCER_HOSTNAME}:30305/soa-infra
    http://${LOADBALANCER_HOSTNAME}:30305/soa/composer
    http://${LOADBALANCER_HOSTNAME}:30305/integration/worklistapp
    http://${LOADBALANCER_HOSTNAME}:30305/ess
    http://${LOADBALANCER_HOSTNAME}:30305/EssHealthCheck
    ```
