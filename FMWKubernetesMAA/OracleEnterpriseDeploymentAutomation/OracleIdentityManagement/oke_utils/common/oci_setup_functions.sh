#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script that will configure a bastion host and webtier hosts with the necessary
# configuration to be ready to run the kubectl, helm, and oci commands to setup an integrated 
# OUD-OAM-OIG kubernetes environment as described in the EDG.
#
# Dependencies: ../responsefile/oci-oke.rsp
#
# Usage: invoked automatically as needed, not directly
#
# Common Environment Variables
#

# Install the required OS packages on the bastion host
install_bastion_packages() {
   PACKAGE_LIST="python36-oci-cli libXrender libXtst xauth xterm nc openldap* git"
   for package in $PACKAGE_LIST
   do
     STEPNO=$((STEPNO+1))
     if [[ $STEPNO -gt $PROGRESS ]]; then
       print_msg begin "Installing the OS package '$package'..."
       cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"sudo yum install -y $package \""
       execute "$cmd"
       print_msg end
     fi
   done
}

# Enable X11 forading on the bastion host
bastion_enable_x11()
{
   IP=$1
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Enabling X11 Forwarding..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" opc@$BASTIONIP \"sudo sed -i  's/#X11UseLocalhost.*/X11UseLocalhost no/' /etc/ssh/sshd_config\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Restarting the sshd Daemon..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" opc@$BASTIONIP \"sudo systemctl restart sshd\""
     execute "$cmd"
     print_msg end
   fi
}

# Install the helm product on the bastion host
install_helm() {
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Downloading the Helm version $HELM_VER package..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"wget https://get.helm.sh/helm-v${HELM_VER}-linux-amd64.tar.gz\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Untaring Helm..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"tar -zxvf  helm-v${HELM_VER}-linux-amd64.tar.gz\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Installing Helm..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"sudo mv linux-amd64/helm  /bin/helm\""
     execute "$cmd"
     print_msg end
   fi
   
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then  
     print_msg begin "Cleaning up the Helm Installation Artifacts..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"rm -rf helm-v${HELM_VER}-linux-amd64.tar.gz linux-amd64\""
     execute "$cmd"
     print_msg end
   fi
}

# Install the OCI command line tool on the bastion host
install_oci_tools() {
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Copying the Local OCI Config Settings to the Bastion Node..."
     cmd="scp -r -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE ~/.oci opc@$BASTIONIP:."
     execute "$cmd"
     print_msg end
   fi
   
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Updating the OCI config File on the Bastion Node..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP sed -i 's/key_file=.*/key_file=\\\/home\\\/opc\\\/\.oci\\\/oci_api_key.pem/ /home/opc/.oci/config'"
     execute "$cmd"
     print_msg end
   fi
   
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Updating the bashrc File..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"echo \\\"source /usr/lib/python3.6/site-packages/oci_cli/bin/oci_autocomplete.sh\\\"  >> /home/opc/.bashrc\""
     execute "$cmd"
     print_msg end
   fi
}

# Install kubectl on the bastion host and configure it to connect to the OKE cluster 
setup_kubectl() {
   OKEID=$(cat $RESOURCE_OCID_FILE | grep $OKE_CLUSTER_DISPLAY_NAME | cut -d: -f2)
   
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Creating the kubeconfig Directory..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"mkdir -p /home/opc/.kube\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Creating the kubeconfig File..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"oci ce cluster create-kubeconfig --cluster-id $OKEID --file /home/opc/.kube/config --region $REGION --token-version 2.0.0 --kube-endpoint PRIVATE_ENDPOINT > /dev/null 2>&1\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Modifying the bashrc File..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"echo \"export KUBECONFIG=/home/opc/.kube/config\" >> .bashrc\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Downloading kubectl..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"curl -LO https://storage.googleapis.com/kubernetes-release/release/$OKE_CLUSTER_VERSION/bin/linux/amd64/kubectl\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Moving kubectl into Place..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"sudo mv kubectl  /bin/\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Setting kubectl File Permissions..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"sudo chmod +x /bin/kubectl\""
     execute "$cmd"
     print_msg end
   fi
}

# Mount the NFS file systems for all of the persistent volumes on the bastion host
mount_bastion_nfs() {
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     ST=`date +%s`
     print_msg begin "Building the Shell Script to Mount the NFS Filesystems on the Bastion Host..."
     okemt=$(oci fs mount-target list --region $REGION --compartment-id $COMPARTMENT_ID --display-name $OKE_MOUNT_TARGET_DISPLAY_NAME \
        --availability-domain ${!OKE_MOUNT_TARGET_AD} --query 'data[0]."private-ip-ids"' | jq -r '.[]')
     okeip=$(oci network private-ip get --region $REGION --private-ip-id $okemt | jq -r '.data."ip-address"')

     echo "# $BASTION_INSTANCE_DISPLAY_NAME node" > $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_OAALOGPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_OAACREDPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_OAACONFIGPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_OAAVAULTPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_WORKPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_DINGPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_OIRIPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_OUDSMPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_OUDCONFIGPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_OUDPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_OIGPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mkdir -p $FS_OAMPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_OAALOGPV_NFS_PATH $FS_OAALOGPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_OAACREDPV_NFS_PATH $FS_OAACREDPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_OAACONFIGPV_NFS_PATH $FS_OAACONFIGPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_OAAVAULTPV_NFS_PATH $FS_OAAVAULTPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_WORKPV_NFS_PATH $FS_WORKPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_DINGPV_NFS_PATH $FS_DINGPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_OIRIPV_NFS_PATH $FS_OIRIPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_OUDSMPV_NFS_PATH $FS_OUDSMPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_OUDCONFIGPV_NFS_PATH $FS_OUDCONFIGPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_OUDPV_NFS_PATH $FS_OUDPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_OIGPV_NFS_PATH $FS_OIGPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "echo \"$okeip:$FS_OAMPV_NFS_PATH $FS_OAMPV_LOCAL_MOUNTPOINT nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/bastion_mounts.sh
     echo "sudo mount -a" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OAALOGPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OAACREDPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OAACONFIGPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OAAVAULTPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_WORKPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_DINGPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OIRIPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OUDSMPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OUDCONFIGPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OUDVAULTPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OUDPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OIGPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     echo  "sudo chmod 777 $FS_OAMPV_LOCAL_MOUNTPOINT" >> $OUTDIR/bastion_mounts.sh
     ET=`date +%s`
     print_msg end
     PROGRESS=$((PROGRESS+1))
     echo $PROGRESS > $LOGDIR/progressfile
   fi
   
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Copying the Bastion Mount Configuration File..."
     cmd="scp -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE $OUTDIR/bastion_mounts.sh opc@$BASTIONIP:."
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Setting the Execute Permission..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP chmod 700 ./bastion_mounts.sh "
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Creating and Mounting the Bastion Filesystems..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP ./bastion_mounts.sh"
     execute "$cmd"
     print_msg end
   fi
   
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Cleaning up the Bastion Mount Configuration File..."
     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP rm bastion_mounts.sh"
     execute "$cmd"
     print_msg end
   fi
}

# Update the /etc/hosts file with the IP address of the public load balancer
update_bastion_hosts_file() {
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Updating the /etc/hosts File..."
     LBRIP=$(oci lb load-balancer list --region $REGION -c $COMPARTMENT_ID  --display-name $PUBLIC_LBR_DISPLAY_NAME --query 'data[0]."ip-addresses"[0]."ip-address"' --raw-output)
     if [[ "$?" != "0" ]]; then
       print_msg  screen "Failed to obtain the IP address for '$PUBLIC_LBR_DISPLAY_NAME'"
       exit 1
     fi

     cmd="ssh -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE opc@$BASTIONIP \"echo \\\"$LBRIP $PUBLIC_LBR_LOGIN_HOSTNAME $PUBLIC_LBR_PROV_HOSTNAME $PUBLIC_LBR_IADADMIN_HOSTNAME $PUBLIC_LBR_IGDADMIN_HOSTNAME\\\" | sudo tee -a /etc/hosts\""
     execute "$cmd"
     print_msg end
   fi
}

# Call individual functions to setup the bastion host 
setupBastion() {
  get_bastion_ip
  install_bastion_packages
  bastion_enable_x11
  install_helm
  install_oci_tools
  setup_kubectl
  mount_bastion_nfs
  update_bastion_hosts_file
}

# Install the required OS packages on the webhosts
install_webhost_packages() {
   IP=$1
   PACKAGE_LIST="libXrender libXtst xauth xterm nc libaio-devel* compat-libstdc++-* compat-libcap* gcc-c++-* ksh* libnsl* "
   for package in $PACKAGE_LIST
   do
     STEPNO=$((STEPNO+1))
     if [[ $STEPNO -gt $PROGRESS ]]; then
       print_msg begin "Installing the OS package '$package' on Webhost $IP..."
       cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo yum install -y $package \""
       execute "$cmd"
       print_msg end
     fi
   done
}

# Enable X11 forwarding on the webhosts
webhost_enable_x11()
{
   IP=$1
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Enabling X11 Forwarding on Webhost $IP..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo sed -i  's/#X11UseLocalhost.*/X11UseLocalhost no/' /etc/ssh/sshd_config\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Restarting the sshd Daemon on Webhost $IP..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo systemctl restart sshd\""
     execute "$cmd"
     print_msg end
   fi
}

# Open the firewall ports for the OHS server
open_firewall() {
   IP=$1
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Opening the Firewall Port $OHS_NON_SSL_PORT on Webhost $IP..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo firewall-cmd --permanent --add-port=$OHS_NON_SSL_PORT/tcp\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Restarting the Firewall on Webhost $IP..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo systemctl restart firewalld\""
     execute "$cmd"
     print_msg end
   fi
}

# Mount the binary and config data NFS mounts on the webhost
mount_webtier_nfs() {
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     ST=`date +%s`
     print_msg begin "Building the Shell Scripts to Mount the NFS Filesystems on the Webhosts..."
     wt1mt=$(oci fs mount-target list --region $REGION --compartment-id $COMPARTMENT_ID --display-name $WEBHOST1_MOUNT_TARGET_DISPLAY_NAME \
        --availability-domain ${!WEBHOST1_AD} --query 'data[0]."private-ip-ids"' | jq -r '.[]')
     wt1ip=$(oci network private-ip get --region $REGION --private-ip-id $wt1mt | jq -r '.data."ip-address"')
     wt2mt=$(oci fs mount-target list --region $REGION --compartment-id $COMPARTMENT_ID --display-name $WEBHOST2_MOUNT_TARGET_DISPLAY_NAME \
        --availability-domain ${!WEBHOST2_AD} --query 'data[0]."private-ip-ids"' | jq -r '.[]')
     wt2ip=$(oci network private-ip get --region $REGION --private-ip-id $wt2mt | jq -r '.data."ip-address"')

     echo "# $WEBHOST1_DISPLAY_NAME" > $OUTDIR/webhost1_mounts.sh
     echo "sudo mkdir -p $WEBHOST1_PRODUCTS_PATH" >> $OUTDIR/webhost1_mounts.sh
     echo "sudo mkdir -p $WEBHOST1_CONFIG_PATH" >> $OUTDIR/webhost1_mounts.sh
     echo "echo \"$wt1ip:$FS_WEBBINARIES1_PATH $WEBHOST1_PRODUCTS_PATH nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/webhost1_mounts.sh
     echo "echo \"$wt1ip:$FS_WEBCONFIG1_PATH $WEBHOST1_CONFIG_PATH nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab"  >> $OUTDIR/webhost1_mounts.sh
     echo "sudo mount -a" >> $OUTDIR/webhost1_mounts.sh
     echo "sudo chmod 777 $WEBHOST1_PRODUCTS_PATH" >> $OUTDIR/webhost1_mounts.sh
     echo "sudo chmod 777 $WEBHOST1_CONFIG_PATH" >> $OUTDIR/webhost1_mounts.sh

     echo "# $WEBHOST2_DISPLAY_NAME" > $OUTDIR/webhost2_mounts.sh
     echo "sudo mkdir -p $WEBHOST2_PRODUCTS_PATH" >> $OUTDIR/webhost2_mounts.sh
     echo "sudo mkdir -p $WEBHOST2_CONFIG_PATH" >> $OUTDIR/webhost2_mounts.sh
     echo "echo \"$wt2ip:$FS_WEBBINARIES2_PATH $WEBHOST2_PRODUCTS_PATH nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/webhost2_mounts.sh
     echo "echo \"$wt2ip:$FS_WEBCONFIG2_PATH $WEBHOST2_CONFIG_PATH nfs auto,rw,bg,hard,nointr,tcp,vers=3,timeo=300,rsize=32768,wsize=32768\" | sudo tee -a /etc/fstab" >> $OUTDIR/webhost2_mounts.sh
     echo "sudo mount -a" >> $OUTDIR/webhost2_mounts.sh
     echo "sudo chmod 777 $WEBHOST2_PRODUCTS_PATH" >> $OUTDIR/webhost2_mounts.sh
     echo "sudo chmod 777 $WEBHOST2_CONFIG_PATH" >> $OUTDIR/webhost2_mounts.sh
     ET=`date +%s`
     print_msg end
     PROGRESS=$((PROGRESS+1))
     echo $PROGRESS > $LOGDIR/progressfile
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Copying the Webhost1 Mount Configuration File..."
     cmd="scp -q -i $SSH_ID_KEYFILE -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE -W %h:%p opc@$BASTIONIP' $OUTDIR/webhost1_mounts.sh opc@$WEBHOST1IP:."
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Setting the Execute Permission..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$WEBHOST1IP chmod 700 ./webhost1_mounts.sh"
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Creating and Mounting the Webhost1 Filesystems..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$WEBHOST1IP ./webhost1_mounts.sh"
     execute "$cmd"
     print_msg end
   fi
   
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Cleaning up the Webhost1 Mount Configuration File..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$WEBHOST1IP rm ./webhost1_mounts.sh"
     execute "$cmd"
     print_msg end
   fi
   
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Copying the Webhost2 Mount Configuration File..."
     cmd="scp -q -i $SSH_ID_KEYFILE -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE -W %h:%p opc@$BASTIONIP' $OUTDIR/webhost2_mounts.sh opc@$WEBHOST2IP:."
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Setting the Execute Permission..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$WEBHOST2IP chmod 700 ./webhost2_mounts.sh"
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Creating and Mounting the Webhost2 Filesystems..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$WEBHOST2IP ./webhost2_mounts.sh"
     execute "$cmd"
     print_msg end
   fi
   
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Cleaning up the Webhost2 Mount Configuration File..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$WEBHOST2IP rm ./webhost2_mounts.sh"
     execute "$cmd"
     print_msg end
   fi
}

# Update the /etc/hosts file with the public load balancer IP address
update_webhosts_hosts_file() {
   LBRIP=$(oci lb load-balancer list -c $COMPARTMENT_ID --region $REGION --display-name $INT_LBR_DISPLAY_NAME --query 'data[0]."ip-addresses"[0]."ip-address"' --raw-output)
   if [[ "$?" != "0" ]]; then
      print_msg  screen "Failed to obtain the IP address for '$INT_LBR_DISPLAY_NAME'"
      exit 1
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin  "Updating the /etc/hosts File on Webhost1..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$WEBHOST1IP \"echo \\\"$LBRIP  $PUBLIC_LBR_LOGIN_HOSTNAME \\\" | sudo tee -a /etc/hosts\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Updating the /etc/hosts File on Webhost2..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$WEBHOST2IP \"echo \\\"$LBRIP  $PUBLIC_LBR_LOGIN_HOSTNAME \\\" | sudo tee -a /etc/hosts\""
     execute "$cmd"
     print_msg end
   fi
}

# Setup a user other than opc on the webhost
setup_users() {
   IP=$1
   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Creating the OS User $OHS_SOFTWARE_OWNER on Webhost $IP..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo adduser -u 1001 $OHS_SOFTWARE_OWNER\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Creating the OS Group $OHS_SOFTWARE_GROUP on Webhost $IP..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo groupadd -g 1002 $OHS_SOFTWARE_GROUP\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Assigning the $OHS_SOFTWARE_OWNER User to Group $OHS_SOFTWARE_GROUP on Webhost $IP..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo usermod -a -G $OHS_SOFTWARE_GROUP $OHS_SOFTWARE_OWNER\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Updating the User $OHS_SOFTWARE_OWNER with Group $OHS_SOFTWARE_GROUP on Webhost $IP..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo usermod -g $OHS_SOFTWARE_GROUP $OHS_SOFTWARE_OWNER\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Copying authorized_keys file to the User $OHS_SOFTWARE_OWNER ..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo cp -r /home/opc/.ssh /home/$OHS_SOFTWARE_OWNER\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Setting ownership of authorized_keys file to the User $OHS_SOFTWARE_OWNER ..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo chown -R $OHS_SOFTWARE_OWNER:$OHS_SOFTWARE_GROUP /home/$OHS_SOFTWARE_OWNER/.ssh\""
     execute "$cmd"
     print_msg end
   fi

   STEPNO=$((STEPNO+1))
   if [[ $STEPNO -gt $PROGRESS ]]; then
     print_msg begin "Granting SUDO to the Group $OHS_SOFTWARE_GROUP ..."
     cmd="ssh -q -i $SSH_ID_KEYFILE -t -o \"StrictHostKeyChecking no\" -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$IP \"sudo sed -i \\\"/# %wheel/a%$OHS_SOFTWARE_GROUP  ALL=(ALL)       NOPASSWD: ALL\\\" /etc/sudoers\""
     execute "$cmd"
     print_msg end
   fi
}

# Call the individal functions required to setup the webhost instances
setupWebHosts() {
  get_bastion_ip
  get_webhost_ip
  install_webhost_packages $WEBHOST1IP
  install_webhost_packages $WEBHOST2IP
  webhost_enable_x11 $WEBHOST1IP
  webhost_enable_x11 $WEBHOST2IP
  open_firewall $WEBHOST1IP
  open_firewall $WEBHOST2IP
  mount_webtier_nfs
  update_webhosts_hosts_file 
  if [[  "$OHS_SOFTWARE_OWNER" != "opc" ]]; then
      setup_users $WEBHOST1IP
      setup_users $WEBHOST2IP
  fi
}

# Poll the database waiting for it to reach an AVAILABLE state for a max of 3 hours
waitForDatabase() {
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Waiting for the '${DB_NAME}_${DB_SUFFIX}' Database to Become Available (waiting up to 3 hours)..."
    ocid=$(cat $RESOURCE_OCID_FILE | grep $DB_DISPLAY_NAME | cut -d: -f2)
    dbCnt=0
    dbOutput=$(oci db system get --region $REGION --db-system-id $ocid --query 'data."lifecycle-state"' --raw-output)
    while [[ ! "$dbOutput" =~ "AVAILABLE" ]] || [[ "$dbCnt" -ge 36 ]]; do
      now=$(date +"%a %d %b %Y %T")
      echo -en "\n      DB availability check at $now (sleeping 5 minutes)..."
      sleep 300
      dbOutput=$(oci db system get --region $REGION --db-system-id $ocid --query 'data."lifecycle-state"' --raw-output)
      ((dbCnt++))
    done
    print_msg end
    PROGRESS=$((PROGRESS+1))
    echo $PROGRESS > $LOGDIR/progressfile
  fi
}

# Create a pluggable database with the given name
createPluggableDB() {
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    if [[ ! "$DBPDBS" =~ "$1" ]]; then
      print_msg begin "Creating the '$1' Pluggable Database (and waiting for it to become available)..."
      ocid=$(cat $RESOURCE_OCID_FILE | grep $DB_DISPLAY_NAME | cut -d: -f2)
      cdb=$(oci db database list --region $REGION --compartment-id $COMPARTMENT_ID --db-system-id $ocid --query 'data[0].id' --raw-output)
      cmd="oci db pluggable-database create --region $REGION --container-database-id $cdb --pdb-name $1 \
          --pdb-admin-password $DB_PWD --tde-wallet-password $DB_PWD --wait-for-state AVAILABLE --wait-for-state FAILED"
      execute "$cmd"
      print_msg end
    else
      ST=`date +%s`
      print_msg begin "Skipping Creation of the Pluggable Database '$1' as it Already Exists..."
      ET=`date +%s`
      print_msg end
      PROGRESS=$((PROGRESS+1))
      echo $PROGRESS > $LOGDIR/progressfile
    fi
  fi
}

# Create the srvctl serivce for the PDBs
createService() {
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    if [[ ! "$DBSERVICES" =~ "$2" ]]; then
      print_msg begin "Creating the srvctl Service for the '$1' Pluggable Database..."    
      cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP 'srvctl add service -db ${DB_NAME}_${DB_SUFFIX} -service $2 -pdb $1 -preferred $DBINSTANCES'"
      execute "$cmd"
      print_msg end
    else
      ST=`date +%s`
      print_msg begin "Cannot create the Service '$1' as it Already Exists..."
      ET=`date +%s`
      print_msg end
      PROGRESS=$((PROGRESS+1))
      echo $PROGRESS > $LOGDIR/progressfile
    fi
  fi
}

# Start the PDB service
startService() {
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
      print_msg begin "Starting the '$1' Service..."
      cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP 'srvctl start service -db ${DB_NAME}_${DB_SUFFIX} -s $1'"
      execute "$cmd"
      print_msg end
  fi
}

# Restart the database via srvctl
restartDatabase() {
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Stopping the '${DB_NAME}_${DB_SUFFIX}' Database..."
    cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP 'srvctl stop database -d ${DB_NAME}_${DB_SUFFIX}'"
    execute "$cmd"
    print_msg end
  fi
  
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Starting the '${DB_NAME}_${DB_SUFFIX}' Database..."
    cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP 'srvctl start database -d ${DB_NAME}_${DB_SUFFIX}'"
    execute "$cmd"
    print_msg end
  fi  
}

# Copy opc's authorized_keys file the the oracle user on the DB node
copy_authorized_keys() {
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Setting Up Passwordless Authentication for the OS 'oracle' User..."
    cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' opc@$DBIP 'sudo cp /home/opc/.ssh/authorized_keys /home/oracle/.ssh/authorized_keys'"
    execute "$cmd"
    print_msg end
  fi
}

# Run dbca to install JSERVER and ORACLE_TEXT in the container database
run_dbca() {
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Running 'dbca' to Install the JServer and Oracle Text Options..."
    cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP 'dbca -silent -configureDatabase -sourceDB ${DB_NAME}_${DB_SUFFIX} -addDBOption JSERVER,ORACLE_TEXT'" 
    execute "$cmd"
    print_msg end
  fi
}

# Set the database initialization parameters
db_tuning() {
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    ST=`date +%s`
    print_msg begin "Creating the DB Tuning Parameters Script..."
    DB_MEMORY_CONFIG=$(tr '[:upper:]' '[:lower:]' <<< $DB_MEMORY_CONFIG)
    echo "#!/bin/bash" > $OUTDIR/db-tuning.sh
    echo "sqlplus / as sysdba << EOF" >> $OUTDIR/db-tuning.sh
    echo "alter system set aq_tm_processes=10 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set dml_locks=200 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set job_queue_processes=12 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set open_cursors=1600 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set session_max_open_files=50 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set sessions=5000 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set processes=5000 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set pga_aggregate_limit=25000M;" >> $OUTDIR/db-tuning.sh
    echo "alter system set session_cached_cursors=1000 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set db_keep_cache_size=800 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set cursor_sharing=FORCE scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set query_rewrite_integrity=TRUSTED scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set query_rewrite_enabled=TRUE scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set max_dispatchers=0 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set max_shared_servers=0 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set disk_asynch_io=FALSE scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set db_securefile=ALWAYS scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set plsql_code_type=NATIVE scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set \"_active_session_legacy_behavior\"=TRUE scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set open_cursors=3000 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set open_links=20 scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set nls_sort=BINARY scope=spfile;" >> $OUTDIR/db-tuning.sh
    echo "alter system set shared_servers=0 scope=spfile;" >> $OUTDIR/db-tuning.sh
    if [[ "$DB_MEMORY_CONFIG" =~ "small" ]]; then
      echo "alter system set sga_target=28G scope=spfile;" >> $OUTDIR/db-tuning.sh
      echo "alter system set pga_aggregate_target=7G scope=spfile;" >> $OUTDIR/db-tuning.sh
      echo "alter system set sga_max_size=28G scope=spfile;" >> $OUTDIR/db-tuning.sh
    elif [[ "$DB_MEMORY_CONFIG" =~ "medium" ]]; then
      echo "alter system set sga_target=58G scope=spfile;" >> $OUTDIR/db-tuning.sh
      echo "alter system set pga_aggregate_target=14G scope=spfile;" >> $OUTDIR/db-tuning.sh
      echo "alter system set sga_max_size=58G scope=spfile;" >> $OUTDIR/db-tuning.sh
    elif [[ "$DB_MEMORY_CONFIG" =~ "large" ]]; then
      echo "alter system set sga_target=118G scope=spfile;" >> $OUTDIR/db-tuning.sh
      echo "alter system set pga_aggregate_target=29G scope=spfile;" >> $OUTDIR/db-tuning.sh
      echo "alter system set sga_max_size=188G scope=spfile;" >> $OUTDIR/db-tuning.sh
    else
      echo "alter system set sga_target=5G scope=spfile;" >> $OUTDIR/db-tuning.sh
      echo "alter system set pga_aggregate_target=2G scope=spfile;" >> $OUTDIR/db-tuning.sh
      echo "alter system set sga_max_size=5G scope=spfile;" >> $OUTDIR/db-tuning.sh
    fi
    echo "exit" >> $OUTDIR/db-tuning.sh
    echo "EOF" >> $OUTDIR/db-tuning.sh
    ET=`date +%s`
    print_msg end
    chmod 755 $OUTDIR/db-tuning.sh
    PROGRESS=$((PROGRESS+1))
    echo $PROGRESS > $LOGDIR/progressfile
  fi
  
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Copy the 'db-tuning.sh' Script to the DB node $DBIP..."
    cmd="scp -q -i $SSH_ID_KEYFILE -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' $OUTDIR/db-tuning.sh oracle@$DBIP:."
    execute "$cmd"
    print_msg end
  fi
    
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Execute the 'db-tuning.sh' script on the DB node $DBIP..."
    cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP '/home/oracle/db-tuning.sh'"
    execute "$cmd"
    print_msg end
  fi
    
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then  
    print_msg begin "Cleaning up the 'db-tuning.sh' Script on the DB node $DBIP..."  
    cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP 'rm /home/oracle/db-tuning.sh'"
    execute "$cmd"
    print_msg end
  fi
}

# Get a list of the db instance names, services and PDBs for the RAC db
get_db_instance_pdbs_services() {
  cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP srvctl \"status database -d ${DB_NAME}_${DB_SUFFIX} | cut -d' ' -f2 | paste -sd',' | tr -d '\n'\""
  output=$(eval $cmd 2>&1)
  DBINSTANCES=$output
 
  cmd="oci db pluggable-database list --region $REGION --compartment-id $COMPARTMENT_ID --all --lifecycle-state AVAILABLE --query 'data[*].\"pdb-name\"'"
  output=$(eval $cmd 2>&1)
  DBPDBS=$output

  cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP 'srvctl status service -d ${DB_NAME}_${DB_SUFFIX}'"
  output=$(eval $cmd 2>&1)
  DBSERVICES=$output
}

# Create the XA views in the OIG pdb
createOIGXAviews() {
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the XA Views Script..."
    ST=`date +%s`
    echo "#!/bin/bash" > $OUTDIR/db-xaviews.sh
    echo "export ORACLE_PDB_SID=$1" >> $OUTDIR/db-xaviews.sh
    echo "sqlplus / as sysdba << EOF" >> $OUTDIR/db-xaviews.sh
    echo "show con_name" >> $OUTDIR/db-xaviews.sh
    echo "@?/rdbms/admin/xaview.sql" >> $OUTDIR/db-xaviews.sh
    echo "exit" >> $OUTDIR/db-xaviews.sh
    echo "EOF" >> $OUTDIR/db-xaviews.sh
    ET=`date +%s`
    print_msg end
    chmod 755 $OUTDIR/db-xaviews.sh
    PROGRESS=$((PROGRESS+1))
    echo $PROGRESS > $LOGDIR/progressfile
  fi
    
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Copy the 'db-xaviews.sh' Script to the DB node $DBIP..."
    cmd="scp -q -i $SSH_ID_KEYFILE -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' $OUTDIR/db-xaviews.sh oracle@$DBIP:."
    execute "$cmd"
    print_msg end
  fi
  
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Execute the 'db-xaviews.sh' Script in the '$OIG_PDB_NAME' PDB..."
    cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP '/home/oracle/db-xaviews.sh'"
    execute "$cmd"
    print_msg end
  fi
  
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Cleaning up the 'db-xaviews.sh' Script on the DB node $DBIP..."
    cmd="ssh -q -i $SSH_ID_KEYFILE -t -o 'StrictHostKeyChecking no' -o ProxyCommand='ssh -q -i $SSH_ID_KEYFILE opc@$BASTIONIP -W %h:%p' oracle@$DBIP 'rm /home/oracle/db-xaviews.sh'"
    execute "$cmd"
    print_msg end
  fi
}

# Call the individual functions required to configure the database
setupDatabase() {
  waitForDatabase
  if [[ "$dbCnt" -ge 36 ]]; then
    echo "Database creation failed or timed-out and cannot proceed with automatic database tuning/configuration."
  fi
  get_bastion_ip
  get_database_ip
  copy_authorized_keys
  get_db_instance_pdbs_services
  run_dbca
  db_tuning
CREATE_OAM_PDB=$(tr '[:upper:]' '[:lower:]' <<< $CREATE_OAM_PDB)
CREATE_OIG_PDB=$(tr '[:upper:]' '[:lower:]' <<< $CREATE_OIG_PDB)
CREATE_OAA_PDB=$(tr '[:upper:]' '[:lower:]' <<< $CREATE_OAA_PDB)
CREATE_OIRI_PDB=$(tr '[:upper:]' '[:lower:]' <<< $CREATE_OIRI_PDB)
  if [[ "$CREATE_OAM_PDB" ==  "true" ]]; then
    createPluggableDB $OAM_PDB_NAME
    createService $OAM_PDB_NAME $OAM_SERVICE_NAME
    startService $OAM_SERVICE_NAME
  fi
  if [[ "$CREATE_OIG_PDB" ==  "true" ]]; then
    createPluggableDB $OIG_PDB_NAME
    createService $OIG_PDB_NAME $OIG_SERVICE_NAME
    startService $OIG_SERVICE_NAME
    createOIGXAviews $OIG_PDB_NAME
  fi
  if [[ "$CREATE_OAA_PDB" ==  "true" ]]; then
    createPluggableDB $OAA_PDB_NAME
    createService $OAA_PDB_NAME $OAA_SERVICE_NAME
    startService $OAA_SERVICE_NAME
  fi
  if [[ "$CREATE_OIRI_PDB" ==  "true" ]]; then
    createPluggableDB $OIRI_PDB_NAME
    createService $OIRI_PDB_NAME $OIRI_SERVICE_NAME
    startService $OIRI_SERVICE_NAME
  fi
  restartDatabase
}
