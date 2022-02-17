# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
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
   ST=`date +%s`
   print_msg "Creating Seedfile"
   cp $TEMPLATES_DIR/base.ldif $WORKDIR

   SEEDFILE=$WORKDIR/base.ldif

   # Perform variable substitution in template files
   #
   update_variable "<OUDADMINUSER>" $OUD_ADMIN_USER $SEEDFILE
   update_variable "<SEARCH_BASE>" $OUD_SEARCHBASE $SEEDFILE
   update_variable "<REGION>" $OUD_REGION $SEEDFILE
   update_variable "<GROUP_SEARCHBASE>" $OUD_GROUP_SEARCHBASE $SEEDFILE
   update_variable "<GROUP_SEARCHBASE>" $OUD_GROUP_SEARCHBASE $SEEDFILE
   update_variable "<USER_SEARCHBASE>" $OUD_USER_SEARCHBASE $SEEDFILE
   update_variable "<RESERVE_SEARCHBASE>" $OUD_RESERVE_SEARCHBASE $SEEDFILE
   update_variable "<SYSTEMIDS>" $OUD_SYSTEMIDS $SEEDFILE
   update_variable "<OAMADMIN>" $OUD_OAMADMIN_USER $SEEDFILE
   update_variable "<OAMADMINGRP>" $OUD_OAMADMIN_GRP $SEEDFILE
   update_variable "<OIGADMINGRP>" $OUD_OIGADMIN_GRP $SEEDFILE
   update_variable "<OAMLDAPUSER>" $OUD_OAMLDAP_USER  $SEEDFILE
   update_variable "<OIGLDAPUSER>" $OUD_OIGLDAP_USER  $SEEDFILE
   update_variable "<OAMADMINUSER>" $OUD_OAMADMIN_USER  $SEEDFILE
   update_variable "<WLSADMIN>" $OUD_WLSADMIN_USER  $SEEDFILE
   update_variable "<WLSADMINGRP>" $OUD_WLSADMIN_GRP  $SEEDFILE
   update_variable "<XELSYSADM>" $OUD_XELSYSADM_USER  $SEEDFILE
   update_variable "<PASSWORD>" $OUD_USER_PWD  $SEEDFILE
   update_variable "<OUD_PWD_EXPIRY>" $OUD_PWD_EXPIRY  $SEEDFILE

   echo "Success"
   ET=`date +%s`
   print_time STEP "Create LDAP Seedfile " $ST $ET >> $LOGDIR/timings.log
}

# Create a Helm override file
#
create_override()
{
   ST=`date +%s`
   print_msg "Creating Helm Override file"
   cp $TEMPLATES_DIR/override_oud.yaml $WORKDIR
   OVERRIDE_FILE=$WORKDIR/override_oud.yaml
   update_variable "<OUD_SEARCHBASE>" $OUD_SEARCHBASE  $OVERRIDE_FILE
   update_variable "<OUD_ADMIN_USER>" $OUD_ADMIN_USER $OVERRIDE_FILE
   update_variable "<OUD_ADMIN_PWD>" $OUD_ADMIN_PWD $OVERRIDE_FILE
   update_variable "<PVSERVER>" $PVSERVER $OVERRIDE_FILE
   update_variable "<OUD_SHARE>" $OUD_SHARE $OVERRIDE_FILE
   update_variable "<OUD_CONFIG_SHARE>" $OUD_CONFIG_SHARE $OVERRIDE_FILE
   update_variable "<OUD_REPLICAS>" $OUD_REPLICAS $OVERRIDE_FILE
   update_variable "<OUD_OIGADMIN_GRP>" $OUD_OIGADMIN_GRP $OVERRIDE_FILE
   update_variable "<REPOSITORY>" $OUD_IMAGE $OVERRIDE_FILE
   update_variable "<IMAGE_VER>" $OUD_VER $OVERRIDE_FILE
   update_variable "<USE_INGRESS>" $USE_INGRESS $OVERRIDE_FILE

   echo "Success"
   ET=`date +%s`
   print_time STEP "Create Helm Override File" $ST $ET >> $LOGDIR/timings.log
}

# Create a Nginx override file
#
create_nginx_override()
{
   ST=`date +%s`
   print_msg "Creating NGINX Override file"
   cp $TEMPLATES_DIR/oud_nginx.yaml $WORKDIR
   OVERRIDE_FILE=$WORKDIR/oud_nginx.yaml
   update_variable "<OUDNS>" $OUDNS  $OVERRIDE_FILE
   update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $OVERRIDE_FILE
   update_variable "<OUD_LDAP_K8>" $OUD_LDAP_K8 $OVERRIDE_FILE
   update_variable "<OUD_LDAPS_K8>" $OUD_LDAPS_K8 $OVERRIDE_FILE
   update_variable "<OUD_HTTP_K8>" $OUD_HTTP_K8 $OVERRIDE_FILE
   update_variable "<OUD_HTTPS_K8>" $OUD_HTTPS_K8 $OVERRIDE_FILE
   print_status $?
   ET=`date +%s`
   print_time STEP "Create Nginx Override File" $ST $ET >> $LOGDIR/timings.log
}

# Copy seed files to OUD Config Share
#
copy_files_to_share()
{
   ST=`date +%s`
   print_msg "Copy files to local share"
   cp $SEEDFILE $OUD_LOCAL_SHARE
   cp $TEMPLATES_DIR/99-user.ldif $OUD_LOCAL_SHARE
   chmod 777 $OUD_LOCAL_SHARE/*.ldif

   echo "Success"
   ET=`date +%s`
   print_time STEP "Copy files to local share " $ST $ET >> $LOGDIR/timings.log
}

# Create the OUD instances using helm
#
create_oud()
{

   ST=`date +%s`
   print_msg "Use Helm to create OUD"

   rm -f $OUD_LOCAL_SHARE/rejects.ldif $OUD_LOCAL_SHARE/skip.ldif 2> /dev/null > /dev/null
   cd $WORKDIR/samples/kubernetes/helm/
   helm install --namespace $OUDNS --values $WORKDIR/override_oud.yaml $OUD_POD_PREFIX oud-ds-rs > $LOGDIR/create_oud.log 
   print_status $? $LOGDIR/create_oud.log
   ET=`date +%s`
   print_time STEP "Create OUD Instances" $ST $ET >> $LOGDIR/timings.log

}

# Check that the OUD servers have started
#
check_oud_started()
{
   ST=`date +%s`
   print_msg "Check First OUD Server starts"
   echo
   check_running $OUDNS $OUD_POD_PREFIX-oud-ds-rs-0
   kubectl logs $OUD_POD_PREFIX-oud-ds-rs-0 -n $OUDNS > $LOGDIR/$OUD_POD_PREFIX-oud-ds-rs-0.log
   ET=`date +%s`
   print_time STEP "OUD Primary Started " $ST $ET >> $LOGDIR/timings.log
   ST=`date +%s`
   print_msg "Check First OUD Replica starts"
   echo
   check_running $OUDNS $OUD_POD_PREFIX-oud-ds-rs-1
   kubectl logs $OUD_POD_PREFIX-oud-ds-rs-1 -n $OUDNS > $LOGDIR/$OUD_POD_PREFIX-oud-ds-rs-1.log
   ET=`date +%s`
   print_time STEP "OUD Replica Started " $ST $ET >> $LOGDIR/timings.log
}


# Create OUD Node port services
#
create_oud_nodeport()
{
   ST=`date +%s`
   print_msg "Create OUD Nodeport Services"
   cp $TEMPLATES_DIR/oud_nodeport.yaml $WORKDIR
   update_variable "<OUDNS>" $OUDNS $WORKDIR/oud_nodeport.yaml
   update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/oud_nodeport.yaml
   update_variable "<OUD_LDAP_K8>" $OUD_LDAP_K8 $WORKDIR/oud_nodeport.yaml
   update_variable "<OUD_LDAPS_K8>" $OUD_LDAPS_K8 $WORKDIR/oud_nodeport.yaml

   kubectl apply -f $WORKDIR/oud_nodeport.yaml > $LOGDIR/oud_nodeport.log 2>&1
   print_status $? $LOGDIR/oud_nodeport.log

   ET=`date +%s`
   print_time STEP "Create OUD Nodeport services" $ST $ET >> $LOGDIR/timings.log
}

# Check Validate OUD Dataload was successful
#
validate_oud()
{
    ST=`date +%s`
    print_msg "Validating OUD"
    echo "Validating OUD" > $LOGDIR/validate_oud.log
    echo "--------------" >> $LOGDIR/validate_oud.log
    echo "" >> $LOGDIR/validate_oud.log
    FAIL=0

    printf "\n\t\t\tChecking for Import Errors - "
    grep -q ERROR $OUD_LOCAL_PVSHARE/${OUD_POD_PREFIX}-oud-ds-rs-0/logs/importLdifCmd.log
    if [ $? = 0 ]
    then
         echo "Import Errors Found check logfile $OUD_LOCAL_PVSHARE/${OUD_POD_PREFIX}-oud-ds-rs-0/logs/importLdifCmd.log"
         echo "Import Errors Found check logfile $OUD_LOCAL_PVSHARE/${OUD_POD_PREFIX}-oud-ds-rs-0/logs/importLdifCmd.log" >> $LOGDIR/validate_oud.log
         FAIL=1
    else
         echo "No Errors"
         echo "No Import Errors discovered" >> $LOGDIR/validate_oud.log
    fi
    printf "\t\t\tChecking for Rejects - "
    if [ -s $OUD_LOCAL_SHARE/rejects.ldif ]
    then 
         echo "Rejects found check File: $OUD_LOCAL_SHARE/rejects.ldif"
         echo "Rejects found check File: $OUD_LOCAL_SHARE/rejects.ldif" >> $LOGDIR/validate_oud.log
         FAIL=1
    else
         echo "No Rejects found"
         echo "No Reject Errors discovered" >> $LOGDIR/validate_oud.log
    fi
    printf "\t\t\tChecking for Skipped Records - "
    if [ -s $OUD_LOCAL_SHARE/skip.ldif ]
    then 
         echo "Skipped Records found check File: $OUD_LOCAL_SHARE/skip.ldif"
         echo "Skipped Records found check File: $OUD_LOCAL_SHARE/skip.ldif" >> $LOGDIR/validate_oud.log
         FAIL=1
    else
         echo "No Skipped Records found"
         echo "No Skipped Records discovered" >> $LOGDIR/validate_oud.log
    fi


    if [ "$FAIL" = "1" ]
    then
        printf "\n\t\t\tOUD Vaildation Failed\n"
        exit 1
    else
        printf "\n\t\t\tOUD Vaildation Succeeded\n"
    fi



   ET=`date +%s`
   print_time STEP "Validating OUD" $ST $ET >> $LOGDIR/timings.log
}
create_ingress()
{
    ST=`date +%s`
    echo -n "Adding Ingress Repository - "
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx > $LOGDIR/ingress.log 2>&1
    helm repo update  > $LOGDIR/ingress.log 2>&1

    helm search repo | grep -q nginx
    print_status $? $LOGDIR/ingress.log

    echo -n "Installing Ingress - "
    helm install --namespace $OUDINGNS  --values $WORKDIR/oud_nginx.yaml  edg-nginx ingress-nginx/ingress-nginx >> $LOGDIR/ingress.log 2>&1
    grep -q DEPLOYED $LOGDIR/ingress.log
    print_status $? $LOGDIR/ingress.log

    ET=`date +%s`
    print_time STEP "Creating Ingress" $ST $ET >> $LOGDIR/timings.log
}

# Create a Helm override file to deploy OUDSM
#
create_oudsm_override()
{
   ST=`date +%s`
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

   echo "Success"
   ET=`date +%s`
   print_time STEP "Create OUDSM Override file" $ST $ET >> $LOGDIR/timings.log
}

# Create OUSDM instance using helm
#
create_oudsm()
{

   ST=`date +%s`
   print_msg "Use Helm to create OUDSM"

   cd $WORKDIR/samples/kubernetes/helm
   helm install --namespace $OUDNS --values $WORKDIR/override_oudsm.yaml oudsm oudsm > $LOGDIR/create_oudsm.log 2>&1
   print_status $? $LOGDIR/create_oudsm.log
   ET=`date +%s`
   print_time STEP "Create OUDSM Instances" $ST $ET >> $LOGDIR/timings.log

}

# Check that OUDSM has started
#
check_oudsm_started()
{
   ST=`date +%s`
   print_msg "Check OUDSM Server starts"
   echo
   check_running $OUDNS oudsm
   kubectl logs oudsm-1 -n $OUDNS >> $LOGDIR/create_oudsm.log
   ET=`date +%s`
   print_time STEP "OUDSM Started " $ST $ET >> $LOGDIR/timings.log
}

# Create a node port service for OUDSM
#
create_oudsm_nodeport()
{
   ST=`date +%s`
   print_msg "Create OUDSM Nodeport Service"
   cp $TEMPLATE_DIR/oudsm_nodeport.yaml $WORKDIR
   update_variable "<OUDSM_SERVICE_PORT>" $OUDSM_SERVICE_PORT $WORKDIR/oudsm_nodeport.yaml
   update_variable "<OUDNS>" $OUDNS $WORKDIR/oudsm_nodeport.yaml

   kubectl apply -f $WORKDIR/oudsm_nodeport.yaml > $LOGDIR/oudsm_nodeport.log 2>&1
   print_status $? $LOGDIR/oudsm_nodeport.log

   ET=`date +%s`
   print_time STEP "Create OUDSM Nodeport services" $ST $ET >> $LOGDIR/timings.log
}

create_oudsm_ohs_entries()
{
   print_msg "Create OUDSM OHS entries"
   ST=`date +%s`

   CONFFILE=$LOCAL_WORKDIR/ohs_oudsm.conf

   cp $TEMPLATE_DIR/ohs_oudsm.conf $CONFFILE
   if [ "$USE_INGRESS" = "true" ] 
   then
      update_variable "<OUDSM_SERVICE_PORT>" $OUD_HTTP_K8 $CONFFILE
   else
      update_variable "<OUDSM_SERVICE_PORT>" $OUDSM_SERVICE_PORT $CONFFILE
   fi
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $CONFFILE
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST2 $CONFFILE

   OHSHOST1FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST1
   OHSHOST2FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST2

   if [ -f $OHSHOST1FILES/iadadmin_vh.conf ]
   then
        printf "Adding to iadadmin_vh.conf "
        sed -i '/<\/VirtualHost>/d' $OHSHOST1FILES/iadadmin_vh.conf
        sed -i '/<\/VirtualHost>/d' $OHSHOST2FILES/iadadmin_vh.conf

        cat $CONFFILE >> $OHSHOST1FILES/iadadmin_vh.conf
        cat $CONFFILE >> $OHSHOST2FILES/iadadmin_vh.conf

        print_status $?
   else
        if [ -d $OHSHOST1FILES ]
        then
            printf "Copying to $OHSHOST1FILES $OHSHOST2FILES"
            cp $CONFFILE $OHSHOST1FILES
            cp $CONFFILE $OHSHOST2FILES
        else
            echo "$CONFFILE Created"
        fi
   fi
   ET=`date +%s`
   print_time STEP "Create OHS Entries" $ST $ET >> $LOGDIR/timings.log
}
