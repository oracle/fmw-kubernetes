# Copyright (c) 2021, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of the checks that can be performed before Provisioning Identity Management
# to reduce the likelihood of provisioning failing.
#
#
# Usage: Not invoked directly
#

# Update the LDAP seed file with values from the responsefile
#
edit_seedfile()
{
   ST=$(date +%s)
   print_msg "Creating Seedfile"
   cp $TEMPLATE_DIR/base.ldif $WORKDIR

   SEEDFILE=$WORKDIR/base.ldif

   # Perform variable substitution in template files
   #
   update_variable "<LDAP_ADMIN_USER>" $LDAP_ADMIN_USER $SEEDFILE
   update_variable "<LDAP_SEARCHBASE>" $LDAP_SEARCHBASE $SEEDFILE
   update_variable "<OUD_REGION>" $OUD_REGION $SEEDFILE
   update_variable "<LDAP_GROUP_SEARCHBASE>" $LDAP_GROUP_SEARCHBASE $SEEDFILE
   update_variable "<LDAP_USER_SEARCHBASE>" $LDAP_USER_SEARCHBASE $SEEDFILE
   update_variable "<LDAP_RESERVE_SEARCHBASE>" $LDAP_RESERVE_SEARCHBASE $SEEDFILE
   update_variable "<LDAP_SYSTEMIDS>" $LDAP_SYSTEMIDS $SEEDFILE
   update_variable "<LDAP_OAMADMIN_USER>" $LDAP_OAMADMIN_USER $SEEDFILE
   update_variable "<LDAP_OAMADMIN_GRP>" $LDAP_OAMADMIN_GRP $SEEDFILE
   update_variable "<LDAP_OIGADMIN_GRP>" $LDAP_OIGADMIN_GRP $SEEDFILE
   update_variable "<LDAP_OAMLDAP_USER>" $LDAP_OAMLDAP_USER  $SEEDFILE
   update_variable "<LDAP_OIGLDAP_USER>" $LDAP_OIGLDAP_USER  $SEEDFILE
   update_variable "<LDAP_WLSADMIN_USER>" $LDAP_WLSADMIN_USER  $SEEDFILE
   update_variable "<LDAP_WLSADMIN_GRP>" $LDAP_WLSADMIN_GRP  $SEEDFILE
   update_variable "<LDAP_XELSYSADM_USER>" $LDAP_XELSYSADM_USER  $SEEDFILE
   update_variable "<PASSWORD>" $LDAP_USER_PWD  $SEEDFILE
   update_variable "<OUD_PWD_EXPIRY>" $OUD_PWD_EXPIRY  $SEEDFILE

   echo "Success"
   ET=$(date +%s)
   print_time STEP "Create LDAP Seedfile " $ST $ET >> $LOGDIR/timings.log
}

# Create a Helm override file
#
create_override()
{
   ST=$(date +%s)
   print_msg "Creating Helm Override file"
   if [ "$ENABLE_DIR" = "true" ] && [ "$DR_TYPE" = "STANDBY" ]
   then 
      cp $TEMPLATE_DIR/dr_override_oud.yaml $WORKDIR/override_oud.yaml
   else
      cp $TEMPLATE_DIR/override_oud.yaml $WORKDIR/override_oud.yaml
   fi
   if [ $? -gt 0 ]
   then
     exit 1
   fi
   OVERRIDE_FILE=$WORKDIR/override_oud.yaml
   update_variable "<LDAP_SEARCHBASE>" $LDAP_SEARCHBASE  $OVERRIDE_FILE
   update_variable "<LDAP_ADMIN_USER>" $LDAP_ADMIN_USER $OVERRIDE_FILE
   update_variable "<LDAP_ADMIN_PWD>" $LDAP_ADMIN_PWD $OVERRIDE_FILE
   update_variable "<PVSERVER>" $PVSERVER $OVERRIDE_FILE
   update_variable "<OUD_SHARE>" $OUD_SHARE $OVERRIDE_FILE
   update_variable "<OUD_CONFIG_SHARE>" $OUD_CONFIG_SHARE $OVERRIDE_FILE
   update_variable "<OUD_REPLICAS>" $OUD_REPLICAS $OVERRIDE_FILE
   update_variable "<LDAP_OIGADMIN_GRP>" $LDAP_OIGADMIN_GRP $OVERRIDE_FILE
   update_variable "<REPOSITORY>" $OUD_IMAGE $OVERRIDE_FILE
   update_variable "<IMAGE_VER>" $OUD_VER $OVERRIDE_FILE
   update_variable "<USE_INGRESS>" $USE_INGRESS $OVERRIDE_FILE

   update_variable "<USE_ELK>" $USE_ELK $OVERRIDE_FILE
   update_variable "<ELK_VER>" $ELK_VER $OVERRIDE_FILE
   update_variable "<ELK_USER>" $ELK_USER $OVERRIDE_FILE
   update_variable "<ELK_HOST>" $ELK_HOST $OVERRIDE_FILE
#   if [ ! "$ELK_API" = "" ]
#   then
#      update_variable "<ELK_API_SECRET>" elk-logstash $OVERRIDE_FILE
#      sed -i '/espassword/d'  $OVERRIDE_FILE
#   else
#      update_variable "<ELK_SECRET>" elk-logstash $OVERRIDE_FILE
#      sed -i '/esapikey/d'  $OVERRIDE_FILE
#   fi

#   if [ -e $LOCAL_WORKDIR/ELK/ca.crt ] && [ "$USE_ELK" = "true" ]
#   then
#       replace_value2 escert "|" $OVERRIDE_FILE
#       sed -i "/escert/ r $LOCAL_WORKDIR/ELK/ca.crt" $OVERRIDE_FILE
#   fi
       

   update_variable "<OUDSM_INGRESS_HOST>" $OUDSM_INGRESS_HOST $OVERRIDE_FILE

   KUBERNETES_VER=`kubectl version --short=true 2>/dev/null | grep Server | cut -f2 -d: | cut -f1 -d + | sed 's/ v//' | cut -f 1-3 -d.`
   update_variable "<KUBERNETES_VER>" $KUBERNETES_VER $OVERRIDE_FILE
   update_variable "<KUBECTL_REPO>" $KUBECTL_REPO $OVERRIDE_FILE
   update_variable "<BUSYBOX_REPO>" $BUSYBOX_REPO $OVERRIDE_FILE

   echo "Success"
   ET=$(date +%s)
   print_time STEP "Create Helm Override File" $ST $ET >> $LOGDIR/timings.log
}

# Create a logstash Configmap
#
update_logstash()
{
   ST=$(date +%s)
   print_msg "Updating Logstash to point to $ELK_HOST"
   printf "\n\t\t\tCreating config map yaml - "
   cp $TEMPLATE_DIR/logstash_cm.yaml $WORKDIR
   FILENAME=$WORKDIR/logstash_cm.yaml
   update_variable "<OUDNS>" $OUDNS $FILENAME
   update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $FILENAME
   update_variable "<ELK_HOST>" $ELK_HOST $FILENAME
   update_variable "<ELK_USER_PWD>" $ELK_USER_PWD $FILENAME
   update_variable "<ELK_USER>" $ELK_USER $FILENAME
   echo "Success"

   printf "\t\t\tDeleting existing config map  - "
   kubectl delete cm -n $OUDNS ${OUD_POD_PREFIX}-oud-ds-rs-logstash-configmap > $LOGDIR/logstash.log 2>&1
   print_status $? $LOGDIR/logstash.log
   printf "\t\t\tCreating new config map  - "
   kubectl create -f $FILENAME >> $LOGDIR/logstash.log 2>&1
   print_status $? $LOGDIR/logstash.log

   LOGPOD=`kubectl get pod -n $OUDNS -o wide | grep oud-ds-rs-kibana | awk '{ print $1 }'`
   printf "\t\t\tRestarting Pod $LOGPOD - "
   kubectl delete pod -n $OUDNS $LOGPOD > $LOGDIR/restart_kibana.log 2>&1
   print_status $? $LOGDIR/restart_kibana.log

   ET=$(date +%s)
   print_time STEP "Updating Logstash to use central ELK" $ST $ET >> $LOGDIR/timings.log
}

# Create a Nginx override file
#
create_nginx_override()
{
   ST=$(date +%s)
   print_msg "Creating NGINX Override file"
   cp $TEMPLATE_DIR/oud_nginx.yaml $WORKDIR
   OVERRIDE_FILE=$WORKDIR/oud_nginx.yaml
   update_variable "<OUDNS>" $OUDNS  $OVERRIDE_FILE
   update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $OVERRIDE_FILE
   update_variable "<OUD_LDAP_K8>" $OUD_LDAP_K8 $OVERRIDE_FILE
   update_variable "<OUD_LDAPS_K8>" $OUD_LDAPS_K8 $OVERRIDE_FILE
   update_variable "<OUD_HTTP_K8>" $OUD_HTTP_K8 $OVERRIDE_FILE
   update_variable "<OUD_HTTPS_K8>" $OUD_HTTPS_K8 $OVERRIDE_FILE
   print_status $?
   ET=$(date +%s)
   print_time STEP "Create Nginx Override File" $ST $ET >> $LOGDIR/timings.log
}

# Copy seed files to OUD Config Share
#
copy_files_to_share()
{
   ST=$(date +%s)
   print_msg "Copy files to local share"
   SEEDFILE=$WORKDIR/base.ldif

   if [ -e $SEEDFILE ] 
   then
      cp $SEEDFILE $OUD_LOCAL_CONFIG_SHARE
   fi
   cp $TEMPLATE_DIR/99-user.ldif $OUD_LOCAL_CONFIG_SHARE/99-user.ldif
   chmod 777 $OUD_LOCAL_CONFIG_SHARE/*.ldif
   print_status $?

   ET=$(date +%s)
   print_time STEP "Copy files to local share " $ST $ET >> $LOGDIR/timings.log
}

# Create the OUD instances using helm
#
create_oud()
{

   ST=$(date +%s)
   print_msg "Use Helm to create OUD"

   rm -f $OUD_LOCAL_CONFIG_SHARE/rejects.ldif $OUD_LOCAL_CONFIG_SHARE/skip.ldif 2> /dev/null > /dev/null
   cd $WORKDIR/samples/kubernetes/helm/
   helm install --namespace $OUDNS --values $WORKDIR/override_oud.yaml $OUD_POD_PREFIX oud-ds-rs > $LOGDIR/create_oud.log 2>&1
   print_status $? $LOGDIR/create_oud.log
   ET=$(date +%s)
   print_time STEP "Create OUD Instances" $ST $ET >> $LOGDIR/timings.log

}

# Check that the OUD servers have started
#
check_oud_started()
{
   ST=$(date +%s)
   print_msg "Check First OUD Server starts"
   echo
   check_running $OUDNS $OUD_POD_PREFIX-oud-ds-rs-0 120
   kubectl logs -c oud-ds-rs $OUD_POD_PREFIX-oud-ds-rs-0 -n $OUDNS > $LOGDIR/$OUD_POD_PREFIX-oud-ds-rs-0.log
   ET=$(date +%s)
   print_time STEP "OUD Primary Started " $ST $ET >> $LOGDIR/timings.log
   ST=$(date +%s)
   if [ $OUD_REPLICAS -gt 1 ]
   then
      print_msg "Check First OUD Replica starts"
      echo
      check_running $OUDNS $OUD_POD_PREFIX-oud-ds-rs-1
      kubectl logs -c oud-ds-rs $OUD_POD_PREFIX-oud-ds-rs-1 -n $OUDNS > $LOGDIR/$OUD_POD_PREFIX-oud-ds-rs-1.log
      ET=$(date +%s)
      print_time STEP "OUD Replica Started " $ST $ET >> $LOGDIR/timings.log
   fi
}


# Create OUD Node port services
#
create_oud_nodeport()
{
   ST=$(date +%s)
   print_msg "Create OUD Nodeport Services"
   cp $TEMPLATE_DIR/oud_nodeport.yaml $WORKDIR
   update_variable "<OUDNS>" $OUDNS $WORKDIR/oud_nodeport.yaml
   update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/oud_nodeport.yaml
   update_variable "<OUD_LDAP_K8>" $OUD_LDAP_K8 $WORKDIR/oud_nodeport.yaml
   update_variable "<OUD_LDAPS_K8>" $OUD_LDAPS_K8 $WORKDIR/oud_nodeport.yaml

   kubectl apply -f $WORKDIR/oud_nodeport.yaml > $LOGDIR/oud_nodeport.log 2>&1
   print_status $? $LOGDIR/oud_nodeport.log

   ET=$(date +%s)
   print_time STEP "Create OUD Nodeport services" $ST $ET >> $LOGDIR/timings.log
}

# Check Validate OUD Dataload was successful
#
validate_oud()
{
    ST=$(date +%s)
    print_msg "Validating OUD"
    echo "Validating OUD" > $LOGDIR/validate_oud.log
    echo "--------------" >> $LOGDIR/validate_oud.log
    echo "" >> $LOGDIR/validate_oud.log
    FAIL=0

    printf "\n\t\t\tChecking for Creation Errors - "
    grep -q SEVERE_ERROR $LOGDIR/${OUD_POD_PREFIX}-oud-ds-rs-0.log
    if [ $? = 0 ]
    then
         echo "SEVERE Errors Found check logfile $LOGDIR/${OUD_POD_PREFIX}-oud-ds-rs-0.log"
         echo "SEVERE Errors Found check logfile $LOGDIR/${OUD_POD_PREFIX}-oud-ds-rs-0.log" >> $LOGDIR/validate_oud.log
         FAIL=1
    else
         echo "No Errors"
         echo "No Creation Errors discovered" >> $LOGDIR/validate_oud.log
    fi

    if [ ! "$ENABLE_DR" = "true" ] || [ "$DR_TYPE" = "PRIMARY" ]
    then
       printf "\t\t\tChecking for Import Errors - "
       grep -q ERROR $OUD_LOCAL_SHARE/${OUD_POD_PREFIX}-oud-ds-rs-0/logs/importLdifCmd.log
       if [ $? = 0 ]
       then
            echo "Import Errors Found check logfile $OUD_LOCAL_SHARE/${OUD_POD_PREFIX}-oud-ds-rs-0/logs/importLdifCmd.log"
            echo "Import Errors Found check logfile $OUD_LOCAL_SHARE/${OUD_POD_PREFIX}-oud-ds-rs-0/logs/importLdifCmd.log" >> $LOGDIR/validate_oud.log
            FAIL=1
       else
            echo "No Errors"
            echo "No Import Errors discovered" >> $LOGDIR/validate_oud.log
       fi
       printf "\t\t\tChecking for Rejects - "
       if [ -s $OUD_LOCAL_CONFIG_SHARE/rejects.ldif ]
       then 
            echo "Rejects found check File: $OUD_LOCAL_CONFIG_SHARE/rejects.ldif"
            echo "Rejects found check File: $OUD_LOCAL_CONFIG_SHARE/rejects.ldif" >> $LOGDIR/validate_oud.log
            FAIL=1
       else
            echo "No Rejects found"
            echo "No Reject Errors discovered" >> $LOGDIR/validate_oud.log
       fi
       printf "\t\t\tChecking for Skipped Records - "
       if [ -s $OUD_LOCAL_CONFIG_SHARE/skip.ldif ]
       then 
            echo "Skipped Records found check File: $OUD_LOCAL_CONFIG_SHARE/skip.ldif"
            echo "Skipped Records found check File: $OUD_LOCAL_CONFIG_SHARE/skip.ldif" >> $LOGDIR/validate_oud.log
            FAIL=1
       else
            echo "No Skipped Records found"
            echo "No Skipped Records discovered" >> $LOGDIR/validate_oud.log
       fi
    fi


    if [ "$FAIL" = "1" ]
    then
        printf "\t\t\tOUD Validation Failed\n"
        exit 1
    else
        printf "\t\t\tOUD Validation Succeeded\n"
    fi


   ET=$(date +%s)
   print_time STEP "Validating OUD" $ST $ET >> $LOGDIR/timings.log
}

# Create a Helm override file to deploy OUDSM
#
create_oudsm_override()
{
   ST=$(date +%s)
   print_msg "Create OUDSM Override File"
   cp $TEMPLATE_DIR/override_oudsm.yaml $WORKDIR

   # Perform variable substitution in template file
   #
   update_variable "<OUDSM_USER>" $OUDSM_USER $WORKDIR/override_oudsm.yaml
   update_variable "<OUDSM_PWD>" $OUDSM_PWD $WORKDIR/override_oudsm.yaml
   update_variable "<NFSSERVERNAME>" $PVSERVER $WORKDIR/override_oudsm.yaml
   update_variable "<OUDSM_SHARE>" $OUDSM_SHARE $WORKDIR/override_oudsm.yaml
   update_variable "<REPOSITORY>" $OUDSM_IMAGE $WORKDIR/override_oudsm.yaml
   update_variable "<IMAGE_VER>" $OUDSM_VER $WORKDIR/override_oudsm.yaml
   update_variable "<USE_INGRESS>" $USE_INGRESS $WORKDIR/override_oudsm.yaml
   update_variable "<PVSERVER>" $PVSERVER $WORKDIR/override_oudsm.yaml
   update_variable "<OUDSM_INGRESS_HOST>" $OUDSM_INGRESS_HOST $WORKDIR/override_oudsm.yaml

   echo "Success"
   ET=$(date +%s)
   print_time STEP "Create OUDSM Override file" $ST $ET >> $LOGDIR/timings.log
}

# Create OUSDM instance using helm
#
create_oudsm()
{

   ST=$(date +%s)
   print_msg "Use Helm to create OUDSM"

   cd $WORKDIR/samples/kubernetes/helm
   helm install --namespace $OUDNS --values $WORKDIR/override_oudsm.yaml oudsm oudsm > $LOGDIR/create_oudsm.log 2>&1
   print_status $? $LOGDIR/create_oudsm.log
   ET=$(date +%s)
   print_time STEP "Create OUDSM Instances" $ST $ET >> $LOGDIR/timings.log

}

# Check that OUDSM has started
#
check_oudsm_started()
{
   ST=$(date +%s)
   print_msg "Check OUDSM Server starts"
   echo
   check_running $OUDNS oudsm
   kubectl logs oudsm-1 -n $OUDNS >> $LOGDIR/create_oudsm.log
   ET=$(date +%s)
   print_time STEP "OUDSM Started " $ST $ET >> $LOGDIR/timings.log
}

# Create a node port service for OUDSM
#
create_oudsm_nodeport()
{
   ST=$(date +%s)
   print_msg "Create OUDSM Nodeport Service"
   cp $TEMPLATE_DIR/oudsm_nodeport.yaml $WORKDIR
   update_variable "<OUDSM_SERVICE_PORT>" $OUDSM_SERVICE_PORT $WORKDIR/oudsm_nodeport.yaml
   update_variable "<OUDNS>" $OUDNS $WORKDIR/oudsm_nodeport.yaml

   kubectl apply -f $WORKDIR/oudsm_nodeport.yaml > $LOGDIR/oudsm_nodeport.log 2>&1
   print_status $? $LOGDIR/oudsm_nodeport.log

   ET=$(date +%s)
   print_time STEP "Create OUDSM Nodeport services" $ST $ET >> $LOGDIR/timings.log
}

# Create an ingress service for OUDSM
#
create_oudsm_ingress()
{
   ST=$(date +%s)
   print_msg "Create OUDSM Ingress Service"
   filename=oudsm_ingress.yaml
   cp $TEMPLATE_DIR/$filename $WORKDIR
   update_variable "<OUDNS>" $OUDNS $WORKDIR/$filename
   update_variable "<OUDSM_INGRESS_HOST>" $OUDSM_INGRESS_HOST $WORKDIR/$filename

   kubectl create -f $WORKDIR/$filename > $LOGDIR/create_ingress.log 2>&1
   print_status $? $LOGDIR/create_ingress.log

   ET=$(date +%s)
   print_time STEP "Create OUDSM Ingress services" $ST $ET >> $LOGDIR/timings.log
}

create_oudsm_ohs_entries()
{
   print_msg "Create OUDSM OHS entries"
   ST=$(date +%s)

   CONFFILE=$LOCAL_WORKDIR/ohs_oudsm.conf

   cp $TEMPLATE_DIR/ohs_oudsm.conf $CONFFILE
   if [ "$USE_INGRESS" = "true" ] 
   then
      if [ "$INGRESS_SSL" = "true" ]
      then
          update_variable "<OUDSM_SERVICE_PORT>" $INGRESS_HTTPS_PORT $CONFFILE
      else
          update_variable "<OUDSM_SERVICE_PORT>" $INGRESS_HTTP_PORT $CONFFILE
      fi
   else
      update_variable "<OUDSM_SERVICE_PORT>" $OUDSM_SERVICE_PORT $CONFFILE
   fi
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $CONFFILE
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST2 $CONFFILE

   OHSHOST1FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST1
   OHSHOST2FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST2

   echo "$CONFFILE Created"

   if [ -d $OHSHOST1FILES ]
   then
       printf "\t\t\tCopying to $OHSHOST1FILES - "
       cp $CONFFILE $OHSHOST1FILES
       print_status $?
   fi
   if [ -d $OHSHOST2FILES ]
   then
       printf "\t\t\tCopying to $OHSHOST2FILES - "
       cp $CONFFILE $OHSHOST2FILES
       print_status $?
   fi
   ET=$(date +%s)
   print_time STEP "Create OHS Entries" $ST $ET >> $LOGDIR/timings.log
}

# Create logstash configmap
#
create_oud_logstash_cm()
{
   ST=$(date +%s)
   print_msg "Creating logstash Config Map"

   cp $TEMPLATE_DIR/logstash_cm.yaml $WORKDIR

   update_variable "<OUDNS>" $OUDNS $WORKDIR/logstash_cm.yaml
   update_variable "<ELK_HOST>" $ELK_HOST $WORKDIR/logstash_cm.yaml
   update_variable "<ELK_USER_PWD>" $ELK_USER_PWD $WORKDIR/logstash_cm.yaml

   kubectl create -f $WORKDIR/logstash_cm.yaml >$LOGDIR/logstash_cm.log 2>&1
   if [ $? = 0 ]
   then
        echo "Success"
   else
       grep -q "AlreadyExists" $LOGDIR/logstash_cm.log
       if [ $? = 0 ]
       then
          echo "Already Exists"
       else
          print_status 1 $LOGDIR/logstash_cm.log
       fi
   fi
   ET=$(date +%s)
   print_time STEP "Create Logstash Config Map" $ST $ET >> $LOGDIR/timings.log
}

create_oudsm_logstash_cm()
{
   ST=$(date +%s)
   print_msg "Creating logstash Config Map"
   cp $TEMPLATE_DIR/logstash_cm.yaml $WORKDIR

   update_variable "<OUDNS>" $OUDNS $WORKDIR/logstash_cm.yaml
   update_variable "<ELK_HOST>" $ELK_HOST $WORKDIR/logstash_cm.yaml
   update_variable "<ELK_USER_PWD>" $ELK_USER_PWD $WORKDIR/logstash_cm.yaml

   kubectl create -f $WORKDIR/logstash_cm.yaml >$LOGDIR/logstash_cm.log 2>&1
   if [ $? = 0 ]
   then
        echo "Success"
   else
       grep -q "AlreadyExists" $LOGDIR/logstash_cm.log
       if [ $? = 0 ]
       then
          echo "Already Exists"
       else
          print_status 1 $LOGDIR/logstash_cm.log
       fi
   fi
   ET=$(date +%s)
   print_time STEP "Create Logstash Config Map" $ST $ET >> $LOGDIR/timings.log
}

create_dr_pv_files()
{
   ST=$(date +%s)
   print_msg "Creating DR Persistent Volume Files"
   cp $TEMPLATE_DIR/dr_pv.yaml $WORKDIR/dr_primary_pv.yaml
   update_variable "<OUD_SHARE>" $OUD_PRIMARY_SHARE $WORKDIR/dr_primary_pv.yaml
   update_variable "<PVSERVER>" $DR_PRIMARY_PVSERVER $WORKDIR/dr_primary_pv.yaml

   cp $TEMPLATE_DIR/dr_pv.yaml $WORKDIR/dr_dr_pv.yaml
   update_variable "<OUD_SHARE>" $OUD_SHARE $WORKDIR/dr_dr_pv.yaml
   update_variable "<PVSERVER>" $OUD_STANDBY_SHARE $WORKDIR/dr_dr_pv.yaml
   
   print_status $?

   ET=$(date +%s)
   print_time STEP "Create DR Persistent Volume File" $ST $ET >> $LOGDIR/timings.log
}

create_dr_pvc_files()
{
   ST=$(date +%s)
   print_msg "Creating DR Persistent Volume Claim Files"
   cp $TEMPLATE_DIR/dr_pvc.yaml $WORKDIR/dr_primary_pvc.yaml
   update_variable "<OUDNS>" $OUDNS $WORKDIR/dr_primary_pvc.yaml

   cp $WORKDIR/dr_primary_pvc.yaml $WORKDIR/dr_dr_pvc.yaml
   
   print_status $?

   ET=$(date +%s)
   print_time STEP "Create DR Persistent Volume Claim Files" $ST $ET >> $LOGDIR/timings.log
}

create_dr_cronjob_files()
{
   ST=$(date +%s)
   print_msg "Creating Cron Job Files"

   cp $TEMPLATE_DIR/dr_cron.yaml $WORKDIR/dr_cron.yaml
   update_variable "<OUDNS>" $OUDNS $WORKDIR/dr_cron.yaml
   update_variable "<DR_OUD_MINS>" $DR_OUD_MINS $WORKDIR/dr_cron.yaml
   update_variable "<RSYNC_IMAGE>" $RSYNC_IMAGE $WORKDIR/dr_cron.yaml
   update_variable "<RSYNC_VER>" $RSYNC_VER $WORKDIR/dr_cron.yaml
   update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/dr_cron.yaml

      #cp $TEMPLATE_DIR/dr_cron.yaml $WORKDIR/dr_dr_cron.yaml
      #update_variable "<OUDNS>" $OUDNS $WORKDIR/dr_dr_cron.yaml
      #update_variable "<DR_OUD_MINS>" $DR_OUD_MINS $WORKDIR/dr_dr_cron.yaml
      #update_variable "<RSYNC_IMAGE>" $RSYNC_IMAGE $WORKDIR/dr_dr_cron.yaml
      #update_variable "<RSYNC_VER>" $RSYNC_VER $WORKDIR/dr_dr_cron.yaml
      #update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/dr_dr_cron.yaml
  
   print_status $?

   ET=$(date +%s)
   print_time STEP "Create DR Cron Job Files" $ST $ET >> $LOGDIR/timings.log
}

create_dr_pv()
{
   ST=$(date +%s)
   print_msg "Creating DR Persistent Volume"

   kubectl create -f $WORKDIR/dr_dr_pv.yaml > $LOGDIR/create_dr_pv.log 2>&1
   print_status $? $LOGDIR/create_dr_pv.log

   ET=$(date +%s)
   print_time STEP "Create DR Persistent Volume " $ST $ET >> $LOGDIR/timings.log
}

create_dr_pvc()
{
   ST=$(date +%s)
   print_msg "Creating DR Persistent Volume Claim"
   kubectl create -f $WORKDIR/dr_dr_pvc.yaml > $LOGDIR/create_dr_pvc.log 2>&1
   print_status $? $LOGDIR/create_dr_pvc.log

   ET=$(date +%s)
   print_time STEP "Create DR Persistent Volume Claim " $ST $ET >> $LOGDIR/timings.log
}

copy_dr_script()
{
   ST=$(date +%s)
   print_msg "Creating DR Script Directory"
   kubectl exec -n $OUDNS -ti $OUD_POD_PREFIX-oud-ds-rs-0 -- mkdir /u01/oracle/user_projects/dr_scripts > $LOGDIR/copy_drscripts.log 2>&1
   if [ $? -gt 0 ]
   then
      grep -q exists $LOGDIR/copy_drscripts.log
      if [ $? = 0  ]
      then
         echo " Already Exists"
      else
         echo " Failed - Check logfile $LOGDIR/copy_drscripts.log"
         exit 1
      fi
   else
     echo "Success"
   fi
      
   printf "\t\t\tCopy DR Script to Container - "
   cp $TEMPLATE_DIR/oud_dr.sh $WORKDIR
   update_variable "<ENV_TYPE>" $ENV_TYPE $WORKDIR/oud_dr.sh
   kubectl cp $WORKDIR/oud_dr.sh $OUDNS/$OUD_POD_PREFIX-oud-ds-rs-0:/u01/oracle/user_projects/dr_scripts >>$LOGDIR/copy_drscripts.log 2>&1
   print_status $? $LOGDIR/copy_drscripts.log
  
   printf "\t\t\tSet execute permission - "
   kubectl exec -n $OUDNS -ti $OUD_POD_PREFIX-oud-ds-rs-0 -- chmod 750 /u01/oracle/user_projects/dr_scripts/oud_dr.sh >> $LOGDIR/copy_drscripts.log 2>&1
   print_status $? $LOGDIR/copy_drscripts.log
  
   printf "\t\t\tSet DR Site Type - "
   echo $DR_TYPE > $WORKDIR/dr_type
   kubectl cp $WORKDIR/dr_type $OUDNS/$OUD_POD_PREFIX-oud-ds-rs-0:/u01/oracle/user_projects/dr_scripts >>$LOGDIR/copy_drscripts.log 2>&1
   print_status $? $LOGDIR/copy_drscripts.log

   ET=$(date +%s)
   print_time STEP "Copy DR Script" $ST $ET >> $LOGDIR/timings.log
}

create_dr_cronjob()
{
   ST=$(date +%s)
   print_msg "Creating DR Cron Job"
   kubectl create -f $WORKDIR/dr_cron.yaml  > $LOGDIR/create_dr_cron.log 2>&1
  
   print_status $? $LOGDIR/create_dr_cron.log

   ET=$(date +%s)
   print_time STEP "Create DR Cron Job" $ST $ET >> $LOGDIR/timings.log
}

suspend_cronjob()
{
   ST=$(date +%s)
   print_msg "Suspending DR Cron Job - "
   kubectl patch cronjobs rsyncdr -p '{"spec" : {"suspend" : true }}' -n $OUDNS > $LOGDIR/suspend_cron.log 2>&1
  
   print_status $? $LOGDIR/suspend_cron.log

   ET=$(date +%s)
   print_time STEP "Suspend Cron Job" $ST $ET >> $LOGDIR/timings.log
}

resume_cronjob()
{
   ST=$(date +%s)
   print_msg "Resuming DR Cron Job - "
   kubectl patch cronjobs rsyncdr -p '{"spec" : {"suspend" : false }}' -n $OUDNS > $LOGDIR/resume_cron.log 2>&1
  
   print_status $? resume_cron.log

   ET=$(date +%s)
}

initialise_dr()
{
   ST=$(date +%s)
   print_msg "Creating Job to Initialise OUD DR - "
   kubectl create job --from=cronjob.batch/rsyncdr initialise-dr -n $OUDNS > $LOGDIR/oud_initialise.log 2>&1
   print_status $? $LOGDIR/oud_initialise.log
   printf "Job - initialise-dr Created in namespace $OUDNS"
   PODNAME=`kubectl get pod -n $OUDNS | grep cron | tail -1 | awk '{ print $1 }'`
   printf "Monitor job using the command:  kubectl logs -n $OUDNS $PODNAME"
  
   ET=$(date +%s)
}

stop_oud()
{
   ST=$(date +%s)
   print_msg "Stopping OUD"
   echo helm upgrade -n $OUDNS --set replicaCount=0 $OUD_POD_PREFIX $WORKDIR/samples/kubernetes/helm/oud-ds-rs --reuse-values > $LOGDIR/stop_oud.log 
   helm upgrade -n $OUDNS --set replicaCount=0 $OUD_POD_PREFIX $WORKDIR/samples/kubernetes/helm/oud-ds-rs --reuse-values >> $LOGDIR/stop_oud.log 2>&1
   print_status $?  $LOGDIR/stop_oud.log
   check_stopped $OUDNS ${OUD_POD_PREFIX}-oud-ds-rs-0

   ET=$(date +%s)
   print_time STEP "Create Cron Job Files" $ST $ET >> $LOGDIR/timings.log
}

delete_oud_files()
{
   ST=$(date +%s)
   print_msg "Delete OUD Instance Files"

   echo rm -rf $OUD_LOCAL_SHARE/${OUD_POD_PREFIX}-oud-ds-rs-* > $LOGDIR/delete_oud_instance.log 2>&1
   rm -rf $OUD_LOCAL_SHARE/${OUD_POD_PREFIX}-oud-ds-rs-* >> $LOGDIR/delete_oud_instance.log 2>&1
   print_status $?  $LOGDIR/delete_oud_instance.log

   ET=$(date +%s)
   print_time STEP "Delete OUD Instance Files" $ST $ET >> $LOGDIR/timings.log
}
