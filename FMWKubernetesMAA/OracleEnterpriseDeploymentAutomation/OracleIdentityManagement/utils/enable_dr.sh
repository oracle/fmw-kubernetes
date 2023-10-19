#!/bin/bash
# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of deploying Oracle Identity and Access Management, disaster recovery
#
# Dependencies: ./common/functions.sh
#               ./common/oud_functions.sh
#               ./common/oam_functions.sh
#               ./common/oig_functions.sh
#               ./common/oiri_functions.sh
#               ./common/oaa_functions.sh
#               ./common/ohs_functions.sh
#               ./responsefile/dr.rsp
#               ./templates/oig
#
# Usage: enable_dr.sh
#
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTDIR=$SCRIPTDIR/..

# Check for the existence of a responsefile.

if [ ! -e $SCRIPTDIR/responsefile/dr.rsp ]
then
   echo "Responsefile $SCRIPTDIR/responsefile/dr.rsp not found."
   exit 1
fi
if [ ! -e $SCRIPTDIR/responsefile/.drpwd ]
then
   echo "Password File $SCRIPTDIR/responsefile/.drpwd not found."
   exit 1
fi

. $SCRIPTDIR/responsefile/dr.rsp
. $SCRIPTDIR/responsefile/.drpwd
. $SCRIPTDIR/common/functions.sh

# Validate Product Type and setup Namespace accordingly.
#
product_type=$1
case "$product_type" in
   "oud")
       . $SCRIPTDIR/common/oud_functions.sh
       OPER_DIR=OracleUnifiedDirectory
       PRODUCTNS=$OUDNS
       ;;
   "oam")
       . $SCRIPTDIR/common/oam_functions.sh
       OPER_DIR=OracleAccessManagement
       PRODUCTNS=$OAMNS
       ;;
   "oig")
       . $SCRIPTDIR/common/oig_functions.sh
       OPER_DIR=OracleIdentityGovernance
       PRODUCTNS=$OIGNS
       ;;
   "oiri")
       . $SCRIPTDIR/common/oiri_functions.sh
       if [ ! "$DINGNS" = "$OIRINS" ]
       then
          PRODUCTNS="'$OIRINS $DINGNS'"
       else
          PRODUCTNS=$OIRINS
       fi
       ;;
   "oaa")
       . $SCRIPTDIR/common/oaa_functions.sh
       PRODUCTNS=$OAANS
       ;;
   "ohs")
       . $SCRIPTDIR/common/ohs_functions.sh
       ;;
   *)
       echo "Usage: enable_dr.sh oam|oig|oiri|oaa|ohs"
       exit 1
      ;;
esac

PRODUCT=${product_type^^}

TEMPLATE_DIR=$SCRIPTDIR/templates/$product_type

START_TIME=`date +%s`
WORKDIR=$LOCAL_WORKDIR/${PRODUCT}/DR
LOGDIR=$WORKDIR/logs

DR_ENABLED=DR_$PRODUCT
if [ "${!DR_ENABLED}" != "true" ] && [ "{!DR_ENABLED}" != "TRUE" ]
then
     echo "You have not requested $PRODUCT DR installation"
     exit 1
fi

echo 
echo -n "Enabling $PRODUCT Disaster Recovery - $DR_TYPE " 
date +"%a %d %b %Y %T" 
echo "--------------------------------------------------------------------" 
echo 


# If the MAA scripts are not being used, the program will delete files on the standby system, make user aware.
#
if [ "$DR_TYPE" = "STANDBY" ] && [ "$USE_MAA_SCRIPTS" = "false" ]
then
  echo "WARNING: CREATING A STANDBY SITE WILL REPLACE THE $PRODUCT WITH THE PRIMARY $PRODUCT."
  echo "TAKING A BACKUP IS HIGHLY RECOMMENDED."
  echo ""
fi

echo -n "You are requesting to set this site up as an $DR_TYPE $PRODUCT DR site proceed (y/n) ? "
read ANS

if [ ! "$ANS" = "y" ] &&  [ ! "$ANS" = "Y" ]
then
  echo "Operation Cancelled."
  exit
fi

echo 

create_local_workdir
create_logdir

echo -n "Enabling $PRODUCT Disaster Recovery - $DR_TYPE " >> $LOGDIR/timings.log
date +"%a %d %b %Y %T" >> $LOGDIR/timings.log
echo "----------------------------------------------------------------" >> $LOGDIR/timings.log

STEPNO=0
PROGRESS=$(get_progress)

if [ ! "$product_type" = "ohs" ]
then

   # If using MAA Scripts make sure they are available.
   # MAA scripts are not supported by OAA DR
   #
   if [ "$USE_MAA_SCRIPTS" = "true" ] && [ ! "$PRODUCT" = "OAA" ]
   then
      new_step
      if [ $STEPNO -gt $PROGRESS ]
      then
         download_maa_samples
         update_progress
      fi
   
      new_step
      if [ $STEPNO -gt $PROGRESS ]
      then
         print_msg "Create MAA Directory $WORKDIR/MAA"
         if [  -e $LOCAL_WORKDIR/MAA ]
         then
            echo "Already Exists."
         else
            mkdir -p $WORKDIR/MAA > /dev/null 2>&1
            print_status $?
         fi
         update_progress
      fi
   fi 

   # Create Persistent Volumes for the DR job.
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     create_dr_pvs $PRODUCT
     update_progress
   fi
   
   # Create namespace on DR system
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     create_namespace $DRNS
     update_progress
   fi
   
   # Create a Container Registry Secret if requested
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
      if [ "$CREATE_REGSECRET" = "true" ]
      then
         create_registry_secret $REGISTRY $REG_USER $REG_PWD $DRNS
      fi
      update_progress
   fi
   
   # Create Persistent Volume Claims for the DR Job PVs
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     create_dr_pvcs
     update_progress
    fi
   
   # DR jobs are controlled via a configmap, create that CM here.
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     create_dr_configmap
     update_progress
   fi
   
   # Copy the product specific DR shell script to the product Persistent Volume.
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     copy_dr_script
     update_progress
   fi
   
   if [ "$DR_TYPE" = "PRIMARY" ]
   then
     # Make a backup of the Kubeconfig files used by OIRI
     #
     if [ "$product_type" = "oiri" ] 
     then
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
           backup_k8_files
           update_progress
        fi
     fi
   fi
   
   # Create DR Job for if requested
   #
   
   CREATE_CRON_VAR=DR_CREATE_${PRODUCT}_JOB
   CREATE_CRON_JOB=${!CREATE_CRON_VAR}
   
   if [ "$CREATE_CRON_JOB" = "true" ]
   then
   
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
       create_dr_cronjob_files
       update_progress
     fi
   
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
       create_dr_cronjob
       update_progress
     fi
   
     # Stop automatic replication of PVs using the cronjob.  Initialisation will occur using a one-of job
     #
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
       suspend_cronjob $DRNS ${product_type}rsyncdr
       update_progress
     fi
   fi
   if  [ "$USE_MAA_SCRIPTS" = "false" ]
   then
      # Ensure any existing deployment on the standby system is stopped.
      #
      if [ "$DR_TYPE" = "STANDBY" ] 
      then
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          case "$PRODUCT" in
            "OAM") stop_domain $OAMNS $OAM_DOMAIN_NAME
                   ;;
            "OIG") stop_domain $OIGNS $OIG_DOMAIN_NAME
                   ;;
            "OIRI")
               stop_deployment $DINGNS
               stop_deployment $OIRINS
            ;;
            "OAA")
               stop_deployment $OAANS
            ;;
             esac
          update_progress
        fi
   
        # If you are not using the MAA scripts, you are using a mirrored install.   Delete the files that this install created.
        #
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          case "$PRODUCT" in
            "OAM") delete_oam_files
                   ;;
            "OIG") delete_oig_files
                   ;;
            "OIRI") delete_oiri_files
                   ;;
            "OAA") delete_oaa_files
                   ;;
          esac
          update_progress
        fi
      fi
   fi
   
   # Create a job to initialise the DR PVs from the Primary.  This is a one time operation.
   # if run on the primary it creates a backup and ships it to the standby.
   # if run on the standby it restores the backup.
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ]
   then
     initialise_dr
     update_progress
   fi
   if [ "$DR_TYPE" = "STANDBY" ] 
   then
      new_step
      if [ $STEPNO -gt $PROGRESS ]
      then
         RUNNING_POD=$(kubectl get pods -n $DRNS | grep ${product_type}-initial)
         POD_NAME=$(echo $RUNNING_POD | awk '{print $1}')
         POD_STATUS=$(echo $RUNNING_POD | awk '{print $3}')
         print_msg "Waiting for pod $POD_NAME to complete "
         if [ "$POD_STATUS" = "Pending" ] || [ "$RUNNING_POD" = "" ] 
         then
           echo "Failed to Start Pod - $POD_NAME"
           exit 1 
         elif [ "$POD_STATUS" = "Error" ]|| [ "$POD_STATUS" = "CrashLoopBackOff" ]
         then
	   echo "$POD_NAME has exited with an error"
	   exit 1
         fi
   
         RUNNING=0
         while [ "$RUNNING" -eq 0 ]
         do   
           printf "."
           sleep 60
	   RUNNING_POD=$(kubectl get pods -n $DRNS | grep $POD_NAME)
           POD_NAME=$(echo $RUNNING_POD | awk '{print $1}')
           POD_STATUS=$(echo $RUNNING_POD | awk '{print $3}')
	   if [ "$RUNNING_POD" = "" ]
	   then
	     echo "Pod is not running."
	     exit 1
	   fi
           if [ "$POD_STATUS" = "Error" ] || [ "$POD_STATUS" = "CrashLoopBackOff" ]
           then
	     echo "Job has exited with an error"
	     exit 1
	   elif [ "$POD_STATUS" = "Pending" ]
           then
	     echo "Pod stuck in Pending state - check kubectl describe pod -n $DRNS $POD_NAME."
	     exit 1
	   elif [ "$POD_STATUS" = "Completed" ]
           then
	     RUNNING=1
           fi
	   
         done
         
         printf " Success. \n"
         update_progress
         fi
   
   fi
   
   if [ "$DR_TYPE" = "STANDBY" ] 
   then
      # If the backup is of an WLS domain ensure that the WebLogic Operator is running.
      #
      if [ "$product_type" = "oam"  ] ||  [ "$product_type" = "oig"  ]
      then
         new_step
         if [ $STEPNO -gt $PROGRESS ]
         then
           check_oper_running
	   update_progress
         fi
      fi
   fi

   if  [ "$USE_MAA_SCRIPTS" = "true" ] && [ ! "$PRODUCT" = "OAA" ]
   then
      if [ "$DR_TYPE" = "STANDBY" ] 
      then
   
         # Manually create application persistent volumes on the DR site, pointing to the DR NFS server.
         #
         new_step
         if [ $STEPNO -gt $PROGRESS ]
         then
	     create_dr_source_pv
	     update_progress
         fi
   

         # Create Kubernetes Objects using MAA scripts.
         #
         new_step
         if [ $STEPNO -gt $PROGRESS ]
         then
            print_msg "Restoring Backup of Kubernetes Objects "
            BACKUP_DIR=$(ls -str $WORKDIR/MAA | tail -1  | awk '{ print $2 }')
            if [ "$BACKUP_DIR" = "" ]
            then  
               echo "No Kubernetes backups exist - Copy from primary."
               exit 1
            fi
            BACKUP_FILE=$(ls $WORKDIR/MAA/$BACKUP_DIR/*.gz)
            if [ "$BACKUP_FILE" = "" ] 
            then  
               echo "No Kubernetes backups exist - Copy from primary."
               exit 1
            else
               printf "  From $BACKUP_FILE -"
            fi
            $LOCAL_WORKDIR/maa/kubernetes-maa/maak8-push-all-artifacts.sh $BACKUP_FILE $WORKDIR/MAA/$BACKUP_DIR/restore > $LOGDIR/restore_k8.log 2>&1
            print_status $? $LOGDIR/restore_k8.log
            update_progress
         fi
   
      else
         # Create a snapshot backup of the Kubernetes objects using MAA scripts.
         new_step
         if [ $STEPNO -gt $PROGRESS ]
         then
            print_msg "Creating Backup of Kubernetes Objects in Namespace(s) $PRODUCTNS"
            CMD="$LOCAL_WORKDIR/maa/kubernetes-maa/maak8-get-all-artifacts.sh $WORKDIR/MAA $PRODUCTNS"
            echo $CMD > $LOGDIR/backup_k8.log 
            eval $CMD >> $LOGDIR/backup_k8.log 2>&1
            print_status $? $LOGDIR/backup_k8.log
            BACKUP_DIR=$(ls -str $WORKDIR/MAA | tail -1  | awk '{ print $2 }')
            if [ "$COPY_FILES_TO_DR" = "true" ]
            then
               new_step
               if [ $STEPNO -gt $PROGRESS ]
               then
                 copy_files_to_dr $WORKDIR/MAA/$BACKUP_DIR/*.gz
                 update_progress
               fi
            else
               printf "\n\t\t\tCopy $WORKDIR/MAA/$BACKUP_DIR to your standby system.\n\n"
               update_progress
            fi
         fi
      fi
   fi
   
   if [ "$DR_TYPE" = "PRIMARY" ]
   then
      RUNNING_POD=$(kubectl get pods -n $DRNS | grep ${product_type}-initial )
      POD_NAME=$(echo $RUNNING_POD | awk '{print $1}')
      POD_RUNSTATUS=$(echo $RUNNING_POD | awk '{print $2}')
      POD_STATUS=$(echo $RUNNING_POD | awk '{print $3}')
      if [ "$POD_STATUS" = "Pending" ]
      then
         echo "Failed to start pod - $POD_NAME."
         exit 1
      fi
      if [ ! "$RUNNING_POD" =  "" ] && [ "$POD_RUNSTATUS" = "1/1" ]
      then
         printf "\n\nWait for pod $POD_NAME to complete before enabling DR on the standby site.\n"
      fi
   fi

   # Copy WebGate artifacts to OHS servers on the DR Site. And restart OHS.
   #
   if [ "$DR_TYPE" = "STANDBY" ]  
   then
     if [ "$product_type" = "oam" ]
     then
       if [ "$COPY_WG_FILES" = "true" ]
       then
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
           print_msg "Copy Webate Files to OHS"
   
	   if [ ! "$OHS_HOST1" = "" ]
           then
               printf "\n\t\t\tCopying Webgate file to $OHS_HOST1 - "
   
	       $SCP -r $OAM_LOCAL_SHARE/domains/$OAM_DOMAIN_NAME/output/Webgate_IDM/wallet ${OHS_USER}@$OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
               $SCP -r $OAM_LOCAL_SHARE/domains/$OAM_DOMAIN_NAME/output/Webgate_IDM/password.xml  ${OHS_USER}@$OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
               $SCP -r $OAM_LOCAL_SHARE/domains/$OAM_DOMAIN_NAME/output/Webgate_IDM/aaa*  ${OHS_USER}@$OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/webgate/config/simple >> $LOGDIR/copy_ohs.log 2>&1
               $SCP -r $OAM_LOCAL_SHARE/domains/$OAM_DOMAIN_NAME/output/Webgate_IDM/ObAccessClient.xml  ${OHS_USER}@$OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
	       print_status $? $LOGDIR/copy_ohs.log 2>&1
           fi
   
	   if [ ! "$OHS_HOST2" = "" ]
           then
               printf "\t\t\tCopying Webgate file to $OHS_HOST2 - "
	       $SCP -r $OAM_LOCAL_SHARE/domains/$OAM_DOMAIN_NAME/output/Webgate_IDM/wallet ${OHS_USER}@$OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
               $SCP -r $OAM_LOCAL_SHARE/domains/$OAM_DOMAIN_NAME/output/Webgate_IDM/password.xml  ${OHS_USER}@$OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
               $SCP -r $OAM_LOCAL_SHARE/domains/$OAM_DOMAIN_NAME/output/Webgate_IDM/aaa*  ${OHS_USER}@$OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/webgate/config/simple >> $LOGDIR/copy_ohs.log 2>&1
               $SCP -r $OAM_LOCAL_SHARE/domains/$OAM_DOMAIN_NAME/output/Webgate_IDM/ObAccessClient.xml  ${OHS_USER}@$OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
	       print_status $? $LOGDIR/copy_ohs.log 2>&1
           fi
	   update_progress
           new_step
           if [ $STEPNO -gt $PROGRESS ]
           then
              print_msg "Restarting OHS Servers"
   
	      if [ ! "$OHS_HOST1" = "" ]
              then
                printf "\n\t\t\tRestarting $OHS_HOST1 - "
	        $SSH ${OHS_USER}@$OHS_HOST1 "$OHS_DOMAIN/bin/restartComponent.sh $OHS1_NAME" > $LOGDIR/restart_ohs.log 2>&1
	        print_status $? $LOGDIR/restart_ohs.log 
	      fi
   
	      if [ ! "$OHS_HOST2" = "" ]
              then
                printf "\t\t\tRestarting $OHS_HOST2 - "
	        $SSH ${OHS_USER}@$OHS_HOST2 "$OHS_DOMAIN/bin/restartComponent.sh $OHS2_NAME" >> $LOGDIR/restart_ohs.log 2>&1
	        print_status $? $LOGDIR/restart_ohs.log 
	      fi
	      update_progress
           fi
        fi
      else
           echo "Copy the WebGate agent files to your Oracle HTTP Server and Restart."
      fi
   
     # For OAA DR
     #  Create OAA Namespace and a Registry secret to obtain images.
     #  Create a managment container with access to the local Kubernetes cluster.
     #  Use OAA.sh to create Kubernetes objects on DR site.
     #
     elif [ "$product_type" = "oaa" ]
     then
   
        # Create Kubernetes Namespace(s)
        #
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
           create_namespace $OAANS
           update_progress
        fi
        
   
        # Create a Container Registry Secret if requested
        #
        new_step
        if [ $STEPNO -gt $PROGRESS ] &&  [ "$CREATE_REGSECRET" = "true" ]
        then
           create_registry_secret $REGISTRY $REG_USER $REG_PWD $OAANS
           update_progress
        fi
   
      
        # Create a Management Container
        #
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
           PVSERVER=$DR_STANDBY_PVSERVER
           OAA_CONFIG_SHARE=$OAA_STANDBY_CONFIG_SHARE
           OAA_CRED_SHARE=$OAA_STANDBY_CRED_SHARE
           OAA_LOG_SHARE=$OAA_STANDBY_LOG_SHARE
           OAA_VAULT_SHARE=$OAA_STANDBY_VAULT_SHARE
           create_helper
           update_progress
        fi
   
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
           create_rbac
           update_progress
        fi
   
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
           deploy_oaa_dr
           update_progress
        fi
     fi
   fi
else
  # For OHS create a copy of the OHS configuration on the Primary Site.
  # On the DR site update the OHS routing and send to DR OHS servers, before restarting the OHS servers.
  #
  if [ "$DR_TYPE" = "PRIMARY" ]
  then
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
       get_ohs_config
       update_progress
     fi
   
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
       tar_ohs_config
       update_progress
     fi
     if [ "$COPY_FILES_TO_DR" = "true" ]
     then
        new_step
        if [ $STEPNO -gt $PROGRESS ]
        then
          copy_files_to_dr $WORKDIR/ohs_config.tar.gz
          update_progress
        fi
     else
           printf "\n\nCopy the file  $WORKDIR/ohs_config.tar.gz to  $WORKDIR/ohs_config.tar.gz on your DR system."
     fi
  else
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
       untar_ohs_config
       update_progress
     fi
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
       update_ohs_route
       update_progress
     fi
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
       update_ohs_hostname
       update_progress
     fi
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
       copy_ohs_dr_config
       update_progress
     fi
     new_step
     if [ $STEPNO -gt $PROGRESS ]
     then
        print_msg "Restarting OHS Servers"
  
	if [ ! "$OHS_HOST1" = "" ]
        then
          printf "\n\t\t\tRestarting $OHS_HOST1 - "
	  $SSH ${OHS_USER}@$OHS_HOST1 "$OHS_DOMAIN/bin/restartComponent.sh $OHS1_NAME" > $LOGDIR/restart_ohs.log 2>&1
	  print_status $? $LOGDIR/restart_ohs.log 
	fi
   
	if [ ! "$OHS_HOST2" = "" ]
        then
          printf "\t\t\tRestarting $OHS_HOST2 - "
	  $SSH ${OHS_USER}@$OHS_HOST2 "$OHS_DOMAIN/bin/restartComponent.sh $OHS2_NAME" >> $LOGDIR/restart_ohs.log 2>&1
	  print_status $? $LOGDIR/restart_ohs.log 
	fi
	update_progress
     fi
  fi
fi
   FINISH_TIME=`date +%s`
   print_time TOTAL "Enable $PRODUCT Disaster Recovery - $DR_TYPE" $START_TIME $FINISH_TIME 
   print_time TOTAL "Enable $PRODUCT Disaster Recovery - $DR_TYPE" $START_TIME $FINISH_TIME >> $LOGDIR/timings.log
   
touch $LOCAL_WORKDIR/dr_${product_type}_installed
