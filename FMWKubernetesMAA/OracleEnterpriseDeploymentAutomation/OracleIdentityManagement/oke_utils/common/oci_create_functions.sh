#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of the functions needed to create all of the infrastructure components listed in 
# chapter 9 of the EDG. These functions are used by the provision_oke.sh script.
#
# Dependencies:
#
# Usage: invoked automatically as needed, not directly
#
# Common Environment Variables
#

# Create the resources for the bastion host, including
# - private security list
# - public security list
# - setup security list
# - routing table
# - subnet
# - instance
#
createBastion() {
  # Create the Bastion private security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$BASTION_PRIVATE_SECLIST_DISPLAY_NAME' Security List..."
    cmd="oci network security-list create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $BASTION_PRIVATE_SECLIST_DISPLAY_NAME \
      --egress-security-rules \
        '[{\"destination\": \"0.0.0.0/0\", \"protocol\": \"all\", \"isStateless\": false}]' \
      --ingress-security-rules \
        '[{\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	    \"tcpOptions\": {\"destinationPortRange\": {\"min\": 22, \"max\": 22}, \"sourcePortRange\": null}}, 
         {\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"1\", \"isStateless\": false}]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the Bastion public security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$BASTION_PUBLIC_SECLIST_DISPLAY_NAME' Security List..."
    cmd="oci network security-list create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $BASTION_PUBLIC_SECLIST_DISPLAY_NAME \
      --egress-security-rules \
        '[{\"destination\": \"0.0.0.0/0\", \"protocol\": \"all\", \"isStateless\": false}]' \
      --ingress-security-rules \
        '[{\"source\": \"0.0.0.0/0\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": 22, \"max\": 22}, \"sourcePortRange\": null}},
  	{\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"1\", \"isStateless\": false, \"icmpOptions\": {\"code\": 0,
  	\"type\": 3}}, {\"source\": \"0.0.0.0/0\", \"protocol\": \"1\", \"isStateless\": false}]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the Bastion setup security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$BASTION_SETUP_SECLIST_DISPLAY_NAME' Security List..."
    cmd="oci network security-list create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $BASTION_SETUP_SECLIST_DISPLAY_NAME \
      --egress-security-rules \
        '[]' \
      --ingress-security-rules \
        '[{\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	     \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OAM_ADMIN_SERVICE_PORT, 
         \"max\": $OAM_ADMIN_SERVICE_PORT}, \"sourcePortRange\": null},
  	     \"description\": \"OAM Administration Server Kubernetes Service Port\"},
  	     {\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": 1521, \"max\": 1521}, \"sourcePortRange\": null},
         \"description\": \"SQLNet connectivity\"}
         ]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the Bastion routing table
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$BASTION_ROUTE_TABLE_DISPLAY_NAME' Route Table..."
    igw=$(cat $RESOURCE_OCID_FILE | grep $VCN_INTERNET_GATEWAY_DISPLAY_NAME | cut -d: -f2)
    cmd="oci network route-table create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $BASTION_ROUTE_TABLE_DISPLAY_NAME \
      --route-rules '[{\"cidrBlock\": \"0.0.0.0/0\", \"networkEntityId\": \"$igw\"}]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the Bastion subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$BASTION_SUBNET_DISPLAY_NAME' Subnet..."
    sl=$(cat $RESOURCE_OCID_FILE | grep $BASTION_PUBLIC_SECLIST_DISPLAY_NAME | cut -d: -f2)
    rt=$(cat $RESOURCE_OCID_FILE | grep $BASTION_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2)
    cmd="oci network subnet create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $BASTION_SUBNET_DISPLAY_NAME \
      --dns-label $BASTION_DNS_LABEL \
      --cidr-block $BASTION_SUBNET_CIDR \
      --route-table-id $rt \
      --security-list-ids '[\"$sl\"]'" 
    execute "$cmd"
    print_msg end
  fi

  # Add the bastion private seclist to the k8n Node Subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the '$BASTION_PRIVATE_SECLIST_DISPLAY_NAME' to the Kubernetes Node Subnet..."
    sl=$(oci network subnet get --region $REGION --subnet-id $okeSubnetId --query 'data."security-list-ids"')
    bpsl=$(cat $RESOURCE_OCID_FILE | grep $BASTION_PRIVATE_SECLIST_DISPLAY_NAME | cut -d: -f2)
    sl="'${sl/\"/\"$bpsl\",\"}'"
    cmd="oci network subnet update \
      --region $REGION \
      --subnet-id $okeSubnetId \
      --force \
      --security-list-ids $sl \
      --wait-for-state TERMINATED \
      --wait-for-state AVAILABLE"
    execute "$cmd"
    print_msg end
  fi

  # Add the bastion setup seclist to the k8n Node Subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then  
    print_msg begin "Adding the '$BASTION_SETUP_SECLIST_DISPLAY_NAME' to the Kubernetes Node Subnet..."
    sl=$(oci network subnet get --region $REGION --subnet-id $okeSubnetId --query 'data."security-list-ids"')
    bssl=$(cat $RESOURCE_OCID_FILE | grep $BASTION_SETUP_SECLIST_DISPLAY_NAME | cut -d: -f2)
    sl="'${sl/\"/\"$bssl\",\"}'"
    cmd="oci network subnet update \
      --region $REGION \
      --subnet-id $okeSubnetId \
      --force \
      --security-list-ids $sl"
    execute "$cmd"
    print_msg end
  fi

  # Create the Bastion Instance
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$BASTION_INSTANCE_DISPLAY_NAME' Compute Instance..."
    ocid=$(oci compute instance list --region $REGION --compartment-id $COMPARTMENT_ID \
      --display-name $BASTION_INSTANCE_DISPLAY_NAME --query 'data[0].id' --raw-output 2>/dev/null)
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Bastion Name '$BASTION_INSTANCE_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    sn=$(cat $RESOURCE_OCID_FILE | grep $BASTION_SUBNET_DISPLAY_NAME | cut -d: -f2)
    im=$(oci compute image list --region $REGION --compartment-id $COMPARTMENT_ID --display-name $BASTION_IMAGE_NAME \
         --query 'data[0].id' --raw-output)
    if [[ ! "$im" =~ "ocid" ]]; then
      print_msg screen "Error, the OS image '$BASTION_IMAGE_NAME' is not present in the system."
      exit 1
    fi
    cmd="oci compute instance launch \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --display-name $BASTION_INSTANCE_DISPLAY_NAME \
      --availability-domain ${!BASTION_AD} \
      --shape $BASTION_INSTANCE_SHAPE \
      --shape-config $BASTION_SHAPE_CONFIG \
      --subnet-id $sn \
      --assign-public-ip $BASTION_PUBLIC_IP \
      --hostname-label $BASTION_INSTANCE_DISPLAY_NAME \
      --image-id $im \
      --ssh-authorized-keys-file $SSH_PUB_KEYFILE \
      --wait-for-state RUNNING \
      --wait-for-state TERMINATED"
    execute "$cmd"
    print_msg end
  fi

  # Copy the ssh files to the bastion host
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    ST=`date +%s`
    print_msg begin "Copying the ssh keyfile '$SSH_ID_KEYFILE' to the Bastion Node..."
    id=$(cat $RESOURCE_OCID_FILE | grep $BASTION_INSTANCE_DISPLAY_NAME | cut -d: -f2)
    ip=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $id \
           --query 'data[0]."public-ip"' --raw-output)
    cmd="scp -q -o \"StrictHostKeyChecking no\" -i $SSH_ID_KEYFILE $SSH_ID_KEYFILE opc@$ip:~/.ssh/id_rsa"
    execute "$cmd"
    print_msg end
  fi
}

# Create the resources for DNS resolution, including
# - DNS zone
# - iadadmin CNAME record
# - igdadmin CNAME record
# - login CNAME record
# - prov CNAME record
# - internal load balancer A record
# - igdinternal A record
# - webhost1 A record
# - webhost2 A record
createDNS() {
  # create the DNS zone
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$DNS_DOMAIN_NAME' DNS Zone..."
    ocid=$(oci dns zone list --region $REGION --compartment-id $COMPARTMENT_ID --scope PRIVATE \
    --name $DNS_DOMAIN_NAME --query 'data[0].id' --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Zone '$DNS_DOMAIN_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    pv=$(oci dns view list --region $REGION --compartment-id $COMPARTMENT_ID \
      --query "data [?contains(\"display-name\",'$VCN_DISPLAY_NAME')].id" | jq -r '.[]')
    cmd="oci dns zone create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --name $DNS_DOMAIN_NAME \
      --view-id $pv \
      --zone-type $DNS_ZONE_TYPE \
      --scope $DNS_SCOPE \
      --wait-for-state ACTIVE \
      --wait-for-state FAILED"
    execute "$cmd"
    print_msg end
  fi
    
  zn=$(cat $RESOURCE_OCID_FILE | grep $DNS_DOMAIN_NAME | cut -d: -f2)
  
  # Add iadadmin CNAME record
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the '$INT_LBR_IADADMIN_HOSTNAME' CNAME Record to the Zone..."
    cmd="oci dns record zone patch --region $REGION --zone-name-or-id $zn --compartment-id $COMPARTMENT_ID \
      --scope PRIVATE --items '[{\"domain\": \"$INT_LBR_IADADMIN_HOSTNAME\", \
      \"rtype\": \"CNAME\", \"ttl\": 86400, \"rdata\": \"$DNS_INTERNAL_LBR_DNS_HOSTNAME\"}]'"
    execute "$cmd"
    print_msg end
  fi
    
  # Add igdadmin CNAME record
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the '$INT_LBR_IGDADMIN_HOSTNAME' CNAME Record to the Zone..."
    cmd="oci dns record zone patch --region $REGION --zone-name-or-id $zn --compartment-id $COMPARTMENT_ID \
      --scope PRIVATE --items '[{\"domain\": \"$INT_LBR_IGDADMIN_HOSTNAME\", \
      \"rtype\": \"CNAME\", \"ttl\": 86400, \"rdata\": \"$DNS_INTERNAL_LBR_DNS_HOSTNAME\"}]'"
    execute "$cmd"
    print_msg end
  fi
    
  # Add login CNAME record
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then 
    print_msg begin "Adding the '$INT_LBR_LOGIN_HOSTNAME' CNAME Record to the Zone..."
    cmd="oci dns record zone patch --region $REGION --zone-name-or-id $zn --compartment-id $COMPARTMENT_ID \
      --scope PRIVATE --items '[{\"domain\": \"$INT_LBR_LOGIN_HOSTNAME\", \
      \"rtype\": \"CNAME\", \"ttl\": 86400, \"rdata\": \"$DNS_INTERNAL_LBR_DNS_HOSTNAME\"}]'"
    execute "$cmd"
    print_msg end
  fi
  
  # Add prov CNAME record
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then  
    print_msg begin "Adding the '$INT_LBR_PROV_HOSTNAME' CNAME Record to the Zone..."
    cmd="oci dns record zone patch --region $REGION --zone-name-or-id $zn --compartment-id $COMPARTMENT_ID \
      --scope PRIVATE --items '[{\"domain\": \"$INT_LBR_PROV_HOSTNAME\", \
      \"rtype\": \"CNAME\", \"ttl\": 86400, \"rdata\": \"$DNS_INTERNAL_LBR_DNS_HOSTNAME\"}]'"
    execute "$cmd"
    print_msg end
  fi
    
  # Add internal lbr A record
  lbip=$(oci lb load-balancer list --region $REGION --compartment-id  $COMPARTMENT_ID --display-name \
    $INT_LBR_DISPLAY_NAME --query 'data[0]."ip-addresses"' | jq -r '.[]."ip-address"')      
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the 'A' Record for '$DNS_INTERNAL_LBR_DNS_HOSTNAME' to the Zone..."
    cmd="oci dns record zone patch --zone-name-or-id $zn --region $REGION --compartment-id $COMPARTMENT_ID \
         --scope PRIVATE --items '[{\"domain\": \"$DNS_INTERNAL_LBR_DNS_HOSTNAME\", \
         \"rtype\": \"A\", \"ttl\": 86400, \"rdata\": \"$lbip\"}]'"
    execute "$cmd"
    print_msg end
  fi
    
  # Add igdinternal A record
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the 'A' Record for '$INT_LBR_IGDINTERNAL_HOSTNAME' to the Zone..."
    cmd="oci dns record zone patch --zone-name-or-id $zn --region $REGION --compartment-id $COMPARTMENT_ID \
      --scope PRIVATE --items '[{\"domain\": \"$INT_LBR_IGDINTERNAL_HOSTNAME\", \"rtype\": \"A\", \"ttl\": 86400, \
      \"rdata\": \"$lbip\"}]'" 
    execute "$cmd"
    print_msg end 
  fi
    
  # Add webhost1 A record
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the 'A' Record for '$WEBHOST1_HOSTNAME' to the Zone..."
    wh1=$(cat $RESOURCE_OCID_FILE | grep $WEBHOST1_DISPLAY_NAME: | cut -d: -f2)
    whip1=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $wh1 \
      --query 'data[0]."private-ip"' --raw-output)
    cmd="oci dns record zone patch --zone-name-or-id $zn --region $REGION --compartment-id $COMPARTMENT_ID \
      --scope PRIVATE --items '[{\"domain\": \"$WEBHOST1_HOSTNAME\", \"rtype\": \"A\", \"ttl\": 86400, \
      \"rdata\": \"$whip1\"}]'"
    execute "$cmd"
    print_msg end 
  fi
  
  # Add webhost2 A record    
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the 'A' Record for '$WEBHOST2_HOSTNAME' to the Zone..."
    wh2=$(cat $RESOURCE_OCID_FILE | grep $WEBHOST2_DISPLAY_NAME: | cut -d: -f2)
    whip2=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $wh2 \
      --query 'data[0]."private-ip"' --raw-output)
    cmd="oci dns record zone patch --zone-name-or-id $zn --region $REGION --compartment-id $COMPARTMENT_ID \
      --scope PRIVATE --items '[{\"domain\": \"$WEBHOST2_HOSTNAME\", \"rtype\": \"A\", \"ttl\": 86400, \
      \"rdata\": \"$whip2\"}]'"
    execute "$cmd"
    print_msg end
  fi
}

# Create the resources for the RAC database, including
# - db security list
# - route table
# - subnet
# - RAC database
createDatabase() {
  # Create the db security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$DB_SECLIST_DISPLAY_NAME' Security List..."
    cmd="oci network security-list create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $DB_SECLIST_DISPLAY_NAME \
      --egress-security-rules \
        '[{\"destination\": \"0.0.0.0/0\", \"protocol\": \"all\", \"isStateless\": false}]' \
      --ingress-security-rules \
        '[{\"source\": \"0.0.0.0/0\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": 22, \"max\": 22}, \"sourcePortRange\": null}},
          {\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": $DB_SQLNET_PORT, \"max\": $DB_SQLNET_PORT}, \"sourcePortRange\": null}},
          {\"source\": \"$DB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": $DB_SQLNET_PORT, \"max\": $DB_SQLNET_PORT}, \"sourcePortRange\": null}},
          {\"source\": \"$DB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": 6200, \"max\": 6200}, \"sourcePortRange\": null}},
          {\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": $DB_SQLNET_PORT, \"max\": $DB_SQLNET_PORT}, \"sourcePortRange\": null}},
          {\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": 6200, \"max\": 6200}, \"sourcePortRange\": null}}]'"
    execute "$cmd"
    print_msg end  
  fi

  # Create the db route table
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$DB_ROUTE_TABLE_DISPLAY_NAME' Route Table..."
    sgw=$(cat $RESOURCE_OCID_FILE | grep $VCN_SERVICE_GATEWAY_DISPLAY_NAME | cut -d: -f2)
    dest=$(oci network service-gateway list --region $REGION --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID \
           --query 'data[0].services[0]."service-name"' --raw-output)
    dest1="${dest// /-}"
    dest=`echo "${dest1}" | tr '[A-Z]' '[a-z]'`
    cmd="oci network route-table create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $DB_ROUTE_TABLE_DISPLAY_NAME \
      --route-rules '[{\"destination\": \"$dest\", \"destinationType\": \"SERVICE_CIDR_BLOCK\", 
                       \"networkEntityId\": \"$sgw\"}]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the db subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$DB_SUBNET_DISPLAY_NAME' Subnet..."
    sl=$(cat $RESOURCE_OCID_FILE | grep $DB_SECLIST_DISPLAY_NAME | cut -d: -f2)
    rt=$(cat $RESOURCE_OCID_FILE | grep $DB_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2)
    cmd="oci network subnet create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $DB_SUBNET_DISPLAY_NAME \
      --dns-label $DB_SUBNET_DNS_LABEL \
      --prohibit-public-ip-on-vnic $DB_SUBNET_PROHIBIT_PUBLIC_IP \
      --cidr-block $DB_SUBNET_CIDR \
      --route-table-id $rt \
      --security-list-ids '[\"$sl\"]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the database
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$DB_NAME' Database..."
    ocid=$(oci db system list --region $REGION --compartment-id $COMPARTMENT_ID --query \
      "data [?contains(\"display-name\",'$DB_DISPLAY_NAME')].id" 2>/dev/null)
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Database '$DB_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    CREATE_OAM_PDB=$(tr '[:upper:]' '[:lower:]' <<< $CREATE_OAM_PDB)
    CREATE_OIG_PDB=$(tr '[:upper:]' '[:lower:]' <<< $CREATE_OIG_PDB)
    CREATE_OAA_PDB=$(tr '[:upper:]' '[:lower:]' <<< $CREATE_OAA_PDB)
    CREATE_OIRI_PDB=$(tr '[:upper:]' '[:lower:]' <<< $CREATE_OIRI_PDB)
    if [[ "$CREATE_OAM_PDB" == "true" ]]; then
      initialPDB=$OAM_PDB_NAME
    elif [[ "$CREATE_OIG_PDB" == "true" ]]; then
      initialPDB=$OIG_PDB_NAME
    elif [[ "$CREATE_OAA_PDB" == "true" ]]; then
      initialPDB=$OAA_PDB_NAME
    elif [[ "$CREATE_OIRI_PDB" == "true" ]]; then
      initialPDB=$OIRI_PDB_NAME
    else
      initialPDB=${DB_NAME}_pdb1
    fi
    snid=$(cat $RESOURCE_OCID_FILE | grep $DB_SUBNET_DISPLAY_NAME | cut -d: -f2)
    hst=$(echo $((1 + RANDOM % 100)))
    cmd="oci db system launch \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --admin-password $DB_PWD \
      --availability-domain ${!DB_AD} \
      --cpu-core-count $DB_CPU_COUNT \
      --database-edition $DB_EDITION \
      --db-name $DB_NAME \
      --db-unique-name ${DB_NAME}_${DB_SUFFIX} \
      --db-version $DB_VERSION \
      --display-name $DB_DISPLAY_NAME \
      --hostname $DB_HOSTNAME_PREFIX$hst \
      --initial-data-storage-size-in-gb $DB_INITIAL_STORAGE \
      --license-model $DB_LICENSE \
      --node-count $DB_NODE_COUNT \
      --pdb-name $initialPDB \
      --shape $DB_SHAPE \
      --ssh-authorized-keys-file $SSH_PUB_KEYFILE \
      --storage-management $DB_STORAGE_MGMT \
      --subnet-id $snid \
      --tde-wallet-password $DB_PWD \
      --time-zone $DB_TIMEZONE \
      --wait-for-state PROVISIONING"
    execute "$cmd"
    print_msg end
  fi
}

# Create the resources for the internal load balancer, including
# - internal load balancer
# - OHS/webhost server backend set
# - Installing the SSL certificates
# - Configure virtual hostnames for iadadmin, login, prov, igdadmin, and igdinternal
# - Configure listeners for igdadmin, login, prov, iadadmin, and igdinternal
# - Create access & error log files for the load balancer
createInternalLBR() {
  # Create the internal load balancer
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_DISPLAY_NAME' Load Balancer..."
    ocid=$(oci lb load-balancer list --region $REGION --compartment-id $COMPARTMENT_ID \
       --display-name $INT_LBR_DISPLAY_NAME --detail simple --query 'data[0].id'  --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Load Balancer '$INT_LBR_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    snid=$(cat $RESOURCE_OCID_FILE | grep $WEB_SUBNET_DISPLAY_NAME | cut -d: -f2)
    cmd="oci lb load-balancer create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --compartment-id $COMPARTMENT_ID \
      --display-name $INT_LBR_DISPLAY_NAME \
      --is-private $INT_LBR_PRIVATE \
      --shape-name $INT_LBR_SHAPE \
      --shape-details $INT_LBR_SHAPE_DETAILS \
      --subnet-ids '[\"$snid\"]'"
    execute "$cmd"
    print_msg end
  fi
    
  lbr=$(cat $RESOURCE_OCID_FILE | grep $INT_LBR_DISPLAY_NAME | cut -d: -f2)

  # Create the backend set connecting to the OHS webhosts
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_OHS_SERVERS_BS_NAME' Backend Set..."
    cmd="oci lb backend-set create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --health-checker-protocol $INT_LBR_OHS_SERVERS_BS_PROTOCOL \
      --load-balancer-id $lbr \
      --health-checker-port $OHS_NON_SSL_PORT \
      --health-checker-url-path $INT_LBR_OHS_SERVERS_BS_URI_PATH \
      --name $INT_LBR_OHS_SERVERS_BS_NAME \
      --policy $INT_LBR_OHS_SERVERS_BS_POLICY"
    execute "$cmd"
    print_msg end
  fi

  # Add webhost1 to the backend set
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding '$WEBHOST1_DISPLAY_NAME' to the '$INT_LBR_OHS_SERVERS_BS_NAME' Backend Set..."
    wh1=$(cat $RESOURCE_OCID_FILE | grep $WEBHOST1_DISPLAY_NAME: | cut -d: -f2)
    ip1=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $wh1 \
      --query 'data[0]."private-ip"' --raw-output)
    currentIpList=$(oci lb backend list --region $REGION --backend-set-name $INT_LBR_OHS_SERVERS_BS_NAME \
        --load-balancer-id $lbr --query 'data[*]."ip-address"' --all 2>/dev/null | jq -r '.[]')
    if ! [[ "$currentIpList" =~ "$ip1" ]]; then
      cmd="oci lb backend create \
        --region $REGION \
        --wait-for-state SUCCEEDED \
        --wait-for-state FAILED \
        --backend-set-name $INT_LBR_OHS_SERVERS_BS_NAME \
        --load-balancer-id $lbr \
        --port $OHS_NON_SSL_PORT \
        --ip-address $ip1"
        execute "$cmd"
    else
      PROGRESS=$((PROGRESS+1))
      echo $PROGRESS > $LOGDIR/progressfile
    fi
    print_msg end
  fi
    
  # Add webhost2 to the backend set
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding '$WEBHOST2_DISPLAY_NAME' to the '$INT_LBR_OHS_SERVERS_BS_NAME' Backend Set..."
    wh2=$(cat $RESOURCE_OCID_FILE | grep $WEBHOST2_DISPLAY_NAME: | cut -d: -f2)
    ip2=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $wh2 \
      --query 'data[0]."private-ip"' --raw-output)
    currentIpList=$(oci lb backend list --region $REGION --backend-set-name $INT_LBR_OHS_SERVERS_BS_NAME \
        --load-balancer-id $lbr --query 'data[*]."ip-address"' --all 2>/dev/null | jq -r '.[]')
    if ! [[ "$currentIpList" =~ "$ip2" ]]; then
        cmd="oci lb backend create \
        --region $REGION \
        --wait-for-state SUCCEEDED \
        --wait-for-state FAILED \
        --backend-set-name $INT_LBR_OHS_SERVERS_BS_NAME \
        --load-balancer-id $lbr \
        --port $OHS_NON_SSL_PORT \
        --ip-address $ip2"
      execute "$cmd"
    else
      PROGRESS=$((PROGRESS+1))
      echo $PROGRESS > $LOGDIR/progressfile
    fi
    print_msg end
  fi

  # Add the SSL Certificate to the load balancer
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the SSL Certificate to the Load Balancer..."
    cmd="oci lb certificate create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --certificate-name $INT_LBR_CERTIFICATE_NAME \
      --load-balancer-id $lbr \
      --ca-certificate-file \"$SSL_CA_CERT\" \
      --private-key-file \"$SSL_LBR_KEY\" \
      --public-certificate-file \"$SSL_LBR_CERT\""
    execute "$cmd"
    print_msg end
  fi

  # Create the iadadmin lbr hostname
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_IADADMIN_HOSTNAME' Load Balancer Hostname..."
    cmd="oci lb hostname create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --load-balancer-id $lbr \
      --name $INT_LBR_IADADMIN_DISPLAY_NAME \
      --hostname $INT_LBR_IADADMIN_HOSTNAME"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the login lbr hostname
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_LOGIN_HOSTNAME' Load Balancer Hostname..."
    cmd="oci lb hostname create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --load-balancer-id $lbr \
      --name $INT_LBR_LOGIN_DISPLAY_NAME \
      --hostname $INT_LBR_LOGIN_HOSTNAME"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the prov lbr hostname
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_PROV_HOSTNAME' Load Balancer Hostname..."
    cmd="oci lb hostname create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --load-balancer-id $lbr \
      --name $INT_LBR_PROV_DISPLAY_NAME \
      --hostname $INT_LBR_PROV_HOSTNAME"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the igdadmin lbr hostname
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_IGDADMIN_HOSTNAME' Load Balancer Hostname..."
    cmd="oci lb hostname create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --load-balancer-id $lbr \
      --name $INT_LBR_IGDADMIN_DISPLAY_NAME \
      --hostname $INT_LBR_IGDADMIN_HOSTNAME"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the igdinternal lbr hostname
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_IGDINTERNAL_HOSTNAME' Load Balancer Hostname..."
    cmd="oci lb hostname create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --load-balancer-id $lbr \
      --name $INT_LBR_IGDINTERNAL_DISPLAY_NAME \
      --hostname $INT_LBR_IGDINTERNAL_HOSTNAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the igdadmin lbr listener
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_IGDADMIN_LISTENER_DISPLAY_NAME' Load Balancer Listener..."
    cmd="oci lb listener create \
      --region $REGION \
      --default-backend-set-name $INT_LBR_OHS_SERVERS_BS_NAME \
      --load-balancer-id $lbr \
      --name $INT_LBR_IGDADMIN_LISTENER_DISPLAY_NAME \
      --port $PUBLIC_LBR_NON_SSL_PORT \
      --protocol HTTP \
      --hostname-names '[\"$INT_LBR_IGDADMIN_DISPLAY_NAME\"]'"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the login lbr listener
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_LOGIN_LISTENER_DISPLAY_NAME' Load Balancer Listener..."
    cmd="oci lb listener create \
      --region $REGION \
      --default-backend-set-name $INT_LBR_OHS_SERVERS_BS_NAME \
      --load-balancer-id $lbr \
      --name $INT_LBR_LOGIN_LISTENER_DISPLAY_NAME \
      --port $PUBLIC_LBR_SSL_PORT \
      --protocol HTTP \
      --ssl-certificate-name $INT_LBR_CERTIFICATE_NAME \
      --hostname-names '[\"$INT_LBR_LOGIN_DISPLAY_NAME\"]'"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the prov lbr listener
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_PROV_LISTENER_DISPLAY_NAME' Load Balancer Listener..."
    cmd="oci lb listener create \
      --region $REGION \
      --default-backend-set-name $INT_LBR_OHS_SERVERS_BS_NAME \
      --load-balancer-id $lbr \
      --name $INT_LBR_PROV_LISTENER_DISPLAY_NAME \
      --port $PUBLIC_LBR_SSL_PORT \
      --protocol HTTP \
      --ssl-certificate-name $INT_LBR_CERTIFICATE_NAME \
      --hostname-names '[\"$INT_LBR_PROV_DISPLAY_NAME\"]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the iadadmin lbr listener
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_IADADMIN_LISTENER_DISPLAY_NAME' Load Balancer Listener..."
    cmd="oci lb listener create \
      --region $REGION \
      --default-backend-set-name $INT_LBR_OHS_SERVERS_BS_NAME \
      --load-balancer-id $lbr \
      --name $INT_LBR_IADADMIN_LISTENER_DISPLAY_NAME \
      --port $PUBLIC_LBR_NON_SSL_PORT \
      --protocol HTTP \
      --hostname-names '[\"$INT_LBR_IADADMIN_DISPLAY_NAME\"]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the igdinternal lbr listener
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$INT_LBR_IGDINTERNAL_LISTENER_DISPLAY_NAME' Load Balancer Listener..."
    cmd="oci lb listener create \
      --region $REGION \
      --default-backend-set-name $INT_LBR_OHS_SERVERS_BS_NAME \
      --load-balancer-id $lbr \
      --name $INT_LBR_IGDINTERNAL_LISTENER_DISPLAY_NAME \
      --port $OHS_NON_SSL_PORT \
      --protocol HTTP \
      --hostname-names '[\"$INT_LBR_IGDINTERNAL_DISPLAY_NAME\"]'"
    execute "$cmd"
    print_msg end
  fi

  lgid=$(cat $RESOURCE_OCID_FILE | grep $LBR_LOG_GROUP_NAME | cut -d: -f2)
           
  # Create the lbr access log
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Enabling the '$INT_LBR_ACCESS_LOG_DISPLAY_NAME' Access Log..."
    cmd="oci logging log create \
      --region $REGION \
      --display-name $INT_LBR_ACCESS_LOG_DISPLAY_NAME \
      --log-group-id $lgid \
      --log-type SERVICE \
      --configuration '{\"source\": {\"category\": \"access\",\"resource\": \"$lbr\",\"service\":
         \"loadbalancer\",\"sourceType\": \"OCISERVICE\"}}'"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the lbr error log
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Enabling the '$INT_LBR_ERROR_LOG_DISPLAY_NAME' Access Log..."
    cmd="oci logging log create \
      --region $REGION \
      --display-name $INT_LBR_ERROR_LOG_DISPLAY_NAME \
      --log-group-id $lgid \
      --log-type SERVICE \
      --configuration '{\"source\": {\"category\": \"error\",\"resource\": \"$lbr\",\"service\":
         \"loadbalancer\",\"sourceType\": \"OCISERVICE\"}}'"
    execute "$cmd"
    print_msg end
  fi
}

# Function to check if a given NFS filesystem is already created in the compartment or not.
# Input Parameters:
#   $1 - filesystem display name
#   $2 - availability domain to check
check_FS_exists() {
  ocid=$(oci fs file-system list --region $REGION --compartment-id $COMPARTMENT_ID \
    --display-name $1 --availability-domain $2 --query 'data[0].id' 2>/dev/null)
  if [[ "$ocid" =~ "ocid" ]]; then
    print_msg screen "Error, the File System '$1' already exists in compartment $COMPARTMENT_NAME"
    exit 1
  fi
}

# Create the resources for the NFS servers, including
# - webhost1 mount target
# - webhost2 mount target
# - OKE mount target
# - File systems for webhost binaries, webhost config, oampv, oigpv, oudpv, oudconfigpv, oudsmpv, orirpv,
#                    dingpv, workpv, oaaconfigpv, oaacredpv, oaalogpv, images
# - NFS mount points for the above file systems
# - persistent volume security list
createNFS() {
  # Create the webhost1 mount target
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$WEBHOST1_MOUNT_TARGET_DISPLAY_NAME' Mount Target..."
    ocid=$(oci fs export-set list --region $REGION --compartment-id $COMPARTMENT_ID --availability-domain ${!WEBHOST1_AD} \
      --display-name "$WEBHOST1_MOUNT_TARGET_DISPLAY_NAME - export set" --query 'data[0].id' --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Mount Target '$WEBHOST1_MOUNT_TARGET_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    cmd="oci fs mount-target create \
      --region $REGION \
      --availability-domain ${!WEBHOST1_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $WEBHOST1_MOUNT_TARGET_DISPLAY_NAME \
      --subnet-id $webSubnetId"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the webhost2 mount target
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$WEBHOST2_MOUNT_TARGET_DISPLAY_NAME' Mount Target..."
    ocid=$(oci fs export-set list --region $REGION --compartment-id $COMPARTMENT_ID --availability-domain ${!WEBHOST2_AD} \
      --display-name "$WEBHOST2_MOUNT_TARGET_DISPLAY_NAME - export set" --query 'data[0].id' --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Mount Target '$WEBHOST2_MOUNT_TARGET_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    cmd="oci fs mount-target create \
      --region $REGION \
      --availability-domain ${!WEBHOST2_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $WEBHOST2_MOUNT_TARGET_DISPLAY_NAME \
      --subnet-id $webSubnetId"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the OKE mount target
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$OKE_MOUNT_TARGET_DISPLAY_NAME' Mount Target..."
    ocid=$(oci fs export-set list --region $REGION --compartment-id $COMPARTMENT_ID --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --display-name "$OKE_MOUNT_TARGET_DISPLAY_NAME - export set" --query 'data[0].id' --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Mount Target '$OKE_MOUNT_TARGET_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    cmd="oci fs mount-target create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $OKE_MOUNT_TARGET_DISPLAY_NAME \
      --subnet-id $okeSubnetId"
    execute "$cmd"
    print_msg end
  fi
  
  esl1=$(oci fs export-set list --region $REGION --compartment-id $COMPARTMENT_ID --availability-domain ${!WEBHOST1_AD} \
      --display-name "$WEBHOST1_MOUNT_TARGET_DISPLAY_NAME - export set" --query 'data[0].id' --raw-output)
  esl2=$(oci fs export-set list --region $REGION --compartment-id $COMPARTMENT_ID --availability-domain ${!WEBHOST2_AD} \
      --display-name "$WEBHOST2_MOUNT_TARGET_DISPLAY_NAME - export set" --query 'data[0].id' --raw-output) 
  esl3=$(oci fs export-set list --region $REGION --compartment-id $COMPARTMENT_ID --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --display-name "$OKE_MOUNT_TARGET_DISPLAY_NAME - export set" --query 'data[0].id' --raw-output)

  # Set the webhost1 mount target size
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Setting the Mount Target '$WEBHOST1_MOUNT_TARGET_DISPLAY_NAME' Max Reported Size to 20gb..."
    cmd="oci fs export-set update --region $REGION --export-set-id $esl1 --max-fs-stat-bytes 21474836480"
    execute "$cmd"
    print_msg end
  fi
  
  # Set the webhost2 mount target size
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Setting the Mount Target '$WEBHOST2_MOUNT_TARGET_DISPLAY_NAME' Max Reported Size to 20gb..."
    cmd="oci fs export-set update --region $REGION --export-set-id $esl2 --max-fs-stat-bytes 21474836480"
    execute "$cmd"
    print_msg end
  fi
  
  # Set the OKE mount target size
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Setting the Mount Target '$OKE_MOUNT_TARGET_DISPLAY_NAME' Max Reported Size to 20gb..."
    cmd="oci fs export-set update --region $REGION --export-set-id $esl3 --max-fs-stat-bytes 21474836480"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS filesystem for the webhost1 binaries
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_WEBBINARIES1_DISPLAY_NAME' File System..."
    check_FS_exists $FS_WEBBINARIES1_DISPLAY_NAME ${!WEBHOST1_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!WEBHOST1_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_WEBBINARIES1_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS filesystem for the webhost2 binaries
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_WEBBINARIES2_DISPLAY_NAME' File System..."
    check_FS_exists $FS_WEBBINARIES2_DISPLAY_NAME ${!WEBHOST2_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!WEBHOST2_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_WEBBINARIES2_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS filesystem for the webhost1 config data
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_WEBCONFIG1_DISPLAY_NAME' File System..."
    check_FS_exists $FS_WEBCONFIG1_DISPLAY_NAME ${!WEBHOST1_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!WEBHOST1_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_WEBCONFIG1_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS filesystem for the webhost2 config data
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_WEBCONFIG2_DISPLAY_NAME' File System..."
    check_FS_exists $FS_WEBCONFIG2_DISPLAY_NAME ${!WEBHOST2_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!WEBHOST2_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_WEBCONFIG2_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the oampv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OAMPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_OAMPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_OAMPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the oigpv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OIGPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_OIGPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_OIGPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the oudpv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OUDPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_OUDPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_OUDPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the oudconfigpv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OUDCONFIGPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_OUDCONFIGPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_OUDCONFIGPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the oudsmpv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OUDSMPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_OUDSMPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_OUDSMPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the oiripv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OIRIPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_OIRIPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_OIRIPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the dingpv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_DINGPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_DINGPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_DINGPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the workpv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_WORKPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_WORKPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_WORKPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the oaaconfigpv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OAACONFIGPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_OAACONFIGPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_OAACONFIGPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the oaacredpv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OAACREDPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_OAACREDPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_OAACREDPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the oaavaultpv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OAAVAULTPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_OAAVAULTPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_OAAVAULTPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the oaalogpv file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OAALOGPV_DISPLAY_NAME' File System..."
    check_FS_exists $FS_OAALOGPV_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_OAALOGPV_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the images file system
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_IMAGES_DISPLAY_NAME' File System..."
    check_FS_exists $FS_IMAGES_DISPLAY_NAME ${!OKE_MOUNT_TARGET_AD}
    cmd="oci fs file-system create \
      --region $REGION \
      --availability-domain ${!OKE_MOUNT_TARGET_AD} \
      --compartment-id $COMPARTMENT_ID \
      --display-name $FS_IMAGES_DISPLAY_NAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for the webhost1 binaries
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_WEBBINARIES1_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_WEBBINARIES1_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl1 --file-system-id $fs --path $FS_WEBBINARIES1_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for the webhost2 binaries
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_WEBBINARIES2_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_WEBBINARIES2_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl2 --file-system-id $fs --path $FS_WEBBINARIES2_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for oampv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OAMPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_OAMPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_OAMPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for oigpv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OIGPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_OIGPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_OIGPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for oudpv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OUDPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_OUDPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_OUDPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for oudconfigpv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OUDCONFIGPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_OUDCONFIGPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_OUDCONFIGPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for oudsmpv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OUDSMPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_OUDSMPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_OUDSMPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for oiripv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OIRIPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_OIRIPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_OIRIPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for digpv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_DINGPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_DINGPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_DINGPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for workpv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_WORKPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_WORKPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_WORKPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for oaaconfigpv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OAACONFIGPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_OAACONFIGPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_OAACONFIGPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for oaacredpv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OAACREDPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_OAACREDPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_OAACREDPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for oaavaultpv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OAAVAULTPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_OAAVAULTPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_OAAVAULTPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for oaalogpv
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_OAALOGPV_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_OAALOGPV_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_OAALOGPV_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for the webhost1 config data
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_WEBCONFIG1_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_WEBCONFIG1_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl1 --file-system-id $fs --path $FS_WEBCONFIG1_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for the webhost2 config data
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_WEBCONFIG2_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_WEBCONFIG2_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl2 --file-system-id $fs --path $FS_WEBCONFIG2_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the NFS mount for the images persistent volume
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$FS_IMAGES_DISPLAY_NAME' NFS Mount..."
    fs=$(cat $RESOURCE_OCID_FILE | grep $FS_IMAGES_DISPLAY_NAME | cut -d: -f2)
    cmd="oci fs export create --region $REGION --export-set-id $esl3 --file-system-id $fs --path $FS_IMAGES_NFS_PATH"
    execute "$cmd"
    print_msg end
  fi

  # Create the persistent volume security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PV_SECLIST_DISPLAY_NAME' Security List..."
    cmd="oci network security-list create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $PV_SECLIST_DISPLAY_NAME \
      --egress-security-rules \
        '[{\"destination\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"sourcePortRange\": {\"min\": 111, \"max\": 111}, \"destinationPortRange\": null}},
          {\"destination\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"sourcePortRange\": {\"min\": 2048, \"max\": 2050}, \"destinationPortRange\": null}},
          {\"destination\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"17\", \"isStateless\": false,
           \"udpOptions\": {\"sourcePortRange\": {\"min\": 111, \"max\": 111}, \"destinationPortRange\": null}},
          {\"destination\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"sourcePortRange\": {\"min\": 111, \"max\": 111}, \"destinationPortRange\": null}},
          {\"destination\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"sourcePortRange\": {\"min\": 2048, \"max\": 2050}, \"destinationPortRange\": null}},
          {\"destination\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"17\", \"isStateless\": false,
           \"udpOptions\": {\"sourcePortRange\": {\"min\": 111, \"max\": 111}, \"destinationPortRange\": null}}]' \
      --ingress-security-rules \
        '[{\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": 111, \"max\": 111}, \"sourcePortRange\": null}},
          {\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": 2048, \"max\": 2050}, \"sourcePortRange\": null}},
          {\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"17\", \"isStateless\": false,
           \"udpOptions\": {\"destinationPortRange\": {\"min\": 111, \"max\": 111}, \"sourcePortRange\": null}},
          {\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"17\", \"isStateless\": false,
           \"udpOptions\": {\"destinationPortRange\": {\"min\": 2048, \"max\": 2048}, \"sourcePortRange\": null}},
          {\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": 111, \"max\": 111}, \"sourcePortRange\": null}},
          {\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": 2048, \"max\": 2050}, \"sourcePortRange\": null}},
          {\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"17\", \"isStateless\": false,
           \"udpOptions\": {\"destinationPortRange\": {\"min\": 111, \"max\": 111}, \"sourcePortRange\": null}},
          {\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"17\", \"isStateless\": false,
           \"udpOptions\": {\"destinationPortRange\": {\"min\": 2048, \"max\": 2048}, \"sourcePortRange\": null}},
          {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": 111, \"max\": 111}, \"sourcePortRange\": null}},
          {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": 2048, \"max\": 2050}, \"sourcePortRange\": null}},
          {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"17\", \"isStateless\": false,
           \"udpOptions\": {\"destinationPortRange\": {\"min\": 111, \"max\": 111}, \"sourcePortRange\": null}},
          {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"17\", \"isStateless\": false,
           \"udpOptions\": {\"destinationPortRange\": {\"min\": 2048, \"max\": 2048}, \"sourcePortRange\": null}}]'"
    execute "$cmd"
    print_msg end  
  fi

  # Add the PV seclist to the k8n Node Subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the '$PV_SECLIST_DISPLAY_NAME' to the OKE Subnet..."
    pvsl=$(cat $RESOURCE_OCID_FILE | grep $PV_SECLIST_DISPLAY_NAME | cut -d: -f2)
    sl=$(oci network subnet get --region $REGION --subnet-id $okeSubnetId --query 'data."security-list-ids"')
    sl="'${sl/\"/\"$pvsl\",\"}'"
    cmd="oci network subnet update \
      --region $REGION \
      --subnet-id $okeSubnetId \
      --force \
      --security-list-ids $sl"
    execute "$cmd"
    print_msg end
  fi

  # Add the PV seclist to the bastion subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the '$PV_SECLIST_DISPLAY_NAME' to the '$BASTION_SUBNET_DISPLAY_NAME' Subnet..."
    pvsl=$(cat $RESOURCE_OCID_FILE | grep $PV_SECLIST_DISPLAY_NAME | cut -d: -f2)
    snid=$(cat $RESOURCE_OCID_FILE | grep $BASTION_SUBNET_DISPLAY_NAME | cut -d: -f2)
    sl=$(oci network subnet get --region $REGION --subnet-id $snid --query 'data."security-list-ids"')
    sl="'${sl/\"/\"$pvsl\",\"}'"
    cmd="oci network subnet update \
      --region $REGION \
      --subnet-id $snid \
      --force \
      --security-list-ids $sl"
    execute "$cmd"
    print_msg end
  fi

  # Add the PV seclist to the web subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the '$PV_SECLIST_DISPLAY_NAME' to the '$WEB_SUBNET_DISPLAY_NAME' Subnet..."
    pvsl=$(cat $RESOURCE_OCID_FILE | grep $PV_SECLIST_DISPLAY_NAME | cut -d: -f2)
    snid=$(cat $RESOURCE_OCID_FILE | grep $WEB_SUBNET_DISPLAY_NAME | cut -d: -f2) 
    sl=$(oci network subnet get --region $REGION --subnet-id $snid --query 'data."security-list-ids"')
    sl="'${sl/\"/\"$pvsl\",\"}'"
    cmd="oci network subnet update \
      --region $REGION \
      --subnet-id $snid \
      --force \
      --security-list-ids $sl"
    execute "$cmd"
    print_msg end
  fi
}

# Create the resources for the network load balancer, including
# - network load balancer
# - network load balancer backend set
# - load balancer listener
createNetworkLBR() {
  # Create the network load balancer
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$K8_LBR_DISPLAY_NAME' Load Balancer..."
    ocid=$(oci nlb network-load-balancer list --region $REGION --compartment-id $COMPARTMENT_ID \
      --display-name $K8_LBR_DISPLAY_NAME --query 'data.items[0].id' --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Load Balancer '$K8_LBR_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    cmd="oci nlb network-load-balancer create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --compartment-id $COMPARTMENT_ID \
      --display-name $K8_LBR_DISPLAY_NAME \
      --is-private $K8_LBR_PRIVATE \
      --is-preserve-source-destination $K8_LBR_PRESERVE_SRC_DEST \
      --subnet-id $okeSubnetId"
    execute "$cmd"
    print_msg end
  fi

  lbr=$(cat $RESOURCE_OCID_FILE | grep $K8_LBR_DISPLAY_NAME | cut -d: -f2)
         
  # Create the backend set connecting to the OHS webhosts
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$K8_LBR_K8_WORKERS_BS_NAME' Backend Set..."
    cmd="oci nlb backend-set create \
     --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --network-load-balancer-id $lbr \
      --name $K8_LBR_K8_WORKERS_BS_NAME \
      --policy $K8_LBR_K8_WORKERS_BS_POLICY \
      --is-preserve-source $K8_LBR_K8_WORKERS_BS_PRESERVE_SRC \
      --health-checker '{\"protocol\": \"TCP\", \"port\": \"22\"}'"
    execute "$cmd"
    print_msg end
  fi

  # Adding the OKE nodes to the backend set
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    newStepNo=$((STEPNO+$OKE_NODE_POOL_SIZE-1))
    print_msg begin "(through Step $newStepNo) Adding the OKE Nodes to the '$K8_LBR_K8_WORKERS_BS_NAME' Backend Set..."
    STEPNO=$newStepNo
    clid=$(cat $RESOURCE_OCID_FILE | grep $OKE_CLUSTER_DISPLAY_NAME | cut -d: -f2)
    npid=$(cat $RESOURCE_OCID_FILE | grep $OKE_NODE_POOL_DISPLAY_NAME | cut -d: -f2)
    for i in $(oci ce node-pool get --region $REGION --node-pool-id $npid --query \
      'data.nodes[*].id' | jq -r '.[]')
    do
      currentIpList=$(oci nlb backend list --region $REGION --backend-set-name $K8_LBR_K8_WORKERS_BS_NAME \
          --network-load-balancer-id $lbr --query 'data.items[*]."ip-address"' --all 2>/dev/null | jq -r '.[]')
      ip=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $i \
           --query 'data[0]."private-ip"' --raw-output)
      if ! [[ "$currentIpList" =~ "$ip" ]] &&
        [[ -n "$ip" ]]; then
        cmd="oci nlb backend create \
          --region $REGION \
          --wait-for-state SUCCEEDED \
          --wait-for-state FAILED \
          --backend-set-name $K8_LBR_K8_WORKERS_BS_NAME \
          --network-load-balancer-id $lbr \
          --port 0 \
          --ip-address $ip"
        execute "$cmd"
      fi
    done
    print_msg end
  else
    STEPNO=$((STEPNO+$OKE_NODE_POOL_SIZE-1))
  fi

  # Creating the lbr listener
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$K8_LBR_LISTENER_DISPLAY_NAME' Listener..."
    cmd="oci nlb listener create \
      --region $REGION \
      --default-backend-set-name $K8_LBR_K8_WORKERS_BS_NAME \
      --network-load-balancer-id $lbr \
      --name $K8_LBR_LISTENER_DISPLAY_NAME \
      --port 0 \
      --protocol TCP"
    execute "$cmd"
    print_msg end
  fi
}

# Create the resources for the OKE cluster, including
# - OKE cluster
# - OKE node pool
createOKE() {
  # Create the OKE cluster
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$OKE_CLUSTER_DISPLAY_NAME' Kubernetes Cluster..."
    ocid=$(oci ce cluster list --compartment-id $COMPARTMENT_ID --name $OKE_CLUSTER_DISPLAY_NAME \
      --query 'data[0].id' --lifecycle-state CREATING --lifecycle-state ACTIVE --raw-output 2>/dev/null)
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the OKE Cluster '$OKE_CLUSTER_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    slbsn=$(cat $RESOURCE_OCID_FILE | grep $OKE_SVCLB_SUBNET_DISPLAY_NAME | cut -d: -f2)
    apiep=$(cat $RESOURCE_OCID_FILE | grep $OKE_API_SUBNET_DISPLAY_NAME | cut -d: -f2)
    cmd="oci ce cluster create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --kubernetes-version $OKE_CLUSTER_VERSION \
      --name $OKE_CLUSTER_DISPLAY_NAME \
      --cluster-pod-network-options '[{\"cni-type\": \"$OKE_NETWORK_TYPE\"}]' \
      --endpoint-subnet-id $apiep \
      --pods-cidr $OKE_PODS_CIDR \
      --services-cidr $OKE_SERVICES_CIDR \
      --service-lb-subnet-ids '[\"$slbsn\"]' \
      --wait-for-state IN_PROGRESS \
      --wait-for-state FAILED"
    execute "$cmd"
    print_msg end
  fi

  # Create the OKE node pool
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$OKE_NODE_POOL_DISPLAY_NAME' Kubernetes Node Pool..."
    clid=$(cat $RESOURCE_OCID_FILE | grep $OKE_CLUSTER_DISPLAY_NAME | cut -d: -f2)
    im=$(oci compute image list --region $REGION --compartment-id $COMPARTMENT_ID --display-name \
      $OKE_NODE_POOL_IMAGE_NAME --query 'data[0].id' --raw-output)
    if [[ ! "$im" =~ "ocid" ]]; then
      print_msg screen "Error, the OS image '$OKE_NODE_POOL_IMAGE_NAME' is not present in the system."
      exit 1
    fi
    key=$(cat $SSH_PUB_KEYFILE)
    cmd="oci ce node-pool create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --cluster-id $clid \
      --name $OKE_NODE_POOL_DISPLAY_NAME \
      --node-shape $OKE_NODE_POOL_SHAPE \
      --node-shape-config $OKE_NODE_POOL_SHAPE_CONFIG \
      --kubernetes-version $OKE_CLUSTER_VERSION \
      --node-image-id $im \
      --placement-configs '[" 
    for (( j=1; j<=$ADCNT; j++ ))
    do
      whichAD="ad$j"
      cmd="$cmd {\"availability-domain\": \"${!whichAD}\", \"subnet-id\": \"$okeSubnetId\"},"
    done
    cmd=${cmd%?}
    cmd="$cmd ]' --size $OKE_NODE_POOL_SIZE \
      --ssh-public-key \"$key\" \
      --wait-for-state ACCEPTED \
      --wait-for-state FAILED"
    execute "$cmd"
    print_msg end
  fi
}

# Create the resources for the public load balancer, including
# - SSL certificate
# - public load balancer security list
# - route table
# - lbr1 / lbr2 subnets
# - public load balancer
# - log group used by the public and private load balancer
# - lbr access / error logs
# - iadadmin hostname & listener
# - igdadmin hostname & listener
# - login hostname & listener
# - prov hostname & listener
createPublicLBR() {
  SSL_CONFIG="$OUTDIR/ssl.cnf"
  SSL_CA_KEY="$OUTDIR/ca.key"
  SSL_CA_CSR="$OUTDIR/ca.csr"
  SSL_CA_CERT="$OUTDIR/ca.crt"
  SSL_LBR_KEY="$OUTDIR/loadbalancer.key"
  SSL_LBR_CSR="$OUTDIR/loadbalancer.csr"
  SSL_LBR_CERT="$OUTDIR/loadbalancer.crt"

  # Create the certificate used by the public and private load balancers
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    ST=`date +%s`
    print_msg begin "Creating the Load Balancer SSL Certificates..."
    echo Current STEPNO: $STEPNO  >> $LOGDIR/$LOGFILE
    if [[ -n "$SSL_COUNTRY" ]]; then
      certObj="C=$SSL_COUNTRY"
    fi
    if [[ -n "$SSL_STATE" ]]; then
      certObj+=$'\n'"ST=$SSL_STATE"
    fi
    if [[ -n "$SSL_LOCALE" ]]; then
      certObj+=$'\n'"L=$SSL_LOCALE"
    fi
    if [[ -n "$SSL_ORG" ]]; then
      certObj+=$'\n'"O=$SSL_ORG"
    fi
    if [[ -n "$SSL_ORGUNIT" ]]; then
      certObj+=$'\n'"OU=$SSL_ORGUNIT"
    fi
    if [[ -n "$SSL_CN" ]]; then
      certObj+=$'\n'"CN=$SSL_CN"
    fi
    cat << _end_of_text > $SSL_CONFIG
[ req ]
default_bits           = $SSL_CERT_BITS
distinguished_name     = req_distinguished_name
attributes             = req_attributes
req_extensions         = v3_req
prompt                 = no

[ req_distinguished_name ]
$certObj

[ req_attributes ]
challengePassword              = A challenge password

[ v3_req ]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $SSL_CN
_end_of_text
    out=$(openssl genrsa -out $SSL_CA_KEY $SSL_CERT_BITS 2>&1)
    if [[ "$?" != "0" ]]; then
      echo $out >> $LOGDIR/$LOGFILE
      echo -e "\n\nThe openssl CA key creation has failed and script execution has stopped."
      exit 1
    fi
    out=$(openssl req -new -sha256 -key $SSL_CA_KEY -out $SSL_CA_CSR -batch -config $SSL_CONFIG)
    if [[ "$?" != "0" ]]; then
      echo $out >> $LOGDIR/$LOGFILE
      echo -e "\n\nThe openssl CA CSR creation has failed and script execution has stopped."
      exit 1
    fi
    out=$(openssl x509 -req -sha256 -in $SSL_CA_CSR -signkey $SSL_CA_KEY -out $SSL_CA_CERT -days $SSL_CERT_VALIDITY_DAYS 2>&1)
    if [[ "$?" != "0" ]]; then
      echo $out >> $LOGDIR/$LOGFILE
      echo -e "\n\nThe openssl CA certificate creation has failed and script execution has stopped."
      exit 1
    fi
    out=$(openssl genrsa -out $SSL_LBR_KEY $SSL_CERT_BITS 2>&1)
    if [[ "$?" != "0" ]]; then
      echo $out >> $LOGDIR/$LOGFILE
      echo -e "\n\nThe openssl LBR key creation command has failed and script execution has stopped."
      exit 1
    fi
    out=$(openssl req -new -sha256 -key $SSL_LBR_KEY -out $SSL_LBR_CSR -batch -config $SSL_CONFIG)
    if [[ "$?" != "0" ]]; then
      echo $out >> $LOGDIR/$LOGFILE
      echo -e "\n\nThe LBE CSR creation has failed and script execution has stopped."
      exit 1
    fi
    out=$(openssl x509 -req -sha256 -in $SSL_LBR_CSR -CA $SSL_CA_CERT -CAkey $SSL_CA_KEY -CAcreateserial \
          -out $SSL_LBR_CERT -days $SSL_CERT_VALIDITY_DAYS -extensions v3_req -extfile $SSL_CONFIG 2>&1)
    if [[ "$?" != "0" ]]; then
      echo $out >> $LOGDIR/$LOGFILE
      echo -e "\n\nThe openssl LBR certificate creation has failed and script execution has stopped."
      exit 1
    fi
    out=$(rm -f $SSL_LBR_CSR $SSL_CONFIG)
    ET=`date +%s`
    print_msg end
    PROGRESS=$((PROGRESS+1))
    echo $PROGRESS > $LOGDIR/progressfile
  fi

  # Create the public load balancer security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_SECLIST_DISPLAY_NAME' Security List..."
    cmd="oci network security-list create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $PUBLIC_LBR_SECLIST_DISPLAY_NAME \
      --egress-security-rules \
        '[{\"destination\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
          \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OHS_NON_SSL_PORT, \"max\": $OHS_NON_SSL_PORT}, 
          \"sourcePortRange\": null}}]' \
      --ingress-security-rules \
        '[{\"source\": \"0.0.0.0/0\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": $PUBLIC_LBR_NON_SSL_PORT, \"max\": $PUBLIC_LBR_NON_SSL_PORT},
           \"sourcePortRange\": null}},
          {\"source\": \"0.0.0.0/0\", \"protocol\": \"6\", \"isStateless\": false,
           \"tcpOptions\": {\"destinationPortRange\": {\"min\": $PUBLIC_LBR_SSL_PORT, \"max\": $PUBLIC_LBR_SSL_PORT}, 
           \"sourcePortRange\": null}}]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the public load balancer route table
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_ROUTE_TABLE_DISPLAY_NAME' Route Table..."
    igw=$(cat $RESOURCE_OCID_FILE | grep $VCN_INTERNET_GATEWAY_DISPLAY_NAME | cut -d: -f2)
    cmd="oci network route-table create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $PUBLIC_LBR_ROUTE_TABLE_DISPLAY_NAME \
      --route-rules '[{\"cidrBlock\": \"0.0.0.0/0\", \"networkEntityId\": \"$igw\"}]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the first public load balancer subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$LBR1_DISPLAY_NAME' Subnet..."
    sl=$(cat $RESOURCE_OCID_FILE | grep $PUBLIC_LBR_SECLIST_DISPLAY_NAME | cut -d: -f2)
    rt=$(cat $RESOURCE_OCID_FILE | grep $PUBLIC_LBR_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2)
    cmd="oci network subnet create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --availability-domain ${!LBR1_AD} \
      --display-name $LBR1_DISPLAY_NAME \
      --dns-label $LBR1_DNS_LABEL \
      --cidr-block $LBR1_SUBNET_CIDR \
      --route-table-id $rt \
      --security-list-ids '[\"$sl\"]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the 2nd public load balancer subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$LBR2_DISPLAY_NAME' Subnet..."
    sl=$(cat $RESOURCE_OCID_FILE | grep $PUBLIC_LBR_SECLIST_DISPLAY_NAME | cut -d: -f2)
    rt=$(cat $RESOURCE_OCID_FILE | grep $PUBLIC_LBR_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2)
    cmd="oci network subnet create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --availability-domain ${!LBR2_AD} \
      --display-name $LBR2_DISPLAY_NAME \
      --dns-label $LBR2_DNS_LABEL \
      --cidr-block $LBR2_SUBNET_CIDR \
      --route-table-id $rt \
      --security-list-ids '[\"$sl\"]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the public load balancer
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_DISPLAY_NAME' Load Balancer..."
    ocid=$(oci lb load-balancer list --region $REGION --compartment-id $COMPARTMENT_ID \
      --display-name $PUBLIC_LBR_DISPLAY_NAME --query 'data[0].id' --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Load Balancer '$PUBLIC_LBR_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    snid1=$(cat $RESOURCE_OCID_FILE | grep $LBR1_DISPLAY_NAME | cut -d: -f2)
    snid2=$(cat $RESOURCE_OCID_FILE | grep $LBR2_DISPLAY_NAME | cut -d: -f2)
    cmd="oci lb load-balancer create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --display-name $PUBLIC_LBR_DISPLAY_NAME \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --is-private $PUBLIC_LBR_PRIVATE \
      --shape-name $PUBLIC_LBR_SHAPE \
      --shape-details $PUBLIC_LBR_SHAPE_DETAILS \
      --subnet-ids '[\"$snid1\",\"$snid2\"]'"
    execute "$cmd"
    print_msg end
  fi

  lbr=$(cat $RESOURCE_OCID_FILE | grep $PUBLIC_LBR_DISPLAY_NAME | cut -d: -f2)
  
  # Create the backend set connecting to the OHS webhosts
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_OHS_SERVERS_BS_NAME' Backend Set..." 
    cmd="oci lb backend-set create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --health-checker-protocol $PUBLIC_LBR_OHS_SERVERS_BS_PROTOCOL \
      --load-balancer-id $lbr \
      --health-checker-port $OHS_NON_SSL_PORT \
      --health-checker-url-path $PUBLIC_LBR_OHS_SERVERS_BS_URI_PATH \
      --name $PUBLIC_LBR_OHS_SERVERS_BS_NAME \
      --policy $PUBLIC_LBR_OHS_SERVERS_BS_POLICY"
    execute "$cmd"
    print_msg end
  fi

  # Add webhost1 to the public load balancer backend set
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding '$WEBHOST1_DISPLAY_NAME' to the '$PUBLIC_LBR_OHS_SERVERS_BS_NAME' Backend Set..."
    wh1=$(cat $RESOURCE_OCID_FILE | grep $WEBHOST1_DISPLAY_NAME: | cut -d: -f2)
    ip1=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $wh1 \
      --query 'data[0]."private-ip"' --raw-output)
    currentIpList=$(oci lb backend list --region $REGION --backend-set-name $PUBLIC_LBR_OHS_SERVERS_BS_NAME \
        --load-balancer-id $lbr --query 'data[*]."ip-address"' --all 2>/dev/null | jq -r '.[]')
    if ! [[ "$currentIpList" =~ "$ip1" ]]; then
      cmd="oci lb backend create \
        --region $REGION \
        --wait-for-state SUCCEEDED \
        --wait-for-state FAILED \
        --backend-set-name $PUBLIC_LBR_OHS_SERVERS_BS_NAME \
        --load-balancer-id $lbr \
        --port $OHS_NON_SSL_PORT \
        --ip-address $ip1"
      execute "$cmd"
    else
      PROGRESS=$((PROGRESS+1))
      echo $PROGRESS > $LOGDIR/progressfile
    fi
    print_msg end
  fi
    
  # Add webhost2 to the public load balancer backend set
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding '$WEBHOST2_DISPLAY_NAME' to the '$PUBLIC_LBR_OHS_SERVERS_BS_NAME' Backend Set..."
    wh2=$(cat $RESOURCE_OCID_FILE | grep $WEBHOST2_DISPLAY_NAME: | cut -d: -f2)
    ip2=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $wh2 \
      --query 'data[0]."private-ip"' --raw-output)
    currentIpList=$(oci lb backend list --region $REGION --backend-set-name $PUBLIC_LBR_OHS_SERVERS_BS_NAME \
        --load-balancer-id $lbr --query 'data[*]."ip-address"' --all 2>/dev/null | jq -r '.[]')
    if ! [[ "$currentIpList" =~ "$ip2" ]]; then
      cmd="oci lb backend create \
        --region $REGION \
        --wait-for-state SUCCEEDED \
        --wait-for-state FAILED \
        --backend-set-name $PUBLIC_LBR_OHS_SERVERS_BS_NAME \
        --load-balancer-id $lbr \
        --port $OHS_NON_SSL_PORT \
        --ip-address $ip2"
      execute "$cmd"
    else
      PROGRESS=$((PROGRESS+1))
      echo $PROGRESS > $LOGDIR/progressfile
    fi
    print_msg end
  fi

  # Add the SSL certificate to the load balancer
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the SSL Certificate to the Load Balancer..."
    cmd="oci lb certificate create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --certificate-name $PUBLIC_LBR_CERTIFICATE_NAME \
      --load-balancer-id $lbr \
      --ca-certificate-file \"$SSL_CA_CERT\" \
      --private-key-file \"$SSL_LBR_KEY\" \
      --public-certificate-file \"$SSL_LBR_CERT\""
    execute "$cmd"
    print_msg end
  fi

  # Create the public load balancer iadadmin hostname
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_IADADMIN_HOSTNAME' Load Balancer Hostname..."
    cmd="oci lb hostname create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --load-balancer-id $lbr \
      --name $PUBLIC_LBR_IADADMIN_DISPLAY_NAME \
      --hostname $PUBLIC_LBR_IADADMIN_HOSTNAME"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the public load balancer igdadmin hostname
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_IGDADMIN_HOSTNAME' Load Balancer Hostname..."
    cmd="oci lb hostname create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --load-balancer-id $lbr \
      --name $PUBLIC_LBR_IGDADMIN_DISPLAY_NAME \
      --hostname $PUBLIC_LBR_IGDADMIN_HOSTNAME"
    execute "$cmd"  
    print_msg end
  fi
  
  # Create the public load balancer login hostname
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_LOGIN_HOSTNAME' Load Balancer Hostname..."
    cmd="oci lb hostname create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --load-balancer-id $lbr \
      --name $PUBLIC_LBR_LOGIN_DISPLAY_NAME \
      --hostname $PUBLIC_LBR_LOGIN_HOSTNAME"
    execute "$cmd"  
    print_msg end
  fi
  
  # Create the public load balancer prov hostname
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_PROV_HOSTNAME' Load Balancer Hostname..."
    cmd="oci lb hostname create \
      --region $REGION \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED \
      --load-balancer-id $lbr \
      --name $PUBLIC_LBR_PROV_DISPLAY_NAME \
      --hostname $PUBLIC_LBR_PROV_HOSTNAME"
    execute "$cmd"
    print_msg end
  fi

  # Create the public load balancer iadadmin listener
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_IADADMIN_LISTENER_DISPLAY_NAME' Load Balancer Listener..."
    cmd="oci lb listener create \
      --region $REGION \
      --default-backend-set-name $PUBLIC_LBR_OHS_SERVERS_BS_NAME \
      --load-balancer-id $lbr \
      --name $PUBLIC_LBR_IADADMIN_LISTENER_DISPLAY_NAME \
      --port $PUBLIC_LBR_NON_SSL_PORT \
      --protocol HTTP \
      --hostname-names '[\"$PUBLIC_LBR_IADADMIN_DISPLAY_NAME\"]'"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the public load balancer igdadmin listener
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_IGDADMIN_LISTENER_DISPLAY_NAME' Load Balancer Listener..."
    cmd="oci lb listener create \
      --region $REGION \
      --default-backend-set-name $PUBLIC_LBR_OHS_SERVERS_BS_NAME \
      --load-balancer-id $lbr \
      --name $PUBLIC_LBR_IGDADMIN_LISTENER_DISPLAY_NAME \
      --port $PUBLIC_LBR_NON_SSL_PORT \
      --protocol HTTP \
      --hostname-names '[\"$PUBLIC_LBR_IGDADMIN_DISPLAY_NAME\"]'"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the public load balancer login listener
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_LOGIN_LISTENER_DISPLAY_NAME' Load Balancer Listener..."
    cmd="oci lb listener create \
      --region $REGION \
      --default-backend-set-name $PUBLIC_LBR_OHS_SERVERS_BS_NAME \
      --load-balancer-id $lbr \
      --name $PUBLIC_LBR_LOGIN_LISTENER_DISPLAY_NAME \
      --port $PUBLIC_LBR_SSL_PORT \
      --protocol HTTP \
      --ssl-certificate-name $PUBLIC_LBR_CERTIFICATE_NAME \
      --hostname-names '[\"$PUBLIC_LBR_LOGIN_DISPLAY_NAME\"]'"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the public load balancer prov listener
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$PUBLIC_LBR_PROV_LISTENER_DISPLAY_NAME' Load Balancer Listener..."
    cmd="oci lb listener create \
      --region $REGION \
      --default-backend-set-name $PUBLIC_LBR_OHS_SERVERS_BS_NAME \
      --load-balancer-id $lbr \
      --name $PUBLIC_LBR_PROV_LISTENER_DISPLAY_NAME \
      --port $PUBLIC_LBR_SSL_PORT \
      --protocol HTTP \
      --ssl-certificate-name $PUBLIC_LBR_CERTIFICATE_NAME \
      --hostname-names '[\"$PUBLIC_LBR_PROV_DISPLAY_NAME\"]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the pubic / internal load balancer log group
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$LBR_LOG_GROUP_NAME' Load Balancer Log Group..."
    ocid=$(oci logging log-group list --region $REGION --compartment-id $COMPARTMENT_ID --display-name $LBR_LOG_GROUP_NAME \
        --query 'data[0].id' --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Log Group '$LBR_LOG_GROUP_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    cmd="oci logging log-group create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --display-name $LBR_LOG_GROUP_NAME \
      --description \"The log group for load balancer logs\" \
      --wait-for-state SUCCEEDED \
      --wait-for-state FAILED" 
    execute "$cmd"
    print_msg end
  fi

  lgid=$(cat $RESOURCE_OCID_FILE | grep $LBR_LOG_GROUP_NAME | cut -d: -f2)

  # Create the public load balancer access log
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Enabling the '$PUBLIC_LBR_ACCESS_LOG_DISPLAY_NAME' Access Log..."
    cmd="oci logging log create \
      --region $REGION \
      --display-name $PUBLIC_LBR_ACCESS_LOG_DISPLAY_NAME \
      --log-group-id $lgid \
      --log-type SERVICE \
      --configuration '{\"source\": {\"category\": \"access\",\"resource\": \"$lbr\",\"service\":
         \"loadbalancer\",\"sourceType\": \"OCISERVICE\"}}'"
    execute "$cmd"
    print_msg end
  fi
  
  # Create the public load balancer error log
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Enabling the '$PUBLIC_LBR_ERROR_LOG_DISPLAY_NAME' Error Log..."
    cmd="oci logging log create \
      --region $REGION \
      --display-name $PUBLIC_LBR_ERROR_LOG_DISPLAY_NAME \
      --log-group-id $lgid \
      --log-type SERVICE \
      --configuration '{\"source\": {\"category\": \"error\",\"resource\": \"$lbr\",\"service\": 
         \"loadbalancer\",\"sourceType\": \"OCISERVICE\"}}'"
    execute "$cmd"
    print_msg end
  fi
}

# Create the resources for the VCN, including
# - VCN
# - internet gateway
# - NAT gateway
# - service gateway
# - private route table
# - OKE api security list
# - OKE node security list
# - OKE api subnet
# - OKE node subnet
# - OKE service subnet
createVCN() {
  # Create the VCN
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$VCN_DISPLAY_NAME' VCN..."
    ocid=$(oci network vcn list --region $REGION --compartment-id $COMPARTMENT_ID \
         --display-name $VCN_DISPLAY_NAME --query 'data[0].id' --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the VCN '$VCN_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    cmd="oci network vcn create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --cidr-blocks '[\"$VCN_SUBNET_CIDR\"]' \
      --display-name $VCN_DISPLAY_NAME \
      --dns-label $VCN_DNS_LABEL \
      --wait-for-state AVAILABLE"
    execute "$cmd"
    print_msg end
  fi
    
  VCN_ID=$(cat $RESOURCE_OCID_FILE | grep $VCN_DISPLAY_NAME | cut -d: -f2)
      
  # Create the internet gateway
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$VCN_INTERNET_GATEWAY_DISPLAY_NAME' Internet Gateway..."
    cmd="oci network internet-gateway create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --is-enabled true \
      --display-name $VCN_INTERNET_GATEWAY_DISPLAY_NAME \
      --wait-for-state AVAILABLE"
    execute "$cmd"
    print_msg end
  fi

  # Create the NAT gateway
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$VCN_NAT_GATEWAY_DISPLAY_NAME' NAT Gateway..."
    cmd="oci network nat-gateway create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $VCN_NAT_GATEWAY_DISPLAY_NAME \
      --wait-for-state AVAILABLE"
      execute "$cmd"
    print_msg end
  fi

  # Create the service gateway
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$VCN_SERVICE_GATEWAY_DISPLAY_NAME' Service Gateway..."
    slid=$(oci network service list --query "data[?contains("name",'All')].{ocid:id}" | jq -r '.[].ocid')
    cmd="oci network service-gateway create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --services '[{\"serviceId\": \"$slid\"}]'
      --display-name $VCN_SERVICE_GATEWAY_DISPLAY_NAME \
      --wait-for-state AVAILABLE"
      execute "$cmd"
    print_msg end
  fi

  # Update the default route table to add the internet gateway
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Updating the 'Default Route Table for $VCN_DISPLAY_NAME' Route Table..."
    rtid=$(oci network route-table list --region $REGION --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID \
      --query "data[?contains(\"display-name\",'$VCN_DISPLAY_NAME')].{ocid:id}" | jq -r '.[].ocid')
    igw=$(cat $RESOURCE_OCID_FILE | grep $VCN_INTERNET_GATEWAY_DISPLAY_NAME | cut -d: -f2)
    cmd="oci network route-table update \
      --region $REGION \
      --rt-id $rtid \
      --display-name $VCN_PUBLIC_ROUTE_TABLE_DISPLAY_NAME \
      --route-rules '[{\"cidrBlock\":\"0.0.0.0/0\",\"networkEntityId\":\"$igw\",\"description\":
        \"traffic to/from internet\"}]' \
      --force"
    execute "$cmd"
    print_msg end
  fi

  # Create the private route table
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$VCN_PRIVATE_ROUTE_TABLE_DISPLAY_NAME' Route Table..."
    sgw=$(cat $RESOURCE_OCID_FILE | grep $VCN_SERVICE_GATEWAY_DISPLAY_NAME | cut -d: -f2)
    ngw=$(cat $RESOURCE_OCID_FILE | grep $VCN_NAT_GATEWAY_DISPLAY_NAME | cut -d: -f2)
    dest=$(oci network service-gateway list --region $REGION --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID \
           --query 'data[0].services[0]."service-name"' --raw-output)
    dest1="${dest// /-}"
    dest=`echo "${dest1}" | tr '[A-Z]' '[a-z]'`
    cmd="oci network route-table create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $VCN_PRIVATE_ROUTE_TABLE_DISPLAY_NAME \
      --route-rules '[{\"destination\": \"$dest\", \"destinationType\": \"SERVICE_CIDR_BLOCK\",
        \"networkEntityId\": \"$sgw\", \"description\": \"traffic to OCI services\"},
        {\"destination\": \"0.0.0.0/0\", \"destinationType\": \"CIDR_BLOCK\",
        \"networkEntityId\": \"$ngw\", \"description\": \"traffic to the internet\"}]' \
        --wait-for-state AVAILABLE"
    execute "$cmd"
    print_msg end
  fi

  # Create the OKE api security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$OKE_API_SECLIST_DISPLAY_NAME' Security List..."
    slid=$(oci network service list --query "data[?contains("name",'All')].{cidr:\"cidr-block\"}" | jq -r '.[].cidr')
    cmd="oci network security-list create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $OKE_API_SECLIST_DISPLAY_NAME \
      --egress-security-rules \
        '[{\"destination\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false,
         \"description\": \"Allow traffic to worker nodes\"},
         {\"destination\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"1\", \"isStateless\": false,
         \"icmpOptions\": {\"code\": 4, \"type\": 3}, \"description\": \"Allow traffic to worker nodes\"},
         {\"destination\": \"$slid\", \"destinationType\": \"SERVICE_CIDR_BLOCK\", \"protocol\": \"6\",
         \"isStateless\": false, \"tcpOptions\": {\"destinationPortRange\": {\"min\": 443, \"max\": 443},
         \"sourcePortRange\": null}, \"description\": \"Allow Kubernetes Control Plane to communicate with OKE\"}]'
      --ingress-security-rules \
        '[{\"source\": \"0.0.0.0/0\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": 6443, \"max\": 6443}, \"sourcePortRange\": null},
         \"description\": \"External access to Kubernetes API endpoint\"},
         {\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": 6443, \"max\": 6443}, \"sourcePortRange\": null},
         \"description\": \"Kubernetes worker to Kubernetes API endpoint communication\"},
         {\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": 12250, \"max\": 12250}, \"sourcePortRange\": null},
         \"description\": \"Kubernetes worker to control plane communication\"},
         {\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"1\", \"isStateless\": false, 
         \"icmpOptions\": {\"code\": 4, \"type\": 3}, \"description\": \"Path discovery\"}]' \
      --wait-for-state AVAILABLE"
    execute "$cmd"
    print_msg end
  fi

  # Create the OKE node security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$OKE_NODE_SECLIST_DISPLAY_NAME' Security List..."
    slid=$(oci network service list --query "data[?contains("name",'All')].{cidr:\"cidr-block\"}" | jq -r '.[].cidr')
    cmd="oci network security-list create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $OKE_NODE_SECLIST_DISPLAY_NAME \
      --egress-security-rules \
        '[{\"destination\": \"$OKE_NODE_SUBNET_CIDR\", \"isStateless\": false, \"protocol\": \"all\", 
         \"tcpOptions\": null, \"description\": \"Allow pods on one worker node to communicate with
         pods on other worker nodes\"},
         {\"destination\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": 6443, \"max\": 6443}, \"sourcePortRange\": null},
         \"description\": \"Access to Kubernetes API Endpoint\"},
         {\"destination\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": 12250, \"max\": 12250}, \"sourcePortRange\": null},
         \"description\": \"Kubernetes worker to control plane communication\"},
         {\"destination\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"1\", \"isStateless\": false,
         \"icmpOptions\": {\"code\": 4, \"type\": 3}, \"description\": \"Path discovery\"},
         {\"destination\": \"$slid\", \"destinationType\": \"SERVICE_CIDR_BLOCK\", \"protocol\": \"6\",
         \"isStateless\": false, \"tcpOptions\": {\"destinationPortRange\": {\"min\": 443, \"max\": 443},
         \"sourcePortRange\": null}, \"description\": \"Allow nodes to communicate with OKE to ensure correct
         start-up and continued functioning\"},
         {\"destination\": \"0.0.0.0/0\", \"protocol\": \"1\", \"isStateless\": false,
         \"icmpOptions\": {\"code\": 4, \"type\": 3}, \"description\": \"ICMP Access from Kubernetes Control Plane\"},
        {\"destination\": \"0.0.0.0/0\", \"isStateless\": false, \"protocol\": \"all\", 
         \"tcpOptions\": null, \"description\": \"Worker Nodes access to Internet\"}]' \
      --ingress-security-rules \
        '[{\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"isStateless\": false, \"tcpOptions\": null, \"protocol\": \"all\", 
         \"description\": \"Allow pods on one worker node to communicate with pods on other worker nodes\"},
         {\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"1\", \"isStateless\": false,
         \"icmpOptions\": {\"code\": 4, \"type\": 3}, \"description\": \"Path discovery\"},
         {\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"description\": \"TCP access from Kubernetes Control Plane\"},
         {\"source\": \"0.0.0.0/0\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": 22, \"max\": 22}, \"sourcePortRange\": null},
         \"description\": \"Inbound SSH traffic to worker nodes\"}]' \
      --wait-for-state AVAILABLE"
    execute "$cmd"
    print_msg end
  fi

  # Update the default security list to be the OKE servicelb security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Updating the 'Default' Security List..."
    sl=$(oci network security-list list --region $REGION --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID \
    --query "data[?contains(\"display-name\", 'Default Security List')].{ocid:id}" | jq -r '.[].ocid')
    cmd="oci network security-list update \
    --security-list-id $sl\
    --display-name $OKE_SVCLBR_SECLIST_DISPLAY_NAME \
    --egress-security-rules '[]' \
    --ingress-security-rules '[]' \
    --force"
    execute "$cmd"
    print_msg end
  fi

  # Create the OKE api subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$OKE_API_SUBNET_DISPLAY_NAME' Subnet..."
    sl=$(cat $RESOURCE_OCID_FILE | grep $OKE_API_SECLIST_DISPLAY_NAME | cut -d: -f2)
    rt=$(cat $RESOURCE_OCID_FILE | grep $VCN_PRIVATE_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2)
    cmd="oci network subnet create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $OKE_API_SUBNET_DISPLAY_NAME \
      --dns-label $OKE_API_DNS_LABEL \
      --cidr-block $OKE_API_SUBNET_CIDR \
      --prohibit-public-ip-on-vnic true \
      --route-table-id $rt \
      --security-list-ids '[\"$sl\"]' \
      --wait-for-state AVAILABLE"
    execute "$cmd"
    print_msg end
  fi

  # Create the OKE node subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$OKE_NODE_SUBNET_DISPLAY_NAME' Subnet..."
    sl=$(cat $RESOURCE_OCID_FILE | grep $OKE_NODE_SECLIST_DISPLAY_NAME | cut -d: -f2)
    rt=$(cat $RESOURCE_OCID_FILE | grep $VCN_PRIVATE_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2)
    cmd="oci network subnet create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $OKE_NODE_SUBNET_DISPLAY_NAME \
      --dns-label $OKE_NODE_DNS_LABEL \
      --cidr-block $OKE_NODE_SUBNET_CIDR \
      --prohibit-public-ip-on-vnic true \
      --route-table-id $rt \
      --security-list-ids '[\"$sl\"]' \
      --wait-for-state AVAILABLE"
    execute "$cmd"
    print_msg end
  fi

  # Create the OKE svclb subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$OKE_SVCLB_SUBNET_DISPLAY_NAME' Subnet..."
    sl=$(oci network security-list list --region $REGION --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID \
    --query "data[?contains(\"display-name\", '$OKE_SVCLBR_SECLIST_DISPLAY_NAME')].{ocid:id}" | jq -r '.[].ocid')
    rt=$(oci network route-table list --region $REGION --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID \
      --query "data[?contains(\"display-name\",'$VCN_PUBLIC_ROUTE_TABLE_DISPLAY_NAME')].{ocid:id}" | jq -r '.[].ocid')
    cmd="oci network subnet create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $OKE_SVCLB_SUBNET_DISPLAY_NAME \
      --dns-label $OKE_SVCLBR_DNS_LABEL \
      --cidr-block $OKE_SVCLB_SUBNET_CIDR \
      --prohibit-public-ip-on-vnic false \
      --route-table-id $rt \
      --security-list-ids '[\"$sl\"]' \
      --wait-for-state AVAILABLE"
    execute "$cmd"
    print_msg end
  fi

  okeSubnetId=$(cat $RESOURCE_OCID_FILE | grep $OKE_NODE_SUBNET_DISPLAY_NAME | cut -d: -f2)
}

# Create the resources for the web hosts, including
# - public webhost security list
# - OHS security list
# - webhost route table
# - webhost subnet
# - webhost1 / webhost2 instances
createWebHosts() {
  # Create the Web public security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$WEB_PUBLIC_SECLIST_DISPLAY_NAME'  Security List..."
    cmd="oci network security-list create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $WEB_PUBLIC_SECLIST_DISPLAY_NAME \
      --egress-security-rules \
        '[{\"destination\": \"0.0.0.0/0\", \"protocol\": \"all\", \"isStateless\": false}]' \
      --ingress-security-rules \
        '[{\"source\": \"0.0.0.0/0\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": 22, \"max\": 22}, \"sourcePortRange\": null}},
  	{\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": $PUBLIC_LBR_NON_SSL_PORT, \"max\": $PUBLIC_LBR_NON_SSL_PORT},
           \"sourcePortRange\": null}},
  	{\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": $PUBLIC_LBR_SSL_PORT, \"max\": $PUBLIC_LBR_SSL_PORT}, 
           \"sourcePortRange\": null}},
  	{\"source\": \"0.0.0.0/0\", \"protocol\": \"1\", \"isStateless\": false, 
  	 \"icmpOptions\": {\"code\": 4, \"type\": 3}},
  	{\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"1\", \"isStateless\": false},
  	{\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": 111, \"max\": 111} , \"sourcePortRange\": null}},
  	{\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": 2049, \"max\": 2050} , \"sourcePortRange\": null}},
  	{\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"17\", \"isStateless\": false, 
  	 \"udpOptions\": {\"destinationPortRange\": {\"min\": 111, \"max\": 111} , \"sourcePortRange\": null}},
  	{\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"17\", \"isStateless\": false, 
  	 \"udpOptions\": {\"destinationPortRange\": {\"min\": 2048, \"max\": 2048} , \"sourcePortRange\": null}},
  	{\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OHS_NON_SSL_PORT, \"max\": $OHS_NON_SSL_PORT}, 
           \"sourcePortRange\": null}},
  	{\"source\": \"$BASTION_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OHS_NON_SSL_PORT, \"max\": $OHS_NON_SSL_PORT}, 
           \"sourcePortRange\": null}},
  	{\"source\": \"$LBR1_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OHS_NON_SSL_PORT, \"max\": $OHS_NON_SSL_PORT}, 
           \"sourcePortRange\": null}},
  	{\"source\": \"$LBR2_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OHS_NON_SSL_PORT, \"max\": $OHS_NON_SSL_PORT}, 
           \"sourcePortRange\": null}},
  	{\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": $PUBLIC_LBR_SSL_PORT, \"max\": $PUBLIC_LBR_SSL_PORT}, 
           \"sourcePortRange\": null}},
  	{\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": $PUBLIC_LBR_NON_SSL_PORT, \"max\": $PUBLIC_LBR_NON_SSL_PORT}, 
           \"sourcePortRange\": null}},
  	{\"source\": \"$OKE_NODE_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
  	 \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OHS_NON_SSL_PORT, \"max\": $OHS_NON_SSL_PORT}, 
           \"sourcePortRange\": null}}]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the OHS security list
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$OHS_SECLIST_DISPLAY_NAME' Security List..."
    cmd="oci network security-list create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $OHS_SECLIST_DISPLAY_NAME \
      --egress-security-rules \
        '[{\"destination\": \"0.0.0.0/0\", \"protocol\": \"all\", \"isStateless\": false}]' \
      --ingress-security-rules \
      '[{\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OAM_ADMIN_SERVICE_PORT, \"max\": $OAM_ADMIN_SERVICE_PORT}, 
         \"sourcePortRange\": null}, \"description\": \"OAM Administration Server Kubernetes Service Port\"},
        {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OAM_POLICY_SERVICE_PORT, \"max\": $OAM_POLICY_SERVICE_PORT}, 
         \"sourcePortRange\": null}, \"description\": \"OAM Policy Manager Kubernetes Service Port\"},
        {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OAM_SERVER_SERVICE_PORT, \"max\": $OAM_SERVER_SERVICE_PORT}, 
         \"sourcePortRange\": null}, \"description\": \"OAM Server Kubernetes Service Port\"},
        {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OIG_ADMIN_SERVICE_PORT, \"max\": $OIG_ADMIN_SERVICE_PORT}, 
         \"sourcePortRange\": null}, \"description\": \"OIM Administration Server Kubernetes Service Port\"},
        {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OIG_SERVER_SERVICE_PORT, \"max\": $OIG_SERVER_SERVICE_PORT}, 
         \"sourcePortRange\": null}, \"description\": \"OIM Server Kubernetes Service Port\"},
        {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": $SOA_SERVER_SERICE_PORT, \"max\": $SOA_SERVER_SERICE_PORT}, 
         \"sourcePortRange\": null}, \"description\": \"SOA Server Kubernetes Service Port\"},
        {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": $OUDSM_SERVER_SERVICE_PORT, \"max\": $OUDSM_SERVER_SERVICE_PORT}, 
         \"sourcePortRange\": null}, \"description\": \"OUDSM Server Kubernetes Service Port\"},
        {\"source\": \"$WEB_SUBNET_CIDR\", \"protocol\": \"6\", \"isStateless\": false, 
         \"tcpOptions\": {\"destinationPortRange\": {\"min\": $INGRESS_SERVICE_PORT, \"max\": $INGRESS_SERVICE_PORT}, 
         \"sourcePortRange\": null}, \"description\": \"Nginx Ingress Controller\"}]'"
    execute "$cmd"
    print_msg end
  fi

  # Add the OHS seclist to the k8n Node Subnet
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Adding the '$OHS_SECLIST_DISPLAY_NAME' to the Kubernetes Node Subnet..."
    sl=$(oci network subnet get --region $REGION --subnet-id $okeSubnetId --query 'data."security-list-ids"')
    ohssl=$(cat $RESOURCE_OCID_FILE | grep $OHS_SECLIST_DISPLAY_NAME | cut -d: -f2)
    sl="'${sl/\"/\"$ohssl\",\"}'"
    cmd="oci network subnet update \
      --region $REGION \
      --subnet-id $okeSubnetId \
      --force \
      --security-list-ids $sl"
    execute "$cmd"
    print_msg end
  fi


  # Create the Web route table
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$WEB_ROUTE_TABLE_DISPLAY_NAME' Route Table..."
    sgw=$(cat $RESOURCE_OCID_FILE | grep $VCN_SERVICE_GATEWAY_DISPLAY_NAME | cut -d: -f2)
    dest=$(oci network service-gateway list --region $REGION --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID \
           --query 'data[0].services[0]."service-name"' --raw-output)
    dest1="${dest// /-}"
    dest=`echo "${dest1}" | tr '[A-Z]' '[a-z]'`
    cmd="oci network route-table create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $WEB_ROUTE_TABLE_DISPLAY_NAME \
      --route-rules '[{\"destination\": \"$dest\", \"destinationType\": \"SERVICE_CIDR_BLOCK\", 
                       \"networkEntityId\": \"$sgw\"}]'" 
    execute "$cmd"
    print_msg end
  fi

  # Create the Subnet for the Web Nodes
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$WEB_SUBNET_DISPLAY_NAME' Subnet..."
    sl=$(cat $RESOURCE_OCID_FILE | grep $WEB_PUBLIC_SECLIST_DISPLAY_NAME | cut -d: -f2)
    rt=$(cat $RESOURCE_OCID_FILE | grep $WEB_ROUTE_TABLE_DISPLAY_NAME | cut -d: -f2)
    cmd="oci network subnet create \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --vcn-id $VCN_ID \
      --display-name $WEB_SUBNET_DISPLAY_NAME \
      --prohibit-public-ip-on-vnic $WEB_PROHIBIT_PUBLIC_IP \
      --dns-label $WEB_DNS_LABEL \
      --cidr-block $WEB_SUBNET_CIDR \
      --route-table-id $rt \
      --security-list-ids '[\"$sl\"]'"
    execute "$cmd"
    print_msg end
  fi

  # Create the webhsot1 instance
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$WEBHOST1_DISPLAY_NAME' Compute Instance..."
    ocid=$(oci compute instance list --region $REGION --compartment-id $COMPARTMENT_ID --display-name $WEBHOST1_DISPLAY_NAME \
      --query 'data[0].id' --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Host '$WEBHOST1_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    sn=$(cat $RESOURCE_OCID_FILE | grep $WEB_SUBNET_DISPLAY_NAME | cut -d: -f2)
    im=$(oci compute image list --region $REGION --compartment-id $COMPARTMENT_ID --display-name $WEB_IMAGE_NAME \
         --query 'data[0].id' --raw-output)
    if [[ ! "$im" =~ "ocid" ]]; then
      print_msg screen "Error, the OS image '$WEB_IMAGE_NAME' is not present in the system."
      exit 1
    fi
    if [[ -n "${WEBHOST1_SHAPE_CONFIG}" ]]; then
      wh1shapeConfig="--shape-config ${WEBHOST1_SHAPE_CONFIG}"
    else
      wh1shapeConfig=""
    fi
    cmd="oci compute instance launch \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --display-name $WEBHOST1_DISPLAY_NAME \
      --availability-domain ${!WEBHOST1_AD} \
      --shape $WEBHOST1_SHAPE $wh1shapeConfig \
      --subnet-id $sn \
      --assign-public-ip $WEBHOST1_PUBLIC_IP \
      --hostname-label $WEBHOST1_HOSTNAME_LABEL \
      --image-id $im \
      --ssh-authorized-keys-file $SSH_PUB_KEYFILE"
    execute "$cmd"
    print_msg end
  fi
    
  # Create the webhost2 instance
  STEPNO=$((STEPNO+1))
  if [[ $STEPNO -gt $PROGRESS ]]; then
    print_msg begin "Creating the '$WEBHOST2_DISPLAY_NAME' Compute Instance..."
    ocid=$(oci compute instance list --region $REGION --compartment-id $COMPARTMENT_ID --display-name $WEBHOST2_DISPLAY_NAME \
      --query 'data[0].id' --raw-output 2>/dev/null) 
    if [[ "$ocid" =~ "ocid" ]]; then
      print_msg screen "Error, the Host '$WEBHOST2_DISPLAY_NAME' already exists in compartment $COMPARTMENT_NAME"
      exit 1
    fi
    sn=$(cat $RESOURCE_OCID_FILE | grep $WEB_SUBNET_DISPLAY_NAME | cut -d: -f2)
    im=$(oci compute image list --region $REGION --compartment-id $COMPARTMENT_ID --display-name $WEB_IMAGE_NAME \
         --query 'data[0].id' --raw-output)
    if [[ ! "$im" =~ "ocid" ]]; then
      print_msg screen "Error, the OS image '$WEB_IMAGE_NAME' is not present in the system."
      exit 1
    fi
    if [[ -n "${WEBHOST2_SHAPE_CONFIG}" ]]; then
      wh2shapeConfig="--shape-config ${WEBHOST2_SHAPE_CONFIG}"
    else 
      wh2shapeConfig=""
    fi
    cmd="oci compute instance launch \
      --region $REGION \
      --compartment-id $COMPARTMENT_ID \
      --display-name $WEBHOST2_DISPLAY_NAME \
      --availability-domain ${!WEBHOST2_AD} \
      --shape $WEBHOST2_SHAPE $wh2shapeConfig \
      --subnet-id $sn \
      --assign-public-ip $WEBHOST2_PUBLIC_IP \
      --hostname-label $WEBHOST2_DISPLAY_NAME \
      --image-id $im \
      --ssh-authorized-keys-file $SSH_PUB_KEYFILE"
    execute "$cmd"
    print_msg end
  fi

  webSubnetId=$(cat $RESOURCE_OCID_FILE | grep $WEB_SUBNET_DISPLAY_NAME | cut -d: -f2)
}
