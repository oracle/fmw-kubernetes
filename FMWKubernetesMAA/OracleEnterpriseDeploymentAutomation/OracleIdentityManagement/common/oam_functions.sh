# Copyright (c) 2021, Oracle and/or its affiliates.
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
     echo "Creating Persistent Volumes"
     cd $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc
     replace_value2 domainUID $OAM_DOMAIN_NAME $PWD/create-pv-pvc-inputs.yaml
     replace_value2 namespace $OAMNS $PWD/create-pv-pvc-inputs.yaml
     replace_value2 baseName domain $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStorageType NFS $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStorageNFSServer $PVSERVER $PWD/create-pv-pvc-inputs.yaml
     replace_value2 weblogicDomainStoragePath $OAM_SHARE $PWD/create-pv-pvc-inputs.yaml
     
     ./create-pv-pvc.sh -i create-pv-pvc-inputs.yaml -o output > $LOGDIR/create_pv.log

     kubectl create -f output/pv-pvcs/$OAM_DOMAIN_NAME-domain-pv.yaml -n $OAMNS >> $LOGDIR/create_pv.log
     kubectl create -f output/pv-pvcs/$OAM_DOMAIN_NAME-domain-pvc.yaml -n $OAMNS >> $LOGDIR/create_pv.log

     ET=`date +%s`
     print_time STEP "Create Persistent Volumes" $ST $ET >> $LOGDIR/timings.log
}

# Edit sample domain Configuration File
#
edit_domain_creation_file()
{
     filename=$1

     cp $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-access-domain/domain-home-on-pv/create-domain-inputs.yaml $filename
     ST=`date +%s`
     replace_value2 domainUID $OAM_DOMAIN_NAME $filename
     replace_value2 domainPVMountPath $PV_MOUNT $filename
     replace_value2 domainHome $PV_MOUNT/domains/$OAM_DOMAIN_NAME $filename
     replace_value2 domainType oam $filename
     replace_value2 image oracle/oam:12.2.1.4.0 $filename
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
     ET=`date +%s`
     print_time STEP "Create Domain Configuration File" $ST $ET >> $LOGDIR/timings.log
}

# Update Java parameters for WebLogic Clusters in domain.yaml

update_java_parameters()
{
     echo "Updating Java Parameters"
     cp $TEMPLATE_DIR/oamDomain.sedfile $WORKDIR/OAM
     update_variable "<OAMSERVER_JAVA_PARAMS>" "$OAMSERVER_JAVA_PARAMS" $WORKDIR/OAM/oamDomain.sedfile
     cd $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-access-domain/domain-home-on-pv
     
     sed -i -f $WORKDIR/OAM/oamDomain.sedfile output/weblogic-domains/$OAM_DOMAIN_NAME/domain.yaml
}

# Create the OAM domain
#
create_oam_domain()
{

     echo -n "Initialising the Domain - "
     ST=`date +%s`
     cd $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-access-domain/domain-home-on-pv

     ./create-domain.sh -i $WORKDIR/OAM/create-domain-inputs.yaml -o output > $LOGDIR/create_domain.log 2>$LOGDIR/create_domain.log
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
     if [ "$status" = "Pending" ]
     then
         echo "Domain creation failed"
         echo "Run the following commands to debug"
         echo "kubectl describe job -n $OAMNS $OAM_DOMAIN_ID-create-fmw-infra-sample-domain-job"
         echo "kubectl -n $OAMNS describe domain $OAM_DOMAIN_ID"
         exit 1
     else
         echo "Success"
     fi
     ET=`date +%s`

     print_time STEP "Initialise the Domain" $ST $ET >> $LOGDIR/timings.log

     # Start the Domain
     #
     cp output/weblogic-domains/$OAM_DOMAIN_NAME/domain.yaml output/weblogic-domains/$OAM_DOMAIN_NAME/domain_original.yaml
     update_java_parameters
     echo -n "Starting the Domain - "
     ST=`date +%s`
     kubectl apply -f output/weblogic-domains/$OAM_DOMAIN_NAME/domain.yaml > $LOGDIR/first_start.log
     echo "Success"


     # Check that the domain is started
     #
     check_running $OAMNS adminserver
     check_running $OAMNS oam-server1
}

# Create NodePort Services for OAM
#
create_oam_nodeport()
{
     ST=`date +%s`
     echo  "Creating OAM Services "
     cp $TEMPLATE_DIR/*nodeport*.yaml $WORKDIR/OAM
     cp $TEMPLATE_DIR/*clusterip*.yaml $WORKDIR/OAM

     update_variable "<DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/oam_nodeport.yaml
     update_variable "<NAMESPACE>" $OAMNS $WORKDIR/OAM/oam_nodeport.yaml
     update_variable "<OAM_OAM_K8>" $OAM_OAM_K8 $WORKDIR/OAM/oam_nodeport.yaml
     update_variable "<DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/policy_nodeport.yaml
     update_variable "<NAMESPACE>" $OAMNS $WORKDIR/OAM/policy_nodeport.yaml
     update_variable "<OAM_POLICY_K8>" $OAM_POLICY_K8 $WORKDIR/OAM/policy_nodeport.yaml
     update_variable "<DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/oap_nodeport.yaml
     update_variable "<NAMESPACE>" $OAMNS $WORKDIR/OAM/oap_nodeport.yaml
     update_variable "<OAP_PORT>" $OAM_OAP_PORT $WORKDIR/OAM/oap_nodeport.yaml
     update_variable "<OAP_SERVICEPORT>" $OAM_OAP_SERVICE_PORT $WORKDIR/OAM/oap_nodeport.yaml
     update_variable "<OAP_PORT>" $OAM_OAP_PORT $WORKDIR/OAM/oap_clusterip.yaml
     update_variable "<NAMESPACE>" $OAMNS $WORKDIR/OAM/oap_clusterip.yaml
     update_variable "<DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/oap_clusterip.yaml

     echo -n "  OAM Service - "
     kubectl create -f $WORKDIR/OAM/oam_nodeport.yaml > $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
     if [ $? -eq 0 ] 
     then
         echo  "Success"
     else
         echo  "Failed"
  
     fi
     echo -n "  Policy Mangaer Service - "
     kubectl create -f $WORKDIR/OAM/policy_nodeport.yaml >> $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
     if [ $? -eq 0 ] 
     then
         echo  "Success"
     else
         echo  "Failed"
  
     fi

     echo -n "  OAP Service ClusterIP - "
     kubectl create -f $WORKDIR/OAM/oap_clusterip.yaml >> $LOGDIR/nodeport.log 2>>$LOGDIR/nodeport.log
     if [ $? -eq 0 ] 
     then
         echo  "Success"
     else
         echo  "Failed"
  
     fi
     ET=`date +%s` 
     print_time STEP "Create Kubernetes OAM NodePort Services " $ST $ET >> $LOGDIR/timings.log
}

# Update the newly created OAM domain using OAM API's
#
update_default_oam_domain()
{
     ADMINURL=$1
     USER=$2

     ST=`date +%s`
     echo -n "Updating default OAM Domain Settings - "

     cp $TEMPLATE_DIR/oamconfig_modify_template.xml  $WORKDIR/OAM/oamconfig_modify.xml

     for i in $( seq 1 $OAM_SERVER_COUNT)
     do
         sed -i "2i<Setting Name=\"Value\" Type=\"xsd:string\" Path=\"/DeployedComponent/Server/NGAMServer/Instance/oam_server$i/CoherenceConfiguration/LocalHost/Value\">$OAM_DOMAIN_NAME-oam-server$i</Setting>" $WORKDIR/OAM/oamconfig_modify.xml
         sed -i "2i<Setting Name=\"Port\" Type=\"xsd:integer\" Path=\"/DeployedComponent/Server/NGAMServer/Instance/oam_server$i/oamproxy/Port\">$OAM_OAP_PORT</Setting>" $WORKDIR/OAM/oamconfig_modify.xml
         sed -i "2i<Setting Name=\"host\" Type=\"xsd:string\" Path=\"/DeployedComponent/Server/NGAMServer/Instance/oam_server$i/host\">$OAM_DOMAIN_NAME-oam-server$i</Setting>"  $WORKDIR/OAM/oamconfig_modify.xml
     done

     update_variable "<OAM_SERVER>" $OAM_DOMAIN_NAME $WORKDIR/OAM/oamconfig_modify.xml
     update_variable "<OAP_PORT>" $OAM_OAP_PORT $WORKDIR/OAM/oamconfig_modify.xml
     update_variable "<LBR_HOST>" $OAM_LOGIN_LBR_HOST $WORKDIR/OAM/oamconfig_modify.xml
     update_variable "<LBR_PORT>" $OAM_LOGIN_LBR_PORT $WORKDIR/OAM/oamconfig_modify.xml
     update_variable "<LBR_PROTOCOL>" $OAM_LOGIN_LBR_PROTOCOL $WORKDIR/OAM/oamconfig_modify.xml
     update_variable "<OAP_HOST>" $OAM_OAP_HOST $WORKDIR/OAM/oamconfig_modify.xml
     update_variable "<OAP_SERVICE_PORT>" $OAM_OAP_SERVICE_PORT $WORKDIR/OAM/oamconfig_modify.xml
     
     curl -s -x '' -X PUT $ADMINURL/iam/admin/config/api/v1/config -ikL -H 'Content-Type: application/xml' --user $USER -H 'cache-control: no-cache' -d @$WORKDIR/OAM/oamconfig_modify.xml > $LOGDIR/update_oam.log
     curl -s -x '' -X GET $ADMINURL/iam/admin/config/api/v1/config -ikL -H 'Content-Type: application/xml' --user $USER -H 'cache-control: no-cache'  > $WORKDIR/OAM/oam-config.xml
     grep -q OAMRestEndPointHostName $WORKDIR/OAM/oam-config.xml | grep $OAM_LOGIN_LBR_HOST
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
     
     ST=`date +%s`
     ID=`curl -s -X GET -u $USER $ADMINURL/oam/services/rest/11.1.2.0.0/ssa/policyadmin/hostidentifier?name=IAMSuiteAgent | grep "<id>" | sed "s/^ *//g;s/<id>//;s/<\/id>//"`
     CURL_COMMAND="curl -s -o /dev/null -X PUT -u $USER"
     OAM_RESTAPI="$ADMINURL/oam/services/rest/11.1.2.0.0/ssa/policyadmin/hostidentifier"
     CONTENT_JSON="-H 'Content-Type: application/json' -H 'cache-control: no-cache'"
     START_JSON="-d '{\"Hosts\":{\"host\":[{\"port\":\"80\",\"hostName\":\"IAMSuiteAgent\"},{\"hostName\":\"IAMSuiteAgent\"}"
     END_JSON="]},\"description\":\"Host identifier for IAM Suite resources\",\"name\":\"IAMSuiteAgent\",\"id\":\"${ID}\"}'"
     JSON_HOSTS=",{\"port\":\"$OAM_LOGIN_LBR_PORT\",\"hostName\":\"$OAM_LOGIN_LBR_HOST\"}"
     JSON_HOSTS="$JSON_HOSTS",{\"port\":\"$OIG_LBR_PORT\",\"hostName\":\"$OIG_LBR_HOST\"}""
     JSON_HOSTS="$JSON_HOSTS",{\"port\":\"$OIG_LBR_INT_PORT\",\"hostName\":\"$OIG_LBR_INT_HOST\"}""
     JSON_HOSTS="$JSON_HOSTS",{\"port\":\"$OAM_ADMIN_LBR_PORT\",\"hostName\":\"$OAM_ADMIN_LBR_HOST\"}""
     JSON_HOSTS="$JSON_HOSTS",{\"port\":\"$OIG_ADMIN_LBR_PORT\",\"hostName\":\"$OIG_ADMIN_LBR_HOST\"}""
     JSON=${START_JSON}${JSON_HOSTS}${END_JSON}

     echo -n "Updating Host identifiers - "
     eval "$CURL_COMMAND \"$OAM_RESTAPI\" $CONTENT_JSON $JSON" > $LOGDIR/host_identifiers.log

     if [ $? -eq 0 ] 
     then
         echo  "Success"
     else
         echo  "Failed"
         exit 1
     fi
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
     echo -n "Add Missing Resources - "
     echo "Add Missing Resources"  > $LOGDIR/add_resources.log

     OAM_RESTAPI="'$ADMINURL/oam/services/rest/11.1.2.0.0/ssa/policyadmin/resource'"

     CURL_COMMAND="curl -s -X POST -u $USER"
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

     GET_CURL_COMMAND="curl -s -X GET -u $USER"
     PUT_CURL_COMMAND="curl -s -o /dev/null  -X PUT -u $USER"
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
   echo -n "Wiring OAM to OUD - "
   cp $TEMPLATE_DIR/runidmConfigTool.sh $WORKDIR/OAM
   cp $TEMPLATE_DIR/configoam.props $WORKDIR/OAM

   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/runidmConfigTool.sh
   update_variable "<PV_MOUNT>" $PV_MOUNT $WORKDIR/OAM/runidmConfigTool.sh
   update_variable "<WORK_DIR>" $K8_WORKDIR $WORKDIR/OAM/runidmConfigTool.sh

   update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/OAM/configoam.props
   update_variable "<OUD_ADMIN_USER>" $OUD_ADMIN_USER $WORKDIR/OAM/configoam.props
   update_variable "<OUD_GROUP_SEARCHBASE>" $OUD_GROUP_SEARCHBASE $WORKDIR/OAM/configoam.props
   update_variable "<OUD_SEARCHBASE>" $OUD_SEARCHBASE $WORKDIR/OAM/configoam.props
   update_variable "<OUD_USER_SEARCHBASE>" $OUD_USER_SEARCHBASE $WORKDIR/OAM/configoam.props
   update_variable "<OUD_OAMADMIN_USER>" $OUD_OAMADMIN_USER $WORKDIR/OAM/configoam.props
   update_variable "<OUD_OAMLDAP_USER>" $OUD_OAMLDAP_USER $WORKDIR/OAM/configoam.props
   update_variable "<OUD_OAMADMIN_GRP>" $OUD_OAMADMIN_GRP $WORKDIR/OAM/configoam.props
   update_variable "<OUD_SYSTEMIDS>" $OUD_SYSTEMIDS $WORKDIR/OAM/configoam.props
   update_variable "<OUD_OIGADMIN_GRP>" $OUD_OIGADMIN_GRP $WORKDIR/OAM/configoam.props
   update_variable "<OUD_OIGLDAP_USER>" $OUD_OIGLDAP_USER $WORKDIR/OAM/configoam.props
   update_variable "<OUD_WLSADMIN_USER>" $OUD_WLSADMIN_USER $WORKDIR/OAM/configoam.props
   update_variable "<OUD_WLSADMIN_GRP>" $OUD_WLSADMIN_GRP $WORKDIR/OAM/configoam.props
   update_variable "<OAM_OAP_PORT>" $OAM_OAP_PORT $WORKDIR/OAM/configoam.props
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/configoam.props
   update_variable "<OAM_COOKIE_DOMAIN>" $OAM_COOKIE_DOMAIN $WORKDIR/OAM/configoam.props
   update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $WORKDIR/OAM/configoam.props
   update_variable "<OAM_LOGIN_LBR_PORT>" $OAM_LOGIN_LBR_PORT $WORKDIR/OAM/configoam.props
   update_variable "<OAM_LOGIN_LBR_PROTOCOL>" $OAM_LOGIN_LBR_PROTOCOL $WORKDIR/OAM/configoam.props
   update_variable "<OIG_LBR_PROTOCOL>" $OIG_LBR_PROTOCOL $WORKDIR/OAM/configoam.props
   update_variable "<OIG_LBR_HOST>" $OIG_LBR_HOST $WORKDIR/OAM/configoam.props
   update_variable "<OIG_LBR_PORT>" $OIG_LBR_PORT $WORKDIR/OAM/configoam.props
   update_variable "<OAMNS>" $OAMNS $WORKDIR/OAM/configoam.props
   update_variable "<OUDNS>" $OUDNS $WORKDIR/OAM/configoam.props
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/OAM/configoam.props
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/OAM/configoam.props
   update_variable "<OUD_WLSADMIN_USER>" $OUD_WLSADMIN_USER $WORKDIR/OAM/configoam.props
   update_variable "<OUD_WLSADMIN_GRP>" $OUD_WLSADMIN_GRP $WORKDIR/OAM/configoam.props
   update_variable "<OUD_ADMIN_PWD>" $OUD_ADMIN_PWD $WORKDIR/OAM/configoam.props
   update_variable "<OUD_USER_PWD>" $OUD_USER_PWD $WORKDIR/OAM/configoam.props
   update_variable "<OAM_OIG_INTEG>" $OAM_OIG_INTEG $WORKDIR/OAM/configoam.props

   copy_to_k8 $WORKDIR/OAM/runidmConfigTool.sh workdir $OAMNS $OAM_DOMAIN_NAME
   copy_to_k8 $WORKDIR/OAM/configoam.props workdir $OAMNS $OAM_DOMAIN_NAME

   run_command_k8 $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/runidmConfigTool.sh workdir > $LOGDIR/configoam.out
   if [ $? = 1 ]
   then 
      echo "Failed"
      exit 1
   fi
    
   copy_from_k8 $PV_MOUNT/workdir/configoam.log $WORKDIR/OAM/logs/configoam.log $OAMNS $OAM_DOMAIN_NAME

   grep -q SEVERE $WORKDIR/OAM/logs/configoam.log | grep -v simple
   if [ $? = 0 ]
   then
      echo "Failed - Check logifle $WORKDIR/OAM/logs/configoam.log"
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
   echo -n "Create Webgate Agent - "
   
   cp $TEMPLATE_DIR/Webgate_IDM.xml $WORKDIR/OAM
   cp $TEMPLATE_DIR/create_wg.sh $WORKDIR/OAM
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/Webgate_IDM.xml
   update_variable "<OAMNS>" $OAMNS $WORKDIR/OAM/Webgate_IDM.xml
   update_variable "<OUD_OAMADMIN_USER>" $OUD_OAMADMIN_USER $WORKDIR/OAM/create_wg.sh
   update_variable "<OUD_USER_PWD>" $OUD_USER_PWD $WORKDIR/OAM/create_wg.sh
   update_variable "<PV_MOUNT>" $PV_MOUNT $WORKDIR/OAM/create_wg.sh
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/create_wg.sh

   copy_to_k8 $WORKDIR/OAM/Webgate_IDM.xml workdir $OAMNS $OAM_DOMAIN_NAME
   copy_to_k8 $WORKDIR/OAM/create_wg.sh workdir $OAMNS $OAM_DOMAIN_NAME

   run_command_k8 $OAMNS $OAM_DOMAIN_NAME "chmod 750 $PV_MOUNT/workdir/create_wg.sh"
   run_command_k8 $OAMNS $OAM_DOMAIN_NAME "$PV_MOUNT/workdir/create_wg.sh" > $LOGDIR/create_wg.log

   grep -q "completed successfully" /docker/workdir/OAM/logs/create_wg.log
   if [ $? = 0 ]
   then
       echo "Success"
   else
       echo "Fail"
   fi

   ET=`date +%s`
   print_time STEP "Time taken to create Webgate" $ST $ET >> $LOGDIR/timings.log
}


# Add LDAP groups to weblogic admin group
#
add_admin_roles()
{
    
   ST=`date +%s`
   echo -n "Add Administration Roles to WebLogic - "
   cp $TEMPLATE_DIR/add_admin_roles.py $WORKDIR/OAM
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/add_admin_roles.py
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/OAM/add_admin_roles.py
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/OAM/add_admin_roles.py
   update_variable "<OUD_OAMADMIN_GRP>" $OUD_OAMADMIN_GRP $WORKDIR/OAM/add_admin_roles.py
   update_variable "<OUD_WLSADMIN_GRP>" $OUD_WLSADMIN_GRP $WORKDIR/OAM/add_admin_roles.py
   update_variable "<OAMNS>" $OAMNS $WORKDIR/OAM/add_admin_roles.py

   copy_to_k8 $WORKDIR/OAM/add_admin_roles.py workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/add_admin_roles.py > $LOGDIR/add_admin_roles.log

   if [ $? = 0 ]
   then
       echo "Success"
   else
       echo "Fail"
   fi
   ET=`date +%s`
   print_time STEP "Add Admin Roles" $ST $ET >> $LOGDIR/timings.log
}

# Fix Gridlink Datasoureces
#
fix_gridlink()
{
     ST=`date +%s`
     echo -n "Enabling Database FAN - "

     cp $TEMPLATE_DIR/fix_gridlink.sh $WORKDIR/OAM

     update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/fix_gridlink.sh
     update_variable "<PV_MOUNT>" $PV_MOUNT $WORKDIR/OAM/fix_gridlink.sh

     copy_to_k8 $WORKDIR/OAM/fix_gridlink.sh workdir $OAMNS $OAM_DOMAIN_NAME
     run_command_k8 $OAMNS $OAM_DOMAIN_NAME "chmod 750 $PV_MOUNT/workdir/fix_gridlink.sh"
     run_command_k8 $OAMNS $OAM_DOMAIN_NAME "$PV_MOUNT/workdir/fix_gridlink.sh"
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
   cp $TEMPLATE_DIR/set_weblogic_plugin.py $WORKDIR/OAM
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/set_weblogic_plugin.py
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/OAM/set_weblogic_plugin.py
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/OAM/set_weblogic_plugin.py
   update_variable "<OAMNS>" $OAMNS $WORKDIR/OAM/set_weblogic_plugin.py
   update_variable "<OAM_ADMIN_PORT>" $OAM_ADMIN_PORT $WORKDIR/OAM/set_weblogic_plugin.py

   copy_to_k8 $WORKDIR/OAM/set_weblogic_plugin.py workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/set_weblogic_plugin.py > $LOGDIR/set_weblogic_plugin.log

   echo "Success"
   ET=`date +%s`
   print_time STEP "Set WebLogic Plug-in" $ST $ET >> $LOGDIR/timings.log
}

# Configure ADF Logout
# 
config_adf_logout()
{
    
   ST=`date +%s`
   echo -n "Setting ADF Logout - "
   cp $TEMPLATE_DIR/config_adf_security.py $WORKDIR/OAM
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/config_adf_security.py
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/OAM/config_adf_security.py
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/OAM/config_adf_security.py
   update_variable "<OAMNS>" $OAMNS $WORKDIR/OAM/config_adf_security.py
   update_variable "<OAM_ADMIN_PORT>" $OAM_ADMIN_PORT $WORKDIR/OAM/config_adf_security.py

   copy_to_k8 $WORKDIR/OAM/config_adf_security.py workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/config_adf_security.py > $LOGDIR/config_adf_security.log

   echo "Success"
   ET=`date +%s`
   print_time STEP "Set ADF Logout" $ST $ET >> $LOGDIR/timings.log
}

# Remove OAM from the default Coherence Cluster
#
remove_coherence()
{
    
   ST=`date +%s`
   echo -n "Remove Coherence - "
   cp $TEMPLATE_DIR/remove_coherence.py $WORKDIR/OAM
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/remove_coherence.py
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/OAM/remove_coherence.py
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/OAM/remove_coherence.py
   update_variable "<OAMNS>" $OAMNS $WORKDIR/OAM/remove_coherence.py

   for i in $( seq 1 $OAM_SERVER_COUNT)
   do
       sed -i "4icmo.removeTarget(getMBean(\'/Servers/oam_server$i\'))" $WORKDIR/OAM/remove_coherence.py
       sed -i "4icd(\'/CoherenceClusterSystemResources/defaultCoherenceCluster\')" $WORKDIR/OAM/remove_coherence.py
       sed -i "4icmo.setCoherenceClusterSystemResource(None)" $WORKDIR/OAM/remove_coherence.py
       sed -i "4icd(\'/Servers/oam_server$i\')" $WORKDIR/OAM/remove_coherence.py

       sed -i "4icmo.removeTarget(getMBean(\'/Servers/oam_policy_mgr$i\'))" $WORKDIR/OAM/remove_coherence.py
       sed -i "4icd(\'/CoherenceClusterSystemResources/defaultCoherenceCluster\')" $WORKDIR/OAM/remove_coherence.py
       sed -i "4icmo.setCoherenceClusterSystemResource(None)" $WORKDIR/OAM/remove_coherence.py
       sed -i "4icd(\'/Servers/oam_policy_mgr$i\')" $WORKDIR/OAM/remove_coherence.py
   done
   copy_to_k8 $WORKDIR/OAM/remove_coherence.py workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/remove_coherence.py > $LOGDIR/remove_coherence.log
   echo "Success"
   ET=`date +%s`
   print_time STEP "Removing default Coherence Cluster" $ST $ET >> $LOGDIR/timings.log
}

# Update OAM Datasource
# 
update_oamds()
{
    
   ST=`date +%s`
   echo -n "Updating OAMDS - "
   cp $TEMPLATE_DIR/update_oamds.py $WORKDIR/OAM
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/OAM/update_oamds.py
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $WORKDIR/OAM/update_oamds.py
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $WORKDIR/OAM/update_oamds.py
   update_variable "<OAMNS>" $OAMNS $WORKDIR/OAM/update_oamds.py

   copy_to_k8 $WORKDIR/OAM/update_oamds.py workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/update_oamds.py > $LOGDIR/update_oamds.log
   echo "Success"
   ET=`date +%s`
   print_time STEP "Update OAM Datasource" $ST $ET >> $LOGDIR/timings.log
}

# Create a configuration file which can be used by Oracle HTTP server for accessing OAM
#
create_oam_ohs_config()
{
   ST=`date +%s`
   
   echo -n "Creating OHS Config Files - " 
   OHS_PATH=$WORKDIR/OHS
   if ! [ -d $OHS_PATH/OHS/$OHS_HOST1 ]
   then
        mkdir -p $OHS_PATH/$OHS_HOST1
   fi
   if ! [ -d $OHS_PATH/OHS/$OHS_HOST2 ]
   then
        mkdir -p $OHS_PATH/$OHS_HOST2
   fi

   cp $TEMPLATE_DIR/iadadmin_vh.conf $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
   cp $TEMPLATE_DIR/iadadmin_vh.conf $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
   cp $TEMPLATE_DIR/login_vh.conf $OHS_PATH/$OHS_HOST1/login_vh.conf
   cp $TEMPLATE_DIR/login_vh.conf $OHS_PATH/$OHS_HOST2/login_vh.conf

   update_variable "<OHS_HOST>" $OHS_HOST1 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
   update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
   update_variable "<OAM_ADMIN_LBR_HOST>" $OAM_ADMIN_LBR_HOST $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
   update_variable "<OAM_ADMIN_LBR_PORT>" $OAM_ADMIN_LBR_PORT $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
   update_variable "<OAM_ADMIN_K8>" $OAM_ADMIN_K8 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
   update_variable "<OAM_POLICY_K8>" $OAM_POLICY_K8 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf
   update_variable "<OAM_OAM_K8>" $OAM_OAM_K8 $OHS_PATH/$OHS_HOST1/iadadmin_vh.conf


   update_variable "<OHS_HOST>" $OHS_HOST2 $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
   update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
   update_variable "<OAM_ADMIN_LBR_HOST>" $OAM_ADMIN_LBR_HOST $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
   update_variable "<OAM_ADMIN_LBR_PORT>" $OAM_ADMIN_LBR_PORT $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
   update_variable "<OAM_ADMIN_K8>" $OAM_ADMIN_K8 $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
   update_variable "<OAM_POLICY_K8>" $OAM_POLICY_K8 $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf
   update_variable "<OAM_OAM_K8>" $OAM_OAM_K8 $OHS_PATH/$OHS_HOST2/iadadmin_vh.conf

   update_variable "<OHS_HOST>" $OHS_HOST1 $OHS_PATH/$OHS_HOST1/login_vh.conf
   update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST1/login_vh.conf
   update_variable "<OAM_LOGIN_LBR_PROTOCOL>" $OAM_LOGIN_LBR_PROTOCOL $OHS_PATH/$OHS_HOST1/login_vh.conf
   update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $OHS_PATH/$OHS_HOST1/login_vh.conf
   update_variable "<OAM_LOGIN_LBR_PORT>" $OAM_LOGIN_LBR_PORT $OHS_PATH/$OHS_HOST1/login_vh.conf
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/login_vh.conf
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST1/login_vh.conf
   update_variable "<OAM_OAM_K8>" $OAM_OAM_K8 $OHS_PATH/$OHS_HOST1/login_vh.conf


   update_variable "<OHS_HOST>" $OHS_HOST2 $OHS_PATH/$OHS_HOST2/login_vh.conf
   update_variable "<OHS_PORT>" $OHS_PORT $OHS_PATH/$OHS_HOST2/login_vh.conf
   update_variable "<OAM_LOGIN_LBR_PROTOCOL>" $OAM_LOGIN_LBR_PROTOCOL $OHS_PATH/$OHS_HOST2/login_vh.conf
   update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $OHS_PATH/$OHS_HOST2/login_vh.conf
   update_variable "<OAM_LOGIN_LBR_PORT>" $OAM_LOGIN_LBR_PORT $OHS_PATH/$OHS_HOST2/login_vh.conf
   update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST2/login_vh.conf
   update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST1 $OHS_PATH/$OHS_HOST2/login_vh.conf
   update_variable "<OAM_OAM_K8>" $OAM_OAM_K8 $OHS_PATH/$OHS_HOST2/login_vh.conf

   echo "Success"
   ET=`date +%s`
   print_time STEP "Creating OHS config" $ST $ET >> $LOGDIR/timings.log
}

# Copy Webgate Files to DOMAIN_HOME/output
#
copy_wg_files()
{
   ST=`date +%s`
   echo -n "Copying Webgate Artifacts to $WORKDIR/OHS/webgate - "
   if ! [ -d $WORKDIR/OHS/webgate ]
   then
       mkdir -p $WORKDIR/OHS/webgate
   fi
   copy_from_k8 /u01/oracle/user_projects/domains/accessdomain/output/Webgate_IDM $WORKDIR/OHS/webgate $OAMNS $OAM_DOMAIN_NAME
   echo "Success"
   ET=`date +%s`
   print_time STEP "Copy Webgate Artifacts to $WORKDIR/OHS/webgate" $ST $ET >> $LOGDIR/timings.log
}
