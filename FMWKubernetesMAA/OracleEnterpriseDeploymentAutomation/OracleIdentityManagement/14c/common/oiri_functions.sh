# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of functions and procedures to provision and Configure Oracle Identity Role Intelligence
#
#
# Usage: not invoked Directly
#



# Execute a command in the oiri-cli container
#
oiri_cli()
{
   cmd=$1
   kubectl exec -n $OIRINS -ti oiri-cli -- $cmd
}

# Execute a command in the oiri-ding-cli container
#
ding_cli()
{
   cmd=$1
   kubectl exec -n $DINGNS -ti oiri-ding-cli -- $cmd
}

# Create an oiri-cli pod in Kubernetes
#
create_helper()
{
   print_msg "Creating OIRI Helper Container"
   ST=`date +%s`

   cp $TEMPLATE_DIR/oiri-cli.yaml $WORKDIR
   filename=$WORKDIR/oiri-cli.yaml

   update_variable "<OIRINS>" $OIRINS $filename
   update_variable "<PVSERVER>" $PVSERVER $filename
   update_variable "<OIRI_SHARE>" $OIRI_SHARE $filename
   update_variable "<OIRI_DING_SHARE>" $OIRI_DING_SHARE $filename
   update_variable "<OIRI_WORK_SHARE>" $OIRI_WORK_SHARE $filename
   update_variable "<OIRI_CLI_IMAGE>" $OIRI_CLI_IMAGE $filename
   update_variable "<OIRICLI_VER>" $OIRICLI_VER $filename

   kubectl create -f $filename > $LOGDIR/create_helper.log
   print_status $? $LOGDIR/create_helper.log
   check_running $OIRINS oiri-cli 15

   ET=`date +%s`
   print_time STEP "Create Helper container" $ST $ET >> $LOGDIR/timings.log
}

# Create an oiri-ding-cli pod in Kubernetes
#
create_ding_helper()
{
   print_msg "Creating Data Ingestion Helper Container"
   ST=`date +%s`

   cp $TEMPLATE_DIR/ding-cli.yaml $WORKDIR
   filename=$WORKDIR/ding-cli.yaml

   update_variable "<DINGNS>" $DINGNS $filename
   update_variable "<PVSERVER>" $PVSERVER $filename
   update_variable "<OIRI_SHARE>" $OIRI_SHARE $filename
   update_variable "<OIRI_DING_SHARE>" $OIRI_DING_SHARE $filename
   update_variable "<OIRI_WORK_SHARE>" $OIRI_WORK_SHARE $filename
   update_variable "<OIRI_DING_IMAGE>" $OIRI_DING_IMAGE $filename
   update_variable "<OIRIDING_VER>" $OIRIDING_VER $filename

   kubectl create -f $filename > $LOGDIR/create_helper.log
   print_status $? $LOGDIR/create_helper.log
   check_running $DINGNS oiri-ding-cli 15
   ET=`date +%s`
   print_time STEP "Create DING Helper container" $ST $ET >> $LOGDIR/timings.log
}

# Copy file to Kubernetes Container
#
copy_to_oiri()
{
   filename=$1
   destination=$2
   namespace=$3
   pod=$4

   kubectl cp $filename  $namespace/$pod:$destination
   if  [  $? -gt 0 ]
   then
      echo "Failed to copy $filename."
      RETCODE=1
   else
      RETCODE=0
   fi
}

# Create RBAC for OCI
#
create_rbac()
{
   print_msg "Create OIRI Service Account"
   ST=`date +%s`

   if [ "$USE_INGRESS" = "false" ]
   then
         filename=oiri_svc_acct_noingress.yaml
   else
         filename=oiri_svc_acct_ingress.yaml
   fi
   cp $TEMPLATE_DIR/$filename $WORKDIR
   update_variable "<OIRINS>" $OIRINS $WORKDIR/$filename
   update_variable "<DINGNS>" $DINGNS $WORKDIR/$filename

   kubectl apply -f $WORKDIR/$filename > $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log
   KVER=$(get_k8_ver)
   KVER=${KVER:0:4}
   if [ $KVER > "1.23" ]
   then
     printf "\t\t\tCreating Service Account Secret - "
     cp $TEMPLATE_DIR/create_svc_secret.yaml $WORKDIR
     update_variable "<OIRINS>" $OIRINS $WORKDIR/create_svc_secret.yaml
     kubectl apply -f $WORKDIR/create_svc_secret.yaml >> $LOGDIR/create_rbac.log 2>&1
     print_status $? $LOGDIR/create_rbac.log
     TOKENNAME=oiri-service-account
   else
     TOKENNAME=`kubectl -n $OIRINS get serviceaccount/oiri-service-account -o jsonpath='{.secrets[0].name}'`
   fi
 
   TOKEN=$(kubectl -n $OIRINS get secret $TOKENNAME -o jsonpath='{.data.token}'| base64 --decode)
 
   k8url=`grep server: $KUBECONFIG | sed 's/server://;s/ //g'`

   printf "\t\t\tGenerate ca.crt - "
   kubectl -n $OIRINS get secret $TOKENNAME -o jsonpath='{.data.ca\.crt}'| base64 --decode > $WORKDIR/ca.crt
   print_status $? $LOGDIR/create_rbac.log

   printf "\t\t\tCreate Kubeconfig file - "
   kubectl config --kubeconfig=$WORKDIR/oiri_config set-cluster oiri-cluster --server=$k8url --certificate-authority=$WORKDIR/ca.crt --embed-certs=true >> $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log
 
   printf "\t\t\tAdd credentials - "
   kubectl config --kubeconfig=$WORKDIR/oiri_config set-credentials oiri-service-account --token=$TOKEN >> $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log
 
   printf "\t\t\tAdd Service Account - "
   kubectl config --kubeconfig=$WORKDIR/oiri_config set-context oiri --user=oiri-service-account --cluster=oiri-cluster >> $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log
 
   printf "\t\t\tAdd context - "
   kubectl config --kubeconfig=$WORKDIR/oiri_config use-context oiri >> $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log

   printf "\t\t\tCopy ca.crt to oiri-cli - "
   copy_to_oiri $WORKDIR/ca.crt /app/k8s $OIRINS oiri-cli   >> $LOGDIR/create_rbac.log 2>&1
   print_status $RETCODE $LOGDIR/create_rbac.log
   printf "\t\t\tCopy oiri_config to oiri-cli - "
   copy_to_oiri $WORKDIR/oiri_config /app/k8s/config $OIRINS oiri-cli  >> $LOGDIR/create_rbac.log 2>&1
   print_status $RETCODE $LOGDIR/create_rbac.log

   ET=`date +%s`
   print_time STEP "Create oiri-cli kubeconfig" $ST $ET >> $LOGDIR/timings.log
}

# Copy Kubeconfig file to oiri-cli container.
#
copy_kubeconfig()
{ 
   print_msg "Copying Kubeconfig File to oiri-cli"
   ST=`date +%s`
   copy_to_oiri $KUBECONFIG /app/k8s/config $OIRINS oiri-cli >> $LOGDIR/copy_kubeconfig.log 2>&1
   print_status $RETCODE $LOGDIR/copy_kubeconfig.log
   printf "\t\t\tSet kubeconfig permissions - "
   oiri_cli "chmod 400  /app/k8s/config"
   print_status $? 
   ET=`date +%s`
   print_time STEP "Copy Kubeconfig File to oiri-cli" $ST $ET >> $LOGDIR/timings.log
}


# Validate the kubectl command in the oiri-cli container
#
validate_oiricli()
{
   print_msg "Checking kubectl"
   ST=`date +%s`
   oiri_cli "kubectl get pods -n $OIRINS" > $LOGDIR/check_kubectl.log 2>&1
   grep -q "NAME" $LOGDIR/check_kubectl.log
   print_status $?  $LOGDIR/check_kubectl.log
   ET=`date +%s`
   print_time STEP "Validate kubectl" $ST $ET >> $LOGDIR/timings.log
}

# Copy Kubernetes CA certificate to the oiri-cli pod
#
copy_cacert()
{ 
   print_msg "Copying Kubernetes ca.crt File to DING"
   ST=`date +%s`
   copy_to_oiri $WORKDIR/ca.crt /app $DINGNS oiri-ding-cli > $LOGDIR/copy_cacert.log 2>&1
   print_status $RETCODE $LOGDIR/copy_cacert.log
   ET=`date +%s`
   print_time STEP "Copy Kubernetes ca.crt File to DING " $ST $ET >> $LOGDIR/timings.log
}

# Create OIRI configuration files used by the deployment.
#
setup_config_files()
{
   print_msg "Create intial Config Files"
   ST=`date +%s`
    k8url=`grep server: $KUBECONFIG | sed 's/server://;s/ //g'`
    echo oiri_cli "/oiri-cli/scripts/setupConfFiles.sh -m prod \
             --oigdbhost $OIRI_OIG_DB_SCAN \
             --oigdbport $OIRI_OIG_DB_LISTENER \
             --oigdbsname $OIRI_OIG_DB_SERVICE \
             --oiridbhost $OIRI_DB_SCAN \
             --oiridbport $OIRI_DB_LISTENER \
             --oiridbsname $OIRI_DB_SERVICE \
             --sparkmode k8s \
             --dingnamespace $DINGNS \
             --dingimage $OIRI_DING_IMAGE:$OIRIDING_VER \
             --cookiesecureflag false \
             --k8scertificatefilename ca.crt \
             --sparkk8smasterurl k8s://${k8url} \
             --oigserverurl $OIRI_OIG_URL " > $LOGDIR/setup_config.log
    oiri_cli "/oiri-cli/scripts/setupConfFiles.sh -m prod \
             --oigdbhost $OIRI_OIG_DB_SCAN \
             --oigdbport $OIRI_OIG_DB_LISTENER \
             --oigdbsname $OIRI_OIG_DB_SERVICE \
             --oiridbhost $OIRI_DB_SCAN \
             --oiridbport $OIRI_DB_LISTENER \
             --oiridbsname $OIRI_DB_SERVICE \
             --sparkmode k8s \
             --dingnamespace $DINGNS \
             --dingimage $OIRI_DING_IMAGE:$OIRIDING_VER \
             --cookiesecureflag false \
             --k8scertificatefilename ca.crt \
             --sparkk8smasterurl k8s://${k8url} \
             --oigserverurl $OIRI_OIG_URL " >> $LOGDIR/setup_config.log
   print_status $? $LOGDIR/setup_config.log
   ET=`date +%s`
   print_time STEP "Create intial Config Files" $ST $ET >> $LOGDIR/timings.log
}

# Create Helm files to deploy OIRI
#
setup_helm_files()
{
   print_msg "Create helm Files"
   ST=`date +%s`

    echo "/oiri-cli/scripts/setupValuesYaml.sh  \
              --oiriapiimage $OIRI_IMAGE:$OIRI_VER \
              --oirinamespace $OIRINS \
              --oirinfsserver $PVSERVER \
              --oirireplicas $OIRI_REPLICAS \
              --oiriuireplicas $OIRI_UI_REPLICAS \
              --sparkhistoryserverreplicas $OIRI_SPARK_REPLICAS \
              --oirinfsstoragepath $OIRI_SHARE \
              --oirinfsstoragecapacity $OIRI_SHARE_SIZE \
              --oiriuiimage $OIRI_UI_IMAGE:$OIRIUI_VER \
              --dingimage $OIRI_DING_IMAGE:$OIRIDING_VER \
              --dingnamespace $DINGNS \
              --dingnfsserver $PVSERVER \
              --dingnfsstoragepath $OIRI_DING_SHARE \
              --dingnfsstoragecapacity $OIRI_DING_SHARE_SIZE \
              --ingressenabled false \
              --ingresshostname $OIRI_INGRESS_HOST \
              --sslenabled false "  > $LOGDIR/setup_helm_files.sh
    oiri_cli "/oiri-cli/scripts/setupValuesYaml.sh  \
              --oiriapiimage $OIRI_IMAGE:$OIRI_VER \
              --oirinamespace $OIRINS \
              --oirinfsserver $PVSERVER \
              --oirireplicas $OIRI_REPLICAS \
              --oiriuireplicas $OIRI_UI_REPLICAS \
              --sparkhistoryserverreplicas $OIRI_SPARK_REPLICAS \
              --oirinfsstoragepath $OIRI_SHARE \
              --oirinfsstoragecapacity $OIRI_SHARE_SIZE \
              --oiriuiimage $OIRI_UI_IMAGE:$OIRIUI_VER \
              --dingimage $OIRI_DING_IMAGE:$OIRIDING_VER \
              --dingnamespace $DINGNS \
              --dingnfsserver $PVSERVER \
              --dingnfsstoragepath $OIRI_DING_SHARE \
              --dingnfsstoragecapacity $OIRI_DING_SHARE_SIZE \
              --ingressenabled false \
              --ingresshostname $OIRI_INGRESS_HOST \
              --sslenabled false "  >> $LOGDIR/setup_helm_files.sh 2>&1
   print_status $? $LOGDIR/setup_helm_files.sh
   ET=`date +%s`
   print_time STEP "Create Helm  Config Files" $ST $ET >> $LOGDIR/timings.log
}

# Create OIRI keystore
#
create_keystore()
{
   print_msg "Creating OIRI Keystore"
   ST=`date +%s`
   printf "\n\t\t\tCreating Command - "

   echo "#!/bin/bash" > $WORKDIR/create_keystore.sh
   echo "keytool -genkeypair -alias oiri -keypass $OIRI_KEYSTORE_PWD -keyalg RSA \
             -keystore /app/oiri/data/keystore/keystore.jks \
             -storepass $OIRI_KEYSTORE_PWD -storetype pkcs12 \
             -dname \"CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=Unknown\" \
             -noprompt"  >> $WORKDIR/create_keystore.sh
   copy_to_oiri $WORKDIR/create_keystore.sh /app/k8s $OIRINS oiri-cli >> $LOGDIR/create_keystore.log 2>&1
   print_status $RETCODE $LOGDIR/create_keystore.log

   printf "\t\t\tCreating Keystore - "
   oiri_cli "chmod 700 /app/k8s/create_keystore.sh">> $LOGDIR/create_keystore.log 2>&1
   oiri_cli "/app/k8s/create_keystore.sh" >> $LOGDIR/create_keystore.log 2>&1
   
   print_status $? $LOGDIR/create_keystore.log
   ET=`date +%s`
   print_time STEP "Create OIRI Keystore" $ST $ET >> $LOGDIR/timings.log
}

# Import internal OIG certificate to OIRI
#
get_oig_certificate()
{
   print_msg "Obtaining OIG Certificate"
   ST=$(date +%s)
   if [ "$OIRI_OIG_XELL_FILE" = "" ]
   then
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "keytool -export -rfc -alias xell \
               -file $PV_MOUNT/workdir/xell.pem \
               -keystore $PV_MOUNT/domains/$OIG_DOMAIN_NAME/config/fmwconfig/default-keystore.jks \
               -storepass $OIG_WEBLOGIC_PWD" > $LOGDIR/get_oig_cert.log
     print_status $? 

     printf "\t\t\tCopy Certificate to working directory - "
     copy_from_k8 $PV_MOUNT/workdir/xell.pem $WORKDIR/xell.pem $OIGNS $OIG_DOMAIN_NAME >> $LOGDIR/get_oig_cert.log 2>&1
     print_status $RETCODE $LOGDIR/get_oig_cert.log 

     printf "\t\t\tCopy Certificate PEM to working directory - "
     copy_to_oiri $WORKDIR/xell.pem /app/k8s/xell.pem $OIRINS oiri-cli >> $LOGDIR/get_oig_cert.log 2>&1
     print_status $RETCODE $LOGDIR/get_oig_cert.log 
   else
     printf "\t\t\tCopy Certificate PEM to working directory - "
     copy_to_oiri $OIRI_OIG_XELL_FILE /app/k8s/xell.pem $OIRINS oiri-cli >> $LOGDIR/get_oig_cert.log 2>&1
     print_status $RETCODE $LOGDIR/get_oig_cert.log 
   fi

   printf "\t\t\tImport OIG Certificate into OIRI - "
   oiri_cli "keytool -import \
               -alias xell \
               -file /app/k8s/xell.pem \
               -keystore /app/oiri/data/keystore/keystore.jks\
               -storepass  $OIRI_KEYSTORE_PWD -noprompt" >> $LOGDIR/get_oig_cert.log 2>&1
   print_status $? $LOGDIR/get_oig_cert.log

   if [ "$OIG_LBR_PROTOCOL" = "https" ]
   then
     printf "\t\t\tGet Loadbalancer Certificate - "
     get_lbr_certificate $OIG_LBR_HOST $OIG_LBR_PORT >> $LOGDIR/get_oig_cert.log 2>&1
     grep -q Failed $LOGDIR/get_oig_cert.log
     if [ $? = 0 ]
     then 
       echo "Failed see logfile $LOGDIR/get_oig_cert.log"
     else
       echo "Success"
     fi 

     printf "\t\t\tCopy Loadbalancer Certificate - "
     copy_to_oiri $WORKDIR/$OIG_LBR_HOST.pem /app/k8s/$OIG_LBR_HOST.pem $OIRINS oiri-cli >> $LOGDIR/get_oig_cert.log 2>&1
     print_status $RETCODE $LOGDIR/get_oig_cert.log

     printf "\t\t\tImport OIG Loadbalancer Certificate into OIRI - "
     oiri_cli "keytool -import \
                 -alias oigssl \
                 -file /app/k8s/$OIG_LBR_HOST.pem \
                 -keystore /app/oiri/data/keystore/keystore.jks\
                 -storepass  $OIRI_KEYSTORE_PWD -noprompt" >> $LOGDIR/get_oig_cert.log 2>&1
     print_status $? $LOGDIR/get_oig_cert.log
   fi

   ET=`date +%s`
   print_time STEP "Obtain and Load OIG Certificates" $ST $ET >> $LOGDIR/timings.log
}

# Create a wallet in OIRI with user/database details
#
create_wallet()
{
   print_msg "Creating Wallet"
   ST=`date +%s`
   oiri_cli "oiri-cli --config=/app/data/conf/config.yaml wallet create \
             --oigsau $OIRI_SERVICE_USER \
             --oigsap $OIRI_SERVICE_PWD \
             --oirijka oiri \
             --oirijkp $OIRI_KEYSTORE_PWD \
             --oiriksp $OIRI_KEYSTORE_PWD \
             --oiridbuprefix $OIRI_RCU_PREFIX \
             --oiridbp $OIRI_SCHEMA_PWD \
             --oigdbu ${OIG_RCU_PREFIX}_OIM \
             --oigdbp $OIG_SCHEMA_PWD  " > $LOGDIR/create_wallet.log
   print_status $? $LOGDIR/create_wallet.log

   ET=`date +%s`
   print_time STEP "Create Wallet" $ST $ET >> $LOGDIR/timings.log
}

# Create OIRI database schemas
#
create_schemas()
{
   print_msg "Creating schemas"
   ST=`date +%s`
   oiri_cli "oiri-cli --config=/app/data/conf/config.yaml schema create /app/data/conf/dbconfig.yaml \
             --sysp $OIRI_DB_SYS_PWD " > $LOGDIR/create_schemas.log
   print_status $? $LOGDIR/create_schemas.log

   ET=`date +%s`
   print_time STEP "Create Schemas" $ST $ET >> $LOGDIR/timings.log

}

# Delete OIRI database schemas
#
delete_schemas()
{
   echo -n "Dropping schemas - "
   ST=`date +%s`
   oiri_cli "oiri-cli --config=/app/data/conf/config.yaml schema drop /app/data/conf/dbconfig.yaml \
             --sysp $OIRI_DB_SYS_PWD " > $LOGDIR/drop_schemas.log
   print_status $? $LOGDIR/drop_schemas.log
 
   ET=`date +%s`
   print_time STEP "Create Schemas" $ST $ET >> $LOGDIR/timings.log

}

# Migrate OIRI database schema
#
migrate_schemas()
{
   print_msg "Migrating schemas"
   ST=`date +%s`
   oiri_cli "oiri-cli --config=/app/data/conf/config.yaml schema migrate /app/data/conf/dbconfig.yaml" > $LOGDIR/migrate.log
   print_status $? $LOGDIR/migrate.log

   ET=`date +%s`
   print_time STEP "Migrate Schemas" $ST $ET >> $LOGDIR/timings.log
}

# Create OIRI users in OIG
#
create_users()
{
   ST=`date +%s`
   print_msg "Creating Users"
   cp $TEMPLATE_DIR/createAdminUser.sh $WORKDIR

   USERFILE=$WORKDIR/createAdminUser.sh

   # Perform variable substitution in template files
   #
   update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $USERFILE
   update_variable "<OIRI_OIG_XELSYSADM_USER>" $OIRI_OIG_XELSYSADM_USER $USERFILE
   update_variable "<OIRI_OIG_USER_PWD>" $OIRI_OIG_USER_PWD $USERFILE
   update_variable "<OIRI_ENG_USER>" $OIRI_ENG_USER $USERFILE
   update_variable "<OIRI_ENG_PWD>" $OIRI_ENG_PWD $USERFILE
   update_variable "<OIRI_ENG_GROUP>" $OIRI_ENG_GROUP $USERFILE
   update_variable "<OIRI_SERVICE_USER>" $OIRI_SERVICE_USER $USERFILE
   update_variable "<OIRI_SERVICE_PWD>" $OIRI_SERVICE_PWD $USERFILE
   update_variable "<OIRI_OIG_SERVER>" $OIRI_OIG_SERVER $USERFILE
 
   copy_to_k8 $TEMPLATE_DIR/createAdminUser.java workdir $OIGNS $OIG_DOMAIN_NAME
   copy_to_k8 $USERFILE workdir $OIGNS $OIG_DOMAIN_NAME

   run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/createAdminUser.sh "> $LOGDIR/create_users.log
   
   print_status $?  $LOGDIR/create_users.log

   ET=`date +%s`
   print_time STEP "Create Users" $ST $ET >> $LOGDIR/timings.log
}


# Place OIG into compliance Mode
#
set_compliance_mode()
{
   ST=`date +%s`
   print_msg "Enabling Oracle Identity Governance Compliance Mode"
   cp $TEMPLATE_DIR/setCompliance.sh $WORKDIR

   PROGFILE=$WORKDIR/setCompliance.sh

   # Perform variable substitution in template files
   #
   update_variable "<OIG_DB_SCAN>" $OIG_DB_SCAN $PROGFILE
   update_variable "<OIG_DB_LISTENER>" $OIG_DB_LISTENER $PROGFILE
   update_variable "<OIG_DB_SERVICE>" $OIG_DB_SERVICE $PROGFILE
   update_variable "<OIG_RCU_PREFIX>" $OIG_RCU_PREFIX $PROGFILE
   update_variable "<OIG_SCHEMA_PWD>" $OIG_SCHEMA_PWD $PROGFILE
 
   copy_to_k8 $TEMPLATE_DIR/setCompliance.java workdir $OIGNS $OIG_DOMAIN_NAME
   copy_to_k8 $PROGFILE workdir $OIGNS $OIG_DOMAIN_NAME
   run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/setCompliance.sh "> $LOGDIR/set_compliance.log
   grep -q "OIG.IsIdentityAuditorEnabled value: TRUE" $LOGDIR/set_compliance.log
   print_status $? $LOGDIR/set_compliance.log
   
   ET=`date +%s`
   print_time STEP "Enable Oracle Identity Governance Compliance " $ST $ET >> $LOGDIR/timings.log
}

# Validate the contents of the OIRI wallet
#
verify_wallet()
{
   print_msg "Verifying Wallet"
   ST=`date +%s`
   oiri_cli "./verifyWallet.sh" > $LOGDIR/verify_wallet.log
   
   grep -q FAILURE $LOGDIR/verify_wallet.log
   if [ $? = 0 ]
   then
     echo "Failed - See Logfile: $LOGDIR/verify_wallet.log"
     exit 1
   else 
     echo "Success"
   fi

   ET=`date +%s`
   print_time STEP "Verify Wallet" $ST $ET >> $LOGDIR/timings.log

}

# Deploy OIRI
#
deploy_oiri()
{
   print_msg "Deploying Oracle Identity Role Intelligence Helm Chart"
   ST=`date +%s`
 
   oiri_cli "helm install oiri /helm/oiri -f /app/k8s/values.yaml" > $LOGDIR/deploy_oiri.log
   print_status $? $LOGDIR/deploy_oiri.log

   ET=`date +%s`
   print_time STEP "Deploying Oracle Identity Role Intelligence Helm Chart" $ST $ET >> $LOGDIR/timings.log
}

# Create NodePort Services for OIRI
#
create_oiri_nodeport()
{
     ST=`date +%s`
     print_msg  "Creating OIRI Node Port Services"
     echo ""
     cp $TEMPLATE_DIR/*nodeport*.yaml $WORKDIR

     update_variable "<NAMESPACE>" $OIRINS $WORKDIR/oiri_nodeport.yaml
     update_variable "<NAMESPACE>" $OIRINS $WORKDIR/oiriui_nodeport.yaml

     update_variable "<OIRI_K8>" $OIRI_K8 $WORKDIR/oiri_nodeport.yaml
     update_variable "<OIRI_UI_K8>" $OIRI_UI_K8 $WORKDIR/oiriui_nodeport.yaml

     printf "\t\t\t\tOIRI - "
     kubectl create -f $WORKDIR/oiri_nodeport.yaml > $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
     print_status $? $LOGDIR/nodeport.log
     printf "\t\t\t\tOIRI UI - "
     kubectl create -f $WORKDIR/oiriui_nodeport.yaml >> $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
     print_status $? $LOGDIR/nodeport.log

     ET=`date +%s`
     print_time STEP "Create Kubernetes OAM NodePort Services " $ST $ET >> $LOGDIR/timings.log
}

# Verify the DING configuration
#
verify_ding()
{
   print_msg "Verifying Data Ingestion Configuration"
   ST=`date +%s`
 
   ding_cli "ding-cli --config=/app/data/conf/config.yaml data-ingestion verify /app/data/conf/data-ingestion-config.yaml" > $LOGDIR/verify_ding.log
   grep -q "SUCCESS: Data Ingestion Config is valid" $LOGDIR/verify_ding.log
   print_status $? $LOGDIR/verify_ding.log
   ET=`date +%s`
   print_time STEP "Verifying Data Ingestion Config" $ST $ET >> $LOGDIR/timings.log
}

# Obtain DING security token
#
get_ding_token()
{
   print_msg "Obtaining Ding Security Token"
   ST=`date +%s`
   kubectl describe secret $(kubectl describe serviceaccount ding-sa --namespace=$DINGNS | grep Token | awk '{print $2}') --namespace=$DINGNS | grep token: | awk '{print $2}' > $WORKDIR/ding-sa-token
   print_status $? 

   truncate -s -1 $WORKDIR/ding-sa-token
   printf "Copy token to DING - "
   copy_to_oiri $WORKDIR/ding-sa-token /app/data/conf $DINGNS oiri-ding-cli > $LOGDIR/copy_ding_cert.log 2>&1
   print_status $RETCODE $LOGDIR/copy_ding_cert.log

   ET=`date +%s`
   print_time STEP "Obtain DING security token" $ST $ET >> $LOGDIR/timings.log
}
 
# Perform a Ding data load
#
run_ding()
{
   ST=`date +%s`

   if [ "$OIRI_LOAD_DATA" = "true" ]
   then
       print_msg "Loading Data from OIG Database"
       ding_cli "ding-cli --config=/app/data/conf/config.yaml data-ingestion start /app/data/conf/data-ingestion-config.yaml" > $LOGDIR/data_load.log 2>&1
   else
       print_msg "Checking if OIRI can Load Data from OIG Database"
       ding_cli "ding-cli --config=/app/data/conf/config.yaml data-ingestion dry-run /app/data/conf/data-ingestion-config.yaml" > $LOGDIR/data_load.log 2>&1
   fi

   grep "Application status" $LOGDIR/data_load.log | grep -q "Succeeded"
   print_status $? $LOGDIR/data_load.log

   ET=`date +%s`
   print_time STEP "Load Data From OIG Database" $ST $ET >> $LOGDIR/timings.log
}

# Having perfored an initial data load set all data jobs to incremental
#
set_incremental()
{
   print_msg "Setting Data Ingestion to Incremental"
   ST=`date +%s`
 
   ding_cli "/ding-cli/scripts/updateDataIngestionConfig.sh \
                 --entityusersenabled true --entityuserssyncmode incremental \
                 --entityapplicationsenabled true --entityapplicationssyncmode incremental \
                 --entityentitlementsenabled true --entityentitlementssyncmode incremental \
                 --entityassignedentitlementsenabled true --entityassignedentitlementssyncmode incremental \
                 --entityrolesenabled true --entityrolessyncmode incremental \
                 --entityrolehierarchyenabled true --entityrolehierarchysyncmode incremental \
                 --entityroleusermembershipsenabled true --entityroleusermembershipssyncmode incremental \
                 --entityroleentitlementcompositionsenabled true --entityroleentitlementcompositionssyncmode incremental \
                 --entityaccountsenabled true --entityaccountssyncmode \
             " > $LOGDIR/set_incremental.log
   print_status $? $LOGDIR/set_incremental.log

   ET=`date +%s`
   print_time STEP "Setting Data Ingestion to Incremental" $ST $ET >> $LOGDIR/timings.log
}

# Create entries for OHS
#
create_ohs_entries()
{
   print_msg "Update OHS Files"
   echo
   ST=`date +%s`

 
   if [ "$USE_INGRESS" = "true" ]
   then
      OIRI_UI_K8=$INGRESS_HTTP_PORT
      OIRI_K8=$INGRESS_HTTP_PORT
   fi
   OHSHOST1FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST1
   OHSHOST2FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST2

   NODELIST=$(kubectl get nodes --no-headers=true  | cut -f1 -d ' ')

   if [ ! "$OHS_HOST1" = "" ]
   then
     create_location $TEMPLATE_DIR/locations.txt "$NODELIST" $OHSHOST1FILES
     print_status $?
   fi
   if [ ! "$OHS_HOST2" = "" ]
   then
     create_location $TEMPLATE_DIR/locations.txt "$NODELIST" $OHSHOST2FILES
   fi
   
   print_status $?

   ET=`date +%s`
   print_time STEP "Create OHS Entries" $ST $ET >> $LOGDIR/timings.log
}

# Create logstash configmap
#
create_logstash_cm()
{
   ST=`date +%s`
   print_msg "Creating logstash Config Map"
   cp $TEMPLATE_DIR/logstash_cm.yaml $WORKDIR

   update_variable "<OIRINS>" $OIRINS $WORKDIR/logstash_cm.yaml
   update_variable "<ELK_HOST>" $ELK_HOST $WORKDIR/logstash_cm.yaml

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
   ET=`date +%s`
   print_time STEP "Create Logstash Config Map" $ST $ET >> $LOGDIR/timings.log
}

# Modify the template to create a cronjob
#
create_dr_cronjob_files()
{
   ST=$(date +%s)
   print_msg "Creating Cron Job Files"

   cp $TEMPLATE_DIR/dr_cron.yaml $WORKDIR/dr_cron.yaml
   update_variable "<DRNS>" $DRNS $WORKDIR/dr_cron.yaml
   update_variable "<DR_OIRI_MINS>" $DR_OIRI_MINS $WORKDIR/dr_cron.yaml
   update_variable "<RSYNC_IMAGE>" $RSYNC_IMAGE $WORKDIR/dr_cron.yaml
   update_variable "<RSYNC_VER>" $RSYNC_VER $WORKDIR/dr_cron.yaml

   print_status $?

   ET=$(date +%s)
   print_time STEP "Create DR Cron Job Files" $ST $ET >> $LOGDIR/timings.log
}

# Create Persistent Volumes used by DR Job.
#
create_dr_pv()
{
   ST=$(date +%s)
   print_msg "Creating DR Persistent Volume"

   kubectl create -f $WORKDIR/dr_dr_pv.yaml > $LOGDIR/create_dr_pv.log 2>&1
   print_status $? $LOGDIR/create_dr_pv.log

   ET=$(date +%s)
   print_time STEP "Create DR Persistent Volume " $ST $ET >> $LOGDIR/timings.log
}

# Create Persistent Volume Claims used by DR Job.
#
create_dr_pvc()
{
   ST=$(date +%s)
   print_msg "Creating DR Persistent Volume Claim"
   kubectl create -f $WORKDIR/dr_dr_pvc.yaml > $LOGDIR/create_dr_pvc.log 2>&1
   print_status $? $LOGDIR/create_dr_pvc.log

   ET=$(date +%s)
   print_time STEP "Create DR Persistent Volume Claim " $ST $ET >> $LOGDIR/timings.log
}

# Delete the OIRI files created by a fresh installation.
#
delete_oiri_files()
{
   ST=$(date +%s)
   print_msg "Delete OIRI Files"

   if [ -e $OIRI_LOCAL_SHARE ] && [ ! "$OIRI_LOCAL_SHARE" = "" ]
   then
     echo rm -rf $OIRI_LOCAL_SHARE/domains $OIRI_LOCAL_SHARE/applications $OIRI_LOCAL_SHARE/stores $OIRI_LOCAL_SHARE/keystores  > $LOGDIR/delete_oiri.log 2>&1
     rm -rf $OIRI_LOCAL_SHARE/domains $OIRI_LOCAL_SHARE/applications $OIRI_LOCAL_SHARE/stores $OIRI_LOCAL_SHARE/keystores >> $LOGDIR/delete_oiri.log 2>&1
   else
     echo "Share does not exist, or OIRI_LOCAL_SHARE is not defined."
   fi

   if [ -e $OIRI_DING_LOCAL_SHARE ] && [ ! "$OIRI_DING_LOCAL_SHARE" = "" ]
   then
     echo rm -rf $OIRI_DING_LOCAL_SHARE/domains $OIRI_DING_LOCAL_SHARE/applications $OIRI_DING_LOCAL_SHARE/stores $OIRI_DING_LOCAL_SHARE/keystores  > $LOGDIR/delete_oiri.log 2>&1
     rm -rf $OIRI_DING_LOCAL_SHARE/domains $OIRI_DING_LOCAL_SHARE/applications $OIRI_DING_LOCAL_SHARE/stores $OIRI_DING_LOCAL_SHARE/keystores >> $LOGDIR/delete_oiri.log 2>&1
   else
     echo "Share does not exist, or OIRI_DING_LOCAL_SHARE is not defined."
   fi
   print_status $?  $LOGDIR/delete_oiri.log

   ET=$(date +%s)
   print_time STEP "Delete OIRI Files" $ST $ET >> $LOGDIR/timings.log
}

# Create OIRI PVs on the Standby Site
#
create_dr_source_pv()
{
   ST=$(date +%s)
   print_msg "Creating OIRI Persistent Volume"

   cp $TEMPLATE_DIR/dr_oiripv.yaml $WORKDIR/dr_oiripv.yaml
   update_variable "<PVSERVER>" $DR_STANDBY_PVSERVER $WORKDIR/dr_oiripv.yaml
   update_variable "<OIRI_SHARE>" $OIRI_STANDBY_SHARE $WORKDIR/dr_oiripv.yaml
   update_variable "<OIRI_DING_SHARE>" $OIRI_DING_STANDBY_SHARE $WORKDIR/dr_oiripv.yaml

   kubectl create -f $WORKDIR/dr_oiripv.yaml > $LOGDIR/dr_oiripv.log 2>&1
   print_status $? $LOGDIR/dr_oiripv.log

   ET=$(date +%s)
   print_time STEP "Create OIRI Persistent Volumes" $ST $ET >> $LOGDIR/timings.log
}

# Take a backup of the Kuberenetes Configuration files
#
backup_k8_files()
{
   ST=$(date +%s)
   print_msg "Backing up local Kubernetes config files "

   if [ ! "$OIRI_PRIMARY_K8CA" = "" ]
   then
      printf "\n\t\t\tBacking up DING ca.crt - "
      cp $OIRI_DING_LOCAL_SHARE/ca.crt $OIRI_DING_LOCAL_SHARE/$OIRI_PRIMARY_K8CA
      print_status $?
      printf "\t\t\tBacking up WORK ca.crt - "
      cp $OIRI_WORK_LOCAL_SHARE/ca.crt $OIRI_WORK_LOCAL_SHARE/$OIRI_PRIMARY_K8CA
      print_status $?
   fi

   if [ ! "$OIRI_PRIMARY_K8CONFIG" = "" ]
   then
      printf "\t\t\tBacking up DING config - "
      cp $OIRI_WORK_LOCAL_SHARE/config $OIRI_WORK_LOCAL_SHARE/$OIRI_PRIMARY_K8CONFIG
      print_status $?
   fi

   ET=$(date +%s)
   print_time STEP "Backup local Kubernetes configuration " $ST $ET >> $LOGDIR/timings.log
}
