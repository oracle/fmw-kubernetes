# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of functions and procedures to provision and Configure Oracle Identity Governance
#
#
# Usage: not invoked Directly
#


# Create Persistent Volumes
#
create_persistent_volumes()
{
     ST=`date +%s`
     print_msg "Creating Persistent Volumes"
     cd $WORKDIR/samples/create-weblogic-domain-pv-pvc
     replace_value2 domainUID $OIG_DOMAIN_NAME $PWD/create-pv-pvc-inputs.yaml
     replace_value2 namespace $OIGNS $PWD/create-pv-pvc-inputs.yaml
     replace_value2 baseName domain $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStorageType NFS $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStorageNFSServer $PVSERVER $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStoragePath $OIG_SHARE $PWD/create-pv-pvc-inputs.yaml

     rm output/pv-pvcs/$OIG_DOMAIN_NAME-* 2> /dev/null
     ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output > $LOGDIR/create_pvc.log 2> $LOGDIR/create_pv.log
     kubectl create -f output/pv-pvcs/$OIG_DOMAIN_NAME-domain-pv.yaml -n $OIGNS >> $LOGDIR/create_pvc.log 2> $LOGDIR/create_pv.log
     print_status $? $LOGDIR/create_pvc.log
     printf "\t\t\tCreating Persistent Volume Claims - "
     kubectl create -f output/pv-pvcs/$OIG_DOMAIN_NAME-domain-pvc.yaml -n $OIGNS> $LOGDIR/create_pvc.log 2> $LOGDIR/create_pvc.log
     print_status $? $LOGDIR/create_pvc.log
     ET=`date +%s`
     print_time STEP "Create Persistent Volumes" $ST $ET >> $LOGDIR/timings.log
}

# Edit sample domain Configuration File
#
edit_domain_creation_file()
{
     filename=$1

     print_msg "Creating Domain Configuration File"
     cp $WORKDIR/samples/create-oim-domain/domain-home-on-pv/create-domain-inputs.yaml $filename
     ST=`date +%s`
     if [  "$CREATE_REGSECRET" = "true" ]
     then
        replace_value2 imagePullSecretName regcred $filename
     fi
     replace_value2 domainUID $OIG_DOMAIN_NAME $filename
     replace_value2 domainPVMountPath $PV_MOUNT $filename
     replace_value2 domainHome $PV_MOUNT/domains/$OIG_DOMAIN_NAME $filename
     replace_value2 image $OIG_IMAGE:$OIG_VER $filename
     replace_value2 namespace $OIGNS $filename
     replace_value2 weblogicCredentialsSecretName $OIG_DOMAIN_NAME-credentials $filename
     replace_value2 persistentVolumeClaimName $OIG_DOMAIN_NAME-domain-pvc $filename
     replace_value2 logHome $PV_MOUNT/domains/logs/$OIG_DOMAIN_NAME   $filename
     replace_value2 rcuSchemaPrefix $OIG_RCU_PREFIX   $filename
     replace_value2 rcuDatabaseURL $OIG_DB_SCAN:$OIG_DB_LISTENER/$OIG_DB_SERVICE  $filename
     replace_value2 rcuCredentialsSecret $OIG_DOMAIN_NAME-rcu-credentials  $filename
     if [ "$USE_INGRESS" = "true" ]
     then
          replace_value2 exposeAdminNodePort false $filename
     else
          replace_value2 exposeAdminNodePort true $filename
     fi
     replace_value2 configuredManagedServerCount $OIG_SERVER_COUNT $filename
     replace_value2 initialManagedServerReplicas 1 $filename
     replace_value2 productionModeEnabled true $filename
     replace_value2 adminNodePort $OIG_ADMIN_K8 $filename
     replace_value2 adminPort $OIG_ADMIN_PORT $filename
     replace_value2 t3ChannelPort $OIG_ADMIN_T3_K8 $filename
     replace_value2 frontEndHost $OIG_LBR_HOST $filename
     replace_value2 frontEndPort $OIG_LBR_PORT $filename
     print_status $?
     printf "\t\t\tCopy saved to $WORKDIR\n"
     ET=`date +%s`
     print_time STEP "Create Domain Configuration File" $ST $ET >> $LOGDIR/timings.log
}

# Create the OIG domain
#
create_oig_domain()
{

     print_msg "Initialising the Domain"
     ST=`date +%s`
     cd $WORKDIR/samples/create-oim-domain/domain-home-on-pv

     ./create-domain.sh -i $WORKDIR/create-domain-inputs.yaml -o output > $LOGDIR/create_domain.log 2> $LOGDIR/create_domain.log

     grep -qs ERROR $LOGDIR/create_domain.log
     if [ $? = 0 ]
     then
         echo "Fail - Check logfile $LOGDIR/create_domain.log for details"
         exit 1
     fi
     status=`kubectl get pod -n $OIGNS | grep create | awk  '{ print $3}'`
     pod=`kubectl get pod -n $OIGNS | grep $OIG_DOMAIN_NAME | awk '{ print $1 }'`
     kubectl logs -n $OIGNS $pod | grep -q Failed
     if [ $? = 0 ]
     then
        echo "Fail - See kubectl logs -n $OIGNS $pod for details"
        exit 1
     fi

     kubectl logs -n $OIGNS $pod | grep -q "Successfully Completed"
     if [ $? = 1 ]
     then
        echo "Fail - See kubectl logs -n $OIGNS $pod for details"
        exit 1
     fi

     create_job=`kubectl get pod -n $OIGNS | grep create | awk  '{ print $1}'`
     if [ "$status" = "Pending" ] || [ "$status" = "Error" ]
     then
         kubectl describe job -n $OIGNS $create_job  >> $LOGDIR/create_domain.log 2>&1
         kubectl -n $OIGNS describe domain $OIG_DOMAIN_ID >> $LOGDIR/create_domain.log 2>&1
         kubectl logs -n $OIGNS $create_job >> $LOGDIR/create_domain.log 2>&1
         echo "Failed - See logfile $LOGDIR/create_domain.log"
         exit 1
     else
         echo "Success"
     fi
     ET=`date +%s`

     print_time STEP "Initialise the Domain" $ST $ET >> $LOGDIR/timings.log

}

# Update the oim_cluster memory parameters
#
update_java_parameters()
{
     printf "\t\t\tUpdating Java Parameters - "
     cp $TEMPLATE_DIR/oigDomain.sedfile $WORKDIR
     if [ "$OIG_ENABLE_T3" = "true" ]
     then
          OIMSERVER_JAVA_PARAMS="$OIMSERVER_JAVA_PARAMS -Dweblogic.rjvm.allowUnknownHost=true"
     fi
     update_variable "<OIMSERVER_JAVA_PARAMS>" "$OIMSERVER_JAVA_PARAMS" $WORKDIR/oigDomain.sedfile
     update_variable "<SOASERVER_JAVA_PARAMS>" "$SOASERVER_JAVA_PARAMS" $WORKDIR/oigDomain.sedfile

     sed -i -f $WORKDIR/oigDomain.sedfile output/weblogic-domains/$OIG_DOMAIN_NAME/domain_oim_soa.yaml
     print_status $?
}

# Start the OIG domain for the first time.
# start Admin server and SOA then OIM
#
perform_initial_start()
{
     # Start the Domain
     #
     print_msg "Starting the Domain for the first time"
     echo ""
     ST=`date +%s`
     cd $WORKDIR/samples/create-oim-domain/domain-home-on-pv
     cp output/weblogic-domains/$OIG_DOMAIN_NAME/domain_oim_soa.yaml output/weblogic-domains/$OIG_DOMAIN_NAME/domain_oim_soa.orig
     update_java_parameters

     kubectl apply -f output/weblogic-domains/$OIG_DOMAIN_NAME/domain.yaml > $LOGDIR/initial_start.log 2>&1

     # Check that the domain is started
     #
     check_running $OIGNS adminserver
     check_running $OIGNS soa-server1
 
     kubectl apply -f output/weblogic-domains/$OIG_DOMAIN_NAME/domain_oim_soa.yaml > $LOGDIR/initial_start.log 2>&1

     check_running $OIGNS oim-server1
  
     kubectl logs -n $OIGNS $OIG_DOMAIN_NAME-oim-server1 | grep -q "BootStrap configuration Successfull"
     if [ "$?" = "0" ]
     then 
          echo "BOOTSTRAP SUCCESSFULL" > $LOGDIR/initial_start.log 2>&1
     else
          echo "BOOTSTRAP FAILED - See kubectl logs -n $OIGNS $OIG_DOMAIN_NAME-oim-server1"
          exit 1
     fi
     ET=`date +%s`
     print_time STEP "First Domain Start " $ST $ET >> $LOGDIR/timings.log
}

# Create Ingress Services for OIG
#
create_oig_ingress_manual()
{
     ST=`date +%s`
     print_msg  "Creating OIG Ingress Services "
     cp $TEMPLATE_DIR/oig_ingress.yaml $WORKDIR
     filename=$WORKDIR/oig_ingress.yaml

     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $filename
     update_variable "<OIGNS>" $OIGNS $filename
     update_variable "<OIG_LBR_HOST>" $OIG_LBR_HOST $filename
     update_variable "<OIG_ADMIN_LBR_HOST>" $OIG_ADMIN_LBR_HOST $filename
     update_variable "<OIG_LBR_INT_HOST>" $OIG_LBR_INT_HOST $filename
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $filename

     kubectl create -f $filename > $LOGDIR/ingress.log 2>&1
     print_status $? $LOGDIR/ingress.log

     if [ "$OIG_ENABLE_T3" = "true" ]
     then
          printf "\t\t\tExposing OIM T3 - :"
          cp $TEMPLATE_DIR/design-console-ingress.yaml $WORKDIR
          update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/design-console-ingress.yaml
          cd $WORKDIR/samples
          helm install oig-designconsole-ingress design-console-ingress --namespace oigns --values $WORKDIR/design-console-ingress.yaml >> $LOGDIR/ingress.log 2>&1
          print_status $? $LOGDIR/ingress.log
     fi
     ET=`date +%s`
     print_time STEP "Create Kubernetes OIG Ingress Services " $ST $ET >> $LOGDIR/timings.log
}

create_oig_ingress()
{
     ST=`date +%s`
     print_msg  "Creating OIG Ingress Services "

     cp $WORKDIR/samples/charts/ingress-per-domain/values.yaml $WORKDIR/override_ingress.yaml
     filename=$WORKDIR/override_ingress.yaml

     replace_value2 sslType NONSSL $filename
     replace_value2 domainUID $OIG_DOMAIN_NAME $filename
     replace_value2  adminServerPort $OIG_ADMIN_PORT $filename
     replace_value2  enabled true $filename
     replace_value2 runtime $OIG_LBR_HOST $filename
     replace_value2 admin  $OIG_ADMIN_LBR_HOST $filename
     replace_value2 internal  $OIG_LBR_INT_HOST $filename

     cd $WORKDIR/samples
     helm install oig-nginx charts/ingress-per-domain --namespace $OIGNS --values $filename  > $LOGDIR/ingress.log 2>>$LOGDIR/ingress.log
     print_status $? $LOGDIR/ingress.log

     if [ "$OIG_ENABLE_T3" = "true" ]
     then
          printf "\t\t\tExposing OIM T3 - :"
          cp $WORKDIR/samples/design-console-ingress/values.yaml $WORKDIR/design-console-ingress.yaml
          replace_value2 domainUID $OIG_DOMAIN_NAME $WORKDIR/design-console-ingress.yaml
          helm install oig-designconsole-ingress design-console-ingress --namespace $OIGNS --values $WORKDIR/design-console-ingress.yaml >> $LOGDIR/design_console_ingress.log 2>&1
          print_status $? $LOGDIR/design_console_ingress.log
     fi
     ET=`date +%s`
     print_time STEP "Create Kubernetes OIG Ingress Services " $ST $ET >> $LOGDIR/timings.log
}
# Create NodePort Services for OIG
#
create_oig_nodeport()
{
     ST=`date +%s`
     print_msg  "Creating OIG NodePort Services"
     echo
     cp $TEMPLATE_DIR/*nodeport*.yaml $WORKDIR

     update_variable "<DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/soa_nodeport.yaml
     update_variable "<NAMESPACE>" $OIGNS $WORKDIR/soa_nodeport.yaml
     update_variable "<OIG_SOA_PORT_K8>" $OIG_SOA_PORT_K8 $WORKDIR/soa_nodeport.yaml
     update_variable "<DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/oim_nodeport.yaml
     update_variable "<NAMESPACE>" $OIGNS $WORKDIR/oim_nodeport.yaml
     update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $WORKDIR/oim_nodeport.yaml
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/oim_t3_nodeport.yaml
     update_variable "<NAMESPACE>" $OIGNS $WORKDIR/oim_t3_nodeport.yaml
     update_variable "<OIG_OIM_T3_PORT_K8>" $OIG_OIM_T3_PORT_K8 $WORKDIR/oim_t3_nodeport.yaml

     printf "\t\t\t\tSOA :"
     kubectl create -f $WORKDIR/soa_nodeport.yaml >> $LOGDIR/nodeport.log 2>&1
     print_status $? $LOGDIR/nodeport.log

     printf "\t\t\t\tOIM :"
     kubectl create -f $WORKDIR/oim_nodeport.yaml >> $LOGDIR/nodeport.log 2>&1
     print_status $? $LOGDIR/nodeport.log

     if [ "$OIG_ENABLE_T3" = "true" ]
     then
          printf "\t\t\t\tOIM T3:"
          kubectl create -f $WORKDIR/oim_t3_nodeport.yaml >> $LOGDIR/nodeport.log 2>&1
          print_status $? $LOGDIR/nodeport.log
     fi
     ET=`date +%s`
     print_time STEP "Create Kubernetes OIG NodePort Services " $ST $ET >> $LOGDIR/timings.log
}

# Create a working directory inside the Kubernetes container
#
copy_connector()
{

    ST=`date +%s`
    print_msg "Installing Connector into Container" 

    printf "\n\t\t\tCheck Connector Exists - "
    if [ -d $CONNECTOR_DIR/OID-12.2.1* ]
    then
          echo "Success"
    else
          echo " Connector Bundle not found.  Please download and stage before continuing"
          exit 1
    fi
   
    kubectl exec -ti $OIG_DOMAIN_NAME-oim-server1 -n $OIGNS -- mkdir -p /u01/oracle/user_projects/domains/ConnectorDefaultDirectory
    if ! [ "$?" = "0" ]
    then
       echo "Fail"
       exit 1
    fi
 
    printf "\t\t\tCopy Connector to container - "
    kubectl cp $CONNECTOR_DIR/OID-12.2*  $OIGNS/$OIG_DOMAIN_NAME-adminserver:/u01/oracle/user_projects/domains/ConnectorDefaultDirectory
    print_status $?

    ET=`date +%s`
    print_time STEP "Installing Connector into container" $ST $ET >> $LOGDIR/timings.log
}

# Create integration parameter files
#
create_connector_files()
{
      ST=`date +%s`
      print_msg "Creating Sed files to update OAM/OIG intregration config files"
 
      cp $TEMPLATE_DIR/autn.sedfile $WORKDIR
      cp $TEMPLATE_DIR/oamoig.sedfile $WORKDIR

     update_variable "<LDAP_OIGLDAP_USER>" $LDAP_OIGLDAP_USER $WORKDIR/autn.sedfile
     update_variable "<LDAP_SYSTEMIDS>" $LDAP_SYSTEMIDS $WORKDIR/autn.sedfile
     update_variable "<LDAP_SEARCHBASE>" $LDAP_SEARCHBASE $WORKDIR/autn.sedfile
     update_variable "<LDAP_USER_PWD>" $LDAP_USER_PWD $WORKDIR/autn.sedfile

     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/oamoig.sedfile
     update_variable "<OIGNS>" $OIGNS $WORKDIR/oamoig.sedfile
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/oamoig.sedfile
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/oamoig.sedfile
     update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/oamoig.sedfile
     update_variable "<OUDNS>" $OUDNS $WORKDIR/oamoig.sedfile
     update_variable "<LDAP_ADMIN_USER>" $LDAP_ADMIN_USER $WORKDIR/oamoig.sedfile
     update_variable "<LDAP_ADMIN_PWD>" $LDAP_ADMIN_PWD $WORKDIR/oamoig.sedfile
     update_variable "<LDAP_USER_SEARCHBASE>" $LDAP_USER_SEARCHBASE $WORKDIR/oamoig.sedfile
     update_variable "<LDAP_GROUP_SEARCHBASE>" $LDAP_GROUP_SEARCHBASE $WORKDIR/oamoig.sedfile
     update_variable "<LDAP_SEARCHBASE>" $LDAP_SEARCHBASE $WORKDIR/oamoig.sedfile
     update_variable "<LDAP_SYSTEMIDS>" $LDAP_SYSTEMIDS $WORKDIR/oamoig.sedfile
     update_variable "<LDAP_XELSYSADM_USER>" $LDAP_XELSYSADM_USER $WORKDIR/oamoig.sedfile
     update_variable "<OUD_XELSYSADM_PWD>" $LDAP_USER_PWD $WORKDIR/oamoig.sedfile
     update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/oamoig.sedfile
     update_variable "<OAMNS>" $OAMNS $WORKDIR/oamoig.sedfile
     update_variable "<OAM_OAP_PORT>" $OAM_OAP_PORT $WORKDIR/oamoig.sedfile
     update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $WORKDIR/oamoig.sedfile
     update_variable "<OAM_LOGIN_LBR_PORT>" $OAM_LOGIN_LBR_PORT $WORKDIR/oamoig.sedfile
     update_variable "<LDAP_USER_PWD>" $LDAP_USER_PWD $WORKDIR/oamoig.sedfile
     update_variable "<OAM_COOKIE_DOMAIN>" $OAM_COOKIE_DOMAIN $WORKDIR/oamoig.sedfile
     update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/oamoig.sedfile
     update_variable "<LDAP_OAMADMIN_USER>" $LDAP_OAMADMIN_USER $WORKDIR/oamoig.sedfile

     copy_to_k8 $WORKDIR/oamoig.sedfile workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $WORKDIR/autn.sedfile workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $TEMPLATE_DIR/create_oigoam_files.sh workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $TEMPLATE_DIR/create_oim_auth.sh workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $TEMPLATE_DIR/config_connector.sh workdir $OIGNS $OIG_DOMAIN_NAME

      run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 $PV_MOUNT/workdir/create_oigoam_files.sh"
      run_command_k8 $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/create_oigoam_files.sh 
      run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 /u01/oracle/idm/server/ssointg/bin/OIGOAMIntegration.sh"
      run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 /u01/oracle/idm/server/ssointg/bin/_OIGOAMIntegration.sh"

      print_status $? 
      ET=`date +%s`
      print_time STEP "Creating OAM/OIG intregration config files" $ST $ET >> $LOGDIR/timings.log
}

# Update the OIM_MDS data source to increase the connection pool parameters
#
update_mds()
{
     ST=`date +%s`
     print_msg "Updating MDS Datasource"

     cp $TEMPLATE_DIR/update_mds.py $WORKDIR

     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/update_mds.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/update_mds.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/update_mds.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/update_mds.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/update_mds.py

     copy_to_k8 $WORKDIR/update_mds.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/update_mds.py > $LOGDIR/update_mds.log
     print_status $WLSRETCODE $LOGDIR/update_mds.log

     ET=`date +%s`
     print_time STEP "Update MDS Datasource" $ST $ET >> $LOGDIR/timings.log
}

# Fix Gridlink Datasoureces
#
fix_gridlink()
{
     ST=`date +%s`
     print_msg "Enabling Database FAN"

     cp $TEMPLATE_DIR/fix_gridlink.sh $WORKDIR

     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/fix_gridlink.sh
     update_variable "<PV_MOUNT>" $PV_MOUNT $WORKDIR/fix_gridlink.sh

     copy_to_k8 $WORKDIR/fix_gridlink.sh workdir $OIGNS $OIG_DOMAIN_NAME
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 $PV_MOUNT/workdir/fix_gridlink.sh"
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/fix_gridlink.sh" $LOGDIR/fix_gridlink.log 2>&1
     print_status $?  $LOGDIR/fix_gridlink.log 2>&1
     ET=`date +%s`
     print_time STEP "Enabling DB FAN" $ST $ET >> $LOGDIR/timings.log

}

# Set WebLogic Plugin
#
set_weblogic_plugin()
{

     ST=`date +%s`
     print_msg "Setting WebLogic Plugin"
     cp $TEMPLATE_DIR/set_weblogic_plugin.py $WORKDIR
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/set_weblogic_plugin.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/set_weblogic_plugin.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/set_weblogic_plugin.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/set_weblogic_plugin.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/set_weblogic_plugin.py
  
     copy_to_k8 $WORKDIR/set_weblogic_plugin.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/set_weblogic_plugin.py > $LOGDIR/weblogic_plugin.log
     print_status $WLSRETCODE $LOGDIR/weblogic_plugin.log
     ET=`date +%s`
     print_time STEP "Set WebLogic Plug-in" $ST $ET >> $LOGDIR/timings.log
}

# Set T3 Channel Exit Points
#
enable_oim_T3()
{

     ST=`date +%s`
     print_msg "Enabling OIM T3 Channel"
     cp $TEMPLATE_DIR/set_oim_t3_channel.py $WORKDIR
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/set_oim_t3_channel.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/set_oim_t3_channel.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/set_oim_t3_channel.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/set_oim_t3_channel.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/set_oim_t3_channel.py
     update_variable "<OIG_OIM_T3_PORT_K8>" $OIG_OIM_T3_PORT_K8 $WORKDIR/set_oim_t3_channel.py
     update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $WORKDIR/set_oim_t3_channel.py
  
     copy_to_k8 $WORKDIR/set_oim_t3_channel.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/set_oim_t3_channel.py > $LOGDIR/set_oim_t3_channel.log
     print_status $WLSRETCODE $LOGDIR/set_oim_t3_channel.log
     ET=`date +%s`
     print_time STEP "Enable OIM T3 Channel" $ST $ET >> $LOGDIR/timings.log
}

# Create OUD Authenticator
#
create_oud_authenticator()
{

     ST=`date +%s`
     print_msg "Creating OUD Authenticator"
     cp $TEMPLATE_DIR/create_oud_authenticator.py $WORKDIR
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/create_oud_authenticator.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/create_oud_authenticator.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/create_oud_authenticator.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/create_oud_authenticator.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/create_oud_authenticator.py
     update_variable "<LDAP_GROUP_SEARCHBASE>" $LDAP_GROUP_SEARCHBASE $WORKDIR/create_oud_authenticator.py
     update_variable "<LDAP_USER_SEARCHBASE>" $LDAP_USER_SEARCHBASE $WORKDIR/create_oud_authenticator.py
     update_variable "<LDAP_OIGLDAP_USER>" $LDAP_OIGLDAP_USER $WORKDIR/create_oud_authenticator.py
     update_variable "<LDAP_SYSTEMIDS>" $LDAP_SYSTEMIDS $WORKDIR/create_oud_authenticator.py
     update_variable "<LDAP_SEARCHBASE>" $LDAP_SEARCHBASE $WORKDIR/create_oud_authenticator.py
     update_variable "<LDAP_USER_PWD>" $LDAP_USER_PWD $WORKDIR/create_oud_authenticator.py
     update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/create_oud_authenticator.py
     update_variable "<OUDNS>" $OUDNS $WORKDIR/create_oud_authenticator.py
  
     copy_to_k8 $WORKDIR/create_oud_authenticator.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/create_oud_authenticator.py > $LOGDIR/create_oud_authenticator.log
     print_status $WLSRETCODE $LOGDIR/create_oud_authenticator.log
     ET=`date +%s`
     print_time STEP "Create OUD Authenticator" $ST $ET >> $LOGDIR/timings.log
}


# Add LDAP Groups to WLS Admin Role
#
create_admin_roles()
{

     ST=`date +%s`
     print_msg "Create  WebLogic Admin Roles"
     cp $TEMPLATE_DIR/create_admin_roles.py $WORKDIR
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/create_admin_roles.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/create_admin_roles.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/create_admin_roles.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/create_admin_roles.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/create_admin_roles.py
  
     copy_to_k8 $WORKDIR/create_admin_roles.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/create_admin_roles.py > $LOGDIR/create_admin_roles.log
     print_status $WLSRETCODE $LOGDIR/create_admin_roles.log
     ET=`date +%s`
     print_time STEP "Create WebLogic Admin Roles" $ST $ET >> $LOGDIR/timings.log
}

#
# Update SOA URLS
#
update_soa_urls()
{
     ST=`date +%s`
     print_msg "Update SOA URLs"
     cp $TEMPLATE_DIR/update_soa.py $WORKDIR
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/update_soa.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/update_soa.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/update_soa.py
     update_variable "<LDAP_WLSADMIN_USER>" $LDAP_WLSADMIN_USER $WORKDIR/update_soa.py
     update_variable "<LDAP_USER_PWD>" $LDAP_USER_PWD $WORKDIR/update_soa.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/update_soa.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/update_soa.py
     update_variable "<OIG_LBR_INT_HOST>" $OIG_LBR_INT_HOST $WORKDIR/update_soa.py
     update_variable "<OIG_LBR_INT_PORT>" $OIG_LBR_INT_PORT $WORKDIR/update_soa.py
     update_variable "<OIG_LBR_PROTOCOL>" $OIG_LBR_PROTOCOL $WORKDIR/update_soa.py
     update_variable "<OIG_LBR_HOST>" $OIG_LBR_HOST $WORKDIR/update_soa.py
     update_variable "<OIG_LBR_PORT>" $OIG_LBR_PORT $WORKDIR/update_soa.py
  
     copy_to_k8 $WORKDIR/update_soa.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/update_soa.py > $LOGDIR/update_soa.log
     print_status $WLSRETCODE $LOGDIR/update_soa.log
     ET=`date +%s`
     print_time STEP "Update SOA URLS" $ST $ET >> $LOGDIR/timings.log
}

#
# Assign WSM Roles
#
assign_wsmroles()
{
     ST=`date +%s`
     print_msg "Assign WSM Roles"
     cp $TEMPLATE_DIR/assign_wsm_roles.py $WORKDIR
     filename=$WORKDIR/assign_wsm_roles.py
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $filename
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $filename
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $filename
     update_variable "<LDAP_WLSADMIN_USER>" $LDAP_WLSADMIN_USER $filename
     update_variable "<LDAP_USER_PWD>" $LDAP_USER_PWD $filename
     update_variable "<OIGNS>" $OIGNS $filename
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $filename
     update_variable "<LDAP_WLSADMIN_GRP>" $LDAP_WLSADMIN_GRP $filename
  
     copy_to_k8 $filename workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/assign_wsm_roles.py > $LOGDIR/assign_wsm_roles.log
     print_status $WLSRETCODE $LOGDIR/assign_wsm_roles.log
     ET=`date +%s`
     print_time STEP "Assign WSM Roles" $ST $ET >> $LOGDIR/timings.log
}

# Generate OIGOAMIntegration Parameter files
#
generate_parameter_files()
{
     ST=`date +%s`
     print_msg "Generate Integration Parameter Files"
     if  [ "$INSTALL_OAM" = "true" ] && [ "$OAM_OIG_INTEG" = "true" ]
     then
          cp $TEMPLATE_DIR/get_passphrase.py $WORKDIR

          update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/get_passphrase.py
          update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/get_passphrase.py
          update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/get_passphrase.py
          update_variable "<OAMNS>" $OAMNS $WORKDIR/get_passphrase.py

          copy_to_k8 $TEMPLATE_DIR/get_passphrase.sh workdir $OIGNS $OIG_DOMAIN_NAME
          copy_to_k8 $WORKDIR//get_passphrase.py workdir $OIGNS $OIG_DOMAIN_NAME

          print_status $?

          printf  "\t\t\tObtain Global Passphrase - "
          run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 /u01/oracle/idm/server/ssointg/bin/OIGOAMIntegration.sh"
          run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 /u01/oracle/idm/server/ssointg/bin/_OIGOAMIntegration.sh"
          run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 $PV_MOUNT/workdir/get_passphrase.sh"
          run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/get_passphrase.sh" >> $LOGDIR/get_passphrase.log 2>&1
          print_status $? $LOGDIR/get_passphrase.log

          printf "\t\t\tEdit Integration File - "
     fi
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/create_oigoam_files.sh"
     print_status $?
     ET=`date +%s`
     print_time STEP "Update SOA URLS" $ST $ET >> $LOGDIR/timings.log
}
     
     
# Generate OIGOAMIntegration Parameter files
#
configure_connector()
{
     ST=`date +%s`

     print_msg "Configure OID Connector"

     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/config_connector.sh "> $LOGDIR/configure_connector.log
     grep -q FAILED $LOGDIR/configure_connector.log
     if [ "$?" = "0" ]
     then
        echo "Failed - See Logfile $LOGDIR/configure_connector.log"
        exit 1
     else
        echo "Success"
     fi
     ET=`date +%s`
     print_time STEP "Configure OID Connector" $ST $ET >> $LOGDIR/timings.log
}

# Configure WLS Authenticators
#
create_wlsauthenticators()
{
     ST=`date +%s`

     print_msg "Configure WLS Authenticators"

     copy_to_k8 $TEMPLATE_DIR/createWLSAuthenticators.sh workdir $OIGNS $OIG_DOMAIN_NAME
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/createWLSAuthenticators.sh "> $LOGDIR/configureWLSAuthenticators.log
     grep -q FAILED $LOGDIR/configureWLSAuthenticators.log
     if [ "$?" = "0" ]
     then
        echo "Failed - Check Logfile $LOGDIR/configureWLSAuthenticators.log"
        exit 1
     else
        echo "Success"
     fi
     ET=`date +%s`
     print_time STEP "Configure WLS Authenticators" $ST $ET >> $LOGDIR/timings.log
}

# Add missing Object Classes to existing LDAP entries
#
add_object_classes()
{
     ST=`date +%s`

     print_msg  "Add Missing Object Classes to LDAP"

     copy_to_k8 $TEMPLATE_DIR/add_object_classes.sh workdir $OIGNS $OIG_DOMAIN_NAME
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/add_object_classes.sh "> $LOGDIR/add_object_classes.log
     print_status $? $LOGDIR/add_object_classes.log

     ET=`date +%s`
     print_time STEP "Add missing object classes to LDAP" $ST $ET >> $LOGDIR/timings.log
}

# Configure SSO Integration
#
configure_sso()
{
     ST=`date +%s`

     print_msg "Configure SSO Integration"

     copy_to_k8 $TEMPLATE_DIR/oam_integration.sh workdir $OIGNS $OIG_DOMAIN_NAME
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/oam_integration.sh "> $LOGDIR/oam_integration.log
     grep -q CONFIGURATION_FAILED $LOGDIR/oam_integration.log
     if [ "$?" = "0" ]
     then
        echo "Failed - check logfile $LOGDIR/oam_integration.log"
        exit 1
     else
        echo "Success"
     fi
     ET=`date +%s`
     print_time STEP "Configure SSO Integration" $ST $ET >> $LOGDIR/timings.log
}

# Enable OAM Notifications
#
enable_oam_notifications()
{
     ST=`date +%s`

     print_msg "Enable OAM Notifications"

     copy_to_k8 $TEMPLATE_DIR/oam_notifications.sh workdir $OIGNS $OIG_DOMAIN_NAME
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/oam_notifications.sh "> $LOGDIR/oam_notifications.log
     print_status $? $LOGDIR/oam_notifications.log
     ET=`date +%s`
     print_time STEP "Enable OAM Notifications" $ST $ET >> $LOGDIR/timings.log
}
# Update Match Attribute
#
update_match_attr()
{
     ST=`date +%s`
     print_msg "Update Match Attribute"
     MA=`curl -i -s -u $LDAP_OAMADMIN_USER:$LDAP_USER_PWD  http://$K8_WORKER_HOST1:$OAM_ADMIN_K8/iam/admin/config/api/v1/config?path=/DeployedComponent/Server/NGAMServer/Profile/AuthenticationModules/DAPModules | awk '/Name=\"DAPModules/{p=2} p > 0 { print $0; p--}' | tail -1 | cut -f2 -d\"`

     echo "<Configuration>" > /tmp/MatchLDAPAttribute_input.xml
     echo "  <Setting Name=\"MatchLDAPAttribute\" Type=\"xsd:string\" Path=\"/DeployedComponent/Server/NGAMServer/Profile/AuthenticationModules/DAPModules/${MA}/MatchLDAPAttribute\">uid</Setting>" >> /tmp/MatchLDAPAttribute_input.xml
     echo "</Configuration>" >> /tmp/MatchLDAPAttribute_input.xml

     curl -s -u $LDAP_OAMADMIN_USER:$LDAP_USER_PWD -H 'Content-Type: text/xml' -X PUT http://$K8_WORKER_HOST1:$OAM_ADMIN_K8/iam/admin/config/api/v1/config -d @/tmp/MatchLDAPAttribute_input.xml > $LOGDIR/update_matchattr.log
     print_status $?  $LOGDIR/update_matchattr.log
     ET=`date +%s`
     print_time STEP "Update Match Attribute" $ST $ET >> $LOGDIR/timings.log
}

#
# Run Recon Jobs
#
run_recon_jobs()
{

     ST=`date +%s`
     print_msg "Run Recon Jobs"

     cp $TEMPLATE_DIR/runJob.sh $WORKDIR/
     update_variable "<LDAP_XELSYSADM_USER>" $LDAP_XELSYSADM_USER $WORKDIR/runJob.sh
     update_variable "<LDAP_USER_PWD>" $LDAP_USER_PWD $WORKDIR/runJob.sh
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/runJob.sh
     update_variable "<OIGNS>" $OIGNS $WORKDIR/runJob.sh

     copy_to_k8 $TEMPLATE_DIR/runJob.java workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $WORKDIR/runJob.sh workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $TEMPLATE_DIR/lib workdir $OIGNS $OIG_DOMAIN_NAME


     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/runJob.sh "> $LOGDIR/recon_jobs.log 2>&1

     print_status $?  $LOGDIR/recon_jobs.log
     ET=`date +%s`
     print_time STEP "Run Recon Jobs" $ST $ET >> $LOGDIR/timings.log
}

#
# Update BI Config
#
update_biconfig()
{

     ST=`date +%s`
     print_msg "Update BI Integration"

     cp $TEMPLATE_DIR/update_bi.py $WORKDIR
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/update_bi.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/update_bi.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/update_bi.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/update_bi.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/update_bi.py
     update_variable "<OIG_BI_PROTOCOL>" $OIG_BI_PROTOCOL $WORKDIR/update_bi.py
     update_variable "<OIG_BI_HOST>" $OIG_BI_HOST $WORKDIR/update_bi.py
     update_variable "<OIG_BI_PORT>" $OIG_BI_PORT $WORKDIR/update_bi.py
     update_variable "<OIG_BI_USER>" $OIG_BI_USER $WORKDIR/update_bi.py
     update_variable "<OIG_BI_USER_PWD>" $OIG_BI_USER_PWD $WORKDIR/update_bi.py

     copy_to_k8 $WORKDIR/update_bi.py  workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/update_bi.py > $LOGDIR/update_bi.log
     print_status $WLSRETCODE $LOGDIR/update_bi.log
     ET=`date +%s`
     print_time STEP "Update BI Integration" $ST $ET >> $LOGDIR/timings.log
}

#
# Create Email Driver
#
create_email_driver()
{

     ST=`date +%s`
     print_msg "Create Email Driver"

     cp $TEMPLATE_DIR/create_email.py $WORKDIR

     filename=$WORKDIR/create_email.py

     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $filename
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $filename
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $filename
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $filename
     update_variable "<OIGNS>" $OIGNS $filename
     update_variable "<OIG_EMAIL_SERVER>" $OIG_EMAIL_SERVER $filename
     update_variable "<OIG_EMAIL_PORT>" $OIG_EMAIL_PORT $filename
     if [ "$OIG_EMAIL_SECURITY" = "" ]
     then
         sed -i '/OutgoingMailServerSecurity/d' $filename
     else
         update_variable "<OIG_EMAIL_SECURITY>" $OIG_EMAIL_SECURITY $filename
     fi
     if [ "$OIG_EMAIL_PWD" = "" ]
     then
         sed -i '/OutgoingPassword/d' $filename
     else
         update_variable "<OIG_EMAIL_PWD>" $OIG_EMAIL_PWD $filename
     fi

     update_variable "<OIG_EMAIL_ADDRESS>" $OIG_EMAIL_ADDRESS $filename
     copy_to_k8 $filename  workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/create_email.py > $LOGDIR/create_email.log

     print_status $WLSRETCODE $LOGDIR/create_email.log
     ET=`date +%s`
     print_time STEP "Create Email Driver" $ST $ET >> $LOGDIR/timings.log
}

#
# Set Notifications to Email
#
set_email_notifications()
{

     ST=`date +%s`
     print_msg "Set Notifications to Email"

     cp $TEMPLATE_DIR/update_notifications.py $WORKDIR

     filename=$WORKDIR/update_notifications.py

     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $filename
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $filename
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $filename
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $filename
     update_variable "<OIGNS>" $OIGNS $filename
     update_variable "<OIG_EMAIL_FROM_ADDRESS>" $OIG_EMAIL_FROM_ADDRESS $filename
     update_variable "<OIG_EMAIL_REPLY_ADDRESS>" $OIG_EMAIL_REPLY_ADDRESS $filename

     copy_to_k8 $filename  workdir $OIGNS $OIG_DOMAIN_NAME
     kubectl exec -n $OIGNS -ti $OIG_DOMAIN_NAME-adminserver -- /u01/oracle/soa/common/bin/wlst.sh $PV_MOUNT/workdir/update_notifications.py > $LOGDIR/update_notifications.log

     print_status $? $LOGDIR/update_notifications.log
     ET=`date +%s`
     print_time STEP "Set Notifications to Email" $ST $ET >> $LOGDIR/timings.log
}
#
# Update SOA Config
#
update_soaconfig()
{

     ST=`date +%s`
     print_msg "Update SOA Config"

     cp $TEMPLATE_DIR/update_soaconfig.py $WORKDIR
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/update_soaconfig.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/update_soaconfig.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/update_soaconfig.py
     update_variable "<LDAP_WLSADMIN_USER>" $LDAP_WLSADMIN_USER $WORKDIR/update_soaconfig.py
     update_variable "<LDAP_USER_PWD>" $LDAP_USER_PWD $WORKDIR/update_soaconfig.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/update_soaconfig.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/update_soaconfig.py
     update_variable "<LDAP_WLSADMIN_GRP>" $LDAP_WLSADMIN_GRP $WORKDIR/update_soaconfig.py

     copy_to_k8 $WORKDIR/update_soaconfig.py  workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/update_soaconfig.py > $LOGDIR/update_soaconfig.log 2>&1
     print_status $WLSRETCODE $LOGDIR/update_soaconfig.log
     ET=`date +%s`
     print_time STEP "Update SOA Integration" $ST $ET >> $LOGDIR/timings.log
}
# Add Loadbalancer Certs to Oracle Keystore Service
#
add_certs_to_kss()
{
     ST=`date +%s`
     print_msg "Add Certificates to Oracle Keystore Service"
     echo "connect('$OIG_WEBLOGIC_USER','$OIG_WEBLOGIC_PWD','t3://$OIG_DOMAIN_NAME-adminserver.$OIGNS.svc.cluster.local:$OIG_ADMIN_PORT') " > $WORKDIR/add_cert_to_kss.py
     echo "svc = getOpssService(name='KeyStoreService')" >> $WORKDIR/add_cert_to_kss.py

     for cert in `ls -1 $WORKDIR/*.pem`
     do
           aliasname=`basename $cert | sed 's/.pem//'`
           echo "svc.importKeyStoreCertificate(appStripe='system',name='trust',password='', keypassword='',alias='$aliasname',type='TrustedCertificate', filepath='$PV_MOUNT/keystores/$aliasname.pem')" >> $WORKDIR/add_cert_to_kss.py
           copy_to_k8 $cert  keystores $OIGNS $OIG_DOMAIN_NAME
     done
     echo "syncKeyStores(appStripe='system', keystoreFormat='KSS')" >> $WORKDIR/add_cert_to_kss.py
     echo "exit()" >> $WORKDIR/add_cert_to_kss.py
     
     copy_to_k8 $WORKDIR/add_cert_to_kss.py  workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/add_cert_to_kss.py > $LOGDIR/add_cert_to_kss.log 2>&1
     print_status $WLSRETCODE $LOGDIR/add_cert_to_kss.log
     ET=`date +%s`
     print_time STEP "Add Certificates to Keystore" $ST $ET >> $LOGDIR/timings.log
}

# 
# Create OIG Config Files
#
create_oig_ohs_config()
{
   ST=`date +%s`


   print_msg "Creating OHS Conf files"
   OHS_PATH=$LOCAL_WORKDIR/OHS
   if ! [ -d $OHS_PATH/$OHS_HOST1 ]
   then
        mkdir -p $OHS_PATH/$OHS_HOST1
   fi
   if ! [ -d $OHS_PATH/$OHS_HOST2 ]
   then
        mkdir -p $OHS_PATH/$OHS_HOST2
   fi

   if [ ! "$OHS_HOST1" = "" ]
   then
      cp $TEMPLATE_DIR/igdadmin_vh.conf $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
      cp $TEMPLATE_DIR/igdinternal_vh.conf $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
      cp $TEMPLATE_DIR/prov_vh.conf $OHS_PATH/$OHS_HOST1/prov_vh.conf

      update_variable "<OHS_HOST>" $OHS_HOST1 $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
      update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
      update_variable "<OIG_ADMIN_LBR_HOST>" $OIG_ADMIN_LBR_HOST $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
      update_variable "<OIG_ADMIN_LBR_PORT>" $OIG_ADMIN_LBR_PORT $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
      update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
      update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST2 $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf

      update_variable "<OHS_HOST>" $OHS_HOST1 $OHS_PATH/$OHS_HOST1/prov_vh.conf
      update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST1/prov_vh.conf
      update_variable "<OIG_LBR_PROTOCOL>" $OIG_LBR_PROTOCOL $OHS_PATH/$OHS_HOST1/prov_vh.conf
      update_variable "<OIG_LBR_HOST>" $OIG_LBR_HOST $OHS_PATH/$OHS_HOST1/prov_vh.conf
      update_variable "<OIG_LBR_PORT>" $OIG_LBR_PORT $OHS_PATH/$OHS_HOST1/prov_vh.conf
      update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/prov_vh.conf
      update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST2 $OHS_PATH/$OHS_HOST1/prov_vh.conf

      update_variable "<OHS_HOST>" $OHS_HOST1 $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
      update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
      update_variable "<OIG_LBR_INT_PROTOCOL>" $OIG_LBR_INT_PROTOCOL $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
      update_variable "<OIG_LBR_INT_HOST>" $OIG_LBR_INT_HOST $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
      update_variable "<OIG_LBR_INT_PORT>" $OIG_LBR_INT_PORT $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
      update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
      update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST2 $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf

      if [ "$USE_INGRESS" = "true" ]
      then
         update_variable "<OIG_OIM_PORT_K8>" $INGRESS_HTTP_PORT $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
         update_variable "<OIG_OIM_PORT_K8>" $INGRESS_HTTP_PORT $OHS_PATH/$OHS_HOST1/prov_vh.conf
         update_variable "<OIG_SOA_PORT_K8>" $INGRESS_HTTP_PORT $OHS_PATH/$OHS_HOST1/prov_vh.conf
         update_variable "<OIG_OIM_PORT_K8>" $INGRESS_HTTP_PORT $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
         update_variable "<OIG_SOA_PORT_K8>" $INGRESS_HTTP_PORT $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
         update_variable "<OIG_ADMIN_K8>" $INGRESS_HTTP_PORT $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
      else
         update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
         update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $OHS_PATH/$OHS_HOST1/prov_vh.conf
         update_variable "<OIG_SOA_PORT_K8>" $OIG_SOA_PORT_K8 $OHS_PATH/$OHS_HOST1/prov_vh.conf
         update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
         update_variable "<OIG_SOA_PORT_K8>" $OIG_SOA_PORT_K8 $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
         update_variable "<OIG_ADMIN_K8>" $OIG_ADMIN_K8 $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
      fi

   fi

   if [ ! "$OHS_HOST2" = "" ] 
   then
      cp  $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf
      cp $OHS_PATH/$OHS_HOST1/prov_vh.conf $OHS_PATH/$OHS_HOST2/prov_vh.conf
      cp $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf
      sed -i "s/$OHS_HOST1/$OHS_HOST2/" $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf
      sed -i "s/$OHS_HOST1/$OHS_HOST2/" $OHS_PATH/$OHS_HOST2/prov_vh.conf
      sed -i "s/$OHS_HOST1/$OHS_HOST2/" $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf
   fi
   
   print_status $?

   ET=`date +%s`
   print_time STEP "Creating OHS config" $ST $ET >> $LOGDIR/timings.log
}

# Create logstash configmap
#
create_logstash_cm()
{
   ST=`date +%s`
   print_msg "Creating logstash Config Map"
   cp $TEMPLATE_DIR/logstash_cm.yaml $WORKDIR

   update_variable "<OIGNS>" $OIGNS $WORKDIR/logstash_cm.yaml
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
   ET=`date +%s`
   print_time STEP "Create Logstash Config Map" $ST $ET >> $LOGDIR/timings.log
}

# Deploy WebLogic Monitoring Service
#
generate_wls_monitor()
{
   ST=`date +%s`
   print_msg "Generate WebLogic Monitoring Service"

   cd $WORKDIR/samples/monitoring-service/scripts
   export adminServerPort=$OIG_ADMIN_PORT
   export wlsMonitoringExporterTosoaCluster=true
   export soaManagedServerPort=8001
   export wlsMonitoringExporterTooimCluster=true
   export oimManagedServerPort=14000
   export domainNamespace=$OIGNS
   export domainUID=$OIG_DOMAIN_NAME
   export weblogicCredentialsSecretName=$OIG_DOMAIN_NAME-credentials

   $PWD/get-wls-exporter.sh > $LOGDIR/generate_wls_monitor.log 2>&1
   print_status $? $LOGDIR/generate_wls_monitor.log
   ET=`date +%s`
   print_time STEP "Generate WebLogic Monitoring Service" $ST $ET >> $LOGDIR/timings.log

}

deploy_wls_monitor()
{
   ST=`date +%s`
   print_msg "Deploy WebLogic Monitoring Service"

   cd $WORKDIR/samples/monitoring-service/scripts

   printf "\n\t\t\tCopy Deployment Script 1 - "
   kubectl cp $WORKDIR/samples/monitoring-service/scripts/wls-exporter-deploy  $OIGNS/$OIG_DOMAIN_NAME-adminserver:/u01/oracle > $LOGDIR/deploy_wls_monitor.log 2>&1
   print_status $? $LOGDIR/deploy_wls_monitor.log

   printf "\t\t\tCopy Deployment Script 2 - "
   kubectl cp $WORKDIR/samples/monitoring-service/scripts/deploy-weblogic-monitoring-exporter.py  $OIGNS/$OIG_DOMAIN_NAME-adminserver:/u01/oracle/wls-exporter-deploy > $LOGDIR/deploy_wls_monitor.log 2>&1
   print_status $? $LOGDIR/deploy_wls_monitor.log


   printf "\t\t\tDeploy monitoring service - "
   run_wlst_command $OIGNS $OIG_DOMAIN_NAME "/u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py -domainName $OIG_DOMAIN_NAME -adminServerName AdminServer -adminURL $OIG_DOMAIN_NAME-adminserver:$OIG_ADMIN_PORT -username $OIG_WEBLOGIC_USER -password $OIG_WEBLOGIC_PWD -oimClusterName oim_cluster -wlsMonitoringExporterTooimCluster true -soaClusterName soa_cluster -wlsMonitoringExporterTosoaCluster true" >> $LOGDIR/deploy_wls_monitor.log 2>&1

   print_status $WLSRETCODE $LOGDIR/deploy_wls_monitor.log

   ET=`date +%s`
   print_time STEP "Deploy WebLogic Monitoring Service" $ST $ET >> $LOGDIR/timings.log

}

enable_monitor()
{
   ST=`date +%s`
   print_msg "Configuring Prometheus Operator"

   ENC_WEBLOGIC_USER=`encode_pwd $OIG_WEBLOGIC_USER`
   ENC_WEBLOGIC_PWD=`encode_pwd $OIG_WEBLOGIC_PWD`


   replace_value2 domainName $OIG_DOMAIN_NAME $WORKDIR/samples/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml
   replace_value2 namespace $OIGNS $WORKDIR/samples/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml
   sed -i  "/namespaceSelector/,/-/{s/-.*/- $OIGNS/}" $WORKDIR/samples/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml

   replace_value2 namespace $OIGNS $WORKDIR/samples/monitoring-service/manifests/prometheus-roleSpecific-domain-namespace.yaml
   sed -i  "0,/namespace/{s/namespace:.*/namespace: $OIGNS/}" $WORKDIR/samples/monitoring-service/manifests/prometheus-roleBinding-domain-namespace.yaml

   sed -i '0,/password/{s/'password':.*/'password': '"$ENC_WEBLOGIC_PWD"'/}' $WORKDIR/samples/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml
   sed -i '0,/user/{s/'user':.*/'user': '"$ENC_WEBLOGIC_USER"'/}' $WORKDIR/samples/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml

   kubectl apply -f $WORKDIR/samples/monitoring-service/manifests/ > $LOGDIR/enable_monitor.log
   print_status $? $LOGDIR/enable_monitor.log

   ET=`date +%s`
   print_time STEP "Configure Prometheus Operator" $ST $ET >> $LOGDIR/timings.log

}
