# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of procedures used to configure OAM
#
# Usage: Not invoked directly

#
# Create Persistent Volumes
#
create_persistent_volumes()
{
     ST=`date +%s`
     print_msg "Creating Persistent Volumes"
     cd $WORKDIR/samples/create-weblogic-domain-pv-pvc
     replace_value2 domainUID $OAM_DOMAIN_NAME $PWD/create-pv-pvc-inputs.yaml
     replace_value2 namespace $OAMNS $PWD/create-pv-pvc-inputs.yaml
     replace_value2 baseName domain $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStorageType NFS $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStorageNFSServer $PVSERVER $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStoragePath $OAM_SHARE $PWD/create-pv-pvc-inputs.yaml
     
     ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output > $LOGDIR/create_pv.log

     kubectl create -f output/pv-pvcs/$OAM_DOMAIN_NAME-domain-pv.yaml -n $OAMNS >> $LOGDIR/create_pv.log 2>&1
     print_status $? $LOGDIR/create_pv.log
     printf "\t\t\tCreating Persistent Volume Claims - "
     kubectl create -f output/pv-pvcs/$OAM_DOMAIN_NAME-domain-pvc.yaml -n $OAMNS >> $LOGDIR/create_pv.log 2>&1
     print_status $? $LOGDIR/create_pv.log

     ET=`date +%s`
     print_time STEP "Create Persistent Volumes" $ST $ET >> $LOGDIR/timings.log
}

# Edit sample domain Configuration File
#
edit_domain_creation_file()
{
     filename=$1

     ST=`date +%s`
     print_msg "Creating Domain Configuration File"
     cp $WORKDIR/samples/create-access-domain/domain-home-on-pv/create-domain-inputs.yaml $filename
     ST=`date +%s`
     if [  "$CREATE_REGSECRET" = "true" ]
     then
        replace_value2 imagePullSecretName regcred $filename
     fi
     replace_value2 domainUID $OAM_DOMAIN_NAME $filename
     replace_value2 domainPVMountPath $PV_MOUNT $filename
     replace_value2 domainHome $PV_MOUNT/domains/$OAM_DOMAIN_NAME $filename
     replace_value2 domainType oam $filename
     replace_value2 image $OAM_IMAGE:$OAM_VER $filename
     replace_value2 namespace $OAMNS $filename
     replace_value2 weblogicCredentialsSecretName $OAM_DOMAIN_NAME-credentials $filename
     replace_value2 persistentVolumeClaimName $OAM_DOMAIN_NAME-domain-pvc $filename
     replace_value2 logHome $PV_MOUNT/domains/logs/$OAM_DOMAIN_NAME   $filename
     replace_value2 rcuSchemaPrefix $OAM_RCU_PREFIX   $filename
     replace_value2 rcuDatabaseURL $OAM_DB_SCAN:$OAM_DB_LISTENER/$OAM_DB_SERVICE  $filename
     replace_value2 rcuCredentialsSecret $OAM_DOMAIN_NAME-rcu-credentials  $filename
     replace_value2 exposeAdminNodePort true $filename
     replace_value2 configuredManagedServerCount $OAM_SERVER_COUNT $filename
     replace_value2 initialManagedServerReplicas 1 $filename
     replace_value2 productionModeEnabled true $filename
     replace_value2 exposeAdminT3Channel true $filename
     replace_value2 adminPort $OAM_ADMIN_PORT $filename
     replace_value2 adminNodePort $OAM_ADMIN_K8 $filename
     replace_value2 t3ChannelPort $OAM_ADMIN_T3_K8 $filename

     print_status $?
     printf "\t\t\tCopy saved to $WORKDIR\n"
     ET=`date +%s`
     print_time STEP "Create Domain Configuration File" $ST $ET >> $LOGDIR/timings.log
}

# Update Java parameters for WebLogic Clusters in domain.yaml

update_java_parameters()
{
     printf "\t\t\tUpdating Java Parameters - "
     cp $TEMPLATE_DIR/oamDomain.sedfile $WORKDIR
     update_variable "<OAMSERVER_JAVA_PARAMS>" "$OAMSERVER_JAVA_PARAMS" $WORKDIR/oamDomain.sedfile
     cd $WORKDIR/samples/create-access-domain/domain-home-on-pv
     
     sed -i -f $WORKDIR/oamDomain.sedfile output/weblogic-domains/$OAM_DOMAIN_NAME/domain.yaml
     print_status $?
}

# Create the OAM domain
#
create_oam_domain()
{

     print_msg "Initialising the Domain"
     ST=`date +%s`
     cd $WORKDIR/samples/create-access-domain/domain-home-on-pv

     ./create-domain.sh -i $WORKDIR/create-domain-inputs.yaml -t 1200 -o output > $LOGDIR/create_domain.log 2>$LOGDIR/create_domain.log
     grep -qs ERROR $LOGDIR/create_domain.log
     if [ $? = 0 ]
     then
         echo "Fail - Check logfile $LOGDIR/create_domain.log for details"
         exit 1
     fi

     pod=`kubectl get pod -n $OAMNS | grep $OAM_DOMAIN_NAME | awk '{ print $1 }'`
     kubectl logs -n $OAMNS $pod | grep -q Failed
     if [ $? = 0 ]
     then
        echo "Fail - See kubectl logs -n $OAMNS $pod for details"
        exit 1
     fi

     kubectl logs -n $OAMNS $pod | grep -q "Successfully Completed"
     if [ $? = 1 ]
     then
        echo "Fail - See kubectl logs -n $OAMNS $pod for details"
        exit 1
     fi

     status=`kubectl get pod -n $OAMNS | grep create | awk  '{ print $3}'`
     create_job_name=`kubectl get pod -n $OAMNS | grep create | awk  '{ print $1}'`
     if [ "$status" = "Pending" ] || [ "$status" = "Error" ]
     then
         kubectl describe job -n $OAMNS $create_job_name >> $LOGDIR/create_domain.log 2>&1
         kubectl -n $OAMNS describe domain $OAM_DOMAIN_ID >> $LOGDIR/create_domain.log 2>&1
         kubectl logs -n $OAMNS $create_job_name >> $LOGDIR/create_domain.log 2>&1
         echo " Failed - see logfile $LOGDIR/create_domain.log"
         exit 1
     else
         echo "Success"
     fi
     ET=`date +%s`

     print_time STEP "Initialise the Domain" $ST $ET >> $LOGDIR/timings.log

}
#
# Start the domain for the first time.
#
perform_first_start()
{
     # Start the Domain
     #
     ST=`date +%s`
     print_msg "Starting the Domain"

     cd $WORKDIR/samples/create-access-domain/domain-home-on-pv
     cp output/weblogic-domains/$OAM_DOMAIN_NAME/domain.yaml output/weblogic-domains/$OAM_DOMAIN_NAME/domain_original.yaml
     echo
     update_java_parameters

     printf "\t\t\tPatching the Domain - "
     kubectl apply -f output/weblogic-domains/$OAM_DOMAIN_NAME/domain.yaml > $LOGDIR/first_start.log
     print_status $? $LOGDIR/first_start.log


     # Check that the domain is started
     #
     check_running $OAMNS adminserver
     check_running $OAMNS oam-server1

     ET=`date +%s`

     print_time STEP "Start the Domain" $ST $ET >> $LOGDIR/timings.log
}

# Create NodePort Services for OAM
#
create_oam_nodeport()
{
     ST=`date +%s`
     print_msg  "Creating OAM NodePort Services "
     echo
     cp $TEMPLATE_DIR/*nodeport*.yaml $WORKDIR
     cp $TEMPLATE_DIR/*clusterip*.yaml $WORKDIR

     update_variable "<DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/oam_nodeport.yaml
     update_variable "<NAMESPACE>" $OAMNS $WORKDIR/oam_nodeport.yaml
     update_variable "<OAM_OAM_K8>" $OAM_OAM_K8 $WORKDIR/oam_nodeport.yaml
     update_variable "<DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/policy_nodeport.yaml
     update_variable "<NAMESPACE>" $OAMNS $WORKDIR/policy_nodeport.yaml
     update_variable "<OAM_POLICY_K8>" $OAM_POLICY_K8 $WORKDIR/policy_nodeport.yaml
     update_variable "<DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/oap_nodeport.yaml
     update_variable "<NAMESPACE>" $OAMNS $WORKDIR/oap_nodeport.yaml
     update_variable "<OAP_PORT>" $OAM_OAP_PORT $WORKDIR/oap_nodeport.yaml
     update_variable "<OAP_SERVICEPORT>" $OAM_OAP_SERVICE_PORT $WORKDIR/oap_nodeport.yaml
     update_variable "<OAP_PORT>" $OAM_OAP_PORT $WORKDIR/oap_clusterip.yaml
     update_variable "<NAMESPACE>" $OAMNS $WORKDIR/oap_clusterip.yaml
     update_variable "<DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/oap_clusterip.yaml

     printf "\t\t\t\tOAM Service - "
     kubectl create -f $WORKDIR/oam_nodeport.yaml > $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
     if [ $? -eq 0 ] 
     then
         echo  "Success"
     else
         echo  "Failed"
  
     fi
     printf "\t\t\t\tPolicy Mangaer Service - "
     kubectl create -f $WORKDIR/policy_nodeport.yaml >> $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
     if [ $? -eq 0 ] 
     then
         echo  "Success"
     else
         echo  "Failed"
  
     fi

     printf "\t\t\t\tOAP Service ClusterIP - "
     kubectl create -f $WORKDIR/oap_clusterip.yaml >> $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
     if [ $? -eq 0 ] 
     then
         echo  "Success"
     else
         echo  "Failed"
  
     fi
     ET=`date +%s` 
     print_time STEP "Create Kubernetes OAM NodePort Services " $ST $ET >> $LOGDIR/timings.log
}

# Create Ingress Services for OAM
#
create_oam_ingress_manual()
{
     ST=`date +%s`
     print_msg  "Creating OAM Ingress Services "
     cp $TEMPLATE_DIR/oam_ingress.yaml $WORKDIR
     filename=$WORKDIR/oam_ingress.yaml

     update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $filename
     update_variable "<OAMNS>" $OAMNS $filename
     update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $filename
     update_variable "<OAM_ADMIN_LBR_HOST>" $OAM_ADMIN_LBR_HOST $filename
     update_variable "<OAM_ADMIN_PORT>" $OAM_ADMIN_PORT $filename

     kubectl create -f $filename > $LOGDIR/ingress.log 2>>$LOGDIR/ingress.log
     print_status $? $LOGDIR/ingress.log
     ET=`date +%s` 
     print_time STEP "Create Kubernetes OAM Ingress Services " $ST $ET >> $LOGDIR/timings.log
}

# Create Ingress Services for OAM
#
create_oam_ingress()
{
     ST=`date +%s`
     print_msg  "Creating OAM Ingress Services "
     cp $WORKDIR/samples/charts/ingress-per-domain/values.yaml $WORKDIR/override_ingress.yaml
     filename=$WORKDIR/override_ingress.yaml

     replace_value2 domainUID $OAM_DOMAIN_NAME $filename
     replace_value2  adminServerPort $OAM_ADMIN_PORT $filename
     replace_value2  enabled true $filename
     replace_value2 runtime $OAM_LOGIN_LBR_HOST $filename
     replace_value2 admin  $OAM_ADMIN_LBR_HOST $filename
     replace_value2 sslType  NONSSL $filename

     cd $WORKDIR/samples
     helm install oam-nginx charts/ingress-per-domain --namespace $OAMNS --values $filename  > $LOGDIR/ingress.log 2>>$LOGDIR/ingress.log
     print_status $? $LOGDIR/ingress.log
     ET=`date +%s` 
     print_time STEP "Create Kubernetes OAM Ingress Services " $ST $ET >> $LOGDIR/timings.log
}
# Update the newly created OAM domain using OAM API's
#
update_default_oam_domain()
{
     ADMINURL=$1
     USER=$2

     ST=`date +%s`
     print_msg "Updating default OAM Domain Settings"

     cp $TEMPLATE_DIR/oamconfig_modify_template.xml  $WORKDIR/oamconfig_modify.xml

     for i in $( seq 1 $OAM_SERVER_COUNT)
     do
         sed -i "2i<Setting Name=\"Value\" Type=\"xsd:string\" Path=\"/DeployedComponent/Server/NGAMServer/Instance/oam_server$i/CoherenceConfiguration/LocalHost/Value\">$OAM_DOMAIN_NAME-oam-server$i</Setting>" $WORKDIR/oamconfig_modify.xml
         sed -i "2i<Setting Name=\"Port\" Type=\"xsd:integer\" Path=\"/DeployedComponent/Server/NGAMServer/Instance/oam_server$i/oamproxy/Port\">$OAM_OAP_PORT</Setting>" $WORKDIR/oamconfig_modify.xml
         sed -i "2i<Setting Name=\"host\" Type=\"xsd:string\" Path=\"/DeployedComponent/Server/NGAMServer/Instance/oam_server$i/host\">$OAM_DOMAIN_NAME-oam-server$i</Setting>"  $WORKDIR/oamconfig_modify.xml
     done

     update_variable "<OAM_SERVER>" $OAM_DOMAIN_NAME $WORKDIR/oamconfig_modify.xml
     update_variable "<OAP_PORT>" $OAM_OAP_PORT $WORKDIR/oamconfig_modify.xml
     update_variable "<LBR_HOST>" $OAM_LOGIN_LBR_HOST $WORKDIR/oamconfig_modify.xml
     update_variable "<LBR_PORT>" $OAM_LOGIN_LBR_PORT $WORKDIR/oamconfig_modify.xml
     update_variable "<LBR_PROTOCOL>" $OAM_LOGIN_LBR_PROTOCOL $WORKDIR/oamconfig_modify.xml
     update_variable "<OAP_HOST>" $OAM_OAP_HOST $WORKDIR/oamconfig_modify.xml
     update_variable "<OAP_SERVICE_PORT>" $OAM_OAP_SERVICE_PORT $WORKDIR/oamconfig_modify.xml

     ENCUSER=`encode_pwd ${USER}`
     USER_HEADER="-H 'Authorization: Basic $ENCUSER'"
     
     PUTCURL="curl -s -x '' -X PUT $ADMINURL/iam/admin/config/api/v1/config -ikL -H 'Content-Type: application/xml'  $USER_HEADER -H 'cache-control: no-cache' -d @$WORKDIR/oamconfig_modify.xml" 
     GET_OAMCONFIG="curl -s -x '' -X GET $ADMINURL/iam/admin/config/api/v1/config -ikL -H 'Content-Type: application/xml'  $USER_HEADER -H 'cache-control: no-cache' "

     echo "Executing Command :  $PUTCURL "> $LOGDIR/update_oam.log 
     eval $PUTCURL>> $LOGDIR/update_oam.log 2>&1
     eval $GET_OAMCONFIG > $WORKDIR/oam-config.xml

     grep -q OAMRestEndPointHostName $WORKDIR/oam-config.xml | grep $OAM_LOGIN_LBR_HOST
     if [ $? -eq 1 ] 
     then
         echo  "Success"
     else
         echo  "Failed"
         exit 1
     fi

     ET=`date +%s`
     print_time STEP "Update Default OAM Domain " $ST $ET >> $LOGDIR/timings.log
}

# Update Application Domain HostIDs
#
update_oam_hostids()
{
     ADMINURL=$1
     USER=$2
     
     print_msg "Update Host Identifiers"
     ST=`date +%s`

     ENCUSER=`encode_pwd ${USER}`
     USER_HEADER="-H 'Authorization: Basic $ENCUSER'"

     ID=`curl -s -X GET $USER_HEADER $ADMINURL/oam/services/rest/11.1.2.0.0/ssa/policyadmin/hostidentifier?name=IAMSuiteAgent | grep "<id>" | sed "s/^ *//g;s/<id>//;s/<\/id>//"`
     CURL_COMMAND="curl -s -o /dev/null -X PUT $USER_HEADER"
     OAM_RESTAPI="$ADMINURL/oam/services/rest/11.1.2.0.0/ssa/policyadmin/hostidentifier"
     CONTENT_JSON="-H 'Content-Type: application/json' -H 'cache-control: no-cache'"
     START_JSON="-d '{\"Hosts\":{\"host\":[{\"port\":\"80\",\"hostName\":\"IAMSuiteAgent\"},{\"hostName\":\"IAMSuiteAgent\"}"
     END_JSON="]},\"description\":\"Host identifier for IAM Suite resources\",\"name\":\"IAMSuiteAgent\",\"id\":\"${ID}\"}'"
     JSON_HOSTS=",{\"port\":\"$OAM_LOGIN_LBR_PORT\",\"hostName\":\"$OAM_LOGIN_LBR_HOST\"}"
     JSON_HOSTS="$JSON_HOSTS",{\"port\":\"$OIG_LBR_PORT\",\"hostName\":\"$OIG_LBR_HOST\"}""
     JSON_HOSTS="$JSON_HOSTS",{\"port\":\"$OIG_LBR_INT_PORT\",\"hostName\":\"$OIG_LBR_INT_HOST\"}""
     JSON_HOSTS="$JSON_HOSTS",{\"port\":\"$OAM_ADMIN_LBR_PORT\",\"hostName\":\"$OAM_ADMIN_LBR_HOST\"}""
     JSON_HOSTS="$JSON_HOSTS",{\"port\":\"$OIG_ADMIN_LBR_PORT\",\"hostName\":\"$OIG_ADMIN_LBR_HOST\"}""
     JSON_HOSTS="$JSON_HOSTS",{\"port\":\"$OHS_PORT\",\"hostName\":\"$OHS_HOST1\"}""
     if [ ! "$OHS_HOST2" = "" ]
     then
        JSON_HOSTS="$JSON_HOSTS",{\"port\":\"$OHS_PORT\",\"hostName\":\"$OHS_HOST2\"}""
     fi
     JSON=${START_JSON}${JSON_HOSTS}${END_JSON}

     echo "Executing Command : " "$CURL_COMMAND \"$OAM_RESTAPI\" $CONTENT_JSON $JSON" > $LOGDIR/host_identifiers.log
     eval "$CURL_COMMAND \"$OAM_RESTAPI\" $CONTENT_JSON $JSON" >> $LOGDIR/host_identifiers.log 2>&1

     print_status $? $LOGDIR/host_identifiers.log
     ET=`date +%s`
     print_time STEP "Update Host Identifiers" $ST $ET >> $LOGDIR/timings.log
}


# Add Resources to IAMSuite Application domain
#
add_oam_resources()
{
     ADMINURL=$1
     USER=$2
     INPUT_FILE="$TEMPLATE_DIR/resource_list.txt"

     ST=`date +%s`
     print_msg "Add Missing Resources"
     echo "Add Missing Resources"  > $LOGDIR/add_resources.log

     OAM_RESTAPI="'$ADMINURL/oam/services/rest/11.1.2.0.0/ssa/policyadmin/resource'"

     ENCUSER=`encode_pwd ${USER}`
     USER_HEADER="-H 'Authorization: Basic $ENCUSER'"

     CURL_COMMAND="curl -s -X POST $USER_HEADER"
     CONTENT_TYPE="-H 'Content-Type: application/json' -H 'cache-control: no-cache'"

     while IFS= read -r RESOURCE
     do

       RES_URL=`echo $RESOURCE | cut -f1 -d:`
       RES_TYPE=`echo $RESOURCE | cut -f2 -d:`
       RES_AUTHN=`echo $RESOURCE | cut -f3 -d:`
       RES_AUTHZ=`echo $RESOURCE | cut -f4 -d:`
    
       START_JSON="-d '{\"queryString\":null,\"applicationDomainName\":\"IAM Suite\",\"hostIdentifierName\":\"IAMSuiteAgent\",\"resourceURL\":\"${RES_URL}\",\"protectionLevel\":\"$RES_TYPE\""
       START_JSON="${START_JSON},\"QueryParameters\":null,\"resourceTypeName\":\"HTTP\",\"Operations\":null,\"description\":\"${RES_URL}\",\"name\":\"${RES_URL}\",\"id\":\"1\"}'"

       RES_JSON=$START_JSON

       XX=`eval "$CURL_COMMAND $OAM_RESTAPI $CONTENT_TYPE $RES_JSON"`  >> $LOGDIR/add_resources.log

       ID=`echo $XX | cut -f2 -d=`

       echo "  Created Resource ${RES_URL} ID: $ID" >> $LOGDIR/add_resources.log
       if [ "$RES_TYPE" = "PROTECTED" ]
       then
          PROTECTED_RESOURCES="$PROTECTED_RESOURCES $ID"
       fi

     done < $INPUT_FILE

     echo "Protected Resources" $PROTECTED_RESOURCES  >> $LOGDIR/add_resources.log

     # Assign Protected Resources to Authentication Policy

     REST_API="'$ADMINURL/oam/services/rest/11.1.2.0.0/ssa/policyadmin/authnpolicy?appdomain=IAM%20Suite&name=Protected%20HigherLevel%20Policy'"

     GET_CURL_COMMAND="curl -s -X GET $USER_HEADER"
     PUT_CURL_COMMAND="curl -s -o /dev/null  -X PUT $USER_HEADER"
     CONTENT_TYPE="-H 'Content-Type: application/xml' -H 'cache-control: no-cache'"

     eval "$GET_CURL_COMMAND $REST_API " > /tmp/authn.xml
     if [ $? = 1 ] 
     then
         echo  "Failed"
         exit 1
     fi

     for RESOURCE in $PROTECTED_RESOURCES
     do
      sed -i '/<Resources>*/a \ \ \ \ \ \ <Resource>'${RESOURCE}'</Resource>' /tmp/authn.xml
     done

     sed -i 's/<\/AuthenticationPolicies>//;s/<AuthenticationPolicies>/\n/' /tmp/authn.xml
     sed -i '/<\?xml/d' /tmp/authn.xml
     eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE -d @/tmp/authn.xml"
     if [ $? = 1 ] 
     then
         echo  "Failed"
         exit 1
     fi

     # Assign Protected Resources to Authorisation Policy

     REST_API="'$ADMINURL/oam/services/rest/11.1.2.0.0/ssa/policyadmin/authzpolicy?appdomain=IAM%20Suite&name=Protected%20Resource%20Policy'"

     eval "$GET_CURL_COMMAND $REST_API " > /tmp/authz.xml
     if [ $? = 1 ] 
     then
         echo  "Failed"
         exit 1
     fi

     for RESOURCE in $PROTECTED_RESOURCES
     do
        sed -i '/<Resources>*/a \ \ \ \ \ \ <Resource>'${RESOURCE}'</Resource>' /tmp/authz.xml
     done

     sed -i 's/<\/AuthorizationPolicies>//;s/<AuthorizationPolicies>/\n/' /tmp/authz.xml
     sed -i '/<\?xml/d' /tmp/authz.xml
     eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE -d @/tmp/authz.xml" >$LOGDIR/authn.log

     if [ $? = 1 ] 
     then
         echo  "Failed"
         exit 1
     else
         echo "Success"
     fi

     ET=`date +%s`
     print_time STEP "Add Resources" $ST $ET >> $LOGDIR/timings.log
     
}

# Wire OAM to OUD
#
run_idmConfigTool()
{

   ST=`date +%s`
   print_msg "Wiring OAM to OUD"
   cp $TEMPLATE_DIR/runidmConfigTool.sh $WORKDIR
   cp $TEMPLATE_DIR/configoam.props $WORKDIR

   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/runidmConfigTool.sh
   update_variable "<PV_MOUNT>" $PV_MOUNT $WORKDIR/runidmConfigTool.sh
   update_variable "<WORK_DIR>" $K8_WORKDIR $WORKDIR/runidmConfigTool.sh

   update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/configoam.props
   update_variable "<LDAP_ADMIN_USER>" $LDAP_ADMIN_USER $WORKDIR/configoam.props
   update_variable "<LDAP_GROUP_SEARCHBASE>" $LDAP_GROUP_SEARCHBASE $WORKDIR/configoam.props
   update_variable "<LDAP_SEARCHBASE>" $LDAP_SEARCHBASE $WORKDIR/configoam.props
   update_variable "<LDAP_USER_SEARCHBASE>" $LDAP_USER_SEARCHBASE $WORKDIR/configoam.props
   update_variable "<LDAP_OAMADMIN_USER>" $LDAP_OAMADMIN_USER $WORKDIR/configoam.props
   update_variable "<LDAP_OAMLDAP_USER>" $LDAP_OAMLDAP_USER $WORKDIR/configoam.props
   update_variable "<LDAP_OAMADMIN_GRP>" $LDAP_OAMADMIN_GRP $WORKDIR/configoam.props
   update_variable "<LDAP_SYSTEMIDS>" $LDAP_SYSTEMIDS $WORKDIR/configoam.props
   update_variable "<LDAP_OIGADMIN_GRP>" $LDAP_OIGADMIN_GRP $WORKDIR/configoam.props
   update_variable "<LDAP_OIGLDAP_USER>" $LDAP_OIGLDAP_USER $WORKDIR/configoam.props
   update_variable "<LDAP_WLSADMIN_USER>" $LDAP_WLSADMIN_USER $WORKDIR/configoam.props
   update_variable "<LDAP_WLSADMIN_GRP>" $LDAP_WLSADMIN_GRP $WORKDIR/configoam.props
   update_variable "<OAM_OAP_PORT>" $OAM_OAP_PORT $WORKDIR/configoam.props
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/configoam.props
   update_variable "<OAM_COOKIE_DOMAIN>" $OAM_COOKIE_DOMAIN $WORKDIR/configoam.props
   update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $WORKDIR/configoam.props
   update_variable "<OAM_LOGIN_LBR_PORT>" $OAM_LOGIN_LBR_PORT $WORKDIR/configoam.props
   update_variable "<OAM_LOGIN_LBR_PROTOCOL>" $OAM_LOGIN_LBR_PROTOCOL $WORKDIR/configoam.props
   update_variable "<OIG_LBR_PROTOCOL>" $OIG_LBR_PROTOCOL $WORKDIR/configoam.props
   update_variable "<OIG_LBR_HOST>" $OIG_LBR_HOST $WORKDIR/configoam.props
   update_variable "<OIG_LBR_PORT>" $OIG_LBR_PORT $WORKDIR/configoam.props
   update_variable "<OAMNS>" $OAMNS $WORKDIR/configoam.props
   update_variable "<OUDNS>" $OUDNS $WORKDIR/configoam.props
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/configoam.props
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/configoam.props
   update_variable "<LDAP_WLSADMIN_USER>" $LDAP_WLSADMIN_USER $WORKDIR/configoam.props
   update_variable "<LDAP_WLSADMIN_GRP>" $LDAP_WLSADMIN_GRP $WORKDIR/configoam.props
   update_variable "<LDAP_ADMIN_PWD>" $LDAP_ADMIN_PWD $WORKDIR/configoam.props
   update_variable "<LDAP_USER_PWD>" $LDAP_USER_PWD $WORKDIR/configoam.props
   update_variable "<OAM_OIG_INTEG>" $OAM_OIG_INTEG $WORKDIR/configoam.props

   copy_to_k8 $WORKDIR/runidmConfigTool.sh workdir $OAMNS $OAM_DOMAIN_NAME
   copy_to_k8 $WORKDIR/configoam.props workdir $OAMNS $OAM_DOMAIN_NAME

   run_command_k8 $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/runidmConfigTool.sh workdir > $LOGDIR/configoam.out
   print_status $? $LOGDIR/configoam.out
    
   printf "\t\t\tChecking Log File - "
   copy_from_k8 $PV_MOUNT/workdir/configoam.log $WORKDIR/logs/configoam.log $OAMNS $OAM_DOMAIN_NAME

   grep SEVERE $WORKDIR/logs/configoam.log | grep -v simple > /dev/null
   if [ $? = 0 ]
   then
      echo "Failed - Check logifle $WORKDIR/logs/configoam.log"
      echo "SEVERE Error Message Detected." >>  $WORKDIR/logs/configoam.log
      exit 1
   else
      echo "Success"
   fi

   ET=`date +%s`
   print_time STEP "Create Kubernetes Working Directory" $ST $ET >> $LOGDIR/timings.log

}

# Create a Webgate Agent for IAMSuite
#
create_wg_agent()
{
   ST=`date +%s`
   print_msg "Create Webgate Agent"
   
   cp $TEMPLATE_DIR/Webgate_IDM.xml $WORKDIR
   cp $TEMPLATE_DIR/create_wg.sh $WORKDIR
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/Webgate_IDM.xml
   update_variable "<OAMNS>" $OAMNS $WORKDIR/Webgate_IDM.xml
   update_variable "<LDAP_OAMADMIN_USER>" $LDAP_OAMADMIN_USER $WORKDIR/create_wg.sh
   update_variable "<LDAP_USER_PWD>" $LDAP_USER_PWD $WORKDIR/create_wg.sh
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/create_wg.sh
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/create_wg.sh
   update_variable "<PV_MOUNT>" $PV_MOUNT $WORKDIR/create_wg.sh
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/create_wg.sh

   copy_to_k8 $WORKDIR/Webgate_IDM.xml workdir $OAMNS $OAM_DOMAIN_NAME
   copy_to_k8 $WORKDIR/create_wg.sh workdir $OAMNS $OAM_DOMAIN_NAME

   run_command_k8 $OAMNS $OAM_DOMAIN_NAME "chmod 750 $PV_MOUNT/workdir/create_wg.sh"
   run_command_k8 $OAMNS $OAM_DOMAIN_NAME "$PV_MOUNT/workdir/create_wg.sh" > $LOGDIR/create_wg.log 2>&1

   grep -q "completed successfully" $LOGDIR/create_wg.log
   print_status $? $LOGDIR/create_wg.log

   ET=`date +%s`
   print_time STEP "Time taken to create Webgate" $ST $ET >> $LOGDIR/timings.log
}


# Add LDAP groups to weblogic admin group
#
add_admin_roles()
{
    
   ST=`date +%s`
   print_msg  "Add Administration Roles to WebLogic"
   cp $TEMPLATE_DIR/add_admin_roles.py $WORKDIR
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/add_admin_roles.py
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/add_admin_roles.py
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/add_admin_roles.py
   update_variable "<LDAP_OAMADMIN_GRP>" $LDAP_OAMADMIN_GRP $WORKDIR/add_admin_roles.py
   update_variable "<LDAP_WLSADMIN_GRP>" $LDAP_WLSADMIN_GRP $WORKDIR/add_admin_roles.py
   update_variable "<OAMNS>" $OAMNS $WORKDIR/add_admin_roles.py

   copy_to_k8 $WORKDIR/add_admin_roles.py workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/add_admin_roles.py > $LOGDIR/add_admin_roles.log 2>&1
   print_status $WLSRETCODE $LOGDIR/add_admin_roles.log

   ET=`date +%s`
   print_time STEP "Add Admin Roles" $ST $ET >> $LOGDIR/timings.log
}

# Fix Gridlink Datasoureces
#
fix_gridlink()
{
     ST=`date +%s`
     print_msg "Enabling Database FAN"

     cp $TEMPLATE_DIR/fix_gridlink.sh $WORKDIR

     update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/fix_gridlink.sh
     update_variable "<PV_MOUNT>" $PV_MOUNT $WORKDIR/fix_gridlink.sh

     copy_to_k8 $WORKDIR/fix_gridlink.sh workdir $OAMNS $OAM_DOMAIN_NAME
     run_command_k8 $OAMNS $OAM_DOMAIN_NAME "chmod 750 $PV_MOUNT/workdir/fix_gridlink.sh"
     run_command_k8 $OAMNS $OAM_DOMAIN_NAME "$PV_MOUNT/workdir/fix_gridlink.sh" > $LOGDIR/fix_gridlink.log 2>&1
     print_status $? $LOGDIR/fix_gridlink.log
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
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/set_weblogic_plugin.py
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/set_weblogic_plugin.py
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/set_weblogic_plugin.py
   update_variable "<OAMNS>" $OAMNS $WORKDIR/set_weblogic_plugin.py
   update_variable "<OAM_ADMIN_PORT>" $OAM_ADMIN_PORT $WORKDIR/set_weblogic_plugin.py

   copy_to_k8 $WORKDIR/set_weblogic_plugin.py workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/set_weblogic_plugin.py > $LOGDIR/set_weblogic_plugin.log

   print_status $WLSRETCODE $LOGDIR/set_weblogic_plugin.log
   ET=`date +%s`
   print_time STEP "Set WebLogic Plug-in" $ST $ET >> $LOGDIR/timings.log
}

# Configure ADF Logout
# 
config_adf_logout()
{
    
   ST=`date +%s`
   print_msg "Setting ADF Logout"
   cp $TEMPLATE_DIR/config_adf_security.py $WORKDIR
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/config_adf_security.py
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/config_adf_security.py
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/config_adf_security.py
   update_variable "<OAMNS>" $OAMNS $WORKDIR/config_adf_security.py
   update_variable "<OAM_ADMIN_PORT>" $OAM_ADMIN_PORT $WORKDIR/config_adf_security.py

   copy_to_k8 $WORKDIR/config_adf_security.py workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/config_adf_security.py > $LOGDIR/config_adf_security.log

   print_status $WLSRETCODE $LOGDIR/config_adf_security.log
   ET=`date +%s`
   print_time STEP "Set ADF Logout" $ST $ET >> $LOGDIR/timings.log
}

# Remove OAM from the default Coherence Cluster
#
remove_coherence()
{
    
   ST=`date +%s`
   print_msg "Remove Coherence"
   cp $TEMPLATE_DIR/remove_coherence.py $WORKDIR
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/remove_coherence.py
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/remove_coherence.py
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/remove_coherence.py
   update_variable "<OAMNS>" $OAMNS $WORKDIR/remove_coherence.py

   for i in $( seq 1 $OAM_SERVER_COUNT)
   do
       sed -i "4icmo.removeTarget(getMBean(\'/Servers/oam_server$i\'))" $WORKDIR/remove_coherence.py
       sed -i "4icd(\'/CoherenceClusterSystemResources/defaultCoherenceCluster\')" $WORKDIR/remove_coherence.py
       sed -i "4icmo.setCoherenceClusterSystemResource(None)" $WORKDIR/remove_coherence.py
       sed -i "4icd(\'/Servers/oam_server$i\')" $WORKDIR/remove_coherence.py

       sed -i "4icmo.removeTarget(getMBean(\'/Servers/oam_policy_mgr$i\'))" $WORKDIR/remove_coherence.py
       sed -i "4icd(\'/CoherenceClusterSystemResources/defaultCoherenceCluster\')" $WORKDIR/remove_coherence.py
       sed -i "4icmo.setCoherenceClusterSystemResource(None)" $WORKDIR/remove_coherence.py
       sed -i "4icd(\'/Servers/oam_policy_mgr$i\')" $WORKDIR/remove_coherence.py
   done
   copy_to_k8 $WORKDIR/remove_coherence.py workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/remove_coherence.py > $LOGDIR/remove_coherence.log
   print_status $WLSRETCODE $LOGDIR/remove_coherence.log
   ET=`date +%s`
   print_time STEP "Removing default Coherence Cluster" $ST $ET >> $LOGDIR/timings.log
}

# Update OAM Datasource
# 
update_oamds()
{
    
   ST=`date +%s`
   print_msg "Updating OAMDS"
   cp $TEMPLATE_DIR/update_oamds.py $WORKDIR
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/update_oamds.py
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/update_oamds.py
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/update_oamds.py
   update_variable "<OAMNS>" $OAMNS $WORKDIR/update_oamds.py

   copy_to_k8 $WORKDIR/update_oamds.py workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/update_oamds.py > $LOGDIR/update_oamds.log
   print_status $WLSRETCODE  $LOGDIR/update_oamds.log
   ET=`date +%s`
   print_time STEP "Update OAM Datasource" $ST $ET >> $LOGDIR/timings.log
}

# Create a configuration file which can be used by Oracle HTTP server for accessing OAM
#
create_oam_ohs_config()
{
   ST=`date +%s`
   
   print_msg "Creating OHS Config Files" 
   OHS_PATH=$LOCAL_WORKDIR/OHS
   if  [ ! -d $OHS_PATH/$OHS_HOST1 ]
   then
        mkdir -p $OHS_PATH/$OHS_HOST1
   fi
   if  [ ! -d $OHS_PATH/$OHS_HOST2 ]
   then
        mkdir -p $OHS_PATH/$OHS_HOST2
   fi

   if [ ! "$OHS_HOST1" = "" ]
   then
      cp $TEMPLATE_DIR/iadadmin_vh.conf $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
      cp $TEMPLATE_DIR/login_vh.conf $OHS_PATH/$OHS_HOST1/login_vh.conf
      update_variable "<OHS_HOST>" $OHS_HOST1 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
      update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
      update_variable "<OAM_ADMIN_LBR_HOST>" $OAM_ADMIN_LBR_HOST $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
      update_variable "<OAM_ADMIN_LBR_PORT>" $OAM_ADMIN_LBR_PORT $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
      update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
      update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST2 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
      update_variable "<OHS_HOST>" $OHS_HOST1 $OHS_PATH/$OHS_HOST1/login_vh.conf
      update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST1/login_vh.conf
      update_variable "<OAM_LOGIN_LBR_PROTOCOL>" $OAM_LOGIN_LBR_PROTOCOL $OHS_PATH/$OHS_HOST1/login_vh.conf
      update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $OHS_PATH/$OHS_HOST1/login_vh.conf
      update_variable "<OAM_LOGIN_LBR_PORT>" $OAM_LOGIN_LBR_PORT $OHS_PATH/$OHS_HOST1/login_vh.conf
      update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/login_vh.conf
      update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST2 $OHS_PATH/$OHS_HOST1/login_vh.conf

      if [ "$USE_INGRESS" = "true" ]
      then
        update_variable "<OAM_ADMIN_K8>" $INGRESS_HTTP_PORT $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
        update_variable "<OAM_POLICY_K8>" $INGRESS_HTTP_PORT $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
        update_variable "<OAM_OAM_K8>" $INGRESS_HTTP_PORT $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
        update_variable "<OAM_OAM_K8>" $INGRESS_HTTP_PORT $OHS_PATH/$OHS_HOST1/login_vh.conf
      else
        update_variable "<OAM_ADMIN_K8>" $OAM_ADMIN_K8 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
        update_variable "<OAM_POLICY_K8>" $OAM_POLICY_K8 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
        update_variable "<OAM_OAM_K8>" $OAM_OAM_K8 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
        update_variable "<OAM_OAM_K8>" $OAM_OAM_K8 $OHS_PATH/$OHS_HOST1/login_vh.conf
      fi
   fi

   if [ ! "$OHS_HOST2" = "" ] 
   then
       cp $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
       cp $OHS_PATH/$OHS_HOST1/login_vh.conf $OHS_PATH/$OHS_HOST2/login_vh.conf
       sed -i "s/$OHS_HOST1/$OHS_HOST2/" $OHS_PATH/$OHS_HOST2/login_vh.conf
       sed -i "s/$OHS_HOST1/$OHS_HOST2/" $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
  fi

   print_status $?

   ET=`date +%s`
   print_time STEP "Creating OHS config" $ST $ET >> $LOGDIR/timings.log
}

# Copy Webgate Files to DOMAIN_HOME/output
#
copy_wg_files()
{
   ST=`date +%s`
   print_msg "Copying Webgate Artifacts to $LOCAL_WORKDIR/OHS/webgate"
   if  [ ! -d $LOCAL_WORKDIR/OHS/webgate ]
   then
       mkdir -p $LOCAL_WORKDIR/OHS/webgate
   fi
   copy_from_k8 /u01/oracle/user_projects/domains/accessdomain/output/Webgate_IDM $LOCAL_WORKDIR/OHS/webgate $OAMNS $OAM_DOMAIN_NAME > $LOGDIR/copy_wg_files 2>&1
   print_status $RETCODE $LOGDIR/copy_wg_files
   ET=`date +%s`
   print_time STEP "Copy Webgate Artifacts to $LOCAL_WORKDIR/OHS/webgate" $ST $ET >> $LOGDIR/timings.log
}

# Create logstash configmap
#
create_logstash_cm()
{
   ST=`date +%s`
   print_msg "Creating logstash Config Map"
   cp $TEMPLATE_DIR/logstash_cm.yaml $WORKDIR

   update_variable "<OAMNS>" $OAMNS $WORKDIR/logstash_cm.yaml
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
   export adminServerPort=$OAM_ADMIN_PORT
   export wlsMonitoringExporterTopolicyCluster=true
   export policyManagedServerPort=15100
   export wlsMonitoringExporterTooamCluster=true
   export oamManagedServerPort=14100
   export domainNamespace=$OAMNS
   export domainUID=$OAM_DOMAIN_NAME
   export weblogicCredentialsSecretName=$OAM_DOMAIN_NAME-credentials

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
   kubectl cp $WORKDIR/samples/monitoring-service/scripts/wls-exporter-deploy  $OAMNS/$OAM_DOMAIN_NAME-adminserver:/u01/oracle > $LOGDIR/deploy_wls_monitor.log 2>&1
   print_status $? $LOGDIR/deploy_wls_monitor.log

   printf "\t\t\tCopy Deployment Script 2 - "
   kubectl cp $WORKDIR/samples/monitoring-service/scripts/deploy-weblogic-monitoring-exporter.py  $OAMNS/$OAM_DOMAIN_NAME-adminserver:/u01/oracle/wls-exporter-deploy > $LOGDIR/deploy_wls_monitor.log 2>&1
   print_status $? $LOGDIR/deploy_wls_monitor.log


   printf "\t\t\tDeploy monitoring service - "
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME "/u01/oracle/wls-exporter-deploy/deploy-weblogic-monitoring-exporter.py -domainName $OAM_DOMAIN_NAME -adminServerName AdminServer -adminURL $OAM_DOMAIN_NAME-adminserver:$OAM_ADMIN_PORT -username $OAM_WEBLOGIC_USER -password $OAM_WEBLOGIC_PWD -oamClusterName oam_cluster -wlsMonitoringExporterTooamCluster true -policyClusterName policy_cluster -wlsMonitoringExporterTopolicyCluster true" >> $LOGDIR/deploy_wls_monitor.log 2>&1

   print_status $WLSRETCODE $LOGDIR/deploy_wls_monitor.log

   ET=`date +%s`
   print_time STEP "Deploy WebLogic Monitoring Service" $ST $ET >> $LOGDIR/timings.log

}

enable_monitor()
{
   ST=`date +%s`
   print_msg "Configuring Prometheus Operator"

   ENC_WEBLOGIC_USER=`encode_pwd $OAM_WEBLOGIC_USER`
   ENC_WEBLOGIC_PWD=`encode_pwd $OAM_WEBLOGIC_PWD`
   

   replace_value2 domainName $OAM_DOMAIN_NAME $WORKDIR/samples/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml
   replace_value2 namespace $OAMNS $WORKDIR/samples/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml
   sed -i  "/namespaceSelector/,/-/{s/-.*/- $OAMNS/}" $WORKDIR/samples/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml

   replace_value2 namespace $OAMNS $WORKDIR/samples/monitoring-service/manifests/prometheus-roleSpecific-domain-namespace.yaml
   sed -i  "0,/namespace/{s/namespace:.*/namespace: $OAMNS/}" $WORKDIR/samples/monitoring-service/manifests/prometheus-roleBinding-domain-namespace.yaml

   sed -i '0,/password/{s/'password':.*/'password': '"$ENC_WEBLOGIC_PWD"'/}' $WORKDIR/samples/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml
   sed -i '0,/user/{s/'user':.*/'user': '"$ENC_WEBLOGIC_USER"'/}' $WORKDIR/samples/monitoring-service/manifests/wls-exporter-ServiceMonitor.yaml

   kubectl apply -f $WORKDIR/samples/monitoring-service/manifests/ > $LOGDIR/enable_monitor.log
   print_status $? $LOGDIR/enable_monitor.log

   ET=`date +%s`
   print_time STEP "Configure Prometheus Operator" $ST $ET >> $LOGDIR/timings.log

}
