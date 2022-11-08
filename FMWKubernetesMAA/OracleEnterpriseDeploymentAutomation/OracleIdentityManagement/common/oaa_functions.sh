# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of functions and procedures to provision and Configure Oracle Advanced Authentication
#
#
# Usage: not invoked Directly
#

# Execute a command in the oaa-mgmt container
#
oaa_mgmt()
{
   cmd=$1
   kubectl exec -n $OAANS -ti oaa-mgmt -- $cmd
}

# Create an oaa-mgmt pod in Kubernetes
#
create_helper()
{
   print_msg "Creating OAA Management Container"
   ST=`date +%s`

   kubectl get pod -n $OAANS oaa-mgmt > /dev/null 2> /dev/null
   if [ "$?" = "0" ]
   then
       echo "Already Created"
       check_running $OAANS oaa-mgmt
   else
       if [ "$OAA_VAULT_TYPE" = "file" ]
       then
           cp $TEMPLATE_DIR/oaa-mgmt-vfs.yaml $WORKDIR/oaa-mgmt.yaml
       else
           cp $TEMPLATE_DIR/oaa-mgmt-oci.yaml $WORKDIR/oaa-mgmt.yaml
       fi

       filename=$WORKDIR/oaa-mgmt.yaml

       update_variable "<OAANS>" $OAANS $filename
       update_variable "<PVSERVER>" $PVSERVER $filename
       update_variable "<OAA_CONFIG_SHARE>" $OAA_CONFIG_SHARE $filename
       update_variable "<OAA_CRED_SHARE>" $OAA_CRED_SHARE $filename
       update_variable "<OAA_LOG_SHARE>" $OAA_LOG_SHARE $filename
       update_variable "<OAA_VAULT_SHARE>" $OAA_VAULT_SHARE $filename
       update_variable "<OAA_MGT_IMAGE>" $OAA_MGT_IMAGE $filename
       update_variable "<OAAMGT_VER>" $OAAMGT_VER $filename

       kubectl create -f $filename > $LOGDIR/create_mgmt.log
       print_status $? $LOGDIR/create_mgmt.log
       check_running $OAANS oaa-mgmt

       printf "\t\t\tCopying Settings file - "

       kubectl exec -it -n $OAANS oaa-mgmt -- cp /u01/oracle/installsettings/installOAA.properties /u01/oracle/scripts/settings/ >> $LOGDIR/create_mgmt.log
       print_status $? $LOGDIR/create_mgmt.log
   fi

   ET=`date +%s`
   print_time STEP "Create OAA Management container" $ST $ET >> $LOGDIR/timings.log
}

# Copy file to Kubernetes Container
#
copy_to_oaa()
{
   source=$1
   destination=$2
   namespace=$3
   pod=$4

   COPYCODE=0
   kubectl cp $source  $namespace/$pod:$destination
   if  [  $? -gt 0 ]
   then
      echo "Failed to copy $filename."
      COPYCODE=1
   fi
}

# Copy file from Kubernetes Container
#
copy_from_oaa()
{
   source=$1
   destination=$2
   namespace=$3
   pod=$4

   kubectl cp $namespace/$pod:$source $destination
   if  [  $? -gt 0 ]
   then
      echo "Failed to copy $filename."
      exit 1
   fi
}

# Create Property file
#
prepare_property_file()
{

   print_msg "Prepare Property File"
   ST=`date +%s`

   kubectl cp  $OAANS/oaa-mgmt:/u01/oracle/installsettings/installOAA.properties $WORKDIR/installOAA.properties > $LOGDIR/create_property.log 2>&1
   kubectl cp  $OAANS/oaa-mgmt:/u01/oracle/installsettings/oaaoverride.yaml $WORKDIR/oaaoverride.yaml > $LOGDIR/create_property.log 2>&1
   propfile=$WORKDIR/installOAA.properties
   override=$WORKDIR/oaaoverride.yaml

   sed -i 's/database.sshuser=opc/database.sshuser=/' $propfile
   replace_value database.host $OAA_DB_SCAN $propfile
   replace_value database.port $OAA_DB_LISTENER $propfile
   replace_value database.svc $OAA_DB_SERVICE $propfile
   replace_value "#database.syspassword" $OAA_DB_SYS_PWD $propfile
   replace_value database.schema ${OAA_RCU_PREFIX}_OAA $propfile
   replace_value database.tablespace ${OAA_RCU_PREFIX}_OAA_TBS $propfile
   replace_value database.schemapassword $OAA_SCHEMA_PWD $propfile
   replace_value database.datafile /tmp/dbfiles/oaa.dat $propfile
   replace_value database.validaitonfile /tmp/dbfiles/validate.sql $propfile
   replace_value database.name $OAA_DB_SID $propfile
   replace_value database.createschema true $propfile
   replace_value common.deployment.name $OAA_DEPLOYMENT $propfile
   replace_value common.kube.namespace $OAANS $propfile
   replace_value common.deployment.namespace.coherenceoperator $OAACONS $propfile
   replace_value common.deployment.keystorepassphrase $OAA_KEYSTORE_PWD $propfile
   replace_value common.deployment.truststorepassphrase $OAA_KEYSTORE_PWD $propfile
   replace_value oauth.domainname $OAA_DOMAIN $propfile
   replace_value oauth.identityprovider OAMIDSTORE $propfile
   replace_value oauth.clientpassword $OAA_OAUTH_PWD $propfile
   replace_value oauth.adminurl http://${OAM_DOMAIN_NAME}-adminserver.${OAMNS}.svc.cluster.local:$OAM_ADMIN_PORT $propfile

   replace_value oauth.basicauthzheader `encode_pwd ${OAM_OAMADMIN_USER}:${OAM_OAMADMIN_PWD}` $propfile
   replace_value oauth.identityuri ${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT} $propfile
   replace_value oauth.redirecturl ${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT} $propfile
   replace_value install.oaa-admin-ui.serviceurl  http://${OAM_ADMIN_LBR_HOST}:${OAM_ADMIN_LBR_PORT} $propfile
   replace_value "install.global.serviceurl" ${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT} $propfile
   sed -i "s/#install.oaa-admin-ui.serviceurl/install.oaa-admin-ui.serviceurl/" $propfile
   sed -i "s/#install.global.serviceurl/install.global.serviceurl/" $propfile
  
 
   replace_value vault.deploy.name oaavault $propfile
   
   if [ "$OAA_VAULT_TYPE" = "file" ]
   then
        replace_value vault.provider fks $propfile
        replace_value vault.fks.server $PVSERVER $propfile
        replace_value vault.fks.path $OAA_VAULT_SHARE $propfile
        replace_value vault.fks.key `encode_pwd $OAA_VAULT_PWD` $propfile
   else
        replace_value vault.provider oci $propfile
        replace_value vault.oci.uasoperator $OAA_OCI_OPER $propfile
        replace_value vault.oci.tenancyId $OAA_OCI_TENANT $propfile
        replace_value vault.oci.userId $OAA_OCI_USER $propfile
        replace_value vault.oci.fpId $OAA_OCI_FP $propfile
        replace_value vault.oci.compartmentId $OAA_OCI_COMPARTMENT $propfile
        replace_value vault.oci.vaultId $OAA_OCI_VAULT_ID $propfile
        replace_value vault.oci.keyId $OAA_OCI_KEY $propfile
        sed -i "s/#vault.oci/vault.oci/" $propfile
   fi

   replace_value install.global.repo $REGISTRY $propfile
   replace_value install.global.imagePullSecret regcred $propfile
   global_replace_value dockersecret regcred $propfile
   if [ "$CREATE_GITSECRET" = "true" ]
   then
       sed -i '/install.global.imagePullSecrets.*/a install.global.imagePullSecrets\\[1\\].name=github' $propfile
   fi
   replace_value install.global.image.tag $OAA_VER $propfile
   replace_value install.global.oauth.host $OAM_LOGIN_LBR_HOST $propfile
   replace_value install.global.uasapikey $OAA_API_PWD $propfile
   replace_value install.global.policyapikey $OAA_API_PWD $propfile
   replace_value install.global.factorsapikey $OAA_API_PWD $propfile
   replace_value install.global.riskapikey $OAA_API_PWD $propfile

   hostip=`dig +short $OAM_LOGIN_LBR_HOST | grep "^[0-9]"`
  
   if [ "$hostip" = "" ]
   then
       hostip=` ping $OAM_LOGIN_LBR_HOST -c 1 -n -W 1 | head -1 | sed 's/[()]//g ' | awk '{print $3}'`
       if [ $? -gt 0 ]
       then
          echo "Unable to Obtain IP address of $OAM_LOGIN_LBR_HOST"
          exit 1
       fi
   fi

   replace_value install.global.oauth.ip $hostip $propfile
   replace_value install.global.oauth.logouturl ${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT}/oam/server/logout $propfile
   replace_value install.global.oauth.serviceurl ${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT} $propfile

   sed -i "s/#database.syspassword/database.syspassword/" $propfile
   sed -i "s/#common.kube.namespace/common.kube.namespace/" $propfile
   sed -i "s/#install.global.oauth.serviceurl/install.global.oauth.serviceurl/" $propfile

   if [ "$USE_INGRESS" = "false" ]
   then
       replace_value install.service.type NodePort $propfile
       replace_value install.oaa-admin-ui.service.type NodePort $propfile
       replace_value install.oaa-policy.service.type NodePort $propfile
       replace_value install.spui.service.type NodePort $propfile
       replace_value install.totp.service.type NodePort $propfile
       replace_value install.fido.service.type NodePort $propfile
       replace_value install.push.service.type NodePort $propfile
       replace_value install.email.service.type NodePort $propfile
       replace_value install.sms.service.type NodePort $propfile
       replace_value install.yotp.service.type NodePort $propfile
       replace_value install.oaa-kba.service.type NodePort $propfile
       replace_value install.risk.service.type NodePort $propfile
       replace_value install.risk.riskcc.service.type NodePort $propfile
   else
       replace_value install.service.type ClusterIP $propfile
       replace_value install.oaa-admin-ui.service.type ClusterIP $propfile
       replace_value install.oaa-policy.service.type ClusterIP $propfile
       replace_value install.spui.service.type ClusterIP $propfile
       replace_value install.totp.service.type ClusterIP $propfile
       replace_value install.fido.service.type ClusterIP $propfile
       replace_value install.push.service.type ClusterIP $propfile
       replace_value install.email.service.type ClusterIP $propfile
       replace_value install.sms.service.type ClusterIP $propfile
       replace_value install.yotp.service.type ClusterIP $propfile
       replace_value install.oaa-kba.service.type ClusterIP $propfile
       replace_value install.risk.service.type ClusterIP $propfile
       replace_value install.risk.riskcc.service.type ClusterIP $propfile
       awk  -v "var=install.ingress.hosts\\\\[0\\\\].host=${OAM_LOGIN_LBR_HOST}\ninstall.ingress.hosts\\\\[1\\\\].host=${OAM_ADMIN_LBR_HOST}" '/install.ingress.hosts/ && !x {print var; x=1} 1' $propfile > ${propfile}1
       mv ${propfile}1 $propfile
   fi
   sed -i "s/#install.global.ingress.enabled=true/install.global.ingress.enabled=${USE_INGRESS}/" $propfile
   sed -i "s/#install.global.ingress.runtime.host=.*/install.global.ingress.runtime.host=${OAM_LOGIN_LBR_HOST}/" $propfile
   sed -i "s/#install.global.ingress.admin.host=.*/install.global.ingress.admin.host=${OAM_ADMIN_LBR_HOST}/"  $propfile
   sed -i "s/#common.deployment.overridefile/common.deployment.overridefile/" $propfile

   sed -i "0,/replicaCount/s/replicaCount.*/replicaCount: $OAA_REPLICAS/" $override
   sed -i "/spui:/{n;s/replicaCount.*/replicaCount: $OAA_SPUI_REPLICAS/}"  $override
   sed -i "/totp:/{n;s/replicaCount.*/replicaCount: $OAA_TOTP_REPLICAS/}"  $override
   sed -i "/yotp:/{n;s/replicaCount.*/replicaCount: $OAA_YOTP_REPLICAS/}"  $override
   sed -i "/fido:/{n;s/replicaCount.*/replicaCount: $OAA_FIDO_REPLICAS/}"  $override
   sed -i "/oaa-admin-ui:/{n;s/replicaCount.*/replicaCount: $OAA_ADMIN_REPLICAS/}"  $override
   sed -i "/email:/{n;s/replicaCount.*/replicaCount: $OAA_EMAIL_REPLICAS/}"  $override
   sed -i "/sms:/{n;s/replicaCount.*/replicaCount: $OAA_SMS_REPLICAS/}"  $override
   sed -i "/oaa-policy:/{n;s/replicaCount.*/replicaCount: $OAA_POLICY_REPLICAS/}"  $override
   sed -i "/push:/{n;s/replicaCount.*/replicaCount: $OAA_PUSH_REPLICAS/}"  $override


   copy_to_oaa $propfile /u01/oracle/scripts/settings/installOAA.properties $OAANS oaa-mgmt  >> $LOGDIR/create_property.log 2>&1
   copy_to_oaa $override /u01/oracle/scripts/settings/oaaoverride.yaml $OAANS oaa-mgmt  >> $LOGDIR/create_property.log 2>&1
   print_status $COPYCODE $LOGDIR/create_property.log

   ET=`date +%s`
   print_time STEP "Create property_file" $ST $ET >> $LOGDIR/timings.log
}


# Create RBAC for OCI
#
create_rbac()
{
   print_msg "Create OAA Service Account"
   ST=`date +%s`

   filename=oaa_svc_acct_ingress.yaml

   cp $TEMPLATE_DIR/$filename $WORKDIR
   update_variable "<OAANS>" $OAANS $WORKDIR/$filename
   update_variable "<OAACONS>" $OAACONS $WORKDIR/$filename

   kubectl apply -f $WORKDIR/$filename > $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log

   TOKENNAME=`kubectl -n $OAANS get serviceaccount/oaa-service-account -o jsonpath='{.secrets[0].name}'`

   TOKEN=`kubectl -n $OAANS get secret $TOKENNAME -o jsonpath='{.data.token}'| base64 --decode`

   k8url=`grep server: $KUBECONFIG | sed 's/server://;s/ //g'`

   printf "\t\t\tGenerate ca.crt - "
   kubectl -n $OAANS get secret $TOKENNAME -o jsonpath='{.data.ca\.crt}'| base64 --decode > $WORKDIR/ca.crt
   print_status $? $LOGDIR/create_rbac.log

   printf "\t\t\tCreate Kubeconfig file - "
   kubectl config --kubeconfig=$WORKDIR/oaa_config set-cluster oaa-cluster --server=$k8url --certificate-authority=$WORKDIR/ca.crt --embed-certs=true >> $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log

   printf "\t\t\tAdd credentials - "
   kubectl config --kubeconfig=$WORKDIR/oaa_config set-credentials oaa-service-account --token=$TOKEN >> $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log

   printf "\t\t\tAdd Service Account - "
   kubectl config --kubeconfig=$WORKDIR/oaa_config set-context oaa --user=oaa-service-account --cluster=oaa-cluster >> $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log

   printf "\t\t\tAdd context - "
   kubectl config --kubeconfig=$WORKDIR/oaa_config use-context oaa >> $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log

   printf "\t\t\tCopy ca.crt to oaa-mgmt - "
   echo copy_to_oaa $WORKDIR/ca.crt /u01/oracle/scripts/creds $OAANS oaa-mgmt  >> $LOGDIR/create_rbac.log 2>&1
   copy_to_oaa $WORKDIR/ca.crt /u01/oracle/scripts/creds $OAANS oaa-mgmt  >> $LOGDIR/create_rbac.log 2>&1
   print_status $COPYCODE $LOGDIR/create_rbac.log
   printf "\t\t\tCopy KUBECONFIG to oaa-mgmt - "
   copy_to_oaa $WORKDIR/oaa_config /u01/oracle/scripts/creds/k8sconfig $OAANS oaa-mgmt  >> $LOGDIR/create_rbac.log 2>&1
   print_status $COPYCODE $LOGDIR/create_rbac.log

   ET=`date +%s`
   print_time STEP "Create oaa-mgmt kubeconfig" $ST $ET >> $LOGDIR/timings.log
}

# Validate the kubectl command in the oiri-cli container
#
validate_oaamgmt()
{
   print_msg "Checking kubectl"
   ST=`date +%s`
   oaa_mgmt "kubectl get pods -n $OAANS" > $LOGDIR/check_kubectl.log 2>&1
   grep -q "NAME" $LOGDIR/check_kubectl.log
   print_status $?  $LOGDIR/check_kubectl.log
   ET=`date +%s`
   print_time STEP "Validate kubectl" $ST $ET >> $LOGDIR/timings.log
}

# Create a Helm Configuration File
#
create_helm_file()
{
   print_msg "Creating Helm Configuration File"
   ST=`date +%s`
   copy_to_oaa $TEMPLATE_DIR/helmconfig /u01/oracle/scripts/creds $OAANS oaa-mgmt  >> $LOGDIR/create_helm_file.log 2>&1
   print_status $COPYCODE  $LOGDIR/create_helm_file.log
   ET=`date +%s`
   print_time STEP "Create Helm Config File" $ST $ET >> $LOGDIR/timings.log
}

#
# Create OAA Server certificates
create_server_certs()
{
   print_msg "Creating Server Certificates"
   ST=`date +%s`

   mkdir $WORKDIR/ssl > /dev/null 2>&1
   printf "\n\t\t\tCreate Self Signed Root Key - "
   openssl genrsa -out $WORKDIR/ssl/ca.key 4096 > $LOGDIR/server_cert.log 2>&1
   print_status $? $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tCreate Self Signed Root Certificate - "
   openssl req -new -x509 -days 3650 -key $WORKDIR/ssl/ca.key -out $WORKDIR/ssl/ca.crt -subj "/C=$SSL_COUNTRY/ST=$SSL_STATE/L=$SSL_CITY/O=$SSL_ORG/CN=CARoot" >> $LOGDIR/server_cert.log 2>&1
   print_status $? $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tGenerate P12 Trust Store - "
   openssl pkcs12 -export -out $WORKDIR/ssl/trust.p12 -nokeys -in $WORKDIR/ssl/ca.crt -passout pass:$OAA_KEYSTORE_PWD >> $LOGDIR/server_cert.log 2>&1
   print_status $? $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tVerifying Key - "

   openssl rsa -in $WORKDIR/ssl/ca.key -check > $WORKDIR/ssl/keycheck  2>&1
   grep -q "RSA key ok" $WORKDIR/ssl/keycheck
   print_status $? $LOGDIR/server_cert.log

   printf "\t\t\tVerifying Certificate - "
   openssl x509 -in $WORKDIR/ssl/ca.crt -text  -noout > /dev/null 2>&1
   print_status $? $LOGDIR/server_cert.log

   printf "\t\t\tCreate Self Signed Server Key - "
   openssl genrsa -out $WORKDIR/ssl/oaa.key 4096 >> $LOGDIR/server_cert.log 2>&1
   print_status $? $LOGDIR/server_cert.log

   printf "\t\t\tCreate Self Signed Server Certificate - "
   openssl req -new -key $WORKDIR/ssl/oaa.key -out $WORKDIR/ssl/cert.csr -subj "/C=$SSL_COUNTRY/ST=$SSL_STATE/L=$SSL_CITY/O=$SSL_ORG/CN=$OAM_LOGIN_LBR_HOST" >> $LOGDIR/server_cert.log 2>&1
   print_status $? $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tCreate Self Signing Request - "
   openssl x509 -req -days 1826 -in $WORKDIR/ssl/cert.csr -CA $WORKDIR/ssl/ca.crt -CAkey $WORKDIR/ssl/ca.key -set_serial 01 -out $WORKDIR/ssl/oaa.crt >> $LOGDIR/server_cert.log 2>&1
   print_status $? $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tConvert to PKCS12 - "
   openssl pkcs12 -export -out $WORKDIR/ssl/cert.p12 -inkey $WORKDIR/ssl/oaa.key -in $WORKDIR/ssl/oaa.crt -chain -CAfile $WORKDIR/ssl/ca.crt -passout pass:$OAA_KEYSTORE_PWD>> $LOGDIR/server_cert.log 2>&1
   print_status $? $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tConvert crt to pem - "
   openssl x509 -in $WORKDIR/ssl/oaa.crt -out $WORKDIR/ssl/oaa.pem -outform PEM >> $LOGDIR/server_cert.log 2>&1
   print_status $? $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tExport existing CA Cert from Trustore to PEM bundle file - "
   openssl pkcs12 -in $WORKDIR/ssl/trust.p12 -out $WORKDIR/ssl/bundle.pem -cacerts -nokeys -passin pass:$OAA_KEYSTORE_PWD >> $LOGDIR/server_cert.log 2>&1
   print_status $? $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tAdd OAM cert to Bundle - "
   cat $WORKDIR/$OAM_LOGIN_LBR_HOST.pem >> $WORKDIR/ssl/bundle.pem

   print_status $? $LOGDIR/server_cert.log 2>&1
   printf "\t\t\tImport PEM cert into truststore - "
   openssl pkcs12 -export -in $WORKDIR/ssl/bundle.pem -nokeys -out $WORKDIR/ssl/trust.p12 -passout pass:$OAA_KEYSTORE_PWD >> $LOGDIR/server_cert.log 2>&1
   print_status $? $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tCopy Trust Store to oaa-mgmt - "
   copy_to_oaa $WORKDIR/ssl/trust.p12 /u01/oracle/scripts/creds $OAANS oaa-mgmt  >> $LOGDIR/server_cert.log 2>&1
   print_status $COPYCODE $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tCopy Server Certificate to oaa-mgmt - "
   copy_to_oaa $WORKDIR/ssl/cert.p12 /u01/oracle/scripts/creds $OAANS oaa-mgmt  >> $LOGDIR/server_cert.log 2>&1
   print_status $COPYCODE $LOGDIR/server_cert.log 2>&1

   printf "\t\t\tCopy File to oaa-mgmt - "
   copy_to_oaa $TEMPLATE_DIR/helmconfig /u01/oracle/scripts/creds $OAANS oaa-mgmt  >> $LOGDIR/server_cert.log 2>&1
   print_status $COPYCODE $LOGDIR/server_cert.log 2>&1
   ET=`date +%s`
   print_time STEP "Create Server Certs" $ST $ET >> $LOGDIR/timings.log
}

 
# Create LDAP Users and Groups
#

create_ldap_entries()
{

     DIR_TYPE=$1

     ST=`date +%s`
     print_msg "Create Users/Groups in LDAP"

     cp $TEMPLATE_DIR/users.ldif $WORKDIR
     filename=$WORKDIR/users.ldif

     update_variable "<OAA_ADMIN_USER>" $OAA_ADMIN_USER $filename
     update_variable "<OAA_ADMIN_PWD>" $OAA_ADMIN_PWD $filename
     update_variable "<LDAP_USER_SEARCHBASE>" $LDAP_USER_SEARCHBASE $filename
     update_variable "<LDAP_GROUP_SEARCHBASE>" $LDAP_GROUP_SEARCHBASE $filename
     update_variable "<LDAP_SEARCHBASE>" $LDAP_SEARCHBASE $filename
     update_variable "<OAA_ADMIN_GROUP>" $OAA_ADMIN_GROUP $filename
     update_variable "<OAA_USER_GROUP>" $OAA_USER_GROUP $filename


     if [ "$DIR_TYPE" = "oud" ]
     then
         cp $TEMPLATE_DIR/oud_add_users.sh $WORKDIR
         shfile=$WORKDIR/oud_add_users.sh
         update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $shfile
         update_variable "<OUDNS>" $OUDNS $shfile
         update_variable "<LDAP_ADMIN_USER>" $LDAP_ADMIN_USER $shfile
         update_variable "<LDAP_ADMIN_PWD>" $LDAP_ADMIN_PWD $shfile

         kubectl cp $filename $OUDNS/$OUD_POD_PREFIX-oud-ds-rs-0:/u01/oracle/config-input > $LOGDIR/create_ldap.log 2>&1
         kubectl cp $shfile $OUDNS/$OUD_POD_PREFIX-oud-ds-rs-0:/u01/oracle/config-input >> $LOGDIR/create_ldap.log 2>&1
         kubectl exec -ti -n $OUDNS $OUD_POD_PREFIX-oud-ds-rs-0 -c oud-ds-rs -- /u01/oracle/config-input/oud_add_users.sh >> $LOGDIR/create_ldap.log 2>&1
     fi

     if [ $? -gt 0 ]
     then
           grep -q exists $LOGDIR/create_ldap.log
           if [ $? = 0 ]
           then 
              printf "Already exists\n"
           else
             print_status 1 $LOGDIR/create_ldap.log
           fi
     else
       printf " Success\n"
     fi

     ET=`date +%s`
     print_time STEP "Create Users and Groups" $ST $ET >> $LOGDIR/timings.log
}

# Update Enable OAM OAuth
#
enable_oauth()
{
     ADMINURL=$1
     USER=$2

     ST=`date +%s`
     print_msg "Enabling OAM OAuth"

     cp $TEMPLATE_DIR/enable_oauth.xml  $WORKDIR/enable_oauth.xml

     curl -s -x '' -X PUT $ADMINURL/iam/admin/config/api/v1/config -ikL -H 'Content-Type: application/xml' --user $USER -H 'cache-control: no-cache' -d @$WORKDIR/enable_oauth.xml > $LOGDIR/enable_oauth.log 2>&1
     
     print_status $? $LOGDIR/enable_oauth.log
     ET=`date +%s`
     print_time STEP "Enable OAM OAuth " $ST $ET >> $LOGDIR/timings.log
}

# Validate OAuth
#
validate_oauth()
{

     ST=`date +%s`
     print_msg "Validating OAM OAuth"

     cp $TEMPLATE_DIR/enable_oauth.xml  $WORKDIR/enable_oauth.xml

     AUTHZHEADER=`encode_pwd OAAClient:${OAA_OAUTH_PWD}`

     echo "Validating OAuth using the command:" > $LOGDIR/validate_oauth.log
     echo curl -s -k --location --request GET ${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT}/oauth2/rest/token  >> $LOGDIR/validate_oauth.log

     curl -s -k --location --request GET ${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT}/oauth2/rest/token  >> $LOGDIR/validate_oauth.log
     grep -q "Method Not Allowed" $LOGDIR/validate_oauth.log

     print_status $? $LOGDIR/validate_oauth.log
     ET=`date +%s`
     print_time STEP "Validate OAuth" $ST $ET >> $LOGDIR/timings.log
}

add_existing_users()
{

     DIR_TYPE=$1

     ST=`date +%s`
     print_msg "Add existing users to $OAA_USER_GROUP"

     if [ "$DIR_TYPE" = "oud" ]
     then
         cp $TEMPLATE_DIR/oud_add_existing_users.sh $WORKDIR
         shfile=$WORKDIR/oud_add_existing_users.sh
         update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $shfile
         update_variable "<OUDNS>" $OUDNS $shfile
         update_variable "<LDAP_ADMIN_USER>" $LDAP_ADMIN_USER $shfile
         update_variable "<LDAP_ADMIN_PWD>" $LDAP_ADMIN_PWD $shfile
         update_variable "<LDAP_USER_SEARCHBASE>" $LDAP_USER_SEARCHBASE $shfile
         update_variable "<LDAP_GROUP_SEARCHBASE>" $LDAP_GROUP_SEARCHBASE $shfile
         update_variable "<OAA_ADMIN_USER>" $OAA_ADMIN_USER $shfile
         update_variable "<OAA_USER_GROUP>" $OAA_USER_GROUP $shfile

         kubectl cp $shfile $OUDNS/$OUD_POD_PREFIX-oud-ds-rs-0:/u01/oracle/config-input  > $LOGDIR/add_existing_users.log 2>&1
         kubectl exec -ti -n $OUDNS $OUD_POD_PREFIX-oud-ds-rs-0 -c oud-ds-rs -- /u01/oracle/config-input/oud_add_existing_users.sh >> $LOGDIR/add_existing_users.log 2>&1
     fi

     if [ $? -gt 0 ]
     then
           grep -q duplicate $LOGDIR/add_existing_users.log
           if [ $? = 0 ]
           then 
              printf "Already exists\n"
           else
             print_status 1 $LOGDIR/add_existing_users.log
           fi
     else
        echo " Success"
     fi

     ET=`date +%s`
     print_time STEP "Add Existing Users to OAA Group" $ST $ET >> $LOGDIR/timings.log
}


add_ohs_rewrite_rules()
{

     ST=`date +%s`
     print_msg "Add OHS Rewrite Rules"

     cp $TEMPLATE_DIR/ohs_header.conf $WORKDIR
     update_variable "<OAA_DOMAIN>" $OAA_DOMAIN $WORKDIR/ohs_header.conf

     OHSHOST1FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST1
     OHSHOST2FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST2

     grep -q X-OAUTH-IDENTITY-DOMAIN-NAME $OHSHOST1FILES/login_vh.conf
     if [ $? -gt 0 ]
     then
         sed -i "/RewriteEngine/r $WORKDIR/ohs_header.conf" $OHSHOST1FILES/login_vh.conf
     fi

     if [ ! "$OHS_HOST2" = "" ]
     then
       grep -q X-OAUTH-IDENTITY-DOMAIN-NAME $OHSHOST2FILES/login_vh.conf
       if [ $? -gt 0 ]
       then
         sed -i "/RewriteEngine/r $WORKDIR/ohs_header.conf" $OHSHOST2FILES/login_vh.conf
       fi
     fi

     print_status $? 
     ET=`date +%s`
     print_time STEP "Add OHS Rewrite Rules" $ST $ET >> $LOGDIR/timings.log
}

create_ohs_entries()
{

     ST=`date +%s`
     print_msg "Add OHS Directives"

     cp $TEMPLATE_DIR/ohs_login.conf $WORKDIR
     cp $TEMPLATE_DIR/ohs_admin.conf $WORKDIR
     cp $TEMPLATE_DIR/create_ohs_wallet.sh $WORKDIR

     update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $WORKDIR/ohs_login.conf
     update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST2 $WORKDIR/ohs_login.conf

     if [ "$USE_INGRESS"  = "false" ]
     then
         OAA_K8=`get_k8_port oaa $OAANS`
         OAA_POLICY_K8=`get_k8_port policy $OAANS`
         OAA_EMAIL_K8=`get_k8_port email $OAANS`
         OAA_SMS_K8=`get_k8_port sms $OAANS`
         OAA_TOTP_K8=`get_k8_port totp $OAANS`
         OAA_PUSH_K8=`get_k8_port push $OAANS`
         OAA_YOTP_K8=`get_k8_port yotp $OAANS`
         OAA_FIDO_K8=`get_k8_port fido $OAANS`
         OAA_SPUI_K8=`get_k8_port spui $OAANS`
         OAA_ADMINUI_K8=`get_k8_port admin-ui $OAANS`
         OAA_KBA_K8=`get_k8_port kba $OAANS`
         RISK_ANAL_K8=`get_k8_port risk $OAANS`
         RISK_CC_K8=`get_k8_port risk-cc $OAANS`
     else
         OAA_K8=$INGRESS_HTTP_PORT
         OAA_POLICY_K8=$INGRESS_HTTP_PORT
         OAA_EMAIL_K8=$INGRESS_HTTP_PORT
         OAA_SMS_K8=$INGRESS_HTTP_PORT
         OAA_TOTP_K8=$INGRESS_HTTP_PORT
         OAA_PUSH_K8=$INGRESS_HTTP_PORT
         OAA_YOTP_K8=$INGRESS_HTTP_PORT
         OAA_FIDO_K8=$INGRESS_HTTP_PORT
         OAA_SPUI_K8=$INGRESS_HTTP_PORT
         OAA_ADMINUI_K8=$INGRESS_HTTP_PORT
         OAA_KBA_K8=$INGRESS_HTTP_PORT
         RISK_ANAL_K8=$INGRESS_HTTP_PORT
         RISK_CC_K8=$INGRESS_HTTP_PORT
         sed -i '/SecureProxy/d' $WORKDIR/ohs_login.conf
         sed -i '/SecureProxy/d' $WORKDIR/ohs_admin.conf
      fi

     update_variable "<OAA_K8>" $OAA_K8 $WORKDIR/ohs_login.conf
     update_variable "<OAA_FIDO_K8>" $OAA_FIDO_K8 $WORKDIR/ohs_login.conf
     update_variable "<OAA_SPUI_K8>" $OAA_SPUI_K8 $WORKDIR/ohs_login.conf
     update_variable "<OAA_EMAIL_K8>" $OAA_EMAIL_K8 $WORKDIR/ohs_login.conf
     update_variable "<OAA_SMS_K8>" $OAA_SMS_K8 $WORKDIR/ohs_login.conf
     update_variable "<OAA_TOTP_K8>" $OAA_TOTP_K8 $WORKDIR/ohs_login.conf
     update_variable "<OAA_YOTP_K8>" $OAA_YOTP_K8 $WORKDIR/ohs_login.conf
     update_variable "<OAA_KBA_K8>" $OAA_KBA_K8 $WORKDIR/ohs_login.conf
     update_variable "<OAA_PUSH_K8>" $OAA_PUSH_K8 $WORKDIR/ohs_login.conf
     update_variable "<OAA_POLICY_K8>" $OAA_POLICY_K8 $WORKDIR/ohs_login.conf
     update_variable "<RISK_ANAL_K8>" $RISK_ANAL_K8 $WORKDIR/ohs_login.conf
     update_variable "<RISK_CC_K8>" $RISK_CC_K8 $WORKDIR/ohs_login.conf

     update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $WORKDIR/ohs_admin.conf
     update_variable "<K8_WORKER_HOST2>" $K8_WORKER_HOST2 $WORKDIR/ohs_admin.conf
     update_variable "<OAA_ADMIN_K8>" $OAA_ADMINUI_K8 $WORKDIR/ohs_admin.conf
     update_variable "<OAA_KBA_K8>" $OAA_KBA_K8 $WORKDIR/ohs_admin.conf

     OHSHOST1FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST1
     OHSHOST2FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST2

     grep -q "/oaa/rui"  $OHSHOST1FILES/login_vh.conf
     if [ $? -gt 0 ]
     then
         sed -i '/<\/VirtualHost>/d' $OHSHOST1FILES/iadadmin_vh.conf
         sed -i '/<\/VirtualHost>/d' $OHSHOST1FILES/login_vh.conf
         cat $WORKDIR/ohs_login.conf >> $OHSHOST1FILES/login_vh.conf
         cat $WORKDIR/ohs_admin.conf >> $OHSHOST1FILES/iadadmin_vh.conf

         if [ ! "$OHS_HOST2" = "" ]
         then
            sed -i '/<\/VirtualHost>/d' $OHSHOST2FILES/iadadmin_vh.conf
            sed -i '/<\/VirtualHost>/d' $OHSHOST2FILES/login_vh.conf
            cat $WORKDIR/ohs_login.conf >> $OHSHOST2FILES/login_vh.conf
            cat $WORKDIR/ohs_admin.conf >> $OHSHOST2FILES/iadadmin_vh.conf
         fi
     fi

     update_variable "<OHS_ORACLE_HOME>" $OHS_ORACLE_HOME $WORKDIR/create_ohs_wallet.sh
     update_variable "<OHS_DOMAIN>" $OHS_DOMAIN $WORKDIR/create_ohs_wallet.sh
     update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $WORKDIR/create_ohs_wallet.sh
     update_variable "<OAA_K8>" $OAA_K8  $WORKDIR/create_ohs_wallet.sh

     print_status $? 
     ET=`date +%s`
     print_time STEP "Add OHS Directives" $ST $ET >> $LOGDIR/timings.log
}

# Copy OHS config Files to OHS servers
#
create_ohs_wallet()
{
     OHS_SERVERS=$1

     print_msg "Create OHS Wallet with OAA Certificate"
     printf "\n\t\t\tCopy Script to OHS Server $OHS_HOST1 - "

     scp $WORKDIR/create_ohs_wallet.sh  $OHS_HOST1:/tmp > $LOGDIR/create_wallet.log 2>&1
     print_status $? $LOGDIR/create_wallet.log

     printf "\t\t\tChanging Permissions - "
     ssh $OHS_HOST1 "chmod +x /tmp/create_ohs_wallet.sh" >> $LOGDIR/copy_ohs.log 2>&1
     print_status $? $LOGDIR/copy_ohs.log

     printf "\t\t\tCreating Wallet on OHS Server $OHS_HOST1 - "
     ssh $OHS_HOST1 "/tmp/create_ohs_wallet.sh" >> $LOGDIR/copy_ohs.log 2>&1
     print_status $? $LOGDIR/copy_ohs.log

     printf "\t\t\tRestarting Oracle HTTP Server $OHS_HOST1 - "
     ssh $OHS_HOST1 "$OHS_DOMAIN/bin/restartComponent.sh $OHS1_NAME" >> $LOGDIR/copy_ohs.log 2>&1
     print_status $? $LOGDIR/copy_ohs.log

     if [ ! "$OHS_HOST2" = "" ]
     then
        printf "\n\t\t\tCopy Script to OHS Server $OHS_HOST2 - "

        scp $WORKDIR/create_ohs_wallet.sh  $OHS_HOST2:/tmp >> $LOGDIR/create_wallet.log 2>&1
        print_status $? $LOGDIR/create_wallet.log

        printf "\t\t\tChanging Permissions - "
        ssh $OHS_HOST2 "chmod +x /tmp/create_ohs_wallet.sh" >> $LOGDIR/copy_ohs.log 2>&1
        print_status $? $LOGDIR/copy_ohs.log

        printf "\t\t\tCreating Wallet on OHS Server $OHS_HOST2 - "
        ssh $OHS_HOST2 "/tmp/create_ohs_wallet.sh" >> $LOGDIR/copy_ohs.log 2>&1
        print_status $? $LOGDIR/copy_ohs.log

        printf "\t\t\tRestarting Oracle HTTP Server $OHS_HOST2 - "
        ssh $OHS_HOST2 "$OHS_DOMAIN/bin/restartComponent.sh $OHS2_NAME" >> $LOGDIR/copy_ohs.log 2>&1
        print_status $? $LOGDIR/copy_ohs.log
     fi


     ET=`date +%s`
     print_time STEP "Create OHS Wallet" $ST $ET >> $LOGDIR/timings.log
}

# Deploy Coherence
#
deploy_coherence()
{
   print_msg "Deploy Coherence"
   ST=`date +%s`

   printf "\n\t\t\tAdd Coherence Repository - "
   helm repo add coherence https://oracle.github.io/coherence-operator/charts  > $LOGDIR/deploy_coherence.log 2>&1
   print_status $? $LOGDIR/deploy_coherence.log

   printf "\t\t\tUpdate Helm Repository - " 
   helm repo update >> $LOGDIR/deploy_coherence.log 2>&1
   print_status $? $LOGDIR/deploy_coherence.log


   printf "\t\t\tInstall Coherence - "
   helm install -n $OAACONS  coherence-operator coherence/coherence-operator >> $LOGDIR/deploy_coherence.log 2>&1
   print_status $? $LOGDIR/deploy_coherence.log
   
   
   ET=`date +%s`
   print_time STEP "Deploy Coherence" $ST $ET >> $LOGDIR/timings.log
}

# Deploy OAA
#
deploy_oaa()
{

   print_msg "Deploy OAA"
   ST=`date +%s`

   printf "\n\t\t\tUpdate Property File - "
   propfile=$WORKDIR/installOAA.properties

   copy_to_oaa $propfile /u01/oracle/scripts/settings/installOAA.properties $OAANS oaa-mgmt  >> $LOGDIR/create_property.log 2>&1
   print_status $COPYCODE $LOGDIR/create_property.log

   printf "\t\t\tDeploy OAA - "
   oaa_mgmt "/u01/oracle/OAA.sh -f installOAA.properties" > $LOGDIR/deploy_oaa.log 2>&1
   print_status $? $LOGDIR/deploy_oaa.log 2>&1

   ET=`date +%s`
   print_time STEP "Deploy OAA" $ST $ET >> $LOGDIR/timings.log
}

# Deploy OAA Snapshot
#
import_snapshot()
{

   print_msg "Import OAA Snapshot"
   ST=`date +%s`

   printf "\n\t\t\tUpdate Property File - "
   propfile=$WORKDIR/installOAA.properties
   echo "common.deployment.import.snapshot=true" >> $propfile
   echo "common.deployment.import.snapshot.file=/u01/oracle/scripts/oarm-12.2.1.4.1-base-snapshot.zip" >> $propfile
   copy_to_oaa $propfile /u01/oracle/scripts/settings/installOAA.properties $OAANS oaa-mgmt  > $LOGDIR/import_snapshot.log 2>&1
   print_status $COPYCODE $LOGDIR/import_snapshot.log

   printf "\t\t\tImport Snapshot - " 
   oaa_mgmt "/u01/oracle/scripts/importPolicySnapshot.sh -f /u01/oracle/scripts/settings/installOAA.properties " >> $LOGDIR/import_snapshot.log 2>&1

   if [ $? -gt 0 ]
   then
        grep -q "504 Gateway Time-out" $LOGDIR/import_snapshot.log
        if [ $? = 0 ]
        then
          printf "\n\t\t\tTrying again because of Timeout - "
          oaa_mgmt "/u01/oracle/scripts/importPolicySnapshot.sh -f /u01/oracle/scripts/settings/installOAA.properties " >> $LOGDIR/import_snapshot.log 2>&1
          print_status $? $LOGDIR/import_snapshot.log 2>&1
        else
          echo "Failed - Check Logfile $LOGDIR/import_snapshot.log"
          exit 1
        fi
   else
        echo "Success"
   fi
       
   printf "\t\t\tResetting Snapshot Flag in property file - "
   replace_value common.deployment.import.snapshot false $propfile
   copy_to_oaa $propfile /u01/oracle/scripts/settings/installOAA.properties $OAANS oaa-mgmt  >> $LOGDIR/import_snapshot.log 2>&1
   print_status $COPYCODE $LOGDIR/import_snapshot.log

   ET=`date +%s`
   print_time STEP "Import OAA Snapshot" $ST $ET >> $LOGDIR/timings.log
}

# Update OAuth redirect URLS
#
update_urls()
{

   print_msg "Update OAM URLs"
   ST=`date +%s`

   ADMINURL=http://$K8_WORKER_HOST1:$OAM_ADMIN_K8 

   REST_API="'$ADMINURL/oam/services/rest/ssa/api/v1/oauthpolicyadmin/client'"

   USER=`encode_pwd ${OAM_OAMADMIN_USER}:${OAM_OAMADMIN_PWD}`
 
   GET_CURL_COMMAND="curl -s -X GET -u $USER"
   PUT_CURL_COMMAND="curl --location --request  PUT "
   CONTENT_TYPE="-H 'Content-Type: application/json' -H 'Authorization: Basic $USER'"
   PAYLOAD="-d '{\"id\": \"OAAClient\",\"clientType\": \"PUBLIC_CLIENT\", \"idDomain\": \"$OAA_DOMAIN\", \"name\": \"OAAClient\","
   PAYLOAD=$PAYLOAD"\"redirectURIs\": [ { \"url\": \"${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT}/oaa/rui\", \"isHttps\":true }, "
   PAYLOAD=$PAYLOAD"{ \"url\": \"${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT}/oaa/rui/oidc/redirect\", \"isHttps\":true }, "
   PAYLOAD=$PAYLOAD"{ \"url\": \"http://${OAM_ADMIN_LBR_HOST}:${OAM_ADMIN_LBR_PORT}/oaa-admin\", \"isHttps\":false }, "
   PAYLOAD=$PAYLOAD"{ \"url\": \"http://${OAM_ADMIN_LBR_HOST}:${OAM_ADMIN_LBR_PORT}/oaa-admin/oidc/redirect\", \"isHttps\":false }, "
   PAYLOAD=$PAYLOAD"{ \"url\": \"${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT}/fido\", \"isHttps\":true }, "
   PAYLOAD=$PAYLOAD"{ \"url\": \"${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT}/fido/oidc/redirect\", \"isHttps\":true } "
   PAYLOAD=$PAYLOAD" ] }'"

   echo "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" > $LOGDIR/update_urls.log 2>&1
   eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/update_urls.log 2>&1
   grep -q "Sucessfully modified entity"  $LOGDIR/update_urls.log
   print_status $? $LOGDIR/update_urls.log 2>&1

   ET=`date +%s`
   print_time STEP "Update OAM URLs" $ST $ET >> $LOGDIR/timings.log
}
# Delete Schemas
#
delete_schemas()
{
   ST=`date +%s`
   print_msg "Deleting OAA Schemas" 

   cp $TEMPLATE_DIR/delete_schemas.sh $WORKDIR
   filename=$WORKDIR/delete_schemas.sh
   update_variable "<OAA_DB_SYS_PWD>" $OAA_DB_SYS_PWD $filename
   update_variable "<OAA_DB_SCAN>" $OAA_DB_SCAN $filename
   update_variable "<OAA_DB_LISTENER>" $OAA_DB_LISTENER $filename
   update_variable "<OAA_DB_SERVICE>" $OAA_DB_SERVICE $filename
   update_variable "<OAA_RCU_PREFIX>" $OAA_RCU_PREFIX $filename

   copy_to_oaa $filename /tmp/delete_schemas.sh $OAANS oaa-mgmt  
   print_status $COPYCODE 
   
   oaa_mgmt /tmp/delete_schemas.sh 

   ET=`date +%s`
   print_time STEP "Drop OAA Schemas" $ST $ET 
}

# Register OAA as an OAM Partner Application
#
register_tap()
{

   ST=`date +%s`
   print_msg "Creating OAM TAP Partner"
   cp $TEMPLATE_DIR/create_tap_partner.py $WORKDIR

   filename=$WORKDIR/create_tap_partner.py
   update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $filename
   update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $filename
   update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $filename
   update_variable "<OAMNS>" $OAMNS $filename
   update_variable "<OAM_ADMIN_PORT>" $OAM_ADMIN_PORT $filename
   update_variable "<OAA_KEYSTORE_PWD>" $OAA_KEYSTORE_PWD $filename
   update_variable "<OAM_LOGIN_LBR_PROTOCOL>" $OAM_LOGIN_LBR_PROTOCOL $filename
   update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $filename
   update_variable "<OAM_LOGIN_LBR_PORT>" $OAM_LOGIN_LBR_PORT $filename

   copy_to_k8 $filename workdir $OAMNS $OAM_DOMAIN_NAME
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/create_tap_partner.py > $LOGDIR/create_tap_partner.log

   print_status $WLSRETCODE $LOGDIR/create_tap_partner.log

   printf "\t\t\tCopy keystore to $WORKDIR - "
   copy_from_k8 $PV_MOUNT/workdir/OAMOAAKeyStore.jks $WORKDIR/OAMOAAKeyStore.jks $OAMNS $OAM_DOMAIN_NAME
   print_status $RETCODE $LOGDIR/create_tap_partner.log

   ET=`date +%s`
   print_time STEP "Create OAM TAP Partner" $ST $ET >> $LOGDIR/timings.log
}

# Create UMS integration
#
configure_ums()
{

   ST=`date +%s`
   print_msg "Integrating OAA with Email/SMS Client"


   OAA_K8=`get_k8_port oaa $OAANS`
   ADMINURL=$OAM_LOGIN_LBR_PROTOCOL://$OAM_LOGIN_LBR_HOST:$OAM_LOGIN_LBR_PORT

   REST_API="'$ADMINURL/oaa/runtime/config/property/v1'"

   USER=`encode_pwd ${OAA_DEPLOYMENT}-oaa:${OAA_API_PWD}`

   GET_CURL_COMMAND="curl -s -X GET -u $USER"
   POST_CURL_COMMAND="curl --location -k --request  POST "
   PUT_CURL_COMMAND="curl --location -k --request  PUT "
   CONTENT_TYPE="-H 'Content-Type: application/json' -H 'Authorization: Basic $USER'"

   PAYLOAD="-d '[" \
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeEmail.umsClientURL\",\"value\": \"$OAA_EMAIL_SERVER\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeEmail.umsClientName\",\"value\": \"$OAA_EMAIL_USER\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeEmail.umsClientPass\",\"value\": \"$OAA_EMAIL_PWD\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeSMS.umsClientURL\",\"value\": \"$OAA_SMS_SERVER\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeSMS.umsClientName\",\"value\": \"$OAA_SMS_USER\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeSMS.umsClientPass\",\"value\": \"$OAA_SMS_PWD\"}"
   PAYLOAD=$PAYLOAD"  ]'"

   echo "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" > $LOGDIR/configure_ums.log 2>&1
   eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/configure_ums.log 2>&1
   print_status $? $LOGDIR/configure_ums.log


   ET=`date +%s`
   print_time STEP "Create OAA Agent" $ST $ET >> $LOGDIR/timings.log
}

# Create OAA Agent
#
create_oaa_agent()
{

   ST=`date +%s`
   print_msg "Creating OAA Agent"

   OAA_KEY=`xxd -plain -u $WORKDIR/OAMOAAKeyStore.jks | tr -d '\n'`

   ADMINURL=http://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT

   REST_API="'$ADMINURL/oaa-policy/aggregation/v1?detailresponse=true'"

   USER=`encode_pwd ${OAA_DEPLOYMENT}-oaa-policy:${OAA_POLICY_PWD}`

   GET_CURL_COMMAND="curl -s -k -X GET -H 'Authorization: Basic $USER' '$ADMINURL/oaa-policy/agent/v1/?agentName=OAM-OAA-TAP' "
   POST_CURL_COMMAND="curl --location -k --request  POST "
   PUT_CURL_COMMAND="curl --location -k --request  PUT "
   CONTENT_TYPE="-H 'Content-Type: application/json' -H 'Authorization: Basic $USER'"

   PAYLOAD="-d '{\"agentname\" : \"OAM-OAA-TAP\","
   PAYLOAD=$PAYLOAD"\"type\" : \"oam\","
   PAYLOAD=$PAYLOAD" \"actions\" : [\"ChallengeEmail\" , \"ChallengeSMS\" , \"ChallengeOMATOTP\"]"
   PAYLOAD=$PAYLOAD"  }'"

   echo "$POST_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" > $LOGDIR/create_oaa_agent.log 2>&1
   eval "$POST_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/create_oaa_agent.log 2>&1

   sleep 10
   echo "$GET_CURL_COMMAND | jq -r .agents[].agentgid" >> $LOGDIR/create_oaa_agent.log 2>&1
   XX="$GET_CURL_COMMAND | jq -r .agents[].agentgid"
   AGENTID=`eval $XX`

   if [ "$AGENTID" = "" ]
   then
        echo "Failed - Check Logfile $LOGDIR/create_oaa_agent.log"
        exit 1
   fi

   REST_API="'$ADMINURL/oaa-policy/agent/v1/$AGENTID'"
   PAYLOAD1="-d '{\"description\" : \"OAM TAP Agent\","
   PAYLOAD1=$PAYLOAD1"\"privateKey\": \"$OAA_KEY\","
   PAYLOAD1=$PAYLOAD1"\"privateKeyFile\": \"OAMOAAKeyStore.jks\","
   PAYLOAD1=$PAYLOAD1"\"privateKeyPassword\": \"$OAA_KEYSTORE_PWD\""
   PAYLOAD1=$PAYLOAD1"  }'"

   echo "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD1" > $LOGDIR/update_agent.log 2>&1
   eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD1" >> $LOGDIR/update_agent.log 2>&1

   grep -q clientId $LOGDIR/update_agent.log
   print_status $? $LOGDIR/update_agent.log

   ET=`date +%s`
   print_time STEP "Create OAA Agent" $ST $ET >> $LOGDIR/timings.log
}
   
# Obtain OAA Plugin
#
copy_plugin()
{

   ST=`date +%s`
   print_msg "Obtaining OAA Plugin"

   copy_from_oaa /u01/oracle/libs/OAAAuthnPlugin.jar  $WORKDIR/OAAAuthnPlugin.jar $OAANS oaa-mgmt > $LOGDIR/copy_plugin.log 2>&1
   if [ ! -f $WORKDIR/OAAAuthnPlugin.jar ]
   then
       print_status 1 $LOGDIR/copy_plugin.log
   else
       echo "Success"
   fi
   printf "\t\t\tCopy Plugin to OAM - "
   copy_to_k8 $WORKDIR/OAAAuthnPlugin.jar workdir $OAMNS $OAM_DOMAIN_NAME >> $LOGDIR/copy_plugin.log 2>&1
   print_status $? $LOGDIR/copy_plugin.log

   ET=`date +%s`
   print_time STEP "Obtain OAA Plugin" $ST $ET >> $LOGDIR/timings.log
}

# Install OAA Plugin
#
install_plugin()
{

   ST=`date +%s`
   print_msg "Installing OAA Plugin"

   ENCUSER=`encode_pwd $LDAP_OAMADMIN_USER:$LDAP_USER_PWD`
   USER_HEADER="-H 'Authorization: Basic $ENCUSER'"
   GET_OAMCONFIG="curl -x '' -X GET http://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT/iam/admin/config/api/v1/config -ikL -H 'Content-Type: application/xml'  $USER_HEADER -H 'cache-control: no-cache'"

   echo  $GET_OAMCONFIG > $LOGDIR/install_plugin.log
   eval $GET_OAMCONFIG > $WORKDIR/oam-config.xml 2>$LOGDIR/oam_config.log

   grep -q "Configuration Configuration.xsd" $WORKDIR/oam-config.xml
   if [ $? = 1 ]
   then
       cat $WORKDIR/oam-config.xml >> $LOGDIR/install_plugin.log
       echo "Failed to Obtain oam-config.xml - See $LOGDIR/install_plugin.log"
       exit 1
   fi

   grep -q OAAAuthnPlugin $WORKDIR/oam-config.xml
   if [ $? = 0 ]
   then
       echo "Already Installed"
   else
       cp $TEMPLATE_DIR/install_plugin.py $WORKDIR

       filename=$WORKDIR/install_plugin.py
       update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $filename
       update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $filename
       update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $filename
       update_variable "<OAMNS>" $OAMNS $filename
       update_variable "<OAM_ADMIN_PORT>" $OAM_ADMIN_PORT $filename
    
       copy_to_k8 $filename workdir $OAMNS $OAM_DOMAIN_NAME
       run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/install_plugin.py > $LOGDIR/install_plugin.log

       print_status $WLSRETCODE $LOGDIR/install_plugin.log

   fi
   ET=`date +%s`
   print_time STEP "Install OAA Plugin" $ST $ET >> $LOGDIR/timings.log
}

# Create OAM Authentication Module
#
create_auth_module()
{

   ST=`date +%s`
   print_msg "Creating OAM Authentication Module"

   cp $TEMPLATE_DIR/create_auth_module.xml $WORKDIR

   filename=$WORKDIR/create_auth_module.xml
   update_variable "<OAM_LOGIN_LBR_PROTOCOL>" $OAM_LOGIN_LBR_PROTOCOL $filename
   update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $filename
   update_variable "<OAM_LOGIN_LBR_PORT>" $OAM_LOGIN_LBR_PORT $filename

   ADMINURL=http://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT

   USER=`encode_pwd ${OAA_DEPLOYMENT}-oaa-policy:${OAA_POLICY_PWD}`

   AGENT_CURL_COMMAND="curl -s -k -X GET -H 'Authorization: Basic $USER' '$ADMINURL/oaa-policy/agent/v1/?agentName=OAM-OAA-TAP' "

   echo "$AGENT_CURL_COMMAND | jq -r .agents[].clientId" > $LOGDIR/create_auth_module.log
   AGENT_DETAILS=`eval "$AGENT_CURL_COMMAND"`
   
   CLIENTID=`echo $AGENT_DETAILS | jq -r .agents[].clientId`
   echo ClientID: $CLIENTID >> $LOGDIR/create_auth_module.log

   CLIENTSECRET=`echo $AGENT_DETAILS | jq -r .agents[].clientSecret`
   echo ClientSecret: $CLIENTSECRET >> $LOGDIR/create_auth_module.log

   AGENTID=`echo $AGENT_DETAILS | jq -r .agents[].agentgid`
   echo AgentID: $AGENTID >> $LOGDIR/create_auth_module.log

   ASS_CURL_COMMAND="curl -s -k -X GET -H 'Authorization: Basic $USER' '$ADMINURL/oaa-policy/assuranceLevel/v1?agentid=$AGENTID' "

   ASSURANCE=`eval "$ASS_CURL_COMMAND " | jq -r '.assuranceLevels[].id'`
   echo AssuranceID : $ASSURANCE >> $LOGDIR/create_auth_module.log

   update_variable "<CLIENT_ID>" $CLIENTID $filename
   update_variable "<CLIENT_SECRET>" $CLIENTSECRET $filename
   update_variable "<ASSURANCE_LEVEL>" $ASSURANCE $filename

   ADMIN_URL=http://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT/iam/admin/config/api/v1/config?path=/DeployedComponent/Server/NGAMServer/Profile/AuthenticationModules/CompositeModules

   USER=`encode_pwd $LDAP_OAMADMIN_USER:$LDAP_USER_PWD`

   CURLCMD="curl -s --fail -H 'Authorization: Basic $USER' -H 'Content-Type: text/xml' -X PUT '$ADMIN_URL' -d @$filename" 
   echo $CURLCMD >> $LOGDIR/create_auth_module.log
   printf "\n Cmd Output :\n">> $LOGDIR/create_auth_module.log

   eval $CURLCMD >> $LOGDIR/create_auth_module.log 2>&1

    print_status $? $LOGDIR/create_auth_module.log

   ET=`date +%s`
   print_time STEP "Create Authentication Module in OAM" $ST $ET >> $LOGDIR/timings.log
}


# Create OAM Authentication Scheme
#
create_auth_scheme()
{

   ST=`date +%s`
   print_msg "Creating OAM Authentication Scheme"

   ADMIN_URL=http://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT/oam/services/rest/11.1.2.0.0/ssa/policyadmin/authnscheme

   USER=`encode_pwd $LDAP_OAMADMIN_USER:$LDAP_USER_PWD`

   CURLCMD="curl --fail -H 'Authorization: Basic $USER' -H 'Content-Type: application/xml' -X POST '$ADMIN_URL' -d @$TEMPLATE_DIR/create_auth_scheme.xml"
   CURLCMD1="curl -s -H 'Authorization: Basic $USER' -H 'Content-Type: application/xml' -X POST '$ADMIN_URL' -d @$TEMPLATE_DIR/create_auth_scheme.xml"
   echo $CURLCMD1 > $LOGDIR/create_auth_scheme.log
   printf "\n Cmd Output :\n">> $LOGDIR/create_auth_scheme.log

   eval $CURLCMD >> $LOGDIR/create_auth_scheme.log 2>&1

   if [ $? -gt 0 ]
   then
        eval $CURLCMD1 >> $LOGDIR/create_auth_scheme.log 2>&1
        grep -q "already exists" $LOGDIR/create_auth_scheme.log
        if [ $? = 0 ]
        then
           echo "Already Exists"
        else
           echo "Failed - see logfile $LOGDIR/create_auth_scheme.log"
           exit 1
        fi
    else
        echo "Success"
    fi

   ET=`date +%s`
   print_time STEP "Create Authentication Scheme in OAM" $ST $ET >> $LOGDIR/timings.log
}

# Delete OAM Authentication Scheme
#
delete_auth_scheme()
{

   LOG=$1

   DELETE_URL="http://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT/oam/services/rest/11.1.2.0.0/ssa/policyadmin/authnscheme?name=OAA-MFA-Scheme"

   USER=`encode_pwd $LDAP_OAMADMIN_USER:$LDAP_USER_PWD`

   CURLCMD="curl --fail -H 'Authorization: Basic $USER' -X DELETE '$DELETE_URL'"
   CURLCMD1="curl -s -H 'Authorization: Basic $USER' DELETE '$DELETE_URL' "
   echo $CURLCMD1 >> $LOG
   printf "\n Cmd Output :\n">> $LOG

   eval $CURLCMD >> $LOG 2>&1


}
# Create OAM Authentication Policy
#
create_auth_policy()
{

   ST=`date +%s`
   print_msg "Creating OAM Authentication Policy"

   ADMIN_URL="http://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT/oam/services/rest/11.1.2.0.0/ssa/policyadmin/authnpolicy"

   USER=`encode_pwd $LDAP_OAMADMIN_USER:$LDAP_USER_PWD`

   
   CURLCMD="curl --fail -H 'Authorization: Basic $USER' -H 'Content-Type: application/json' -X POST '$ADMIN_URL' -d @$TEMPLATE_DIR/create_auth_policy.json" 
   CURLCMD1="curl -s -H 'Authorization: Basic $USER' -H 'Content-Type: application/json' -X POST '$ADMIN_URL' -d @$TEMPLATE_DIR/create_auth_policy.json" 

   echo $CURLCMD1 > $LOGDIR/create_auth_policy.log
   printf "\nCmd Output :\n">> $LOGDIR/create_auth_policy.log

   eval $CURLCMD >> $LOGDIR/create_auth_policy.log 2>&1
   if [ $? -gt 0 ]
   then
        eval $CURLCMD1 >> $LOGDIR/create_auth_policy.log 2>&1
        grep -q "already exists" $LOGDIR/create_auth_policy.log
        if [ $? = 0 ]
        then
           echo "Already Exists"
        else
           echo "Failed - see logfile $LOGDIR/create_auth_policy.log"
           exit 1
        fi
    else
        echo "Success"
    fi

   ET=`date +%s`
   print_time STEP "Create Authentication Policy in OAM" $ST $ET >> $LOGDIR/timings.log
}

# Delete OAM Authentication Policy
#
delete_auth_policy()
{

   LOG=$1

   DELETE_URL="http://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT/oam/services/rest/11.1.2.0.0/ssa/policyadmin/authnpolicy?appdomain=IAM Suite&name=OAA_MFA-Policy"
   USER=`encode_pwd $LDAP_OAMADMIN_USER:$LDAP_USER_PWD`

   
   CURLCMD="curl --fail -H 'Authorization: Basic $USER' -H 'Content-Type: application/json' -X DELETE '$DELETE_URL' " 
   CURLCMD1="curl -s -H 'Authorization: Basic $USER' -H 'Content-Type: application/json' -X DELETE '$DELETE_URL' " 

   echo $CURLCMD1 >> $LOG 
   printf "\nCmd Output :\n">> $LOG 

   eval $CURLCMD >> $LOG 2>&1
   if [ $? -gt 0 ]
   then
      eval $CURLCMD1 >> $LOG 2>&1
   fi

}
# Create OAA Test User
#

create_test_user()
{

     DIR_TYPE=$1

     ST=`date +%s`
     print_msg "Create Test User $OAA_USER in LDAP"

     cp $TEMPLATE_DIR/test_user.ldif $WORKDIR
     filename=$WORKDIR/test_user.ldif

     update_variable "<OAA_USER>" $OAA_USER $filename
     update_variable "<OAA_USER_PWD>" $OAA_USER_PWD $filename
     update_variable "<OAA_USER_EMAIL>" $OAA_USER_EMAIL $filename
     update_variable "<OAA_USER_POSTCODE>" $OAA_USER_POSTCODE $filename
     update_variable "<LDAP_USER_SEARCHBASE>" $LDAP_USER_SEARCHBASE $filename
     update_variable "<LDAP_GROUP_SEARCHBASE>" $LDAP_GROUP_SEARCHBASE $filename
     update_variable "<LDAP_SEARCHBASE>" $LDAP_SEARCHBASE $filename
     update_variable "<OAA_USER_GROUP>" $OAA_USER_GROUP $filename


     if [ "$DIR_TYPE" = "oud" ]
     then
         cp $TEMPLATE_DIR/oud_test_user.sh $WORKDIR
         shfile=$WORKDIR/oud_test_user.sh
         update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $shfile
         update_variable "<OUDNS>" $OUDNS $shfile
         update_variable "<LDAP_ADMIN_USER>" $LDAP_ADMIN_USER $shfile
         update_variable "<LDAP_ADMIN_PWD>" $LDAP_ADMIN_PWD $shfile

         kubectl cp $filename $OUDNS/$OUD_POD_PREFIX-oud-ds-rs-0:/u01/oracle/config-input  > $LOGDIR/create_test_user.log 2>&1
         kubectl cp $shfile $OUDNS/$OUD_POD_PREFIX-oud-ds-rs-0:/u01/oracle/config-input  >> $LOGDIR/create_test_user.log 2>&1
         kubectl exec -ti -n $OUDNS $OUD_POD_PREFIX-oud-ds-rs-0  -c oud-ds-rs -- /u01/oracle/config-input/oud_test_user.sh >> $LOGDIR/create_test_user.log 2>&1
     fi

     if [ $? -gt 0 ]
     then
           grep -q exists $LOGDIR/create_test_user.log
           if [ $? = 0 ]
           then 
              printf "Already exists\n"
           else
             print_status 1 $LOGDIR/create_test_user.log
           fi
     else
       printf " Success\n"
     fi

     ET=`date +%s`
     print_time STEP "Create Test User $OAA_USER in LDAP" $ST $ET >> $LOGDIR/timings.log
}
