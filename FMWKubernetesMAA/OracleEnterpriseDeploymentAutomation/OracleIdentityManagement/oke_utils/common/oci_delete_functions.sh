#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of the functions needed to delete all of the infrastructure components that were
# created by the provision_oke.sh script. These function are used by the delete_oke.sh script
#
# Dependencies: 
#
# Usage: invoked automatically as needed, not directly
#
# Common Environment Variables
#

# Delete the bastion instance and its associated resources
deleteBastion() {
  # Delete the bastion instance
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$BASTION_INSTANCE_DISPLAY_NAME' Instance..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $BASTION_INSTANCE_DISPLAY_NAME | cut -d: -f2)
  if [[ "$ocid" =~ "ocid"  ]]; then
    cmd="oci compute instance terminate --region $REGION --instance-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  okeSubnetId=$(cat $RESOURCE_OCID_FILE | grep $OKE_NODE_SUBNET_DISPLAY_NAME | cut -d: -f2) 

  # Delete the bastion setup security list
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$BASTION_SETUP_SECLIST_DISPLAY_NAME' from the Kubernetes Node Subnet..."
  sl=$(oci network subnet get --region $REGION --subnet-id $okeSubnetId --query 'data."security-list-ids"' 2>/dev/null)
  sl=$(echo $sl | tr '\n' ' ')
  bssl=$(cat $RESOURCE_OCID_FILE | grep $BASTION_SETUP_SECLIST_DISPLAY_NAME | cut -d: -f2)
  if [[ "$sl" =~ "$bssl" ]]; then
    sl="'${sl/\"$bssl\"/}'"
    sl=$(sed 's/, *\]/ \]/g' <<< $sl)
    sl=$(sed 's/, *,/, /g' <<< $sl)
    sl=$(sed 's/\[ *,/\[ /g' <<< $sl)
    cmd="oci network subnet update --region $REGION --subnet-id $okeSubnetId --security-list-ids $sl \
      --wait-for-state AVAILABLE --wait-interval-seconds 10 --force"
    execute "$cmd"
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the bastion private security list
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$BASTION_PRIVATE_SECLIST_DISPLAY_NAME' from the Kubernetes Node Subnet..."
  sl=$(oci network subnet get --region $REGION --subnet-id $okeSubnetId --query 'data."security-list-ids"' 2>/dev/null)
  sl=$(echo $sl | tr '\n' ' ')
  bssl=$(cat $RESOURCE_OCID_FILE | grep $BASTION_PRIVATE_SECLIST_DISPLAY_NAME | cut -d: -f2)
  if [[ "$sl" =~ "$bssl" ]]; then
    sl="'${sl/\"$bssl\"/}'"
    sl=$(sed 's/, *\]/ \]/g' <<< $sl)
    sl=$(sed 's/, *,/, /g' <<< $sl)
    sl=$(sed 's/\[ *,/\[ /g' <<< $sl)
    cmd="oci network subnet update --region $REGION --subnet-id $okeSubnetId --security-list-ids $sl \
      --wait-for-state AVAILABLE --wait-interval-seconds 10 --force"
    execute "$cmd"
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the bastion subnet
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$BASTION_SUBNET_DISPLAY_NAME' Subnet..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $BASTION_SUBNET_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network subnet delete --region $REGION --subnet-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the bastion route table
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$BASTION_ROUTE_TABLE_DISPLAY_NAME' Route Table..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $BASTION_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network route-table delete --region $REGION --rt-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the bastion setup security list
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$BASTION_SETUP_SECLIST_DISPLAY_NAME' Security List..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $BASTION_SETUP_SECLIST_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network security-list delete --region $REGION --security-list-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the bastion public security list
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$BASTION_PUBLIC_SECLIST_DISPLAY_NAME' Security List..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $BASTION_PUBLIC_SECLIST_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network security-list delete --region $REGION --security-list-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the bastion private security list
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$BASTION_PRIVATE_SECLIST_DISPLAY_NAME' Security List..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $BASTION_PRIVATE_SECLIST_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network security-list delete --region $REGION --security-list-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
}

# Delete the resoures related to the DNS zone
deleteDNS() {
  # Delete the DNS zone which also deletes the CNAME & A records
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$DNS_DOMAIN_NAME' DNS Zone..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $DNS_DOMAIN_NAME | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci dns zone delete --region $REGION --compartment-id $COMPARTMENT_ID \
      --zone-name-or-id $ocid --scope PRIVATE --force"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
}

# Delete the resources related to the RAC database
deleteDatabase() {
  # Delete the database
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$DB_DISPLAY_NAME' Database (may take 30+ minutes)..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $DB_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci db system terminate --region $REGION --db-system-id  $ocid --force 
        --max-wait-seconds 3600 --wait-for-state SUCCEEDED --wait-for-state FAILED" 
    execute "$cmd"
    print_msg end
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the database subnet
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$DB_SUBNET_DISPLAY_NAME' Subnet..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $DB_SUBNET_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network subnet delete --region $REGION --subnet-id $ocid \
      --wait-for-state TERMINATED --wait-interval-seconds 10 --force"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the database route table
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$DB_ROUTE_TABLE_DISPLAY_NAME' Route Table..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $DB_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network route-table delete --region $REGION --rt-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the database security list
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$DB_SECLIST_DISPLAY_NAME' Security List..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $DB_SECLIST_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network security-list delete --region $REGION --security-list-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
}

# Delete the resources related to the internal load balancer which includes all of the
# hostname, listeners, backend sets, and certificates
deleteInternalLBR() {
  # Delete the internal load balancer
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$INT_LBR_DISPLAY_NAME' Load Balancer..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $INT_LBR_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci lb load-balancer delete --region $REGION --load-balancer-id $ocid --force \
      --wait-for-state SUCCEEDED --wait-for-state FAILED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
}

# Delete the resources related to the NFS file systems and mount targets
deleteNFS() {
  okeSubnetId=$(cat $RESOURCE_OCID_FILE | grep $OKE_NODE_SUBNET_DISPLAY_NAME | cut -d: -f2) 
  pvsl=$(cat $RESOURCE_OCID_FILE | grep $PV_SECLIST_DISPLAY_NAME | cut -d: -f2) 
  if [[ -z "$pvsl" ]]; then
    pvsl="notFound"
  fi

  # Delete the persistent volume security list
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$PV_SECLIST_DISPLAY_NAME' from the Kubernetes Node Subnet..."
  sl=$(oci network subnet get --region $REGION --subnet-id $okeSubnetId --query 'data."security-list-ids"' 2>/dev/null)
  sl=$(echo $sl | tr '\n' ' ')
  if [[ "$sl" =~ "$pvsl" ]]; then
    sl="'${sl/\"$pvsl\"/}'"
    sl=$(sed 's/, *\]/ \]/g' <<< $sl)
    sl=$(sed 's/, *,/, /g' <<< $sl)
    sl=$(sed 's/\[ *,/\[ /g' <<< $sl)
    cmd="oci network subnet update --region $REGION --subnet-id $okeSubnetId --security-list-ids $sl --force \
      --wait-for-state AVAILABLE --wait-interval-seconds 10"
    execute "$cmd"
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the pvseclist from the bastion subnet
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$PV_SECLIST_DISPLAY_NAME' from the '$BASTION_SUBNET_DISPLAY_NAME' Subnet..."
  snid=$(cat $RESOURCE_OCID_FILE | grep $BASTION_SUBNET_DISPLAY_NAME | cut -d: -f2)
  sl=$(oci network subnet get --region $REGION --subnet-id $snid --query 'data."security-list-ids"' 2>/dev/null)
  sl=$(echo $sl | tr '\n' ' ')
  if [[ "$sl" =~ "$pvsl" ]]; then
    sl="'${sl/\"$pvsl\"/}'"
    sl=$(sed 's/, *\]/ \]/g' <<< $sl)
    sl=$(sed 's/, *,/, /g' <<< $sl)
    sl=$(sed 's/\[ *,/\[ /g' <<< $sl)
    cmd="oci network subnet update --region $REGION --subnet-id $snid --security-list-ids $sl --force \
      --wait-for-state AVAILABLE --wait-interval-seconds 10"
    execute "$cmd"
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the pvseclist from the web subnet
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$PV_SECLIST_DISPLAY_NAME' from the '$WEB_SUBNET_DISPLAY_NAME' Subnet..."
  snid=$(cat $RESOURCE_OCID_FILE | grep $WEB_SUBNET_DISPLAY_NAME | cut -d: -f2)
  sl=$(oci network subnet get --region $REGION --subnet-id $snid --query 'data."security-list-ids"' 2>/dev/null)
  sl=$(echo $sl | tr '\n' ' ')
  if [[ "$sl" =~ "$pvsl" ]]; then
    sl="'${sl/\"$pvsl\"/}'"
    sl=$(sed 's/, *\]/ \]/g' <<< $sl)
    sl=$(sed 's/, *,/, /g' <<< $sl)
    sl=$(sed 's/\[ *,/\[ /g' <<< $sl)
    cmd="oci network subnet update --region $REGION --subnet-id $snid --security-list-ids $sl --force \
      --wait-for-state AVAILABLE --wait-interval-seconds 10"
    execute "$cmd"
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the pv security list
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$PV_SECLIST_DISPLAY_NAME' Security List..."
  if [[ "$pvsl" =~ "ocid" ]]; then
    cmd="oci network security-list delete --region $REGION --security-list-id $pvsl --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$pvsl/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the webhost1 mount target
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$WEBHOST1_MOUNT_TARGET_DISPLAY_NAME' Mount Target..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep -e "$WEBHOST1_MOUNT_TARGET_DISPLAY_NAME.*mounttarget" | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci fs mount-target delete --region $REGION --mount-target-id $ocid --force \
      --wait-for-state DELETED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$WEBHOST1_MOUNT_TARGET_DISPLAY_NAME.*mounttarget/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the webhost2 mount target
  STEPNO=$((STEPNO+1))  
  print_msg begin "Deleting the '$WEBHOST2_MOUNT_TARGET_DISPLAY_NAME' Mount Target..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep -e "$WEBHOST2_MOUNT_TARGET_DISPLAY_NAME.*mounttarget" | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci fs mount-target delete --region $REGION --mount-target-id $ocid --force \
      --wait-for-state DELETED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$WEBHOST2_MOUNT_TARGET_DISPLAY_NAME.*mounttarget/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the OKE mount target
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$OKE_MOUNT_TARGET_DISPLAY_NAME' Mount Target..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep -e "$OKE_MOUNT_TARGET_DISPLAY_NAME.*mounttarget" | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci fs mount-target delete --region $REGION --mount-target-id $ocid --force \
      --wait-for-state DELETED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$OKE_MOUNT_TARGET_DISPLAY_NAME.*mounttarget/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  for i in $FS_WEBBINARIES1_DISPLAY_NAME $FS_WEBBINARIES2_DISPLAY_NAME $FS_WEBCONFIG1_DISPLAY_NAME \
    $FS_WEBCONFIG2_DISPLAY_NAME $FS_OAMPV_DISPLAY_NAME $FS_OIGPV_DISPLAY_NAME $FS_OUDPV_DISPLAY_NAME \
    $FS_OUDCONFIGPV_DISPLAY_NAME $FS_OUDSMPV_DISPLAY_NAME $FS_OIRIPV_DISPLAY_NAME $FS_DINGPV_DISPLAY_NAME \
    $FS_WORKPV_DISPLAY_NAME $FS_OAAVAULTPV_DISPLAY_NAME $FS_OAACONFIGPV_DISPLAY_NAME $FS_OAACREDPV_DISPLAY_NAME $FS_OAALOGPV_DISPLAY_NAME \
    $FS_IMAGES_DISPLAY_NAME
  do
    # Delete the NFS file systems
    STEPNO=$((STEPNO+1))
    print_msg begin "Deleting the '$i' File System..."  
    ocid=$(cat $RESOURCE_OCID_FILE | grep $i | cut -d: -f2) 
    if [[ "$ocid" =~ "ocid" ]]; then
      cmd="oci fs file-system delete --region $REGION --file-system-id $ocid --wait-for-state DELETED \
        --wait-for-state FAILED --wait-interval-seconds 10 --force"
      execute "$cmd"
      out=$(ex +"g/$i/d" -scwq $RESOURCE_OCID_FILE)
      print_msg end
    else
      print_msg screen "resource not found, probably already deleted"
    fi
  done
}

# Delete the resources related to the network load balancer
deleteNetworkLBR() {
  # Delete the network load balancer which includes all of the
  # hostname, listeners, backend sets, and certificates
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$K8_LBR_DISPLAY_NAME' Load Balancer..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $K8_LBR_DISPLAY_NAME | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci nlb network-load-balancer delete --region $REGION --network-load-balancer-id $ocid \
      --wait-for-state SUCCEEDED --wait-for-state FAILED --force --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
}

# Delete the resources related to the OKE cluster
deleteOKE() {
  # Delete the OKE node pool
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$OKE_NODE_POOL_DISPLAY_NAME' Kubernetes Node Pool..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $OKE_NODE_POOL_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci ce node-pool delete --region $REGION --node-pool-id  $ocid --force \
        --wait-for-state IN_PROGRESS --wait-for-state SUCCEEDED --wait-for-state FAILED"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the OKE cluster
  STEPNO=$((STEPNO+1)) 
  print_msg begin "Deleting the '$OKE_CLUSTER_DISPLAY_NAME' Kubernetes Cluster (may take 20+ minutes)..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $OKE_CLUSTER_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci ce cluster delete --region $REGION --cluster-id  $ocid --force \
        --wait-for-state SUCCEEDED --wait-for-state FAILED"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the OKE subnet
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$OKE_NODE_SUBNET_DISPLAY_NAME' Subnet..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $OKE_NODE_SUBNET_DISPLAY_NAME | cut -d: -f2)  
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network subnet delete --region $REGION --subnet-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the OKE service lb subnet
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$OKE_SVCLB_SUBNET_DISPLAY_NAME' Subnet..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $OKE_SVCLB_SUBNET_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network subnet delete --region $REGION --subnet-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the OKE api subnet
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$OKE_API_SUBNET_DISPLAY_NAME' Subnet..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $OKE_API_SUBNET_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network subnet delete --region $REGION --subnet-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the OKE node security list
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$OKE_NODE_SECLIST_DISPLAY_NAME' Security List..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $OKE_NODE_SECLIST_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network security-list delete --region $REGION --security-list-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the OKE api security list
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$OKE_API_SECLIST_DISPLAY_NAME' Security List..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $OKE_API_SECLIST_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network security-list delete --region $REGION --security-list-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
}

# Delete the resources related to the public load balancer 
deletePublicLBR() {
  lgid=$(cat $RESOURCE_OCID_FILE | grep $LBR_LOG_GROUP_NAME | cut -d: -f2)

  if [[ "$lgid" =~ "ocid" ]]; then
    # Delete the public load balancer access log
    STEPNO=$((STEPNO+1))
    print_msg begin "Deleting the '$PUBLIC_LBR_ACCESS_LOG_DISPLAY_NAME' Log File..."
    ocid=$(oci logging log list --region $REGION --display-name $PUBLIC_LBR_ACCESS_LOG_DISPLAY_NAME \
      --query 'data[0].id' --log-group-id $lgid --raw-output 2>/dev/null)
    if [[ "$ocid" =~ "ocid" ]]; then
      cmd="oci logging log delete --region $REGION --log-group-id $lgid --log-id $ocid \
      --wait-for-state SUCCEEDED --wait-for-state FAILED --wait-interval-seconds 10 --force"
      execute "$cmd"
      print_msg end
    else
      print_msg screen "resource not found, probably already deleted"
    fi
  fi

  if [[ "$lgid" =~ "ocid" ]]; then
    # Delete the public load balancer error log
    STEPNO=$((STEPNO+1))
    print_msg begin "Deleting the '$PUBLIC_LBR_ERROR_LOG_DISPLAY_NAME' Log File..."
    ocid=$(oci logging log list --region $REGION --display-name $PUBLIC_LBR_ERROR_LOG_DISPLAY_NAME \
      --query 'data[0].id' --log-group-id $lgid --raw-output 2>/dev/null)
    if [[ "$ocid" =~ "ocid" ]]; then
      cmd="oci logging log delete --region $REGION --log-group-id $lgid --log-id $ocid \
      --wait-for-state SUCCEEDED --wait-for-state FAILED --wait-interval-seconds 10 --force"
      execute "$cmd"
      print_msg end
    else
      print_msg screen "resource not found, probably already deleted"
    fi
  fi

  if [[ "$lgid" =~ "ocid" ]]; then
    # Delete the internal load balancer access log
    STEPNO=$((STEPNO+1))
    print_msg begin "Deleting the '$INT_LBR_ACCESS_LOG_DISPLAY_NAME' Log File..."
    ocid=$(oci logging log list --region $REGION --display-name $INT_LBR_ACCESS_LOG_DISPLAY_NAME \
      --query 'data[0].id' --log-group-id $lgid --raw-output 2>/dev/null)
    if [[ "$ocid" =~ "ocid" ]]; then
      cmd="oci logging log delete --region $REGION --log-group-id $lgid --log-id $ocid \
      --wait-for-state SUCCEEDED --wait-for-state FAILED --wait-interval-seconds 10 --force"
      execute "$cmd"
      print_msg end
    else
      print_msg screen "resource not found, probably already deleted"
    fi
  fi

  if [[ "$lgid" =~ "ocid" ]]; then
    # Delete the internal load balancer error log
    STEPNO=$((STEPNO+1))
    print_msg begin "Deleting the '$INT_LBR_ERROR_LOG_DISPLAY_NAME' Log File..."
    ocid=$(oci logging log list --region $REGION --display-name $INT_LBR_ERROR_LOG_DISPLAY_NAME \
      --query 'data[0].id' --log-group-id $lgid --raw-output 2>/dev/null)
    if [[ "$ocid" =~ "ocid" ]]; then
      cmd="oci logging log delete --region $REGION --log-group-id $lgid --log-id $ocid \
      --wait-for-state SUCCEEDED --wait-for-state FAILED --wait-interval-seconds 10 --force"
      execute "$cmd"
      print_msg end
    else
      print_msg screen "resource not found, probably already deleted"
    fi
  fi

  # Delete the load balancer log group
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$LBR_LOG_GROUP_NAME' Log Group..."
  if [[ "$lgid" =~ "ocid" ]]; then
    cmd="oci logging log-group delete --region $REGION --log-group-id $lgid --force \
      --wait-for-state SUCCEEDED --wait-for-state FAILED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$lgid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the public load balancer which includes all of the
  # hostname, listeners, backend sets, and certificates
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$PUBLIC_LBR_DISPLAY_NAME' Load Balancer..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $PUBLIC_LBR_DISPLAY_NAME | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci lb load-balancer delete --region $REGION --load-balancer-id $ocid --force \
      --wait-for-state SUCCEEDED --wait-for-state FAILED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the public loadbalancer subnet1
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$LBR2_DISPLAY_NAME' Subnet..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $LBR2_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network subnet delete --region $REGION --subnet-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi 

  # Delete the public loadbalancer subnet2
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$LBR1_DISPLAY_NAME' Subnet..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $LBR1_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network subnet delete --region $REGION --subnet-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the public load balancer route table
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$PUBLIC_LBR_ROUTE_TABLE_DISPLAY_NAME' Route Table..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $PUBLIC_LBR_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network route-table delete --region $REGION --rt-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the public load balancer security list
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$PUBLIC_LBR_SECLIST_DISPLAY_NAME' Security List..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $PUBLIC_LBR_SECLIST_DISPLAY_NAME | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network security-list delete --region $REGION --security-list-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
}

# Delete the resoures associated with the VCN
deleteVCN() {  
  # Delete the private route table
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$VCN_PRIVATE_ROUTE_TABLE_DISPLAY_NAME' Route Table..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $VCN_PRIVATE_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network route-table delete --region $REGION --rt-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Remove the internet gateway from the default route table
  STEPNO=$((STEPNO+1)) 
  print_msg begin "Removing the internet gateway '$VCN_INTERNET_GATEWAY_DISPLAY_NAME' from the Default Route Table..."
  ocid=$(oci network route-table list --region $REGION --compartment-id $COMPARTMENT_ID \
       --display-name $VCN_PUBLIC_ROUTE_TABLE_DISPLAY_NAME --query 'data[0].id' --raw-output 2>/dev/null) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network route-table update --region $REGION --rt-id $ocid --force \
      --route-rules '[]' --wait-for-state AVAILABLE --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the internet gateway
  STEPNO=$((STEPNO+1))  
  print_msg begin "Deleting the '$VCN_INTERNET_GATEWAY_DISPLAY_NAME' Internet Gateway..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $VCN_INTERNET_GATEWAY_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network internet-gateway delete --region $REGION --ig-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the NAT gateway
  STEPNO=$((STEPNO+1))  
  print_msg begin "Deleting the '$VCN_NAT_GATEWAY_DISPLAY_NAME' NAT Gateway..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $VCN_NAT_GATEWAY_DISPLAY_NAME | cut -d: -f2)  
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network nat-gateway delete --region $REGION --nat-gateway-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the service gateway
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$VCN_SERVICE_GATEWAY_DISPLAY_NAME' Service Gateway..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $VCN_SERVICE_GATEWAY_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network service-gateway delete --region $REGION --service-gateway-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the VCN
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$VCN_DISPLAY_NAME' VCN..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $VCN_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network vcn delete --region $REGION --vcn-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
}

# Delete the resources related to the web hosts
deleteWebHosts() {
  # Delete the webhos1 instance
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$WEBHOST1_DISPLAY_NAME' Instance..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $WEBHOST1_DISPLAY_NAME: | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid"  ]]; then
    cmd="oci compute instance terminate --region $REGION --instance-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the webhost2 instance
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$WEBHOST2_DISPLAY_NAME' Instance..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $WEBHOST2_DISPLAY_NAME: | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid"  ]]; then
   cmd="oci compute instance terminate --region $REGION --instance-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
  
  # Delete the web subnet
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$WEB_SUBNET_DISPLAY_NAME' Subnet..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $WEB_SUBNET_DISPLAY_NAME | cut -d: -f2) 
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network subnet delete --region $REGION --subnet-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the web route table
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$WEB_ROUTE_TABLE_DISPLAY_NAME' Route Table..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $WEB_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network route-table delete --region $REGION --rt-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the OHS security list
  STEPNO=$((STEPNO+1))
  print_msg begin  "Deleting the '$OHS_SECLIST_DISPLAY_NAME' from the Kubernetes Node Subnet..."
  okeSubnetId=$(cat $RESOURCE_OCID_FILE | grep $OKE_NODE_SUBNET_DISPLAY_NAME | cut -d: -f2)
  sl=$(oci network subnet get --region $REGION --subnet-id $okeSubnetId --query 'data."security-list-ids"' 2>/dev/null)
  sl=$(echo $sl | tr '\n' ' ')
  ohssl=$(cat $RESOURCE_OCID_FILE | grep $OHS_SECLIST_DISPLAY_NAME | cut -d: -f2)
  if [[ "$sl" =~ "$ohssl" ]]; then
    sl="'${sl/\"$ohssl\"/}'"
    sl=$(sed 's/, *\]/ \]/g' <<< $sl)
    sl=$(sed 's/, *,/, /g' <<< $sl)
    sl=$(sed 's/\[ *,/\[ /g' <<< $sl)
    cmd="oci network subnet update --region $REGION --subnet-id $okeSubnetId --security-list-ids $sl \
      --wait-for-state AVAILABLE --force --wait-interval-seconds 10"
    execute "$cmd"
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the OHS security list
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$OHS_SECLIST_DISPLAY_NAME' Security List..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $OHS_SECLIST_DISPLAY_NAME | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network security-list delete --region $REGION --security-list-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi

  # Delete the web public security list
  STEPNO=$((STEPNO+1))
  print_msg begin "Deleting the '$WEB_PUBLIC_SECLIST_DISPLAY_NAME' Security List..."
  ocid=$(cat $RESOURCE_OCID_FILE | grep $WEB_PUBLIC_SECLIST_DISPLAY_NAME | cut -d: -f2)
  if [[ "$ocid" =~ "ocid" ]]; then
    cmd="oci network security-list delete --region $REGION --security-list-id $ocid --force \
      --wait-for-state TERMINATED --wait-interval-seconds 10"
    execute "$cmd"
    out=$(ex +"g/$ocid/d" -scwq $RESOURCE_OCID_FILE)
    print_msg end
  else
    print_msg screen "resource not found, probably already deleted"
  fi
}
