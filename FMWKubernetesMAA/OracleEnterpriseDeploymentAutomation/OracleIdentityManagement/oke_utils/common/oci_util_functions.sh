#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of common functions used by the provision_oke.sh and delete_oke.sh scripts.
# 
#
# Dependencies: OS 'jq' command
#               
#
# Usage: invoked automatically as needed, not directly
#
# Common Environment Variables
#

# Print a message to the screen, logfile, or timings file.
# Inputs - $1 - write beginning or ending messages
#          $2 - the message to write to the log file
print_msg() {
  OLD_IFS="$IFS"
  IFS=
  if [[ "$1" == "begin" ]]; then
    msg=$2
    echo -n "   Step $STEPNO : $msg"
    echo $msg >> $LOGDIR/$LOGFILE
  elif [[ "$1" == "end" ]]; then
    echo "Completed"
    echo "===========" >> $LOGDIR/$LOGFILE
    time_taken=$((ET-ST))
    ostype="$(uname -s)"
    if [[ "$ostype" == "Darwin" ]]; then
      step_time=$(gdate -ud "@$time_taken" +' %H hours %M minutes %S seconds')
    else
      step_time=$(date -ud "@$time_taken" +' %H hours %M minutes %S seconds')
    fi
    echo -e "Step $STEPNO : Time taken to execute step '$msg': $step_time" >> $LOGDIR/timings.log
  else
    echo -e $2
    echo -e $2 >> $LOGDIR/$LOGFILE
  fi
  IFS=$OLD_IFS
}

# Execute a command passed in as parameter $1 echoing the command and its output
# to the logfile and adding the resulting ocid value to the ocid resource file.
execute() {
  echo Current STEPNO: $STEPNO  >> $LOGDIR/$LOGFILE
  echo $1 >> $LOGDIR/$LOGFILE
  cmd=$1
  ST=`date +%s`
  output=$(eval $cmd 2>&1)
  mychk=$?
  ET=`date +%s`

  if [[ "$output" =~ "debug flag" ]] ||
     [[ "$output" =~ "Usage:" ]] ||
     [[ "$mychk" != "0" ]] &&
     [[ ! "$cmd" =~ "oci db system terminate" ]] &&
     [[ ! "$cmd" =~ "dbca" ]] &&
     [[ ! "$cmd" =~ "start service" ]] &&
     [[ ! "$cmd" =~ "yum install" ]]; then
    echo $output >> $LOGDIR/$LOGFILE
    echo -e "\n\nThe following command failed and script execution has stopped:"
    echo $cmd
    exit 1
  fi
  
  if [[ $cmd =~ "ssh " ]] || 
     [[ $cmd =~ "scp " ]] ||
     [[ $cmd =~ "fs export create" ]] ||
     [[ $cmd =~ "backend-set create" ]] ||
     [[ $cmd =~ "backend create" ]] ||
     [[ $cmd =~ "certificate create" ]] ||
     [[ $cmd =~ "hostname create" ]] ||
     [[ $cmd =~ "listener create" ]] ||
     [[ $cmd =~ "log create" ]] ||
     [[ $cmd =~ "record zone patch" ]] ||
     [[ $cmd =~ "pluggable-database create" ]] ||
     [[ $cmd =~ "dbca" ]]; then
       PROGRESS=$((PROGRESS+1))
       echo $PROGRESS > $LOGDIR/progressfile
       echo $output >> $LOGDIR/$LOGFILE
       echo "Status=$mychk" >> $LOGDIR/$LOGFILE
       return;
  fi
      
  if [[ $cmd =~ "create" ]] || [[ $cmd =~ "update" ]] || 
     [[ $cmd =~ "launch" ]] || [[ $cmd =~ "patch" ]]; then 
    output=$(echo $output | sed 's/^[^{]*{/{/')
    name=""
    ocid=""
    if [[ "$cmd" =~ "oci ce cluster create" ]]; then
      name=$OKE_CLUSTER_DISPLAY_NAME
      ocid=$(jq -r '.data.resources[].identifier' <<< $output)
    elif [[ "$cmd" =~ "oci ce node-pool create" ]]; then
      name=$OKE_NODE_POOL_DISPLAY_NAME
      ocid=$(jq -r '.data.resources[] | select(."entity-type"=="nodepool").identifier' <<< $output)
    elif [[ "$cmd" =~ "oci logging log-group create" ]]; then
      name=$LBR_LOG_GROUP_NAME
      ocid=$(jq -r '.data.resources[] | select(."entity-type"=="loggroup").identifier' <<< $output)
    elif [[ "$cmd" =~ "oci nlb network-load-balancer create" ]]; then
      name=$K8_LBR_DISPLAY_NAME
      ocid=$(jq -r '.data.resources[] | select(."entity-type"=="NetworkLoadBalancer").identifier' <<< $output)
    elif [[ "$cmd" =~ "oci dns zone create" ]]; then
      name=$DNS_DOMAIN_NAME
      ocid=$(jq -r '.data.id' <<< $output)
    else
      name=$(jq -r '.data."display-name"' <<< $output)
      ocid=$(jq -r '.data.id' <<< $output)
    fi
    if ! grep -q "$ocid" "$RESOURCE_OCID_FILE"; then 
      if [[ -n "$name" ]] && [[ -n "$ocid" ]]; then
        echo $name:$ocid >> $RESOURCE_OCID_FILE
      else
        echo "Unable to determine the name:OCID of the most recently executed command, exiting"
        exit 1
      fi
    fi
    PROGRESS=$((PROGRESS+1))
    echo $PROGRESS > $LOGDIR/progressfile
    echo $output >> $LOGDIR/$LOGFILE
    echo "Status=$mychk" >> $LOGDIR/$LOGFILE
  fi
}

# Simple validation that the configuration file has been updated with end-user data
validateVariables() {
  if [[ "$WORKDIR" =~ "your-workdir" ]]; then
    echo -e "\nThe 'WORKDIR' variable is not configured, please set it and re-run the script"
    exit 1
  fi
  if [[ "$REGION" =~ "your-region" ]]; then
    echo -e "\nThe 'REGION' variable is not configured, please set it and re-run the script"
    exit 1
  fi
  if [[ "$COMPARTMENT_NAME" =~ "your-compartment-name" ]]; then
    echo -e "\nThe 'COMPARTMENT_NAME' variable is not configured, please set it and re-run the script"
    exit 1
  fi
  if [[ "$VCN_DISPLAY_NAME" =~ "your-vcn-name" ]]; then
    echo -e "\nThe 'VCN_DSISPLAY_NAME' variable is not configured, please set it and re-run the script"
    exit 1
  fi
  if [[ "$SSH_PUB_KEYFILE" =~ "path-to" ]]; then
    echo -e "\nThe 'SSH_PUB_KEYFILE' variable is not configured, please set it and re-run the script"
    exit 1
  fi
  if [[ ! -s "$SSH_PUB_KEYFILE" ]]; then
    echo -e "\nThe 'SSH_PUB_KEYFILE' does not exist or is empty, please correct the value and re-run the script"
    exit 1
  fi
  if [[ "$SSH_ID_KEYFILE" =~ "path-to" ]]; then
    echo -e "\nThe 'SSH_ID_KEYFILE' variable is not configured, please set it and re-run the script"
    exit 1
  fi
  if [[ ! -s "$SSH_ID_KEYFILE" ]]; then
    echo -e "\nThe 'SSH_ID_KEYFILE' does not exist or is empty, please correct the value and re-run the script"
    exit 1
  fi
}

# Get a list of the availability domains accessible for the current users region
get_ad_list() {
  ad=$(oci iam availability-domain list --region $REGION | jq -r '.data[].name')
  ADCNT=0;
  for i in $ad
  do
    case "$i" in
      *-1 ) ad1=$i;;
      *-2 ) ad2=$i;;
      *-3 ) ad3=$i;;
    esac
    ADCNT=$((ADCNT+1))
  done
}

# Convert the given compartment name from the configuration file to its ocid value
get_compartment_ocid() {
  cmpt=$(oci iam compartment list --compartment-id-in-subtree true --all --name $COMPARTMENT_NAME \
   --query 'data[0].{ocid:id, created:"time-created"}')
  if [[ "$cmpt" =~ "ocid" ]]; then
    COMPARTMENT_ID=$(jq -r '.ocid' <<< $cmpt)
    COMPARTMENT_CREATED=$(jq -r '.created' <<< $cmpt)
    COMPARTMENT_CREATED=$(sed 's/T/ @/' <<< $COMPARTMENT_CREATED)
  else
    echo -e "Exiting, No compartment named '$COMPARTMENT_NAME' found"
    exit 1
  fi 
}

# Update the progress file with the successful completion of the current step
get_progress() {
  if [[ -f $LOGDIR/progressfile ]]; then
    cat $LOGDIR/progressfile
  else
    echo 0
  fi
}

# Format the shape parameters from the config file to a useable format for the oci command
formatShapeConfig() {
  BASTION_SHAPE_CONFIG=$(tr -d ' ' <<< "$BASTION_SHAPE_CONFIG")
  OKE_NODE_POOL_SHAPE_CONFIG=$(tr -d ' ' <<< "$OKE_NODE_POOL_SHAPE_CONFIG")
  PUBLIC_LBR_SHAPE_DETAILS=$(tr -d ' ' <<< "$PUBLIC_LBR_SHAPE_DETAILS")
  INT_LBR_SHAPE_DETAILS=$(tr -d ' ' <<< "$INT_LBR_SHAPE_DETAILS")
  WEBHOST1_SHAPE_CONFIG=$(tr -d ' ' <<< "$WEBHOST1_SHAPE_CONFIG")
  WEBHOST2_SHAPE_CONFIG=$(tr -d ' ' <<< "$WEBHOST2_SHAPE_CONFIG")
}

# Retrieve the IP address of the bastion host given its ocid
get_bastion_ip() {
  id=$(cat $RESOURCE_OCID_FILE | grep $BASTION_INSTANCE_DISPLAY_NAME: | cut -d: -f2)
  BASTIONIP=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $id \
          --query 'data[0]."public-ip"' --raw-output)
  if [[ "$?" != "0" ]]; then
    print_msg screen "Failed to obtain the IP address for '$BASTION_INSTANCE_DISPLAY_NAME'"
    exit 1
  fi
}

# Retrieve the IP addresses of the webhosts given the ocid
get_webhost_ip() {
  WEBHOST1ID=$(cat $RESOURCE_OCID_FILE | grep $WEBHOST1_DISPLAY_NAME: | cut -d: -f2)
  WEBHOST1IP=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $WEBHOST1ID \
          --query 'data[0]."private-ip"' --raw-output)
  if [[ "$?" != "0" ]]; then
     print_msg screen "Failed to obtain the IP address for '$WEBHOST1_DISPLAY_NAME'"
    exit 1
  fi
   
  WEBHOST2ID=$(cat $RESOURCE_OCID_FILE | grep $WEBHOST2_DISPLAY_NAME: | cut -d: -f2)
  WEBHOST2IP=$(oci compute instance list-vnics --region $REGION --compartment-id $COMPARTMENT_ID --instance-id $WEBHOST2ID \
          --query 'data[0]."private-ip"' --raw-output)
  if [[ "$?" != "0" ]]; then
    print_msg screen "Failed to obtain the IP address for '$WEBHOST2_DISPLAY_NAME'"
    exit 1
  fi
}

# Retrieve the IP address of one of the RAC database nodes to use for configuring the DB
get_database_ip() {
  DBSYSTEMID=$(cat $RESOURCE_OCID_FILE | grep $DB_DISPLAY_NAME | cut -d: -f2)
  vnic=$(oci db system get --db-system-id $DBSYSTEMID --query 'data."scan-ip-ids"[0]' --raw-output)
  DBIP=$(oci network private-ip get --region $REGION --private-ip-id $vnic --query 'data."ip-address"' --raw-output)
}
