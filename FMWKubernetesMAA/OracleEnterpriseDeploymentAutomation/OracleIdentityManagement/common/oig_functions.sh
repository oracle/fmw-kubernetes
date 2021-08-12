# Copyright (c) 2021, Oracle and/or its affiliates.
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
     echo  -n "Creating Persistent Volumes - "
     cd $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc
     replace_value2 domainUID $OIG_DOMAIN_NAME $PWD/create-pv-pvc-inputs.yaml
     replace_value2 namespace $OIGNS $PWD/create-pv-pvc-inputs.yaml
     replace_value2 baseName domain $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStorageType NFS $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStorageNFSServer $PVSERVER $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStoragePath $OIG_SHARE $PWD/create-pv-pvc-inputs.yaml

     rm output/pv-pvcs/$OIG_DOMAIN_NAME-* 2> /dev/null
     ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output > $LOGDIR/create_pvc.log 2> $LOGDIR/create_pv.log
     kubectl create -f output/pv-pvcs/$OIG_DOMAIN_NAME-domain-pv.yaml -n $OIGNS >> $LOGDIR/create_pvc.log 2> $LOGDIR/create_pv.log
     if [ "$?" = "1" ]
     then 
         echo "Failed to create PV"
         exit 1
     fi
     kubectl create -f output/pv-pvcs/$OIG_DOMAIN_NAME-domain-pvc.yaml -n $OIGNS> $LOGDIR/create_pvc.log 2> $LOGDIR/create_pvc.log
     if [ "$?" = "1" ]
     then 
         echo "Failed to create PV"
         exit 1
     else
         echo "Success"
     fi
     ET=`date +%s`
     print_time STEP "Create Persistent Volumes" $ST $ET >> $LOGDIR/timings.log
}

# Edit sample domain Configuration File
#
edit_domain_creation_file()
{
     filename=$1

     echo -n "Creating Domain Configuration File -"
     cp $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv/create-domain-inputs.yaml $filename
     ST=`date +%s`
     replace_value2 domainUID $OIG_DOMAIN_NAME $filename
     replace_value2 domainPVMountPath $PV_MOUNT $filename
     replace_value2 domainHome $PV_MOUNT/domains/$OIG_DOMAIN_NAME $filename
     replace_value2 image oracle/oig:12.2.1.4.0 $filename
     replace_value2 namespace $OIGNS $filename
     replace_value2 weblogicCredentialsSecretName $OIG_DOMAIN_NAME-credentials $filename
     replace_value2 persistentVolumeClaimName $OIG_DOMAIN_NAME-domain-pvc $filename
     replace_value2 logHome $PV_MOUNT/domains/logs/$OIG_DOMAIN_NAME   $filename
     replace_value2 rcuSchemaPrefix $OIG_RCU_PREFIX   $filename
     replace_value2 rcuDatabaseURL $OIG_DB_SCAN:$OIG_DB_LISTENER/$OIG_DB_SERVICE  $filename
     replace_value2 rcuCredentialsSecret $OIG_DOMAIN_NAME-rcu-credentials  $filename
     replace_value2 exposeAdminNodePort true $filename
     replace_value2 configuredManagedServerCount $OIG_SERVER_COUNT $filename
     replace_value2 initialManagedServerReplicas 1 $filename
     replace_value2 productionModeEnabled true $filename
     replace_value2 adminNodePort $OIG_ADMIN_K8 $filename
     replace_value2 adminPort $OIG_ADMIN_PORT $filename
     replace_value2 frontEndHost $OIG_LBR_HOST $filename
     replace_value2 frontEndPort $OIG_LBR_PORT $filename
     echo "Success"
     echo ".. Copy saved to $WORKDIR/OIG"
     ET=`date +%s`
     print_time STEP "Create Domain Configuration File" $ST $ET >> $LOGDIR/timings.log
}

# Create the OIG domain
#
create_oig_domain()
{

     echo -n "Initialising the Domain - "
     ST=`date +%s`
     cd $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv

     ./create-domain.sh -i $WORKDIR/OIG/create-domain-inputs.yaml -o output > $LOGDIR/create_domain.log 2> $LOGDIR/create_domain.log

     grep -qs ERROR $LOGDIR/create_domain.log
     if [ $? = 0 ]
     then
         echo "Fail - Check logfile $LOGDIR/create_domain.log for details"
         exit 1
     fi
     status=`kubectl get pod -n $OIGNS | grep create | awk  '{ print $3}'`
     pod=`kubectl get pod -n $OIGNS | grep $OIG_DOMAIN_NAME | awk '{ print $1 }'`
     echo kubectl logs -n $OIGNS $pod | grep -q Failed
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

     if [ "$status" = "Pending" ]
     then
         echo "Domain creation failed"
         echo "Run the following commands to debug"
         echo "kubectl describe job -n $OIGNS $OIG_DOMAIN_ID-create-fmw-infra-sample-domain-job"
         echo "kubectl -n $OIGNS describe domain $OIG_DOMAIN_ID"
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
     echo "Updating Java Parameters"
     cp $TEMPLATE_DIR/oigDomain.sedfile $WORKDIR/OIG
     if [ "$OIG_ENABLE_T3" = "true" ]
     then
          OIMSERVER_JAVA_PARAMS="$OIMSERVER_JAVA_PARAMS -Dweblogic.rjvm.allowUnknownHost=true"
     fi
     update_variable "<OIMSERVER_JAVA_PARAMS>" "$OIMSERVER_JAVA_PARAMS" $WORKDIR/OIG/oigDomain.sedfile

     sed -i -f $WORKDIR/OIG/oigDomain.sedfile output/weblogic-domains/$OIG_DOMAIN_NAME/domain_oim_soa.yaml
}

# Start the OIG domain for the first time.
# start Admin server and SOA then OIM
#
perform_initial_start()
{
     # Start the Domain
     #
     echo "Starting the Domain for the first time"
     echo ""
     ST=`date +%s`
     cd $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv
     cp output/weblogic-domains/$OIG_DOMAIN_NAME/domain_oim_soa.yaml output/weblogic-domains/$OIG_DOMAIN_NAME/domain_oim_soa.orig
     update_java_parameters

     kubectl apply -f output/weblogic-domains/$OIG_DOMAIN_NAME/domain.yaml

     # Check that the domain is started
     #
     check_running $OIGNS adminserver
     check_running $OIGNS soa-server1
 
     sleep 120
     echo ""
     kubectl apply -f output/weblogic-domains/governancedomain/domain_oim_soa.yaml

     check_running $OIGNS oim-server1
  
     kubectl logs -n $OIGNS $OIG_DOMAIN_NAME-oim-server1 | grep -q "BootStrap configuration Successfull"
     if [ "$?" = "0" ]
     then 
          echo "BOOTSTRAP SUCCESSFULL"
     else
          echo "BOOTSTRAP FAILED"
          exit 1
     fi
     ET=`date +%s`
     print_time STEP "First Domain Start " $ST $ET >> $LOGDIR/timings.log
}

# Create Kubernetes Reigstry Secret
#
create_registry_secret()
{
     echo "Creating Registry Secret"
     ST=`date +%s`
     kubectl create secret docker-registry oig-docker -n $OIGNS --docker-username='<user_name>' --docker-password='<password>' --docker-server='<docker_registry_url>' --docker-email='<email_address>'
     ET=`date +%s`

     print_time STEP "Create Registry Secret" $ST $ET >> $LOGDIR/timings.log
}

# Create NodePort Services for OIG
#
create_oig_nodeport()
{
     ST=`date +%s`
     echo "Creating OIG Services "
     cp $TEMPLATE_DIR/*nodeport*.yaml $WORKDIR/OIG

     update_variable "<DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/soa_nodeport.yaml
     update_variable "<NAMESPACE>" $OIGNS $WORKDIR/OIG/soa_nodeport.yaml
     update_variable "<OIG_SOA_PORT_K8>" $OIG_SOA_PORT_K8 $WORKDIR/OIG/soa_nodeport.yaml
     update_variable "<DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/oim_nodeport.yaml
     update_variable "<NAMESPACE>" $OIGNS $WORKDIR/OIG/oim_nodeport.yaml
     update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $WORKDIR/OIG/oim_nodeport.yaml
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/oim_t3_nodeport.yaml
     update_variable "<NAMESPACE>" $OIGNS $WORKDIR/OIG/oim_t3_nodeport.yaml
     update_variable "<OIG_OIM_T3_PORT_K8>" $OIG_OIM_T3_PORT_K8 $WORKDIR/OIG/oim_t3_nodeport.yaml

     echo -n "  SOA :"
     kubectl create -f $WORKDIR/OIG/soa_nodeport.yaml >> $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
     if [ $? -eq 0 ]
     then
         echo  "Success"
     else
         echo  "Failed"

     fi
     echo -n "  OIM Service NodePort:"
     kubectl create -f $WORKDIR/OIG/oim_nodeport.yaml >> $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
     if [ $? -eq 0 ]
     then
         echo  "Success"
     else
         echo  "Failed"

     fi

     if [ "$OIG_ENABLE_T3" = "true" ]
     then
          echo -n "  OIM T3 Service NodePort:"
          kubectl create -f $WORKDIR/OIG/oim_t3_nodeport.yaml >> $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
          if [ $? -eq 0 ]
          then
              echo  "Success"
          else
              echo  "Failed"
          fi
     fi
     ET=`date +%s`
     print_time STEP "Create Kubernetes OIG NodePort Services " $ST $ET >> $LOGDIR/timings.log
}

# Create a working directory inside the Kubernetes container
#
copy_connector()
{

    ST=`date +%s`
    echo -n "Installing Connector into Container" - 

   
    kubectl exec -ti $OIG_DOMAIN_NAME-oim-server1 -n $OIGNS -- mkdir -p /u01/oracle/user_projects/ConnectorDefaultDirectory
    if ! [ "$?" = "0" ]
    then
       echo "Fail"
       exit 1
    fi
 
    kubectl cp $CONNECTOR_DIR/OID-12.2*  $OIGNS/$OIG_DOMAIN_NAME-adminserver:/u01/oracle/user_projects/ConnectorDefaultDirectory
    if ! [ "$?" = "0" ]
    then
       echo "Fail"
       exit 1
    else
       echo "Success"
    fi


     ET=`date +%s`

     print_time STEP "Installing Connector into container" $ST $ET >> $LOGDIR/timings.log
}

# Create integration parameter files
#
create_connector_files()
{
      ST=`date +%s`
      echo -n "Creating Sed files to update OAM/OIG intregration config files - "
 
      cp $TEMPLATE_DIR/autn.sedfile $WORKDIR/OIG
      cp $TEMPLATE_DIR/oamoig.sedfile $WORKDIR/OIG

     update_variable "<OUD_OIGLDAP_USER>" $OUD_OIGLDAP_USER $WORKDIR/OIG/autn.sedfile
     update_variable "<OUD_SYSTEMIDS>" $OUD_SYSTEMIDS $WORKDIR/OIG/autn.sedfile
     update_variable "<OUD_SEARCHBASE>" $OUD_SEARCHBASE $WORKDIR/OIG/autn.sedfile
     update_variable "<OUD_USER_PWD>" $OUD_USER_PWD $WORKDIR/OIG/autn.sedfile

     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUDNS>" $OUDNS $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_ADMIN_USER>" $OUD_ADMIN_USER $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_ADMIN_PWD>" $OUD_ADMIN_PWD $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_USER_SEARCHBASE>" $OUD_USER_SEARCHBASE $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_GROUP_SEARCHBASE>" $OUD_GROUP_SEARCHBASE $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_SEARCHBASE>" $OUD_SEARCHBASE $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_SYSTEMIDS>" $OUD_SYSTEMIDS $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_XELSYSADM_USER>" $OUD_XELSYSADM_USER $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_XELSYSADM_PWD>" $OUD_USER_PWD $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OAMNS>" $OAMNS $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OAM_OAP_PORT>" $OAM_OAP_PORT $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OAM_LOGIN_LBR_PORT>" $OAM_LOGIN_LBR_PORT $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_USER_PWD>" $OUD_USER_PWD $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OAM_COOKIE_DOMAIN>" $OAM_COOKIE_DOMAIN $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/OIG/oamoig.sedfile
     update_variable "<OUD_OAMADMIN_USER>" $OUD_OAMADMIN_USER $WORKDIR/OIG/oamoig.sedfile

     copy_to_k8 $WORKDIR/OIG/oamoig.sedfile workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $WORKDIR/OIG/autn.sedfile workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $TEMPLATE_DIR/create_oigoam_files.sh workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $TEMPLATE_DIR/create_oim_auth.sh workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $TEMPLATE_DIR/config_connector.sh workdir $OIGNS $OIG_DOMAIN_NAME

      run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 $PV_MOUNT/workdir/create_oigoam_files.sh"
      run_command_k8 $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/create_oigoam_files.sh 
      run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 /u01/oracle/idm/server/ssointg/bin/OIGOAMIntegration.sh"
      run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 /u01/oracle/idm/server/ssointg/bin/_OIGOAMIntegration.sh"

      echo "Success"
      ET=`date +%s`
      print_time STEP "Creating OAM/OIG intregration config files" $ST $ET >> $LOGDIR/timings.log
}

# Update the OIM_MDS data source to increase the connection pool parameters
#
update_mds()
{
     ST=`date +%s`
     echo -n "Updating MDS Datasource - "

     cp $TEMPLATE_DIR/update_mds.py $WORKDIR/OIG

     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/update_mds.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/update_mds.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/OIG/update_mds.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/OIG/update_mds.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/OIG/update_mds.py

     copy_to_k8 $WORKDIR/OIG/update_mds.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/update_mds.py > $LOGDIR/update_mds.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Update MDS Datasource" $ST $ET >> $LOGDIR/timings.log
}

# Fix Gridlink Datasoureces
#
fix_gridlink()
{
     ST=`date +%s`
     echo -n "Enabling Database FAN - "

     cp $TEMPLATE_DIR/fix_gridlink.sh $WORKDIR/OIG

     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/fix_gridlink.sh
     update_variable "<PV_MOUNT>" $PV_MOUNT $WORKDIR/OIG/fix_gridlink.sh

     copy_to_k8 $WORKDIR/OIG/fix_gridlink.sh workdir $OIGNS $OIG_DOMAIN_NAME
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 $PV_MOUNT/workdir/fix_gridlink.sh"
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/fix_gridlink.sh"
     echo "Success"
     ET=`date +%s`
     print_time STEP "Enabling DB FAN" $ST $ET >> $LOGDIR/timings.log

}

# Set WebLogic Plugin
#
set_weblogic_plugin()
{

     ST=`date +%s`
     echo -n "Setting WebLogic Plugin - "
     cp $TEMPLATE_DIR/set_weblogic_plugin.py $WORKDIR/OIG
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/set_weblogic_plugin.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/OIG/set_weblogic_plugin.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/OIG/set_weblogic_plugin.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/set_weblogic_plugin.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/OIG/set_weblogic_plugin.py
  
     copy_to_k8 $WORKDIR/OIG/set_weblogic_plugin.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/set_weblogic_plugin.py > $LOGDIR/weblogic_plugin.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Set WebLogic Plug-in" $ST $ET >> $LOGDIR/timings.log
}

# Set T3 Channel Exit Points
#
enable_oim_T3()
{

     ST=`date +%s`
     echo -n "Enabling OIM T3 Channel - "
     cp $TEMPLATE_DIR/set_oim_t3_channel.py $WORKDIR/OIG
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/set_oim_t3_channel.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/OIG/set_oim_t3_channel.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/OIG/set_oim_t3_channel.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/set_oim_t3_channel.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/OIG/set_oim_t3_channel.py
     update_variable "<OIG_OIM_T3_PORT_K8>" $OIG_OIM_T3_PORT_K8 $WORKDIR/OIG/set_oim_t3_channel.py
     update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $WORKDIR/OIG/set_oim_t3_channel.py
  
     copy_to_k8 $WORKDIR/OIG/set_oim_t3_channel.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/set_oim_t3_channel.py > $LOGDIR/set_oim_t3_channel.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Enable OIM T3 Channel" $ST $ET >> $LOGDIR/timings.log
}

# Create OUD Authenticator
#
create_oud_authenticator()
{

     ST=`date +%s`
     echo -n "Creating OUD Authenticator - "
     cp $TEMPLATE_DIR/create_oud_authenticator.py $WORKDIR/OIG
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OUD_GROUP_SEARCHBASE>" $OUD_GROUP_SEARCHBASE $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OUD_USER_SEARCHBASE>" $OUD_USER_SEARCHBASE $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OUD_OIGLDAP_USER>" $OUD_OIGLDAP_USER $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OUD_SYSTEMIDS>" $OUD_SYSTEMIDS $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OUD_SEARCHBASE>" $OUD_SEARCHBASE $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OUD_USER_PWD>" $OUD_USER_PWD $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/OIG/create_oud_authenticator.py
     update_variable "<OUDNS>" $OUDNS $WORKDIR/OIG/create_oud_authenticator.py
  
     copy_to_k8 $WORKDIR/OIG/create_oud_authenticator.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/create_oud_authenticator.py > $LOGDIR/create_oud_authenticator.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Create OUD Authenticator" $ST $ET >> $LOGDIR/timings.log
     #create_oam_asserter
}

# Create OAM Asserter
#
create_oam_asserter()
{

     ST=`date +%s`
     echo -n "Creating OAM Asserter - "
     cp $TEMPLATE_DIR/create_oam_asserter.py $WORKDIR/OIG
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/create_oam_asserter.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/OIG/create_oam_asserter.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/OIG/create_oam_asserter.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/create_oam_asserter.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/OIG/create_oam_asserter.py
  
     copy_to_k8 $WORKDIR/OIG/create_oam_asserter.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/create_oam_asserter.py > $LOGDIR/create_oam_asserter.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Create OAM Asserter" $ST $ET >> $LOGDIR/timings.log
}

# Add LDAP Groups to WLS Admin Role
#
create_admin_roles()
{

     ST=`date +%s`
     echo -n "Create  WebLogic Admin Roles - "
     cp $TEMPLATE_DIR/create_admin_roles.py $WORKDIR/OIG
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/create_admin_roles.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/OIG/create_admin_roles.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/OIG/create_admin_roles.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/create_admin_roles.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/OIG/create_admin_roles.py
  
     copy_to_k8 $WORKDIR/OIG/create_admin_roles.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/create_admin_roles.py > $LOGDIR/create_admin_roles.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Create WebLogic Admin Roles" $ST $ET >> $LOGDIR/timings.log
}

#
# Update SOA URLS
#
update_soa_urls()
{
     ST=`date +%s`
     echo -n "Update SOA URLs -"
     cp $TEMPLATE_DIR/update_soa.py $WORKDIR/OIG
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/update_soa.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/OIG/update_soa.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/OIG/update_soa.py
     update_variable "<OUD_WLSADMIN_USER>" $OUD_WLSADMIN_USER $WORKDIR/OIG/update_soa.py
     update_variable "<OUD_USER_PWD>" $OUD_USER_PWD $WORKDIR/OIG/update_soa.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/update_soa.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/OIG/update_soa.py
     update_variable "<OIG_LBR_INT_HOST>" $OIG_LBR_INT_HOST $WORKDIR/OIG/update_soa.py
     update_variable "<OIG_LBR_INT_PORT>" $OIG_LBR_INT_PORT $WORKDIR/OIG/update_soa.py
     update_variable "<OIG_LBR_PROTOCOL>" $OIG_LBR_PROTOCOL $WORKDIR/OIG/update_soa.py
     update_variable "<OIG_LBR_HOST>" $OIG_LBR_HOST $WORKDIR/OIG/update_soa.py
     update_variable "<OIG_LBR_PORT>" $OIG_LBR_PORT $WORKDIR/OIG/update_soa.py
  
     copy_to_k8 $WORKDIR/OIG/update_soa.py workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/update_soa.py > $LOGDIR/update_soa.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Update SOA URLS" $ST $ET >> $LOGDIR/timings.log
}

# Generate OIGOAMIntegration Parameter files
#
generate_parameter_files()
{
     ST=`date +%s`
     echo -n "Generate Integration Parameter Files - "
     if  [ "$INSTALL_OAM" = "true" ] && [ "$OAM_OIG_INTEG" = "true" ]
     then
          cp $TEMPLATE_DIR/get_passphrase.py $WORKDIR/OIG

          update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OIG/get_passphrase.py
          update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/OIG/get_passphrase.py
          update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/OIG/get_passphrase.py
          update_variable "<OAMNS>" $OAMNS $WORKDIR/OIG/get_passphrase.py

          copy_to_k8 $TEMPLATE_DIR/get_passphrase.sh workdir $OIGNS $OIG_DOMAIN_NAME
          copy_to_k8 $WORKDIR/OIG//get_passphrase.py workdir $OIGNS $OIG_DOMAIN_NAME

          echo "Success"

          echo -n "  Obtain Global Passphrase - "
          run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 /u01/oracle/idm/server/ssointg/bin/OIGOAMIntegration.sh"
          run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 /u01/oracle/idm/server/ssointg/bin/_OIGOAMIntegration.sh"
          run_command_k8 $OIGNS $OIG_DOMAIN_NAME "chmod 750 $PV_MOUNT/workdir/get_passphrase.sh"
          run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/get_passphrase.sh"
          echo "Success"
          echo -n "  Edit Integration File - "
     fi
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/create_oigoam_files.sh"
     echo "Success"
     ET=`date +%s`
     print_time STEP "Update SOA URLS" $ST $ET >> $LOGDIR/timings.log
}
     
     
# Generate OIGOAMIntegration Parameter files
#
configure_connector()
{
     ST=`date +%s`

     echo -n "Configure OID Connector - "

     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/config_connector.sh "> $LOGDIR/configure_connector.log
     grep -q FAILED $LOGDIR/configure_connector.log
     if [ "$?" = "0" ]
     then
        echo "Failed"
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

     echo -n "Configure WLS Authenticators - "

     copy_to_k8 $TEMPLATE_DIR/createWLSAuthenticators.sh workdir $OIGNS $OIG_DOMAIN_NAME
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/createWLSAuthenticators.sh "> $LOGDIR/configureWLSAuthenticators.log
     grep -q FAILED $LOGDIR/configureWLSAuthenticators.log
     if [ "$?" = "0" ]
     then
        echo "Failed"
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

     echo -n "Add Missing Object Classes to LDAP - "

     copy_to_k8 $TEMPLATE_DIR/add_object_classes.sh workdir $OIGNS $OIG_DOMAIN_NAME
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/add_object_classes.sh "> $LOGDIR/add_object_classes.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Add missing object classes to LDAP" $ST $ET >> $LOGDIR/timings.log
}

# Configure SSO Integration
#
configure_sso()
{
     ST=`date +%s`

     echo -n "Configure SSO Integration - "

     copy_to_k8 $TEMPLATE_DIR/oam_integration.sh workdir $OIGNS $OIG_DOMAIN_NAME
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/oam_integration.sh "> $LOGDIR/oam_integration.log
     grep -q CONFIGURATION_FAILED $LOGDIR/oam_integration.log
     if [ "$?" = "0" ]
     then
        echo "Failed"
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

     echo -n "Enable OAM Notifications - "

     copy_to_k8 $TEMPLATE_DIR/oam_notifications.sh workdir $OIGNS $OIG_DOMAIN_NAME
     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/oam_notifications.sh "> $LOGDIR/oam_notifications.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Enable OAM Notifications" $ST $ET >> $LOGDIR/timings.log
}
# Update Match Attribute
#
update_match_attr()
{
     ST=`date +%s`
     echo "Update Match Attribute -"
     MA=`curl -i -s -u $OUD_OAMADMIN_USER:$OUD_USER_PWD  http://$K8_WORKER_HOST1:$OAM_ADMIN_K8/iam/admin/config/api/v1/config?path=/DeployedComponent/Server/NGAMServer/Profile/AuthenticationModules/DAPModules | awk '/Name=\"DAPModules/{p=2} p > 0 { print $0; p--}' | tail -1 | cut -f2 -d\"`

     echo "<Configuration>" > /tmp/MatchLDAPAttribute_input.xml
     echo "  <Setting Name=\"MatchLDAPAttribute\" Type=\"xsd:string\" Path=\"/DeployedComponent/Server/NGAMServer/Profile/AuthenticationModules/DAPModules/${MA}/MatchLDAPAttribute\">uid</Setting>" >> /tmp/MatchLDAPAttribute_input.xml
     echo "</Configuration>" >> /tmp/MatchLDAPAttribute_input.xml

     curl -s -u $OUD_OAMADMIN_USER:$OUD_USER_PWD -H 'Content-Type: text/xml' -X PUT http://$K8_WORKER_HOST1:$OAM_ADMIN_K8/iam/admin/config/api/v1/config -d @/tmp/MatchLDAPAttribute_input.xml
     echo "Success"
     ET=`date +%s`
     print_time STEP "Update Match Attribute" $ST $ET >> $LOGDIR/timings.log
}

#
# Run Recon Jobs
#
run_recon_jobs()
{

     ST=`date +%s`
     echo -n "Run Recon Jobs  Attribute -"

     cp $TEMPLATE_DIR/runJob.sh $WORKDIR/OIG/
     update_variable "<OUD_XELSYSADM_USER>" $OUD_XELSYSADM_USER $WORKDIR/OIG/runJob.sh
     update_variable "<OUD_USER_PWD>" $OUD_USER_PWD $WORKDIR/OIG/runJob.sh
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/runJob.sh
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/runJob.sh

     copy_to_k8 $TEMPLATE_DIR/runJob.class workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $TEMPLATE_DIR/runJob.java workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $WORKDIR/OIG/runJob.sh workdir $OIGNS $OIG_DOMAIN_NAME
     copy_to_k8 $TEMPLATE_DIR/lib workdir $OIGNS $OIG_DOMAIN_NAME


     run_command_k8 $OIGNS $OIG_DOMAIN_NAME "$PV_MOUNT/workdir/runJob.sh "> $LOGDIR/recon_jobs.log

     echo "Success"
     ET=`date +%s`
     print_time STEP "Run Recon Jobs" $ST $ET >> $LOGDIR/timings.log
}

#
# Update BI Config
#
update_biconfig()
{

     ST=`date +%s`
     echo -n "Update BI Integration - "

     cp $TEMPLATE_DIR/update_bi.py $WORKDIR/OIG
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/update_bi.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/OIG/update_bi.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/OIG/update_bi.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/OIG/update_bi.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/update_bi.py
     update_variable "<OIG_BI_PROTOCOL>" $OIG_BI_PROTOCOL $WORKDIR/OIG/update_bi.py
     update_variable "<OIG_BI_HOST>" $OIG_BI_HOST $WORKDIR/OIG/update_bi.py
     update_variable "<OIG_BI_PORT>" $OIG_BI_PORT $WORKDIR/OIG/update_bi.py
     update_variable "<OIG_BI_USER>" $OIG_BI_USER $WORKDIR/OIG/update_bi.py
     update_variable "<OIG_BI_USER_PWD>" $OIG_BI_USER_PWD $WORKDIR/OIG/update_bi.py

     copy_to_k8 $WORKDIR/OIG/update_bi.py  workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/update_bi.py > $LOGDIR/update_bi.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Update BI Integration" $ST $ET >> $LOGDIR/timings.log
}

#
# Update SOA Config
#
update_soaconfig()
{

     ST=`date +%s`
     echo -n "Update BI Integration - "

     cp $TEMPLATE_DIR/update_soaconfig.py $WORKDIR/OIG
     update_variable "<OIG_DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/OIG/update_soaconfig.py
     update_variable "<OIG_WEBLOGIC_USER>" $OIG_WEBLOGIC_USER $WORKDIR/OIG/update_soaconfig.py
     update_variable "<OIG_WEBLOGIC_PWD>" $OIG_WEBLOGIC_PWD $WORKDIR/OIG/update_soaconfig.py
     update_variable "<OUD_WLSADMIN_USER>" $OUD_WLSADMIN_USER $WORKDIR/OIG/update_soaconfig.py
     update_variable "<OUD_USER_PWD>" $OUD_USER_PWD $WORKDIR/OIG/update_soaconfig.py
     update_variable "<OIGNS>" $OIGNS $WORKDIR/OIG/update_soaconfig.py
     update_variable "<OIG_ADMIN_PORT>" $OIG_ADMIN_PORT $WORKDIR/OIG/update_soaconfig.py
     update_variable "<OUD_WLSADMIN_GRP>" $OUD_WLSADMIN_GRP $WORKDIR/OIG/update_soaconfig.py

     copy_to_k8 $WORKDIR/OIG/update_soaconfig.py  workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/update_soaconfig.py > $LOGDIR/update_soaconfig.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Update SOA Integration" $ST $ET >> $LOGDIR/timings.log
}
# Add Loadbalancer Certs to Oracle Keystore Service
#
add_certs_to_kss()
{
     ST=`date +%s`
     echo -n "Add Certificates to Oracle Keystore Service - "
     echo "connect('$OIG_WEBLOGIC_USER','$OIG_WEBLOGIC_PWD','t3://$OIG_DOMAIN_NAME-adminserver.$OIGNS.svc.cluster.local:$OIG_ADMIN_PORT') " > $WORKDIR/OIG/add_cert_to_kss.py
     echo "svc = getOpssService(name='KeyStoreService')" >> $WORKDIR/OIG/add_cert_to_kss.py

     for cert in `ls -1 $WORKDIR/*.pem`
     do
           aliasname=`basename $cert | sed 's/.pem//'`
           echo "svc.importKeyStoreCertificate(appStripe='system',name='trust',password='', keypassword='',alias='$aliasname',type='TrustedCertificate', filepath='$PV_MOUNT/keystores/$aliasname.pem')" >> $WORKDIR/OIG/add_cert_to_kss.py
           copy_to_k8 $cert  keystores $OIGNS $OIG_DOMAIN_NAME
     done
     echo "syncKeyStores(appStripe='system', keystoreFormat='KSS')" >> $WORKDIR/OIG/add_cert_to_kss.py
     echo "exit()" >> $WORKDIR/OIG/add_cert_to_kss.py
     
     copy_to_k8 $WORKDIR/OIG/add_cert_to_kss.py  workdir $OIGNS $OIG_DOMAIN_NAME
     run_wlst_command $OIGNS $OIG_DOMAIN_NAME $PV_MOUNT/workdir/add_cert_to_kss.py > $LOGDIR/add_cert_to_kss.log
     echo "Success"
     ET=`date +%s`
     print_time STEP "Add Certificates to Keystore" $ST $ET >> $LOGDIR/timings.log
}

# 
# Create OIG Config Files
#
create_oig_ohs_config()
{
   ST=`date +%s`


   echo -n "Creating OHS Conf files - "
   OHS_PATH=$WORKDIR/OHS
   if ! [ -d $OHS_PATH/$OHS_HOST1 ]
   then
        mkdir -p $OHS_PATH/$OHS_HOST1
   fi
   if ! [ -d $OHS_PATH/OHS/$OHS_HOST2 ]
   then
        mkdir -p $OHS_PATH/$OHS_HOST2
   fi

   cp $TEMPLATE_DIR/igdadmin_vh.conf $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
   cp $TEMPLATE_DIR/igdadmin_vh.conf $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf
   cp $TEMPLATE_DIR/prov_vh.conf $OHS_PATH/$OHS_HOST1/prov_vh.conf
   cp $TEMPLATE_DIR/prov_vh.conf $OHS_PATH/$OHS_HOST2/prov_vh.conf
   cp $TEMPLATE_DIR/igdinternal_vh.conf $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
   cp $TEMPLATE_DIR/igdinternal_vh.conf $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf

   update_variable "<OHS_HOST>" $OHS_HOST1 $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
   update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
   update_variable "<OIG_ADMIN_LBR_HOST>" $OIG_ADMIN_LBR_HOST $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
   update_variable "<OIG_ADMIN_LBR_PORT>" $OIG_ADMIN_LBR_PORT $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
   update_variable "<OIG_ADMIN_K8>" $OIG_ADMIN_K8 $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf
   update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $OHS_PATH/$OHS_HOST1/igdadmin_vh.conf


   update_variable "<OHS_HOST>" $OHS_HOST2 $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf
   update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf
   update_variable "<OIG_ADMIN_LBR_HOST>" $OIG_ADMIN_LBR_HOST $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf
   update_variable "<OIG_ADMIN_LBR_PORT>" $OIG_ADMIN_LBR_PORT $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf
   update_variable "<OIG_ADMIN_K8>" $OIG_ADMIN_K8 $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf
   update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $OHS_PATH/$OHS_HOST2/igdadmin_vh.conf

   update_variable "<OHS_HOST>" $OHS_HOST1 $OHS_PATH/$OHS_HOST1/prov_vh.conf
   update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST1/prov_vh.conf
   update_variable "<OIG_LBR_PROTOCOL>" $OIG_LBR_PROTOCOL $OHS_PATH/$OHS_HOST1/prov_vh.conf
   update_variable "<OIG_LBR_HOST>" $OIG_LBR_HOST $OHS_PATH/$OHS_HOST1/prov_vh.conf
   update_variable "<OIG_LBR_PORT>" $OIG_LBR_PORT $OHS_PATH/$OHS_HOST1/prov_vh.conf
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/prov_vh.conf
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/prov_vh.conf
   update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $OHS_PATH/$OHS_HOST1/prov_vh.conf
   update_variable "<OIG_SOA_PORT_K8>" $OIG_SOA_PORT_K8 $OHS_PATH/$OHS_HOST1/prov_vh.conf


   update_variable "<OHS_HOST>" $OHS_HOST2 $OHS_PATH/$OHS_HOST2/prov_vh.conf
   update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST2/prov_vh.conf
   update_variable "<OIG_LBR_PROTOCOL>" $OIG_LBR_PROTOCOL $OHS_PATH/$OHS_HOST2/prov_vh.conf
   update_variable "<OIG_LBR_HOST>" $OIG_LBR_HOST $OHS_PATH/$OHS_HOST2/prov_vh.conf
   update_variable "<OIG_LBR_PORT>" $OIG_LBR_PORT $OHS_PATH/$OHS_HOST2/prov_vh.conf
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST2/prov_vh.conf
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST2/prov_vh.conf
   update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $OHS_PATH/$OHS_HOST2/prov_vh.conf
   update_variable "<OIG_SOA_PORT_K8>" $OIG_SOA_PORT_K8 $OHS_PATH/$OHS_HOST2/prov_vh.conf

   update_variable "<OHS_HOST>" $OHS_HOST2 $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
   update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
   update_variable "<OIG_LBR_INT_PROTOCOL>" $OIG_LBR_INT_PROTOCOL $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
   update_variable "<OIG_LBR_INT_HOST>" $OIG_LBR_INT_HOST $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
   update_variable "<OIG_LBR_INT_PORT>" $OIG_LBR_INT_PORT $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
   update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf
   update_variable "<OIG_SOA_PORT_K8>" $OIG_SOA_PORT_K8 $OHS_PATH/$OHS_HOST1/igdinternal_vh.conf

   update_variable "<OHS_HOST>" $OHS_HOST2 $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf
   update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf
   update_variable "<OIG_LBR_INT_PROTOCOL>" $OIG_LBR_INT_PROTOCOL $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf
   update_variable "<OIG_LBR_INT_HOST>" $OIG_LBR_INT_HOST $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf
   update_variable "<OIG_LBR_INT_PORT>" $OIG_LBR_INT_PORT $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf
   update_variable "<OIG_OIM_PORT_K8>" $OIG_OIM_PORT_K8 $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf
   update_variable "<OIG_SOA_PORT_K8>" $OIG_SOA_PORT_K8 $OHS_PATH/$OHS_HOST2/igdinternal_vh.conf

   echo "Success"
   ET=`date +%s`
   print_time STEP "Creating OHS config" $ST $ET >> $LOGDIR/timings.log
}
