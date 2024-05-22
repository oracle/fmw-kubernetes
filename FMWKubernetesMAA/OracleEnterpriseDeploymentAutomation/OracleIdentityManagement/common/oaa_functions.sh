#!/bin/bash
# Copyright (c) 2022, 2024, Oracle and/or its affiliates.
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
   ST=$(date +%s)

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

   fi

   ET=$(date +%s)
   print_time STEP "Create OAA Management container" $ST $ET >> $LOGDIR/timings.log
}

copy_settings_file()
{
   print_msg "Copying Template OAA Propery file"
   ST=$(date +%s)

   kubectl exec -it -n $OAANS oaa-mgmt -- cp /u01/oracle/installsettings/installOAA.properties /u01/oracle/scripts/settings/ >> $LOGDIR/create_mgmt.log
   print_status $? $LOGDIR/create_mgmt.log
   ET=$(date +%s)
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
   ST=$(date +%s)

   kubectl cp  $OAANS/oaa-mgmt:/u01/oracle/installsettings/installOAA.properties $WORKDIR/installOAA.properties > $LOGDIR/create_property.log 2>&1
   cp $TEMPLATE_DIR/oaaoverride.yaml $WORKDIR/oaaoverride.yaml > $LOGDIR/create_property.log 2>&1
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
   #replace_value database.name $OAA_DB_SID $propfile
   replace_value database.name "" $propfile
   replace_value database.createschema true $propfile
   replace_value common.deployment.name $OAA_DEPLOYMENT $propfile
   replace_value oauth.applicationid $OAA_DEPLOYMENT $propfile
   replace_value common.kube.namespace $OAANS $propfile
   replace_value common.deployment.keystorepassphrase $OAA_KEYSTORE_PWD $propfile
   replace_value common.deployment.truststorepassphrase $OAA_KEYSTORE_PWD $propfile

   if [ "$INSTALL_OAA" = "true" ] && [ "$INSTALL_OUA" = "true" ] && [ "$INSTALL_RISK" = "true" ]
   then
     replace_value common.deployment.mode OUA $propfile
     replace_value install.global.drssapikey $OAA_API_PWD $propfile
   elif [ "$INSTALL_OAA" = "true" ] && [ "$INSTALL_RISK" = "true" ]
   then   
     replace_value common.deployment.mode Both $propfile 
   elif  [ "$INSTALL_OAA" = "true" ]
   then
     replace_value common.deployment.mode OAA $propfile    
   fi
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
       replace_value install.customfactor.service.type NodePort $propfile
       replace_value install.oaa-drss.service.type NodePort $propfile
       
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
       replace_value install.customfactor.service.type ClusterIP $propfile
       replace_value install.oaa-drss.service.type ClusterIP $propfile     
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
   sed -i "/risk:/{n;s/replicaCount.*/replicaCount: $OAA_RISK_REPLICAS/}"  $override   
   sed -i "/risk-cc:/{n;s/replicaCount.*/replicaCount: $OAA_RISKCC_REPLICAS/}"  $override      
   sed -i "/oaa-drss:/{n;s/replicaCount.*/replicaCount: $OAA_DRSS_REPLICAS/}"  $override  
   sed -i "/oaa-kba:/{n;s/replicaCount.*/replicaCount: $OAA_KBA_REPLICAS/}"  $override
   sed -i "/^replicaCount:/a\resources:\n  requests:\n    cpu: $OAA_OAA_CPU\n    memory: \"$OAA_OAA_MEMORY\""   $override
   sed -i "/spui:/a\  resources:\n    requests:\n      cpu: $OAA_SPUI_CPU\n      memory: \"$OAA_SPUI_MEMORY\""   $override
   sed -i "/totp:/a\  resources:\n    requests:\n      cpu: $OAA_TOTP_CPU\n      memory: \"$OAA_TOTP_MEMORY\""   $override
   sed -i "/yotp:/a\  resources:\n    requests:\n      cpu: $OAA_YOTP_CPU\n      memory: \"$OAA_YOTP_MEMORY\""   $override
   sed -i "/fido:/a\  resources:\n    requests:\n      cpu: $OAA_FIDO_CPU\n      memory: \"$OAA_FIDO_MEMORY\""   $override
   sed -i "/email:/a\  resources:\n    requests:\n      cpu: $OAA_EMAIL_CPU\n      memory: \"$OAA_EMAIL_MEMORY\""   $override
   sed -i "/push:/a\  resources:\n    requests:\n      cpu: $OAA_PUSH_CPU\n      memory: \"$OAA_PUSH_MEMORY\""   $override
   sed -i "/sms:/a\  resources:\n    requests:\n      cpu: $OAA_SMS_CPU\n      memory: \"$OAA_SMS_MEMORY\""   $override
   sed -i "/oaa-kba:/a\  resources:\n    requests:\n      cpu: $OAA_KBA_CPU\n      memory: \"$OAA_KBA_MEMORY\""   $override
   sed -i "/oaa-policy:/a\  resources:\n    requests:\n      cpu: $OAA_POLICY_CPU\n      memory: \"$OAA_POLICY_MEMORY\""   $override
   sed -i "/customfactor:/a\  resources:\n    requests:\n      cpu: $OAA_CUSTOM_CPU\n      memory: \"$OAA_CUSTOM_MEMORY\""   $override
   sed -i "/risk:/a\  resources:\n    requests:\n      cpu: $OAA_RISK_CPU\n      memory: \"$OAA_RISK_MEMORY\""   $override
   sed -i "/risk-cc:/a\  resources:\n    requests:\n      cpu: $OAA_RISKCC_CPU\n      memory: \"$OAA_RISKCC_MEMORY\""   $override
   sed -i "/oaa-admin-ui:/a\  resources:\n    requests:\n      cpu: $OAA_ADMIN_CPU\n      memory: \"$OAA_ADMIN_MEMORY\""   $override
   sed -i "/oaa-drss:/a\  resources:\n    requests:\n      cpu: $OAA_DRSS_CPU\n      memory: \"$OAA_DRSS_MEMORY\""   $override


   copy_to_oaa $propfile /u01/oracle/scripts/settings/installOAA.properties $OAANS oaa-mgmt  >> $LOGDIR/create_property.log 2>&1
   copy_to_oaa $override /u01/oracle/scripts/settings/oaaoverride.yaml $OAANS oaa-mgmt  >> $LOGDIR/create_property.log 2>&1
   print_status $COPYCODE $LOGDIR/create_property.log

   ET=$(date +%s)
   print_time STEP "Create property_file" $ST $ET >> $LOGDIR/timings.log

}


# Create RBAC for OCI
#
create_rbac()
{
   print_msg "Create OAA Service Account"
   ST=$(date +%s)

   filename=oaa_svc_acct_ingress.yaml

   cp $TEMPLATE_DIR/$filename $WORKDIR
   update_variable "<OAANS>" $OAANS $WORKDIR/$filename

   kubectl apply -f $WORKDIR/$filename > $LOGDIR/create_rbac.log 2>&1
   print_status $? $LOGDIR/create_rbac.log

   KVER=$(get_k8_ver)
   KVER=${KVER:0:4}
   if [ $KVER > "1.23" ]
   then
     printf "\t\t\tCreating Service Account Secret - "
     cp $TEMPLATE_DIR/create_svc_secret.yaml $WORKDIR
     update_variable "<OAANS>" $OAANS $WORKDIR/create_svc_secret.yaml
     kubectl apply -f $WORKDIR/create_svc_secret.yaml >> $LOGDIR/create_rbac.log 2>&1
     print_status $? $LOGDIR/create_rbac.log
     TOKENNAME=oaa-service-account
   else
     echo "old ver"
     TOKENNAME=`kubectl -n $OAANS get serviceaccount/oaa-service-account -o jsonpath='{.secrets[0].name}'`
   fi

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

   ET=$(date +%s)
   print_time STEP "Create oaa-mgmt kubeconfig" $ST $ET >> $LOGDIR/timings.log
}

# Validate the kubectl command in the oiri-cli container
#
validate_oaamgmt()
{
   print_msg "Checking kubectl"
   ST=$(date +%s)
   oaa_mgmt "kubectl get pods -n $OAANS" > $LOGDIR/check_kubectl.log 2>&1
   grep -q "NAME" $LOGDIR/check_kubectl.log
   print_status $?  $LOGDIR/check_kubectl.log
   ET=$(date +%s)
   print_time STEP "Validate kubectl" $ST $ET >> $LOGDIR/timings.log
}

# Create a Helm Configuration File
#
create_helm_file()
{
   print_msg "Creating Helm Configuration File"
   ST=$(date +%s)
   copy_to_oaa $TEMPLATE_DIR/helmconfig /u01/oracle/scripts/creds $OAANS oaa-mgmt  >> $LOGDIR/create_helm_file.log 2>&1
   print_status $COPYCODE  $LOGDIR/create_helm_file.log
   ET=$(date +%s)
   print_time STEP "Create Helm Config File" $ST $ET >> $LOGDIR/timings.log
}

#
# Create OAA Server certificates
create_server_certs()
{
   print_msg "Creating Server Certificates"
   ST=$(date +%s)

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
   ET=$(date +%s)
   print_time STEP "Create Server Certs" $ST $ET >> $LOGDIR/timings.log
}

 
# Create LDAP Users and Groups
#

create_ldap_entries()
{

     DIR_TYPE=$1

     ST=$(date +%s)
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
       update_variable "<LDAP_HOST>" ${LDAP_EXTERNAL_HOST:=$OUD_POD_PREFIX-oud-ds-rs-lbr-ldap.$OUDNS.svc.cluster.local} $shfile
       update_variable "<LDAP_PORT>" ${LDAP_EXTERNAL_PORT:=1389} $shfile
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

     ET=$(date +%s)
     print_time STEP "Create Users and Groups" $ST $ET >> $LOGDIR/timings.log
}

# Update Enable OAM OAuth
#
enable_oauth()
{
     ADMINURL=$1
     USER=$2

     ST=$(date +%s)
     print_msg "Enabling OAM OAuth"

     cp $TEMPLATE_DIR/enable_oauth.xml  $WORKDIR/enable_oauth.xml

     curl -s -x '' -X PUT $ADMINURL/iam/admin/config/api/v1/config -ikL -H 'Content-Type: application/xml' --user $USER -H 'cache-control: no-cache' -d @$WORKDIR/enable_oauth.xml > $LOGDIR/enable_oauth.log 2>&1
     
     print_status $? $LOGDIR/enable_oauth.log
     ET=$(date +%s)
     print_time STEP "Enable OAM OAuth " $ST $ET >> $LOGDIR/timings.log
}

# Validate OAuth
#
validate_oauth()
{

     ST=$(date +%s)
     print_msg "Validating OAM OAuth"

     cp $TEMPLATE_DIR/enable_oauth.xml  $WORKDIR/enable_oauth.xml

     AUTHZHEADER=`encode_pwd OAAClient:${OAA_OAUTH_PWD}`

     echo "Validating OAuth using the command:" > $LOGDIR/validate_oauth.log
     echo curl -s -k --location --request GET ${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT}/oauth2/rest/token  >> $LOGDIR/validate_oauth.log

     curl -s -k --location --request GET ${OAM_LOGIN_LBR_PROTOCOL}://${OAM_LOGIN_LBR_HOST}:${OAM_LOGIN_LBR_PORT}/oauth2/rest/token  >> $LOGDIR/validate_oauth.log
     grep -q "Method Not Allowed" $LOGDIR/validate_oauth.log

     print_status $? $LOGDIR/validate_oauth.log
     ET=$(date +%s)
     print_time STEP "Validate OAuth" $ST $ET >> $LOGDIR/timings.log
}

# 
# Add all existing users in LDAP in User Search base to OAA_USER_GROUP
#
add_existing_users()
{

     DIR_TYPE=$1

     ST=$(date +%s)
     print_msg "Add existing users to $OAA_USER_GROUP"

     if [ "$DIR_TYPE" = "oud" ]
     then
       cp $TEMPLATE_DIR/oud_add_existing_users.sh $WORKDIR
       shfile=$WORKDIR/oud_add_existing_users.sh
       update_variable "<LDAP_HOST>" ${LDAP_EXTERNAL_HOST:=$OUD_POD_PREFIX-oud-ds-rs-lbr-ldap.$OUDNS.svc.cluster.local} $shfile
       update_variable "<LDAP_PORT>" ${LDAP_EXTERNAL_PORT:=1389} $shfile
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

     ET=$(date +%s)
     print_time STEP "Add Existing Users to OAA Group" $ST $ET >> $LOGDIR/timings.log
}


add_ohs_rewrite_rules()
{

     ST=$(date +%s)
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
     ET=$(date +%s)
     print_time STEP "Add OHS Rewrite Rules" $ST $ET >> $LOGDIR/timings.log
}

create_ohs_entries()
{

     ST=$(date +%s)
     print_msg "Add OHS Directives"
     print_status $? 
     
     cp $TEMPLATE_DIR/create_ohs_wallet.sh $WORKDIR

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
         OAA_DRSS_K8=`get_k8_port oaa-drs $OAANS`
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
         OAA_DRSS_K8=$INGRESS_HTTP_PORT
      fi


     OHSHOST1FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST1
     OHSHOST2FILES=$LOCAL_WORKDIR/OHS/$OHS_HOST2

     NODELIST=$(kubectl get nodes --no-headers=true  | cut -f1 -d ' ')
     create_location $TEMPLATE_DIR/locations.txt "$NODELIST" $OHSHOST1FILES
     print_status $?      

     if [ ! "$OHS_HOST2" = "" ]
     then
         create_location $TEMPLATE_DIR/locations.txt "$NODELIST" $OHSHOST2FILES
         print_status $? 
     fi

     update_variable "<OHS_ORACLE_HOME>" $OHS_ORACLE_HOME $WORKDIR/create_ohs_wallet.sh
     update_variable "<OHS_DOMAIN>" $OHS_DOMAIN $WORKDIR/create_ohs_wallet.sh
     update_variable "<K8_WORKER_HOST1>" $K8_WORKER_HOST1 $WORKDIR/create_ohs_wallet.sh
     update_variable "<OAA_K8>" $OAA_K8  $WORKDIR/create_ohs_wallet.sh

     ET=$(date +%s)
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
     $SSH $OHS_HOST1 "chmod +x /tmp/create_ohs_wallet.sh" >> $LOGDIR/copy_ohs.log 2>&1
     print_status $? $LOGDIR/copy_ohs.log

     printf "\t\t\tCreating Wallet on OHS Server $OHS_HOST1 - "
     $SSH $OHS_HOST1 "/tmp/create_ohs_wallet.sh" >> $LOGDIR/copy_ohs.log 2>&1
     print_status $? $LOGDIR/copy_ohs.log

     printf "\t\t\tRestarting Oracle HTTP Server $OHS_HOST1 - "
     $SSH $OHS_HOST1 "$OHS_DOMAIN/bin/restartComponent.sh $OHS1_NAME" >> $LOGDIR/copy_ohs.log 2>&1
     print_status $? $LOGDIR/copy_ohs.log

     if [ ! "$OHS_HOST2" = "" ]
     then
        printf "\n\t\t\tCopy Script to OHS Server $OHS_HOST2 - "

        $SCP $WORKDIR/create_ohs_wallet.sh  $OHS_HOST2:/tmp >> $LOGDIR/create_wallet.log 2>&1
        print_status $? $LOGDIR/create_wallet.log

        printf "\t\t\tChanging Permissions - "
        $SSH $OHS_HOST2 "chmod +x /tmp/create_ohs_wallet.sh" >> $LOGDIR/copy_ohs.log 2>&1
        print_status $? $LOGDIR/copy_ohs.log

        printf "\t\t\tCreating Wallet on OHS Server $OHS_HOST2 - "
        $SSH $OHS_HOST2 "/tmp/create_ohs_wallet.sh" >> $LOGDIR/copy_ohs.log 2>&1
        print_status $? $LOGDIR/copy_ohs.log

        printf "\t\t\tRestarting Oracle HTTP Server $OHS_HOST2 - "
        $SSH $OHS_HOST2 "$OHS_DOMAIN/bin/restartComponent.sh $OHS2_NAME" >> $LOGDIR/copy_ohs.log 2>&1
        print_status $? $LOGDIR/copy_ohs.log
     fi


     ET=$(date +%s)
     print_time STEP "Create OHS Wallet" $ST $ET >> $LOGDIR/timings.log
}


# Deploy OAA
#
deploy_oaa()
{

   print_msg "Deploy OAA"
   ST=$(date +%s)

   printf "\n\t\t\tUpdate Property File - "
   propfile=$WORKDIR/installOAA.properties

   copy_to_oaa $propfile /u01/oracle/scripts/settings/installOAA.properties $OAANS oaa-mgmt  >> $LOGDIR/create_property.log 2>&1
   print_status $COPYCODE $LOGDIR/create_property.log

   printf "\t\t\tDeploy OAA - "
   oaa_mgmt "/u01/oracle/OAA.sh -f installOAA.properties" > $LOGDIR/deploy_oaa.log 2>&1
   if [ $? -gt 0 ]
   then
      grep -q "OAUTH validation failed" $LOGDIR/deploy_oaa.log
      if [ $? = 0 ]

      then
         echo "Executing command /u01/oracle/scripts/validateOauthForOAA.sh -f /u01/oracle/scripts/settings/installOAA.properties -d true to get more information." >> $LOGDIR/deploy_oaa.log
         oaa_mgmt "/u01/oracle/scripts/validateOauthForOAA.sh -f /u01/oracle/scripts/settings/installOAA.properties -d true" >> $LOGDIR/deploy_oaa.log 2>&1
      fi
      echo "Failed - See Logfile $LOGDIR/deploy_oaa.log"
      exit 1
   else
      echo "Success."
   fi

   ET=$(date +%s)
   print_time STEP "Deploy OAA" $ST $ET >> $LOGDIR/timings.log
}

# Deploy OAA on DR
#
deploy_oaa_dr()
{

   print_msg "Deploy OAA"
   ST=$(date +%s)

   oaa_mgmt "/u01/oracle/OAA.sh -f installOAA.properties" > $LOGDIR/deploy_oaa.log 2>&1
   if [ $? -gt 0 ]
   then
      grep -q "OAUTH validation failed" $LOGDIR/deploy_oaa.log
      if [ $? = 0 ]

      then
         echo "Executing command /u01/oracle/scripts/validateOauthForOAA.sh -f /u01/oracle/scripts/settings/installOAA.properties -d true to get more information." >> $LOGDIR/deploy_oaa.log
         oaa_mgmt "/u01/oracle/scripts/validateOauthForOAA.sh -f /u01/oracle/scripts/settings/installOAA.properties -d true" >> $LOGDIR/deploy_oaa.log 2>&1
      fi
      echo "Failed - See Logfile $LOGDIR/deploy_oaa.log"
      exit 1
   else
      echo "Success."
   fi

   ET=$(date +%s)
   print_time STEP "Deploy OAA" $ST $ET >> $LOGDIR/timings.log
}
# Deploy OAA Snapshot
#
import_snapshot()
{

   print_msg "Import OAA Snapshot"
   ST=$(date +%s)

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

   ET=$(date +%s)
   print_time STEP "Import OAA Snapshot" $ST $ET >> $LOGDIR/timings.log
}

# Update OAuth redirect URLS
#
update_urls()
{

   print_msg "Update OAM URLs"
   ST=$(date +%s)

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

   ET=$(date +%s)
   print_time STEP "Update OAM URLs" $ST $ET >> $LOGDIR/timings.log
}
# Delete Schemas
#
delete_schemas()
{
   ST=$(date +%s)
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

   ET=$(date +%s)
   print_time STEP "Drop OAA Schemas" $ST $ET 
}

# Register OAA as an OAM Partner Application
#
register_tap()
{

   ST=$(date +%s)
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

   ET=$(date +%s)
   print_time STEP "Create OAM TAP Partner" $ST $ET >> $LOGDIR/timings.log
}


# Create UMS integration
#
configure_ums()
{

   ST=$(date +%s)
   print_msg "Integrating OAA with Email/SMS Client"


   OAA_K8=`get_k8_port oaa $OAANS`
   ADMINURL=$OAM_LOGIN_LBR_PROTOCOL://$OAM_LOGIN_LBR_HOST:$OAM_LOGIN_LBR_PORT

   REST_API="'$ADMINURL/oaa/runtime/config/property/v1'"

   USER=`encode_pwd ${OAA_DEPLOYMENT}-oaa:${OAA_API_PWD}`

   GET_CURL_COMMAND="curl -s -X GET -u $USER"
   POST_CURL_COMMAND="curl --location -k --request  POST "
   PUT_CURL_COMMAND="curl --fail --location -k --request  PUT "
   PUT_CURL_COMMAND1="curl --location -k --request  PUT "
   CONTENT_TYPE="-H 'Content-Type: application/json' -H 'Authorization: Basic $USER'"

   PAYLOAD="-d '[" \
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeEmail.umsClientURL\",\"value\": \"$OAA_EMAIL_SERVER\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeEmail.umsClientName\",\"value\": \"$OAA_EMAIL_USER\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeEmail.umsClientPass\",\"value\": \"$OAA_EMAIL_PWD\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeSMS.umsClientURL\",\"value\": \"$OAA_SMS_SERVER\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeSMS.umsClientName\",\"value\": \"$OAA_SMS_USER\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"bharosa.uio.default.challenge.type.enum.ChallengeSMS.umsClientPass\",\"value\": \"$OAA_SMS_PWD\"}",
   PAYLOAD=$PAYLOAD"{ \"name\": \"oaa.default.spui.pref.runtime.autoCreateUser\",\"value\": \"true\"}"
   PAYLOAD=$PAYLOAD"  ]'"

   echo "$PUT_CURL_COMMAND1 $REST_API $CONTENT_TYPE $PAYLOAD" > $LOGDIR/configure_ums.log 2>&1
   eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/configure_ums.log 2>&1
   if [ $? -gt 0 ]
   then
        eval $PUT_CURL_COMMAND1 >> $LOGDIR/configure_ums.log 2>&1
        grep -q "already exists" $LOGDIR/configure_ums.log
        if [ $? = 0 ]
        then
           echo "Already Exists"
        else
           echo "Failed - see logfile $LOGDIR/configure_ums.log"
           exit 1
        fi
    else
        echo "Success"
    fi

   ET=$(date +%s)
   print_time STEP "Create OAA Agent" $ST $ET >> $LOGDIR/timings.log
}

# Create OAA Agent
#
create_oaa_agent()
{

   ST=$(date +%s)
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

   sleep 15
   echo "$GET_CURL_COMMAND | jq -r .agents[].agentgid" >> $LOGDIR/create_oaa_agent.log 2>&1
   XX="$GET_CURL_COMMAND"

   echo ""  >> $LOGDIR/create_oaa_agent.log
   eval $XX >> $LOGDIR/oaa_agent.log 2>&1

   grep -q "agentgid"  $LOGDIR/oaa_agent.log
   if [ $? -eq 0 ]
   then
      AGENTID=$(grep "status" $LOGDIR/oaa_agent.log | jq -r .agents[].agentgid)
      echo "Success"
   else
      echo "Failed - Check Logfile $LOGDIR/create_oaa_agent.log"
      exit 1
   fi

   printf "\t\t\tUpdating Agent - "
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

   ET=$(date +%s)
   print_time STEP "Create OAA Agent" $ST $ET >> $LOGDIR/timings.log
}


# Obtain OAA Plugin
#
copy_plugin()
{

   ST=$(date +%s)
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

   ET=$(date +%s)
   print_time STEP "Obtain OAA Plugin" $ST $ET >> $LOGDIR/timings.log
}

# Install OAA Plugin
#
install_plugin()
{

   ST=$(date +%s)
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
   ET=$(date +%s)
   print_time STEP "Install OAA Plugin" $ST $ET >> $LOGDIR/timings.log
}

# Create OAM Authentication Module
#
create_auth_module()
{

   ST=$(date +%s)
   print_msg "Creating OAM Authentication Module"

   cp $TEMPLATE_DIR/create_auth_module.xml $WORKDIR

   filename=$WORKDIR/create_auth_module.xml
   update_variable "<OAM_LOGIN_LBR_PROTOCOL>" $OAM_LOGIN_LBR_PROTOCOL $filename
   update_variable "<OAM_LOGIN_LBR_HOST>" $OAM_LOGIN_LBR_HOST $filename
   update_variable "<OAM_LOGIN_LBR_PORT>" $OAM_LOGIN_LBR_PORT $filename
   update_variable "<OAA_DEPLOYMENT>" $OAA_DEPLOYMENT $filename

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

   ET=$(date +%s)
   print_time STEP "Create Authentication Module in OAM" $ST $ET >> $LOGDIR/timings.log
}


# Create OAM Authentication Scheme
#
create_auth_scheme()
{

   ST=$(date +%s)
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

   ET=$(date +%s)
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

   ST=$(date +%s)
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

   ET=$(date +%s)
   print_time STEP "Create Authentication Policy in OAM" $ST $ET >> $LOGDIR/timings.log
}

# Delete OAM Authentication Policy
#
delete_auth_policy()
{

   LOG=$1

   DELETE_URL="http://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT/oam/services/rest/11.1.2.0.0/ssa/policyadmin/authnpolicy?appdomain=IAM%20Suite&name=OAA_MFA-Policy"
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

# Set OAA Cookie Domain
#
create_cookie_domain()
{
   ST=$(date +%s)
   print_msg "Setting OAA Cookie Domain"

   USER=`encode_pwd ${OAA_DEPLOYMENT}-oaa-policy:${OAA_API_PWD}`
   PUT_CURL_COMMAND="curl -k -g --fail --request PUT --location "
   PUT_CURL_COMMAND1="curl -k -g --request PUT --location "
   CONTENT_TYPE="-H 'Content-Type: application/json' -H 'Authorization: Basic $USER'"
   PAYLOAD="-d '[{\"name\": \"oaa.browser.cookie.domain\", \"value\": \"$OAM_LOGIN_LBR_HOST\"},"
   PAYLOAD=$PAYLOAD"{ \"name\": \"oaa.risk.integration.postauth.cp\",\"value\": \"postauth\"}"
   PAYLOAD=$PAYLOAD" ]'"
   ADMINURL=$OAM_ADMIN_LBR_PROTOCOL://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT
   REST_API="'$ADMINURL/policy/config/property/v1'"

   echo "   " > $LOGDIR/create_cookie_domain.log 2>&1
   echo "$PUT_CURL_COMMAND1 $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/create_cookie_domain.log 2>&1
   eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/create_cookie_domain.log 2>&1
   if [ $? -gt 0 ]
   then
        eval "$PUT_CURL_COMMAND1 $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/create_cookie_domain.log 2>&1
        grep -q "already exists" $LOGDIR/create_cookie_domain.log
        if [ $? = 0 ]
        then
           echo "Already Exists"
        else
           echo "Failed - see logfile $LOGDIR/create_cookie_domain.log"
           exit 1
        fi
    else
        echo "Success"
    fi   
  

   ET=$(date +%s)
   print_time STEP "Setting OAA Cookie Domain" $ST $ET >> $LOGDIR/timings.log
}

# Create OAA Test User
#

create_test_user()
{

   DIR_TYPE=$1

   ST=$(date +%s)
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
     update_variable "<LDAP_HOST>" ${LDAP_EXTERNAL_HOST:=$OUD_POD_PREFIX-oud-ds-rs-lbr-ldap.$OUDNS.svc.cluster.local} $shfile
     update_variable "<LDAP_PORT>" ${LDAP_EXTERNAL_PORT:=1389} $shfile
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

   ET=$(date +%s)
   print_time STEP "Create Test User $OAA_USER in LDAP" $ST $ET >> $LOGDIR/timings.log
}



# Register OUA as an OAM Partner Application
#
register_tap_oua()
{

   ST=$(date +%s)
   print_msg "Creating OAM TAP Partner for OUA"
   cp $TEMPLATE_DIR/create_tap_partner_oua.py $WORKDIR

   filename=$WORKDIR/create_tap_partner_oua.py
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
   run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/create_tap_partner_oua.py > $LOGDIR/register_tap_oua.log

   print_status $WLSRETCODE $LOGDIR/register_tap_oua.log

   printf "\t\t\tCopy keystore to $WORKDIR - "
   copy_from_k8 $PV_MOUNT/workdir/OAMOUAKeyStore.jks $WORKDIR/OAMOUAKeyStore.jks $OAMNS $OAM_DOMAIN_NAME
   print_status $RETCODE $LOGDIR/register_tap_oua.log

   ET=$(date +%s)
   print_time STEP "Creating OAM TAP Partner for OUA" $ST $ET >> $LOGDIR/timings.log
}

# Edit properties file for OUA
#
edit_properties_oua()
{
   ST=$(date +%s)
   print_msg "Editing properties file for OUA"

   echo "kubectl cp $WORKDIR/OAMOUAKeyStore.jks $OAANS/oaa-mgmt:/u01/oracle/scripts/creds/OAMOUAKeyStore.jks" > $LOGDIR/edit_properties_oua.log 2>&1
   kubectl cp $WORKDIR/OAMOUAKeyStore.jks $OAANS/oaa-mgmt:/u01/oracle/scripts/creds/OAMOUAKeyStore.jks
   echo "kubectl cp $OAANS/oaa-mgmt:/u01/oracle/scripts/settings/installOAA.properties $WORKDIR/installOAA.properties" >> $LOGDIR/edit_properties_oua.log 2>&1
   kubectl cp  $OAANS/oaa-mgmt:/u01/oracle/scripts/settings/installOAA.properties $WORKDIR/installOAA.properties >> $LOGDIR/edit_properties_oua.log 2>&1
   propfile=$WORKDIR/installOAA.properties       

   sed -i "s/#\s*oua.tapAgentName/oua.tapAgentName/" $propfile
   sed -i "s/#\s*oua.tapAgentFilePass/oua.tapAgentFilePass/" $propfile
   sed -i "s/#\s*oua.tapAgentFileLocation/oua.tapAgentFileLocation/" $propfile
   sed -i "s/#\s*oua.oamRuntimeEndpoint/oua.oamRuntimeEndpoint/" $propfile  
   
   replace_value oua.tapAgentName "OAM-OUA-TAP" $propfile     
   ENCODED_TAP_PWD=$(encode_pwd $OAA_KEYSTORE_PWD)     
   replace_value oua.tapAgentFilePass $ENCODED_TAP_PWD $propfile 
   replace_value oua.tapAgentFileLocation "/u01/oracle/scripts/creds/OAMOUAKeyStore.jks" $propfile
   replace_value oua.oamRuntimeEndpoint "$OAM_LOGIN_LBR_PROTOCOL://$OAM_LOGIN_LBR_HOST:$OAM_LOGIN_LBR_PORT" $propfile           
   
   echo "kubectl cp $propfile $OAANS/oaa-mgmt:/u01/oracle/scripts/settings/installOAA.properties" >> $LOGDIR/edit_properties_oua.log 2>&1
   kubectl cp $propfile $OAANS/oaa-mgmt:/u01/oracle/scripts/settings/installOAA.properties >> $LOGDIR/edit_properties_oua.log 2>&1
   print_status $?  $LOGDIR/edit_properties_oua.log   
   ET=$(date +%s)
   print_time STEP "Editing properties file for OUA" $ST $ET >> $LOGDIR/timings.log
}

# Configure DRSS for OUA
#
configure_drss_oua()
{
   ST=$(date +%s)
   print_msg "Configuring DRSS for OUA"

   kubectl exec -n $OAANS -ti oaa-mgmt -- sed -i '1 i\#!/bin/bash' /u01/oracle/scripts/drssconfig/configureDRSS.sh
   oaa_mgmt "/u01/oracle/scripts/drssconfig/configureDRSS.sh -f /u01/oracle/scripts/settings/installOAA.properties" > $LOGDIR/configure_drss_oua.log 2>&1
   if [ $? = 0 ]
   then 
      grep -iq "Agent not found with global id" $LOGDIR/configure_drss_oua.log
      if [ $? = 0 ]
      then 
         printf "Agent not created. Retrying ... \n"
         oaa_mgmt "/u01/oracle/scripts/drssconfig/configureDRSS.sh -f /u01/oracle/scripts/settings/installOAA.properties" > $LOGDIR/configure_drss_oua.log 2>&1
         grep -iq "Agent not found with global id" $LOGDIR/configure_drss_oua.log
         if [ $? = 0 ]
         then 
            print_status 1 $LOGDIR/configure_drss_oua.log 
         fi
      else
         print_status 0 $LOGDIR/configure_drss_oua.log   
      fi
   fi 

   ET=$(date +%s)
   print_time STEP "Configuring DRSS for OUA" $ST $ET >> $LOGDIR/timings.log
}

# Set DRSS parameter for OUA
#
set_drss_param_oua()
{
   ST=$(date +%s)
   print_msg "Setting DRSS parameter for OUA"

   propfile="$WORKDIR/installOAA.properties"
   DRSS_API_KEY=`grep "install.global.drssapikey" $propfile | cut -d '='  -f 2`
   OAA_DEP_UPPERCASE=$(echo "$OAA_DEPLOYMENT" | tr '[:lower:]' '[:upper:]')
   USER=`encode_pwd ${OAA_DEP_UPPERCASE}_OAA_DRSS:$DRSS_API_KEY`
   PUT_CURL_COMMAND="curl -k -g --fail --request PUT --location "
   PUT_CURL_COMMAND1="curl -k -g --request PUT --location "
   CONTENT_TYPE="-H 'Content-Type: application/json' -H 'Authorization: Basic $USER'"
   OAUTH_APPID=`grep "oauth.applicationid" $propfile | cut -d '='  -f 2`
   PAYLOAD="-d '[{\"name\": \"oua.drss.oaa.group\", \"value\": \"$OAUTH_APPID\"}"
   PAYLOAD=$PAYLOAD" ]'"
   ADMINURL=$OAM_LOGIN_LBR_PROTOCOL://$OAM_LOGIN_LBR_HOST:$OAM_LOGIN_LBR_PORT
   REST_API="'$ADMINURL/oaa-drss/oua/property/v1'"

   echo "   " > $LOGDIR/set_drss_param_oua.log 2>&1
   echo "$PUT_CURL_COMMAND1 $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/set_drss_param_oua.log 2>&1
   eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/set_drss_param_oua.log 2>&1
   if [ $? -gt 0 ]
   then
        eval "$PUT_CURL_COMMAND1 $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/set_drss_param_oua.log 2>&1
        grep -q "already exists" $LOGDIR/set_drss_param_oua.log
        if [ $? = 0 ]
        then
           echo "Already Exists"
        else
           echo "Failed - see logfile $LOGDIR/set_drss_param_oua.log"
           exit 1
        fi
    else
        echo "Success"
    fi   

   ET=$(date +%s)
   print_time STEP "Setting DRSS parameter for OUA" $ST $ET >> $LOGDIR/timings.log   
}

# Enable OAM Identity Service
#
enable_oam_identity_service()
{
   ST=$(date +%s)
   print_msg "Enabling OAM Identity Service"

   ADMINURL=$OAM_ADMIN_LBR_PROTOCOL://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT
   REST_API="$ADMINURL/iam/admin/config/api/v1/config?path=/DeployedComponent/Server/NGAMServer/Profile/IdentityManagement/IdentityServiceConfiguration/IdentityServiceEnabled"
   USER=`encode_pwd $LDAP_WLSADMIN_USER:$LDAP_USER_PWD`
   PUT_CURL_COMMAND="curl -s -X PUT "
   GET_CURL_COMMAND="curl -s -X GET "
   CONTENT_TYPE="-H 'Content-Type: text/xml' -H 'Authorization: Basic $USER'"
  
   XX="$GET_CURL_COMMAND $REST_API $CONTENT_TYPE | grep "IdentityServiceEnabled" | grep -iq true"
   echo "$XX" > $LOGDIR/enable_oam_identity_service.log 2>&1
   eval "$XX" >> $LOGDIR/enable_oam_identity_service.log 2>&1
   if [ $? -eq 0 ]
   then
     echo "IdentityServiceEnabled set to true Already " >> $LOGDIR/enable_oam_identity_service.log 2>&1
     echo "Already Exists "
     return 0
   else
      PAYLOAD="-d @$TEMPLATE_DIR/service.xml"
      echo "   " >> $LOGDIR/enable_oam_identity_service.log 2>&1
      echo "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/enable_oam_identity_service.log 2>&1
      eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/enable_oam_identity_service.log 2>&1
      print_status $? $LOGDIR/enable_oam_identity_service.log
   fi
  
    ET=$(date +%s)
    print_time STEP "Enabling OAM Identity Service" $ST $ET >> $LOGDIR/timings.log
}

# Set RequireAuthorizationHeader for OAM
#
set_oam_authz_header()
{
   ST=$(date +%s)
   print_msg "Setting RequireAuthorizationHeader for OAM"

   ADMINURL=$OAM_ADMIN_LBR_PROTOCOL://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT
   REST_API="$ADMINURL/iam/admin/config/api/v1/config?path=/DeployedComponent/Server/NGAMServer/Profile/RestServices/Token/RequireAuthorizationHeader"
   USER=`encode_pwd $LDAP_WLSADMIN_USER:$LDAP_USER_PWD`
   PUT_CURL_COMMAND="curl -s -X PUT "
   GET_CURL_COMMAND="curl -s -X GET "
   CONTENT_TYPE="-H 'Content-Type: text/xml' -H 'Authorization: Basic $USER'"
  
   XX="$GET_CURL_COMMAND $REST_API $CONTENT_TYPE | grep "RequireAuthorizationHeader" | grep -iq true"
   echo "$XX" > $LOGDIR/set_oam_authz_header.log 2>&1
   eval "$XX" >> $LOGDIR/set_oam_authz_header.log 2>&1
   if [ $? -eq 0 ]
   then
     echo "RequireAuthorizationHeader set to true Already " >> $LOGDIR/set_oam_authz_header.log 2>&1
     echo "Already Exists "
   else
      PAYLOAD="-d @$TEMPLATE_DIR/session.xml"
      echo "   " >> $LOGDIR/set_oam_authz_header.log 2>&1
      echo "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/set_oam_authz_header.log 2>&1
      eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/set_oam_authz_header.log 2>&1
      print_status $? $LOGDIR/set_oam_authz_header.log
   fi
   # Restart Domain
   #
   new_step
   if [ $STEPNO -gt $PROGRESS ] && [ "$INSTALL_OUA" = "true" ]
   then
     stop_domain $OAMNS $OAM_DOMAIN_NAME
     update_progress
   fi
   new_step
   if [ $STEPNO -gt $PROGRESS ] && [ "$INSTALL_OUA" = "true" ]
   then
     start_domain $OAMNS $OAM_DOMAIN_NAME
     update_progress
   fi
    ET=$(date +%s)
    print_time STEP "Setting RequireAuthorizationHeader for OAM" $ST $ET >> $LOGDIR/timings.log
}

# Set User Identity Store for OAM
#
set_userid_store ()
{
   ST=$(date +%s)
   print_msg "Setting User Identity Store on OAM for OUA"

   USER=`encode_pwd $LDAP_WLSADMIN_USER:$LDAP_USER_PWD`
   ADMINURL=$OAM_ADMIN_LBR_PROTOCOL://$OAM_ADMIN_LBR_HOST:$OAM_ADMIN_LBR_PORT
   GET_CURL_COMMAND="curl -s -X GET "   
   CONTENT_TYPE="-H 'Content-Type: text/xml' -H 'Authorization: Basic $USER'"
   REST_API="$ADMINURL/iam/admin/config/api/v1/config?path=/DeployedComponent/Server/NGAMServer/Profile/ssoengine/PersistentLogin"
   XX="$GET_CURL_COMMAND $REST_API $CONTENT_TYPE | grep "UserAttributeName" | grep -iq obPSFTID"
   echo "$XX" > $LOGDIR/set_userid_store.log 2>&1
   eval "$XX" >> $LOGDIR/set_userid_store.log 2>&1
   counter=0
   if [ $? -eq 0 ]
   then
    echo "UserAttributeName obPSFTID is set Already " >> $LOGDIR/set_userid_store.log 2>&1
    counter=$(expr $counter + 1)
   fi

   REST_API="$ADMINURL/iam/admin/config/api/v1/config?path=/Resource/LDAP"
   XX="$GET_CURL_COMMAND $REST_API $CONTENT_TYPE | grep "ENABLE_PASSWORD_POLICY" | grep -iq true"
   echo "$XX" >> $LOGDIR/set_userid_store.log 2>&1
   eval "$XX" >> $LOGDIR/set_userid_store.log 2>&1
   if [ $? -eq 0 ]
   then
    echo "ENABLE_PASSWORD_POLICY is set to true Already " >> $LOGDIR/set_userid_store.log 2>&1
    counter=$(expr $counter + 1)
   fi

   REST_API="$ADMINURL/iam/admin/config/api/v1/config?path=/Resource/LDAP"
   XX="$GET_CURL_COMMAND $REST_API $CONTENT_TYPE | grep "USER_SCHEMA" | grep -iq Oblix"
   echo "$XX" >> $LOGDIR/set_userid_store.log 2>&1
   eval "$XX" >> $LOGDIR/set_userid_store.log 2>&1
   if [ $? -eq 0 ]
   then
     echo "USER_SCHEMA is set to Oblix Already " >> $LOGDIR/set_userid_store.log 2>&1
     counter=$(expr $counter + 1)

   fi 

   if [ $counter -eq 3 ]
   then
     echo "Already Exists "
     return 0
   else
     cp $TEMPLATE_DIR/configure_oam_oua.py $WORKDIR
     filename=$WORKDIR/configure_oam_oua.py
     update_variable "<OAM_DOMAIN_NAME>" $OAM_DOMAIN_NAME $filename
     update_variable "<OAM_WEBLOGIC_USER>" $OAM_WEBLOGIC_USER $filename
     update_variable "<OAM_WEBLOGIC_PWD>" $OAM_WEBLOGIC_PWD $filename
     update_variable "<OAMNS>" $OAMNS $filename
     update_variable "<OAM_ADMIN_PORT>" $OAM_ADMIN_PORT $filename

     copy_to_k8 $filename workdir $OAMNS $OAM_DOMAIN_NAME
     echo "   " >> $LOGDIR/set_userid_store.log 2>&1
     echo "Executing WLST command: "run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/configure_oam_oua.py >> $LOGDIR/set_userid_store.log 
     run_wlst_command $OAMNS $OAM_DOMAIN_NAME $PV_MOUNT/workdir/configure_oam_oua.py >> $LOGDIR/set_userid_store.log 
     print_status $? $LOGDIR/set_userid_store.log
   fi 

    ET=$(date +%s)
    print_time STEP "Setting User Identity Store on OAM for OUA" $ST $ET >> $LOGDIR/timings.log
}

# Set ldap attribute to true to all the users in OAA_USER_GROUP
#
set_ldapattr_to_oaausers()
{
   ST=$(date +%s)
   print_msg "Setting ldap attribute to all the users in OAA_USER_GROUP"

   cp $TEMPLATE_DIR/search_modify_oaa_users.sh $WORKDIR
   shfile=$WORKDIR/search_modify_oaa_users.sh
   chmod +x $shfile
   update_variable "<LDAP_HOST>" ${LDAP_EXTERNAL_HOST:=$OUD_POD_PREFIX-oud-ds-rs-lbr-ldap.$OUDNS.svc.cluster.local} $shfile
   update_variable "<LDAP_PORT>" ${LDAP_EXTERNAL_PORT:=1389} $shfile
   update_variable "<LDAP_ADMIN_USER>" $LDAP_ADMIN_USER $shfile
   update_variable "<LDAP_ADMIN_PWD>" $LDAP_ADMIN_PWD $shfile
   update_variable "<OAA_USER_GROUP>" $OAA_USER_GROUP $shfile
   update_variable "<LDAP_GROUP_SEARCHBASE>" $LDAP_GROUP_SEARCHBASE $shfile
   update_variable "<LDAP_USER_SEARCHBASE>" $LDAP_USER_SEARCHBASE $shfile       

   kubectl cp $shfile $OUDNS/$OUD_POD_PREFIX-oud-ds-rs-0:/u01/oracle/config-input  > $LOGDIR/set_ldapattr_to_oaausers.log 2>&1
   if  [  $? -gt 0 ]
   then
      echo "Failed to copy $shfile."
      exit 1
   fi
   kubectl exec -ti -n $OUDNS $OUD_POD_PREFIX-oud-ds-rs-0 -c oud-ds-rs -- /u01/oracle/config-input/search_modify_oaa_users.sh >> $LOGDIR/set_ldapattr_to_oaausers.log 2>&1

   if [ $? = 0 ]
   then
     grep -qi "already modified" $LOGDIR/set_ldapattr_to_oaausers.log
       if [ $? = 0 ]
       then 
         echo "Already exists"
       else 
         echo " Success" 
       fi 
   else
     grep -qi "failed" $LOGDIR/set_ldapattr_to_oaausers.log
       if [ $? = 0 ]
       then 
          echo "Failed - see logfile $LOGDIR/set_ldapattr_to_oaausers.log"
          print_status 1 $LOGDIR/set_ldapattr_to_oaausers.log

      fi       
   fi 
   ET=$(date +%s)
   print_time STEP "Setting ldap attribute to all the users in OAA_USER_GROUP" $ST $ET >> $LOGDIR/timings.log      
}



# Add all the users under OAA-App-User group to the OAA DB
#

add_oua_usersToDB()
{
   ST=$(date +%s)
   print_msg "Adding all the users under $OAA_USER_GROUP group to the OAA DB"

   cp $TEMPLATE_DIR/search_oaa_users.sh $WORKDIR
   shfile=$WORKDIR/search_oaa_users.sh
   chmod +x $shfile
   update_variable "<LDAP_HOST>" ${LDAP_EXTERNAL_HOST:=$OUD_POD_PREFIX-oud-ds-rs-lbr-ldap.$OUDNS.svc.cluster.local} $shfile
   update_variable "<LDAP_PORT>" ${LDAP_EXTERNAL_PORT:=1389} $shfile
   update_variable "<LDAP_ADMIN_USER>" $LDAP_ADMIN_USER $shfile
   update_variable "<LDAP_ADMIN_PWD>" $LDAP_ADMIN_PWD $shfile
   update_variable "<OAA_USER_GROUP>" $OAA_USER_GROUP $shfile
   update_variable "<LDAP_GROUP_SEARCHBASE>" $LDAP_GROUP_SEARCHBASE $shfile     

   kubectl cp $shfile $OUDNS/$OUD_POD_PREFIX-oud-ds-rs-0:/u01/oracle/config-input  > $LOGDIR/add_oua_usersToDB.log 2>&1
   if  [  $? -gt 0 ]
   then
      echo "Failed to copy $shfile."
      print_status 1 $LOGDIR/add_oua_usersToDB.log
   fi
   kubectl exec -ti -n $OUDNS $OUD_POD_PREFIX-oud-ds-rs-0 -c oud-ds-rs -- /u01/oracle/config-input/search_oaa_users.sh >> $LOGDIR/add_oua_usersToDB.log 2>&1
   if  [  $? -gt 0 ]
   then
      echo "Failed to connect to OUD pod - Check OUD is running."
      print_status 1 $LOGDIR/add_oua_usersToDB.log
   fi
  
   ADMINURL=$OAM_LOGIN_LBR_PROTOCOL://$OAM_LOGIN_LBR_HOST:$OAM_LOGIN_LBR_PORT
   REST_API="'$ADMINURL/oaa/runtime/preferences/v1'"
   propfile="$WORKDIR/installOAA.properties"
   OAA_DEP_UPPERCASE=$(echo "$OAA_DEPLOYMENT" | tr '[:lower:]' '[:upper:]')
   USER=`encode_pwd "${OAA_DEP_UPPERCASE}-OAA:${OAA_API_PWD}"`

   CONTENT_TYPE="-H 'Content-Type: application/json' -H 'Authorization: Basic $USER'"
   OAUTH_APPID=`grep "oauth.applicationid" $propfile | cut -d '='  -f 2`
   PAYLOAD="-d @$WORKDIR/oua_user_add.json"
   
   counter=0 
   for unique_member in `grep "uniqueMember:"  "$LOGDIR/add_oua_usersToDB.log" | awk '{print $2}' |  cut -f1 -d "," | cut -f2 -d "="`
   do 
      counter=$(expr $counter + 1)
      cp $TEMPLATE_DIR/oua_user_add.json $WORKDIR
      filename=$WORKDIR/oua_user_add.json   
      update_variable "<OAUTH_APPID>" $OAUTH_APPID $filename
      update_variable "<OAA_USER>" $unique_member $filename
      echo "   " >> $LOGDIR/add_oua_usersToDB.log 2>&1
      POST_CURL_COMMAND="curl -k -g --fail --request POST --location "
      POST_CURL_COMMAND1="curl -k -g --request POST --location "
      echo "$POST_CURL_COMMAND1 $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/add_oua_usersToDB.log 2>&1
      eval "$POST_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/add_oua_usersToDB.log 2>&1
      if [ $? -gt 0 ]
      then
        eval "$POST_CURL_COMMAND1 $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/add_oua_usersToDB.log 2>&1
        grep -iq "Cannot Create User" $LOGDIR/add_oua_usersToDB.log
        if [ $? = 0 ]
        then
           echo "Cannot Create User $unique_member as it already exists" >> $LOGDIR/add_oua_usersToDB.log 2>&1
        else
           echo "Failed - see logfile $LOGDIR/add_oua_usersToDB.log"
           print_status 1 $LOGDIR/add_oua_usersToDB.log
           exit 1
        fi
      else
        echo "$unique_member added to OAA DB " >> $LOGDIR/add_oua_usersToDB.log 2>&1
        sleep 1
      fi
   done

   if [ $counter -eq `grep -i "already exists" $LOGDIR/add_oua_usersToDB.log | wc -l` ]; then 
     echo "Already Exists"
     return 0
   else
      echo "Success"
   fi

   ET=$(date +%s)
   print_time STEP "Adding all the users under $OAA_USER_GROUP group to the OAA DB" $ST $ET >> $LOGDIR/timings.log   
}


# Modify the template to create a cronjob
#
create_dr_cronjob_files()
{
   ST=$(date +%s)
   print_msg "Creating Cron Job Files"

   cp $TEMPLATE_DIR/dr_cron.yaml $WORKDIR/dr_cron.yaml
   update_variable "<DRNS>" $DRNS $WORKDIR/dr_cron.yaml
   update_variable "<DR_OAA_MINS>" $DR_OAA_MINS $WORKDIR/dr_cron.yaml
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

# Delete the OAA files created by a fresh installation.
#
delete_oaa_files()
{
   ST=$(date +%s)
   print_msg "Delete OAA Files"

   if [ -e $OAA_LOCAL_CONFIG_SHARE ] && [ ! "$OAA_LOCAL_CONFIG_SHARE" = "" ]
   then
     echo rm -rf $OAA_LOCAL_CONFIG_SHARE/helm $OAA_LOCAL_CONFIG_SHARE/installOAA.properties $OAA_LOCAL_CONFIG_SHARE/oaaoverride.yaml   > $LOGDIR/delete_oaa.log 2>&1
     rm -rf $OAA_LOCAL_CONFIG_SHARE/helm $OAA_LOCAL_CONFIG_SHARE/installOAA.properties $OAA_LOCAL_CONFIG_SHARE/oaaoverride.yaml   >> $LOGDIR/delete_oaa.log 2>&1
   else
     echo "Share does not exist, or OAA_LOCAL_CONFIG_SHARE is not defined."
   fi

   if [ -e $OAA_LOCAL_VAULT_SHARE ] && [ ! "$OAA_LOCAL_VAULT_SHARE" = "" ]
   then
     echo rm -rf $OAA_LOCAL_VAULT_SHARE/.accessstore.pkcs12 > $LOGDIR/delete_oaa.log 2>&1
     rm -rf $OAA_LOCAL_VAULT_SHARE/.accessstore.pkcs12 >> $LOGDIR/delete_oaa.log 2>&1
   else
     echo "Share does not exist, or OAA_LOCAL_VAULT_SHARE is not defined."
   fi
   print_status $?  $LOGDIR/delete_oaa.log

   ET=$(date +%s)
   print_time STEP "Delete OAA Files" $ST $ET >> $LOGDIR/timings.log
}


