#!/usr/bin/env bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Utility functions that are shared by multiple scripts
#

#
# Function to exit and print an error message
# $1 - text of message
fail() {
  printError $*
  exit 1
}

# Function to print an error message
printError() {
  echo [ERROR] $*
}


# Function to create scripts for Docker and Kubernetes setup
createSetupScripts() {
  host=$1
  setupScriptsDir="/tmp/setupscripts/${host}"
  mkdir -p ${setupScriptsDir}
  # Kubernetes repo
  cat <<EOF > ${setupScriptsDir}/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

  # sysctl params required by setup, params persist across reboots
  cat <<EOF >  ${setupScriptsDir}/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

if [[ "$proxy" != "false" ]]; then
  cat <<EOF > ${setupScriptsDir}/proxy.env
export http_proxy=$http_proxy
export https_proxy=$https_proxy
export no_proxy=$no_proxy
export HTTP_PROXY=$http_proxy
export HTTPS_PROXY=$https_proxy
export NO_PROXY=$no_proxy
EOF
  cat <<EOF > ${setupScriptsDir}/http-proxy.conf
[Service]
Environment="HTTP_PROXY=$http_proxy"
Environment="HTTPS_PROXY=$https_proxy"
Environment="NO_PROXY=$no_proxy"
EOF
fi
  cat <<EOF > ${setupScriptsDir}/os_configure_$host.sh
if [[ -f /tmp/maa/proxy.env ]]; then
  source /tmp/maa/proxy.env
fi
echo "Configuring OS..."
sysctl net.ipv4.conf.${vnic}.forwarding=1
sysctl net.ipv4.conf.lo.forwarding=1
sysctl net.ipv4.ip_nonlocal_bind=1
'net.ipv4.conf.${vnic}.forwarding=1' | sudo tee -a /etc/sysctl.conf
"net.ipv4.conf.lo.forwarding=1" | sudo tee -a /etc/sysctl.conf
"net.ipv4.ip_nonlocal_bind=1" | sudo tee -a /etc/sysctl.conf
iptables -P FORWARD ACCEPT
firewall-cmd --add-masquerade --permanent
firewall-cmd --add-port=2379-2380/tcp --permanent
firewall-cmd --add-port=10250/tcp --permanent
firewall-cmd --add-port=10251/tcp --permanent
firewall-cmd --add-port=10252/tcp --permanent
firewall-cmd --add-port=10255/tcp --permanent
firewall-cmd --add-port=8285/udp --permanent
firewall-cmd --add-port=8472/udp --permanent
firewall-cmd --add-port=6443/tcp --permanent
firewall-cmd --add-port=10248/tcp --permanent
firewall-cmd --add-port=8001/tcp --permanent
systemctl restart firewalld
yum install -y nc
echo "Checking connectivity to front end"
nc -w 5 -z -v $LBR_HN $LBR_PORT
swapoff -a
echo "If there are swap entries in /etc/hosts, please comment those out or k8 will fail after a reboot!!!"
echo "OS configured"
EOF

  cat <<EOF > ${setupScriptsDir}/docker_install_$host.sh
if [[ -f /tmp/maa/proxy.env ]]; then
  source /tmp/maa/proxy.env
fi
echo "Installing and starting docker..."
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sed -i 's/\$releasever/7/g'  /etc/yum.repos.d/docker-ce.repo
yum-config-manager --enable ol7_addons
echo "Sleeping for possible break...."
sleep 30
# In latest releases dockerce has replace docker-engine installer. Refer to:
# https://docs.docker.com/engine/install/centos/
yum install -y docker-ce-${docker_version} docker-ce-cli-${docker_version} containerd.io
yum install -y docker-engine
sleep 5
/sbin/usermod -a -G docker $user
# Storage for docker, needs to be block volume. Issues with vfs and NFS prevent its use
# it is expected that the appropriate /etc/fstab entry already exists for the block volume (it is specific to each node)
mount $docker_dir
mkdir -p ${docker_dir}/${host}
chown ${user}:${user} ${docker_dir}/${host}
EOF

  cat <<EOF > ${setupScriptsDir}/daemon.json
{
   "group": "docker",
   "storage-driver": "overlay2",
   "data-root": "${docker_dir}/${host}"
}
EOF

  cat <<EOF > ${setupScriptsDir}/docker_configure_$host.sh
if [[ -f /tmp/maa/proxy.env ]]; then
  source /tmp/maa/proxy.env
fi
mkdir -p /etc/docker/
cp /tmp/maa/daemon.json /etc/docker/
if [[ -f /tmp/maa/http-proxy.conf ]]; then
  mkdir -p /etc/systemd/system/docker.service.d
  cp /tmp/maa/http-proxy.conf /etc/systemd/system/docker.service.d/
fi
systemctl daemon-reload
systemctl enable docker
systemctl start docker
systemctl restart docker
systemctl status docker
echo "Sleeping for possible break..."
sleep 30
sysctl net.ipv4.conf.docker0.forwarding=1
systemctl daemon-reload
systemctl restart docker
echo "Docker restarted."
EOF    

  cat <<EOF > ${setupScriptsDir}/k8s_install_$host.sh  
if [[ -f /tmp/maa/proxy.env ]]; then
  source /tmp/maa/proxy.env
fi
echo "Installing k8...."
cp /tmp/maa/kubernetes.repo /etc/yum.repos.d/
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
yum install -y kubelet-$k8_version kubeadm-$k8_version kubectl-$k8_version --disableexcludes=kubernetes
cgroup=\`docker info 2>&1 | egrep Cgroup | awk '{print \$NF}'\`
[ "\$cgroup" == "" ] && echo "cgroup not detected!" && exit 1
cp /etc/sysconfig/kubelet /etc/sysconfig/kubelet.bkp
sed -i "s/^KUBELET_EXTRA_ARGS=.*/KUBELET_EXTRA_ARGS='--fail-swap-on=false --cgroup-driver=\${cgroup}'/" /etc/sysconfig/kubelet
cat /etc/sysconfig/kubelet
systemctl enable --now kubelet
cp /tmp/maa/k8s.conf /etc/sysctl.d/
sysctl --system
systemctl daemon-reload
systemctl restart kubelet
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -O /tmp/maa/kube-flannel.yml
wget https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz -O /tmp/maa/helm-v${helm_version}-linux-amd64.tar.gz
echo "kube* packages installed and started."
EOF
}
