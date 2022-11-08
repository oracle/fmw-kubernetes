#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of common functions and procedures used by the provisioning and deletion scripts
# 
#
# Dependencies: 
#               
#
# Usage: invoked as needed not directly
#
# Common Environment Variables
#

SCRIPTDIR=/home/opc/scripts
RSPFILE=$SCRIPTDIR/responsefile/idm.rsp
PWDFILE=$SCRIPTDIR/responsefile/.idmpwds
. $PWDFILE
. $RSPFILE
export SAMPLES_DIR=`echo $SAMPLES_REP | awk -F  "/" '{print $NF}' | sed 's/.git.*//'`

SSH="ssh -q"


# Create local Directories
#
create_local_workdir()
{
    ST=`date +%s`
    if  [ ! -d $WORKDIR ]
    then
        printf "Creating Working Directory : $WORKDIR - "
        mkdir -p $WORKDIR
        print_status $?
    else
        printf "Using Working Directory    : $WORKDIR\n"
    fi
    ET=`date +%s`
}

create_logdir()
{
    ST=`date +%s`
    if  [ ! -d $LOGDIR ]
    then
        printf "Creating Log Directory     : $LOGDIR  - "
        mkdir -p $LOGDIR
        print_status $?
    else
        printf "Using Log Directory        : $LOGDIR\n "
    fi

    echo ""

    ET=`date +%s`
}


#
# Create Container Registry Secret
#
create_registry_secret()
{
    registry=$1
    username=$2
    pass=$3
    namespace=$4

    credname=${5:-"regcred"}

    ST=`date +%s`
    print_msg "Creating Container Registry Secret in namespace $namespace"
    
    kubectl create secret -n $namespace docker-registry $credname --docker-server=$registry --docker-username=$username --docker-password=$pass > $LOGDIR/create_reg_secret.log 2>&1
    grep -q created $LOGDIR/create_reg_secret.log
    if [ $? = 0 ]
    then 
         echo "Success"
    else
          grep -q exists $LOGDIR/create_reg_secret.log
          if [ $? = 0 ]
          then 
               echo "Already Exists"
          else
               echo "Failed - See $LOGDIR/create_reg_secret.log."
               exit 1
          fi
    fi
    ET=`date +%s`
    print_time STEP "Creating Container Registry Secret in namespace $namespace" $ST $ET >> $LOGDIR/timings.log
}

#
# Create github Registry Secret
#
create_git_secret()
{
    username=$1
    token=$2
    namespace=$3

    ST=`date +%s`
    print_msg "Creating GitHub Secret in namespace $namespace"
    
    kubectl create secret -n $namespace docker-registry github --docker-server=ghcr.io --docker-username=$username --docker-password="$token" > $LOGDIR/create_git_secret.log 2>&1
    grep -q created $LOGDIR/create_git_secret.log
    if [ $? = 0 ]
    then 
         echo "Success"
    else
          grep -q exists $LOGDIR/create_git_secret.log
          if [ $? = 0 ]
          then 
               echo "Already Exists"
          else
               echo "Failed - See $LOGDIR/create_git_secret.log."
               exit 1
          fi
    fi
    ET=`date +%s`
    print_time STEP "Creating GitHub Secret" $ST $ET >> $LOGDIR/timings.log
}
#
# Create ELK Secret
#
create_elk_secret()
{
    value=$1
    namespace=$2

    ST=`date +%s`
    print_msg "Creating Elastic Search Secret in namespace $namespace"
    
    kubectl create secret -n $namespace generic elk-logstash --from-literal --password="$token" > $LOGDIR/create_elk_secret.log 2>&1
    grep -q created $LOGDIR/create_elk_secret.log
    if [ $? = 0 ]
    then 
         echo "Success"
    else
          grep -q exists $LOGDIR/create_elk_secret.log
          if [ $? = 0 ]
          then 
               echo "Already Exists"
          else
               echo "Failed - See $LOGDIR/create_elk_secret.log."
               exit 1
          fi
    fi
    ET=`date +%s`
    print_time STEP "Creating ELK Secret" $ST $ET >> $LOGDIR/timings.log
}

#
check_oper_exists()
{
   print_msg "Check Operator has been installed"
   kubectl get namespaces | grep -q $OPERNS 
   if [ $? = 0 ]
   then
       echo "Success"
   else
       echo "Failed Install Operator before continuing."
       exit 1
   fi
}

# Helm Functions
#
install_operator()
{
    ST=`date +%s`
    
    print_msg  "Installing Operator"

    ELK_PROTO=`echo $ELK_HOST | cut -f1 -d:` 
    ELK_HN=`echo $ELK_HOST | cut -f2 -d: | sed 's/\/\///'` 
    ELK_PORT=`echo $ELK_HOST | cut -f3 -d:` 

    cd $WORKDIR/samples
    echo helm install weblogic-kubernetes-operator charts/weblogic-operator --namespace $OPERNS --set image=$OPER_IMAGE:$OPER_VER --set serviceAccount=$OPER_ACT \
            --set "enableClusterRoleBinding=true" \
            --set "javaLoggingLevel=FINE" \
            --set "domainNamespaceSelectionStrategy=LabelSelector" \
            --set "domainNamespaceLabelSelector=weblogic-operator\=enabled" \
            --set "elkIntegrationEnabled=$USE_ELK" \
            --set "elasticSearchHost=$ELK_PROTO://$ELK_HN" \
            --set "elasticSearchPort=$ELK_PORT" \
            --set "logStashImage=docker.elastic.co/logstash/logstash:$ELK_VER" \
            --set "createLogStashConfigMap=true" \
            --wait > $LOGDIR/install_oper.log 

    helm install weblogic-kubernetes-operator charts/weblogic-operator --namespace $OPERNS --set image=$OPER_IMAGE:$OPER_VER --set serviceAccount=$OPER_ACT \
            --set "enableClusterRoleBinding=true" \
            --set "javaLoggingLevel=FINE" \
            --set "domainNamespaceSelectionStrategy=LabelSelector" \
            --set "domainNamespaceLabelSelector=weblogic-operator\=enabled" \
            --set "elkIntegrationEnabled=$USE_ELK" \
            --set "elasticSearchHost=$ELK_PROTO://$ELK_HN" \
            --set "elasticSearchPort=$ELK_PORT" \
            --set "logStashImage=docker.elastic.co/logstash/logstash:$ELK_VER" \
            --set "createLogStashConfigMap=true" \
            --wait >> $LOGDIR/install_oper.log 2>&1

    print_status $? $LOGDIR/install_oper.log
    ET=`date +%s`
    print_time STEP "Install Operator" $ST $ET >> $LOGDIR/timings.log

}

# Kubernetes Functions
#
get_image()
{
   product=$1
   image=`grep $product $imagefile | awk ' { print $2 }'`
   echo $image
}

# Obtain a list of Kubernetes nodes
#
get_k8nodes()
{
    kubectl get nodes | grep -v Disabled | grep -v "control-plane" |sed '/NAME/d' | awk '{ print $1 }'
}

# Obtain a list of Kubernetes Control nodes
#
get_k8masters()
{
    kubectl get nodes |  grep master | awk '{ print $1 }'
}

get_crd()
{
    kubectl get crd | sed '/NAME/d' | awk '{ print $1 }'
}

delete_crd()
{
    print_msg "Deleting CRD if it exists"
    kubectl get crd | grep -q domains.weblogic.oracle
    if [ $? = 0 ]
    then
          kubectl delete crd domains.weblogic.oracle > $LOGDIR/delete_crd.log 2>&1
          print_status $?  $LOGDIR/delete_crd.log
    else
          echo "Not present"
    fi
}

#
# Get Kubernetes NodePort Port
#

get_k8_port()
{
   SVC=$1
   NS=$2
   TYP=${3:-"http"}


   PORTS=`kubectl get service -n $NS | grep NodePort | grep "$SVC " | awk '{ print $5 }'`

   PORT1=(`echo $PORTS | cut -f1 -d, | sed 's/\/TCP//;s/:/ /'`)
   PORT2=(`echo $PORTS | cut -f2 -d, | sed 's/\/TCP//;s/:/ /'`)

   echo $PORTS | grep -q ,

   if [ $? = 1 ]
   then 
        echo  ${PORT1[1]}
   else
       if [ ${PORT1[0]} = 80 ] && [ "$TYP" = "http" ]
       then
          echo  ${PORT1[1]}
       else
          echo  ${PORT2[1]}
       fi
   fi
}

# Create Namespace if it does not already exist
#
create_namespace()
{
   NS=$1
   TYPE=$2
   ST=`date +%s`
   print_msg "Creating Namespace: $NS"
   kubectl get namespace $NS >/dev/null 2> /dev/null
   if [ "$?" = "0" ]
   then
      echo "Already Exists"
   else
       kubectl create namespace $NS > $LOGDIR/create_ns.log 2>&1
       print_status $? $LOGDIR/create_ns.log
       if [ "$TYPE" = "WLS" ]
       then
          printf "\t\t\tMarking as a WebLogic Enabled Namespace - "
          kubectl label namespaces $NS weblogic-operator=enabled >> $LOGDIR/create_ns.log 2>&1
          print_status $? $LOGDIR/create_ns.log
       fi
   fi
   ET=`date +%s`
   print_time STEP "Create Namespace" $ST $ET >> $LOGDIR/timings.log
}

# Create a Kubernetes service account
#
create_service_account()
{
   actname=$1
   nsp=$2
   print_msg "Create Service Account"
   kubectl create serviceaccount -n $nsp $actname >$LOGDIR/create_svc.log 2>&1
   if [ $? -gt 0 ]
   then
      grep "already exists" -q $LOGDIR/create_svc.log
      if [ $? = 0 ]
      then 
        echo "Already Exists"
      else
          print_status 1 $LOGDIR/create_svc.log
      fi
   else
      print_status 0 $LOGDIR/create_svc.log
   fi
}

# Copy file to Kubernetes Container
#
copy_to_k8()
{
   filename=$1
   destination=$2
   namespace=$3
   domain_name=$4

   kubectl cp $filename  $namespace/$domain_name-adminserver:$PV_MOUNT/$destination
   if  [  $? -gt 0 ]
   then
      echo "Failed to copy $filename."
      exit 1
   fi
}

# Determine the status of a Persistent Volume
#
check_pv_ok()
{
    DOMAIN_NAME=$1
    print_msg "Checking ${domain_name}-domain-pv"
    status=$(kubectl get pv | grep $DOMAIN_NAME-domain-pv | awk '{ print $5}' )
    if [ "$status" = "Bound" ]
    then
        echo "Bound Successfully"
    else
        echo "Is not bound - Resolve the issue before continuing"
        exit 1
    fi
}

# Determine the status of a Persistent Volume Claim
#
check_pvc_ok()
{
    domain_name=$1
    namespace=$2
    print_msg "Checking ${domain_name}-domain-pvc"
    status=$(kubectl get pvc -n $namespace | grep $domain_name-domain-pvc | awk '{ print $2}' )
    if [ "$status" = "Bound" ]
    then
        echo "Bound Successfully"
    else
        echo "Is not bound - Resolve the issue before continuing"
        exit 1
    fi
}

# Copy file from Kubernetes Container
#
copy_from_k8 ()
{
   filename=$1
   destination=$2
   namespace=$3
   domain_name=$4

   kubectl cp $namespace/$domain_name-adminserver:$filename $destination > /dev/null
   RETCODE=$?

}

# Create Secrets
#
create_domain_secret()
{
   namespace=$1
   domain_name=$2
   wlsuser=$3
   wlspwd=$4

   ST=`date +%s`
   print_msg "Creating a Kubernetes Domain Secret"
   cd $WORKDIR/samples/create-weblogic-domain-credentials 
   ./create-weblogic-credentials.sh -u $wlsuser -p $wlspwd -n $namespace -d $domain_name -s $domain_name-credentials > $LOGDIR/domain_secret.log  2>&1

   print_status $? $LOGDIR/domain_secret.log
   ET=`date +%s`

   print_time STEP "Create Domain Secret" $ST $ET >> $LOGDIR/timings.log
}

create_rcu_secret()
{
   namespace=$1
   domain_name=$2
   rcuprefix=$3
   rcupwd=$4
   syspwd=$5

   ST=`date +%s`
   print_msg "Creating a Kubernetes RCU Secret"
   cd $WORKDIR/samples/create-rcu-credentials
   ./create-rcu-credentials.sh -u $rcuprefix -p $rcupwd -a sys -q $syspwd -d $domain_name -n $namespace -s $domain_name-rcu-credentials> $LOGDIR/rcu_secret.log  2>&1

   print_status $? $LOGDIR/rcu_secret.log
   ET=`date +%s`

   print_time STEP "Create RCU Secret" $ST $ET >> $LOGDIR/timings.log
}

# Create a working directory inside the Kubernetes container
#
create_workdir()
{
   namespace=$1
   domain_name=$2
  
   ST=`date +%s`
   print_msg "Creating Work directory inside container"
   kubectl exec -n $namespace -ti $domain_name-adminserver -- mkdir -p $K8_WORKDIR
   print_status $? 

   printf "\t\t\tCreating Keystores directory inside container - "
   kubectl exec -n $namespace -ti $domain_name-adminserver -- mkdir -p $PV_MOUNT/keystores
   print_status $? 
   ET=`date +%s`

   print_time STEP "Create Container Working Directory" $ST $ET >> $LOGDIR/timings.log
}

# Execute a command inside the Kubernetes container
#
run_command_k8()
{
   namespace=$1
   domain_name=$2
   command=$3
  
   kubectl exec -n $namespace -ti $domain_name-adminserver -- $command
}

# Execute a command inside the Kubernetes container
#
run_wlst_command()
{
   namespace=$1
   domain_name=$2
   command=$3
  
   WLSRETCODE=0
   kubectl exec -n $namespace -ti $domain_name-adminserver -- /u01/oracle/oracle_common/common/bin/wlst.sh $command 
   if [ $? -gt 0 ]
   then 
      echo "Failed to Execute wlst command: $command"
      WLSRETCODE=1
   fi
}

# Download Samples to Directory
#
download_samples()
{
    ST=`date +%s`
    print_msg "Downloading Oracle Identity Management Samples "
    cd $LOCAL_WORKDIR

    echo $SAMPLES_REP | grep -q orahub
    if [ $? = 0 ]
    then
       unset HTTPS_PROXY
    fi
    if [ -d $SAMPLES_DIR ]
    then
        echo "Already Exists - Skipping"
    else
        git clone -q $SAMPLES_REP > $LOCAL_WORKDIR/sample_download.log 2>&1
        print_status $? $LOCAL_WORKDIR/sample_download.log
    fi
    ET=`date +%s`

    print_time STEP "Download IDM Samples" $ST $ET >> $LOGDIR/timings.log
}

# Copy Samples to Working Directory
#
copy_samples()
{
    product=$1
    ST=`date +%s`
    print_msg "Copying Samples to Working Directory"
    if [ "$product" = "OracleUnifiedDirectorySM" ] || [ "$product" = "OracleUnifiedDirectory" ]
    then
        cp -pr $LOCAL_WORKDIR/$SAMPLES_DIR/$product/ $WORKDIR/samples
    else 
        if [ "$SAMPLES_DIR" = "FMW-DockerImages" ]
        then
            cp -pr $LOCAL_WORKDIR/$SAMPLES_DIR/$product/kubernetes/$OPER_VER $WORKDIR/samples
        else
            cp -pr $LOCAL_WORKDIR/$SAMPLES_DIR/$product/kubernetes $WORKDIR/samples
        fi
    fi
    print_status $?

    ET=`date +%s`

    print_time STEP "Copied IDM Samples" $ST $ET >> $LOGDIR/timings.log
   
}

# Create helper pod
#
create_helper_pod ()
{
   NS=$1
   IMAGE=$2

   ST=`date +%s`
   print_msg "Creating Helper Pod"
   kubectl get pod -n $NS helper > /dev/null 2> /dev/null
   if [ "$?" = "0" ]
   then
       echo "Already Created"
       check_running $NS helper
   else
       if [ "$USE_REGISTRY" = "true" ]
       then
           kubectl run helper -n $NS --image $IMAGE --overrides='{ "spec": { "imagePullSecrets": [{"name": "regcred"}]   } }' -- sleep infinity > $LOGDIR/helper.log 2>&1
           print_status $? $LOGDIR/helper.log
       else
           kubectl run helper  --image $IMAGE -n $NS -- sleep infinity > $LOGDIR/helper.log 2>&1
           print_status $? $LOGDIR/helper.log
       fi
       check_running $NS helper
   fi
   ET=`date +%s`
   print_time STEP "Create Helper Pod" $ST $ET >> $LOGDIR/timings.log
}

# Delete helper Pod
#
remove_helper_pod()
{
   NS=$1
   kubectl -n $NS delete pod,svc helper
   echo "Helper Pod Deleted:"
}

# Update Replica Count
#
update_replica_count()
{
   install_type=$1
   noReplicas=$2


   ST=`date +%s`
   print_msg "Updating Server Start Count to $noReplicas"
   if [ "$install_type" = "oam" ]
   then
      filename=$WORKDIR/samples/create-access-domain/domain-home-on-pv/output/weblogic-domains/$OAM_DOMAIN_NAME
      sed -i "s/replicas:.*/replicas: $noReplicas/" $filename/domain.yaml
      print_status $? $LOGDIR/update_server_count.log 2>&1
      kubectl apply -f $filename/domain.yaml  >>$LOGDIR/update_server_count.log 2>&1
      printf "\t\t\tSaving a Copy of Domain files to : $LOCAL_WORKDIR/TO_KEEP/$OAM_DOMAIN_NAME - "
      mkdir -p $LOCAL_WORKDIR/TO_KEEP/$OAM_DOMAIN_NAME
      cp $filename/* $LOCAL_WORKDIR/TO_KEEP/$OAM_DOMAIN_NAME
      cp $WORKDIR/create-domain-inputs.yaml $LOCAL_WORKDIR/TO_KEEP/$OAM_DOMAIN_NAME
      print_status $? 
   else
      filename=$WORKDIR/samples/create-oim-domain/domain-home-on-pv/output/weblogic-domains/$OIG_DOMAIN_NAME
      sed -i "s/replicas:.*/replicas: $noReplicas/" $filename/domain.yaml
      sed -i "s/replicas:.*/replicas: $noReplicas/" $filename/domain_oim_soa.yaml
      print_status $? $LOGDIR/update_server_count.log 2>&1
      kubectl apply -f $filename/domain_oim_soa.yaml >>$LOGDIR/update_server_count.log 2>&1
      printf "\t\t\tSaving a Copy of Domain files to : $LOCAL_WORKDIR/TO_KEEP/$OIG_DOMAIN_NAME - "
      mkdir -p $LOCAL_WORKDIR/TO_KEEP/$OIG_DOMAIN_NAME
      cp $filename/* $LOCAL_WORKDIR/TO_KEEP/$OIG_DOMAIN_NAME
      cp $WORKDIR/create-domain-inputs.yaml $LOCAL_WORKDIR/TO_KEEP/$OIG_DOMAIN_NAME
      print_status $? 
   fi

   ET=`date +%s`
   print_time STEP "Update Server Count" $ST $ET >> $LOGDIR/timings.log
}

# Image Functions
#

function check_image_exists {
    IMAGE=$1
    VER=$2
    KNODES=`get_k8nodes`
    RETCODE=0

    if [ "$IMAGE_TYPE" = "docker" ]
    then
        CMD="docker"
    else
        CMD="sudo crictl"
    fi

    echo "Checking Image $IMAGE exists on each Kubernetes node"
    for node in $KNODES
    do
         echo -n "... Checking image $IMAGE on $node :"
         if [[ $($SSH $node "$CMD images | grep $IMAGE | grep $VER") = "" ]]
         then
             echo " Missing."
             RETCODE=1
         else
             echo " Exists"
         fi
    done
    return $RETCODE
}

remove_image()
{
    IMAGE=$1
    VER=$2
    KNODES=`get_k8nodes`
    if [ "$IMAGE_TYPE" = "docker" ]
    then
      CMD="docker"
    else
      CMD="sudo crictl"
    fi
    for node in $KNODES
    do
         printf  "... Removing container image $IMAGE:$VER on $node : "
         IMAGE_REC=`$SSH $node "$CMD images | grep $IMAGE | grep $VER  "`
         IMAGE_ID=`echo $IMAGE_REC | awk ' {print $3}'`
         if [  "$IMAGE_ID" = "" ]
         then
            echo "Not Present"
         else
            $SSH $node "$CMD rmi $IMAGE_ID"
            print_status $?
         fi
    done
}


upload_image_if_needed()
{
    IMAGE=$1
    IMAGE_FILE=$2
    KNODES=`get_k8nodes`
    VER=$(basename $IMAGE_FILE | sed 's/.tar//' | cut -f2 -d-)
    LABEL=$(basename $IMAGE_FILE | sed 's/.tar//' | cut -f2-6 -d-)

    if [ "$IMAGE_TYPE" = "docker" ]
    then
      cmd="docker"
    else
      cmd="sudo podman"
    fi

    for node in $KNODES
    do
         echo -n "Checking $IMAGE:$LABEL on $node :"
         if [[ $($SSH $node "$cmd images | grep $IMAGE | grep $VER") = "" ]]
         then
             echo " . Loading"
             $SSH $node "$cmd load < $IMAGE_DIR/$IMAGE_FILE"
         else
             echo "exists"
         fi
    done
}

# Simple Validation functions
#
function check_yes()
{
     input=$1
     if [ "$input" == "y" ]
     then
         return 0
     elif [ "$input" = "Y" ]
     then
         return 0
     else
         return 1
     fi
}

# Encode/Decode Passwords
#
function encode_pwd()
{
    password=$1

    encoded_pwd=`echo -n $password | base64`

    echo $encoded_pwd
}
 
function decode_pwd()
{
    password=$1

    decoded_pwd=`echo -n $password | base64 --decode`

    echo $decoded_pwd
}

#Replace a value in a file
#
replace_value()
{
     name=$1
     val=$2
     filename=$3

     newval=$(echo $val | sed 's/\//\\\//g')
     sed -i 's/'$name'=.*/'$name'='"$newval"'/' $filename
     if [ "$?" = "1" ]
     then 
        echo "Error Modifying File: $filename"
     fi
}

replace_value2()
{
     name=$1
     val=$2
     filename=$3

     newval=$(echo $val | sed 's/\//\\\//g')
     sed -i 's/#'$name':.*/'$name':'" $newval"'/' $filename
     if [ "$?" = "1" ]
     then 
        echo "Error Modifying File: $filename"
     fi
     sed -i 's/'$name':.*/'$name':'" $newval"'/' $filename
     if [ "$?" = "1" ]
     then 
        echo "Error Modifying File: $filename"
     fi

}

#Replace a value in password file
#
replace_password()
{
     name=$1
     val=$2
     filename=$3

     newval=$(echo $val | sed 's/\//\\\//g')
     sed -i 's/'$name'=.*/'$name'='"\"$newval\""'/' $filename
     if [ "$?" = "1" ]
     then 
        echo "Error Modifying File: $filename"
     fi
}
global_replace_value()
{
     val1=$1
     val2=$2
     filename=$3

     oldval=$(echo $val1 | sed 's/\//\\\//g')
     newval=$(echo $val2 | sed 's/\//\\\//g')
     sed -i "s/$oldval/$newval/" $filename
     if [ "$?" = "1" ]
     then 
        echo "Error Modifying File: $filename"
     fi
}

update_variable()
{
     VAR=$1
     VAL=$2
     FILE=$3
     if [ "$VAL" = "" ]
     then
        echo "Unable to update variable: $VAR with $VAL"
        exit 1
     fi
     NEWVAL=$(echo $VAL | sed 's/\//\\\//g')
     sed -i "s/$VAR/$NEWVAL/g" $FILE
     if [ "$?" = "1" ]
     then 
        echo "Error Modifying File: $FILE"
     fi
}

#
# Check variable is numeric
#

check_number()
{
   VAL=$1

   if   ! [[ "$VAL" =~  ^[0-9]+$ ]]
   then
       return 1
   else
       return 0
   fi
}

# Check Password format
# TYP=UC - Must contain a Uppercase and a Number
# TYP=UCS - Must contain a Uppercase and a Number and Symbol
# TYP=NS - Must not contain a symbol
#
function check_password ()
{
  TYP=$1
  password=$2

  LEN=$(echo ${#password})

  RETCODE=0

   if [ $LEN -lt 8 ]; then

     echo "$password is smaller than 8 characters"
     RETCODE=1
   fi

   if [[ ! $password =~ [0-9] ]]
   then
      if [ "$TYP" = "UN" ]
      then
          echo "Password must contain a number"
          RETCODE=1
      fi
   fi

   if [[ ! $password =~ [A-Z] ]] && [ "$TYP" = "NS" ]
   then
      if [ "$TYP" = "UN" ]
      then
         echo "Password must contain an Uppercase Letter"
         RETCODE=1
      fi
   fi

   if  [[  $password =~ ^[[:alnum:]]+$ ]] && [ "$TYP" = "UNS" ]
   then
     echo "Password Must contain a Special Character"
     RETCODE=1
   fi

   if [[ ! $password =~ ^[[:alnum:]]+$ ]] && [ "$TYP" = "NS" ]
   then
     echo "Password Must Not contain a Special Character"
     RETCODE=1
   fi
   return $RETCODE
}

#Get the path and name of a image file
#
function get_image_file()
{
     path=$1
     file=$2
     image=`find $path -name ${file}-*.tar`
     if [ "$image" = "" ]
     then
          echo "There is no Image file for $file in $path"
          exit 1
     else
          echo $image
     fi
}

# RCU Functions
#
create_schemas ()
{
      NAMESPACE=$1
      DB_HOST=$2
      DB_PORT=$3
      DB_SERVICE=$4
      RCU_PREFIX=$5
      SCHEMA_TYPE=$6
      SYSPWD=$7
      RCUPWD=$8

      ST=`date +%s`
      OAM_SCHEMAS=" -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component STB -component OAM "
      OIG_SCHEMAS=" -component MDS -component IAU -component SOAINFRA -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component STB -component OIM -component UCSUMS"

      printf "$SYSPWD\n" > /tmp/pwd.txt
      printf "$RCUPWD\n" >> /tmp/pwd.txt
      print_msg "Creating $SCHEMA_TYPE Schemas"

      printf "#!/bin/bash\n" > /tmp/create_schema.sh
      printf "/u01/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE " >> /tmp/create_schema.sh
      printf " -connectString $DB_HOST:$DB_PORT/$DB_SERVICE " >> /tmp/create_schema.sh
      printf " -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true " >> /tmp/create_schema.sh
      printf " -schemaPrefix $RCU_PREFIX" >> /tmp/create_schema.sh
 
      if [ "$SCHEMA_TYPE" = "OIG" ]
      then
           printf "$OIG_SCHEMAS" >> /tmp/create_schema.sh
      elif [ "$SCHEMA_TYPE" = "OAM" ]
      then
           printf "$OAM_SCHEMAS" >> /tmp/create_schema.sh
      else
           printf "\nInvalid Schema Type: $SCHEMA_TYPE \n"
           exit 1
      fi

      printf " -f < /tmp/pwd.txt \n" >> /tmp/create_schema.sh
      printf " exit \n" >> /tmp/create_schema.sh

      kubectl cp /tmp/pwd.txt  $NAMESPACE/helper:/tmp
      kubectl cp /tmp/create_schema.sh  $NAMESPACE/helper:/tmp
      kubectl exec -n $NAMESPACE -ti helper -- /bin/bash < /tmp/create_schema.sh > $LOGDIR/create_schemas.log 2>&1
      print_status $? $LOGDIR/create_schemas.log
      if [ "$SCHEMA_TYPE" = "OIG" ]
      then
         printf "\t\t\tPatching OIM Schema - " 
         printf "/u01/oracle/oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin/ant " >> /tmp/patch_schema.sh
         printf " -f /u01/oracle/idm/server/setup/deploy-files/automation.xml " >> /tmp/patch_schema.sh
         printf " run-patched-sql-files " >> /tmp/patch_schema.sh
         printf " -logger org.apache.tools.ant.NoBannerLogger " >> /tmp/patch_schema.sh
         printf " -logfile /tmp/patch_oim_wls.log " >> /tmp/patch_schema.sh
         printf " -DoperationsDB.host=$DB_HOST" >> /tmp/patch_schema.sh
         printf " -DoperationsDB.port=$DB_PORT " >> /tmp/patch_schema.sh
         printf " -DoperationsDB.serviceName=$DB_SERVICE " >> /tmp/patch_schema.sh
         printf " -DoperationsDB.user=${RCU_PREFIX}_OIM " >> /tmp/patch_schema.sh
         printf " -DOIM.DBPassword=$RCUPWD " >> /tmp/patch_schema.sh
         printf " -Dojdbc=/u01/oracle/oracle_common/modules/oracle.jdbc/ojdbc8.jar \n" >> /tmp/patch_schema.sh
         printf "exit \n" >> /tmp/patch_schema.sh


         kubectl cp /tmp/create_schema.sh  $NAMESPACE/helper:/tmp
         kubectl exec -n $NAMESPACE -ti helper -- /bin/bash < /tmp/patch_schema.sh > $LOGDIR/patch_schema.log 2>&1
         kubectl cp  $NAMESPACE/helper:/tmp/patch_oim_wls.log $LOGDIR/patch_oim_wls.log > /dev/null
         grep -q "BUILD SUCCESSFUL" $LOGDIR/patch_oim_wls.log
         if [ $? = 0 ]
         then
              echo "Success"
         else
              echo "Fail"
              exit 1
         fi
      fi

      ET=`date +%s`
      print_time STEP "Create Schemas" $ST $ET >> $LOGDIR/timings.log
}

drop_schemas ()
{
      NAMESPACE=$1
      DB_HOST=$2
      DB_PORT=$3
      DB_SERVICE=$4
      RCU_PREFIX=$5
      SCHEMA_TYPE=$6
      SYSPWD=$7
      RCUPWD=$8

      echo -n "Dropping Schemas -"
      OAM_SCHEMAS=" -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component STB -component OAM "
      OIG_SCHEMAS=" -component MDS -component IAU -component SOAINFRA -component IAU_APPEND -component IAU_VIEWER -component OPSS -component WLS -component STB -component OIM -component UCSUMS"

      printf "$SYSPWD\n" > /tmp/pwd.txt
      printf "$RCUPWD\n" >> /tmp/pwd.txt

      printf "#!/bin/bash\n" > /tmp/drop_schema.sh
      printf "/u01/oracle/oracle_common/bin/rcu -silent -dropRepository -databaseType ORACLE " >> /tmp/drop_schema.sh
      printf " -connectString $DB_HOST:$DB_PORT/$DB_SERVICE " >> /tmp/drop_schema.sh
      printf " -dbUser sys -dbRole sysdba -selectDependentsForComponents true " >> /tmp/drop_schema.sh
      printf " -schemaPrefix $RCU_PREFIX" >> /tmp/drop_schema.sh
 
      if [ "$SCHEMA_TYPE" = "OIG" ]
      then
           printf "$OIG_SCHEMAS" >> /tmp/drop_schema.sh
      elif [ "$SCHEMA_TYPE" = "OAM" ]
      then
           printf "$OAM_SCHEMAS" >> /tmp/drop_schema.sh
      else
           printf "\nInvalid Schema Type: $SCHEMA_TYPE \n"
           exit 1
      fi

      printf " -f < /tmp/pwd.txt \n" >> /tmp/drop_schema.sh
      printf " exit \n" >> /tmp/drop_schema.sh


      kubectl cp /tmp/pwd.txt  $NAMESPACE/helper:/tmp
      kubectl cp /tmp/drop_schema.sh  $NAMESPACE/helper:/tmp

      kubectl exec -n $NAMESPACE -ti helper -- /bin/bash < /tmp/drop_schema.sh

      echo "Success"
}

# Check to see if a Kubernetes Pod is running
#
check_running()
{
    NAMESPACE=$1
    SERVER_NAME=$2
    DELAY=$3
    
    printf "\t\t\tChecking $SERVER_NAME "
    if [ "$SERVER_NAME" = "adminserver" ]
    then
        sleep 120
    else 
        sleep ${DELAY:=10}
    fi
    X=0
    while [ "$X" = "0" ]
    do

        POD=`kubectl -n $NAMESPACE get pods -o wide | grep $SERVER_NAME | head -1 `
        if [ "$POD" = "" ]
        then
             JOB_STATUS=`kubectl -n $NAMESPACE get pod -o wide | grep infra-domain-job | awk '{ print $3 }'`
             if [ "$JOB_STATUS" = "Error" ]
             then
                  echo "Domain Creation has an Error"
             else
                  echo "Server Does not exist"
             fi
             exit 1
        fi
        PODSTATUS=`echo $POD | awk '{ print $3 }'`
        RUNNING=`echo $POD | awk '{ print $2 }' | cut -f1 -d/`
        NODE=`echo $POD | awk '{ print $7 }'`

        if [ "$PODSTATUS" = "Error" ]
        then
              echo "Pod $SERVER_NAME has failed to start."
              X=2
        elif [ "$PODSTATUS" = "ErrImagePull" ] ||  [ "$PODSTATUS" = "ImagePullBackOff" ]
        then
              echo "Pod $SERVER_NAME has failed to Obtain the image - Check Image is present on $NODE."
              X=2
        elif [ "$PODSTATUS" = "CrashLoopBackOff" ]
        then
              echo "Pod $SERVER_NAME has failed to Start - Check Image is present on $NODE."
              X=2
        fi
        if [ "$SERVER_NAME" = "oim-server1" ]
        then
              kubectl logs -n $OIGNS ${OIG_DOMAIN_NAME}-oim-server1 | grep -q "BootStrap configuration Failed"
              if [ $? = 0 ]
              then
                 echo "BootStrap configuration Failed - check kubectl logs -n $OIGNS ${OIG_DOMAIN_NAME}-oim-server1"
                 X=3
              fi
        fi
        if [ ! "$RUNNING" = "0" ] 
        then
           echo " Running"
           X=1
        elif [ $X -gt 1 ]
        then
             exit $X
        else 
             echo -e ".\c"
             sleep 60
        fi

    done
}

# Check whether a Kubernetes pod has shutdown
#
check_stopped()
{
    NAMESPACE=$1
    SERVER_NAME=$2
    
    printf "\t\t\tStopping $SERVER_NAME "

    X=0
    while [ "$X" = "0" ]
    do
    
        POD=`kubectl --namespace $NAMESPACE get pod | grep $SERVER_NAME `
        PODSTATUS=`echo $POD | awk '{ print $3 }'`
        RUNNING=`echo $POD | awk '{ print $2 }'`
        if [ "$RUNNING" = "1/1" ]
        then
           echo -e ".\c"
           sleep 10
        else
             echo "Stopped"
           X=1
        fi
    done
}

# Check an LDAP User exists
#
check_ldap_user()
{
  userid=$1

  ST=`date +%s`
  print_msg "Checking User $userid exists in LDAP"

  LDAP_CMD="/u01/oracle/user_projects/${OUD_POD_PREFIX}-oud-ds-rs-0/OUD/bin/ldapsearch -h ${OUD_POD_PREFIX}-oud-ds-rs-lbr-ldap.${OUDNS}.svc.cluster.local -p 1389 -D"
  LDAP_CMD="$LDAP_CMD ${LDAP_ADMIN_USER} -w ${LDAP_ADMIN_PWD} -b cn=${LDAP_SYSTEMIDS},${LDAP_SEARCHBASE} uid=${userid} "

  USER=`kubectl exec -n $OUDNS -ti ${OUD_POD_PREFIX}-oud-ds-rs-0 -c oud-ds-rs -- $LDAP_CMD | grep uid`

  if [ "$USER" = "" ]
  then
     echo "User Does not exist - Fix LDAP before continuing"
     exit 1
  else
     echo " Exists "
  fi

   ET=`date +%s`

  print_time STEP "Start $DOMAIN_NAME Domain" $ST $ET >> $LOGDIR/timings.log
}

# Start a WebLogic Domain
#
start_domain()
{
  NAMESPACE=$1
  DOMAIN_NAME=$2

  ST=`date +%s`
  print_msg "Starting Domain $DOMAIN_NAME "
  echo
  kubectl -n $NAMESPACE patch domains $DOMAIN_NAME --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "IF_NEEDED" }]' > /dev/null

  sleep 120
  check_running $NAMESPACE adminserver

  sleep 5
  if [ "$DOMAIN_NAME" = "$OAM_DOMAIN_NAME" ]
  then
       check_running $NAMESPACE oam-server1
       check_running $NAMESPACE oam-policy-mgr1
  else
       check_running $NAMESPACE soa-server1
       check_running $NAMESPACE oim-server1
  fi
 
  ET=`date +%s`

  print_time STEP "Start $DOMAIN_NAME Domain" $ST $ET >> $LOGDIR/timings.log      

}

# Stop a Running WebLogic Domain
#
stop_domain()
{
  NAMESPACE=$1
  DOMAIN_NAME=$2

  print_msg "Stopping Domain $DOMAIN_NAME "
  echo
  ST=`date +%s`
  kubectl -n $NAMESPACE patch domains $DOMAIN_NAME --type='json' -p='[{"op": "replace", "path": "/spec/serverStartPolicy", "value": "NEVER" }]' > /dev/null

  check_stopped $NAMESPACE adminserver
  ET=`date +%s`

  print_time STEP "Stop $DOMAIN_NAME Domain" $ST $ET >> $LOGDIR/timings.log
}

# Print a message in the timings.log to state how long a step has taken
#
print_time()
{
   type=$1
   descr=$2
   start_time=$3
   end_time=$4
   time_taken=$((end_time-start_time))
   if [ "$type" = "STEP" ]
   then
       eval "echo  Step $STEPNO : Time taken to execute step $descr: $(date -ud "@$time_taken" +' %H hours %M minutes %S seconds')"
   else
       echo
       eval "echo  Total Time taken to $descr: $(date -ud "@$time_taken" +' %H hours %M minutes %S seconds')"
   fi
     
}

# Print a message to show the step being executed
#
print_msg()
{
   msg=$1
   if [ "$STEPNO" = "" ]
   then
       printf "$msg"
   else
       printf "Executing Step $STEPNO:\t$msg - " 
   fi
     
}

# Print Success/Failed Message dependent on status
#
print_status()
{
   statuscode=$1
   logfile=$2
   if [ $1 = 0 ]
   then
       echo "Success"
   else
       echo "Failed - Check Logfile : $logfile"
       exit 1
   fi
}

# Obtain an SSL certificate from a load balancer
#
get_lbr_certificate()
{
     LBRHOST=$1
     LBRPORT=$2
    
     print_msg "Obtaining Load Balancer Certificate $LBRHOST:$LBRPORT"
     ST=`date +%s`
     openssl s_client -connect ${LBRHOST}:${LBRPORT} -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM > $WORKDIR/${LBRHOST}.pem
     if [ $? = 0 ]
     then
        echo "Success"
        return 0
     else
        echo "Fail"
     return 1
     fi

     ET=`date +%s`
     print_time STEP "Obtaining Load Balancer Certificate $LBRHOST:$LBRPORT" $ST $ET >> $LOGDIR/timings.log
}

# Copy OHS config Files to OHS servers
#
copy_ohs_config()
{
     OHS_SERVERS=$1

     print_msg "Copying OHS configuration Files to OHS Servers"
     printf "\n\t\t\tOHS Server $OHS_HOST1 - "

     scp $LOCAL_WORKDIR/OHS/$OHS_HOST1/*vh.conf $OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/moduleconf/ > $LOGDIR/copy_ohs.log 2>&1
     print_status $? $LOGDIR/copy_ohs.log

     if [ "$COPY_WG_FILES" = "true" ]
     then
        scp -r $LOCAL_WORKDIR/OHS/webgate/wallet $OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
        scp -r $LOCAL_WORKDIR/OHS/webgate/ObAccessClient.xml  $OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
        scp -r $LOCAL_WORKDIR/OHS/webgate/password.xml  $OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
        scp -r $LOCAL_WORKDIR/OHS/webgate/aaa*  $OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/webgate/config/simple >> $LOGDIR/copy_ohs.log 2>&1
     fi

     printf "\t\t\tRestarting Oracle HTTP Server $OHS_HOST1 - "
     ssh $OHS_HOST1 "$OHS_DOMAIN/bin/restartComponent.sh $OHS1_NAME" >> $LOGDIR/copy_ohs.log 2>&1
     print_status $? $LOGDIR/copy_ohs.log

     if [ ! "$OHS_HOST2" = "" ]
     then
         printf "\n\t\t\tOHS Server $OHS_HOST2 - "

         scp $LOCAL_WORKDIR/OHS/$OHS_HOST2/*vh.conf $OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/moduleconf/ >> $LOGDIR/copy_ohs.log 2>&1
         print_status $? $LOGDIR/copy_ohs.log
    
         if [ "$COPY_WG_FILES" = "true" ]
         then
            scp -r $LOCAL_WORKDIR/OHS/webgate/wallet $OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
            scp -r $LOCAL_WORKDIR/OHS/webgate/ObAccessClient.xml  $OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
            scp -r $LOCAL_WORKDIR/OHS/webgate/password.xml  $OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/webgate/config >> $LOGDIR/copy_ohs.log 2>&1
            scp -r $LOCAL_WORKDIR/OHS/webgate/aaa*  $OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/webgate/config/simple >> $LOGDIR/copy_ohs.log 2>&1
         fi

         printf "\t\t\tRestarting Oracle HTTP Server $OHS_HOST2 - "
         ssh $OHS_HOST2 "$OHS_DOMAIN/bin/restartComponent.sh $OHS2_NAME" >> $LOGDIR/copy_ohs.log 2>&1
         print_status $? $LOGDIR/copy_ohs.log
     fi


     ET=`date +%s`
     print_time STEP "Copying OHS config" $ST $ET >> $LOGDIR/timings.log
}

# Determine where a script stopped to enable continuation
#
function get_progress()
{
    if [ -f $LOGDIR/progressfile ]
    then
        cat $LOGDIR/progressfile
    else
        echo 0
    fi
}

# Increment Step count
#
new_step()
{
    STEPNO=$((STEPNO+1))
}

# Increment progress count
#
update_progress()
{
    PROGRESS=$((PROGRESS+1))
    echo $PROGRESS > $LOGDIR/progressfile
}

# Check that a loadbalancer virtual host has been configured
#
function check_lbr()
{

    host=$1
    port=$2

    print_msg "Checking Loadbalancer $1 port $2 : "

    nc -z $host $port

    if [ $? = 0 ]
    then
       echo "Success"
       return 0
    else
       echo "Fail"
       return 1
    fi
}

# Change Kibana ELK Host
#
update_kibana_host()
{
   namespace=$1
   confmap=$2

   ST=`date +%s`
   print_msg "Updating Logstash Host"
   kubectl get cm $confmap -n $namespace -o yaml | sed '/kind:/,$d' > $WORKDIR/kibana_cm.yaml
   sed -i "s/hosts.*/hosts => [\"$ELK_HOST\"]/"  $WORKDIR/kibana_cm.yaml

   echo kubectl patch cm $confmap -n $namespace --patch-file $WORKDIR/kibana_cm.yaml > $LOGDIR/update_kibana_host.log
   kubectl patch cm $confmap -n $namespace --patch-file $WORKDIR/kibana_cm.yaml >> $LOGDIR/update_kibana_host.log
   print_status $? $LOGDIR/update_kibana_host.log

   ET=`date +%s`
   print_time STEP "Update logstash host" $ST $ET >> $LOGDIR/timings.log
}

# Create cert Configmap
#
create_cert_cm()
{
   namespace=$1

   ST=`date +%s`
   print_msg "Creating Logstash Certificate configmap"
   certfile=$LOCAL_WORKDIR/ELK/ca.crt

   if [ ! -f $certfile ]
   then 
      echo "Certificate File does not exist."
      exit 1
   fi

   kubectl create configmap elk-cert --from-file=$certfile -n $namespace > $LOGDIR/logstash_cert.log 2>&1
   print_status $? $LOGDIR/logstash_cert.log

   ET=`date +%s`
   print_time STEP "Creating Logstash Certificate Configmap" $ST $ET >> $LOGDIR/timings.log
}

# Create Logstash Pod
#
create_logstash()
{
   namespace=$1

   ST=`date +%s`
   print_msg "Deploy Logstash into $namespace"

   cp $TEMPLATE_DIR/logstash.yaml $WORKDIR 

   if [ "$namespace" = "$OAMNS" ]
   then 
      PVC=${OAM_DOMAIN_NAME}-domain-pv
      MP=`kubectl describe domains $OAM_DOMAIN_NAME -n $OAMNS | grep "Mount Path" | sed 's/Mount Path: //'`
      update_variable "<DOMAIN_NAME>" $OAM_DOMAIN_NAME $WORKDIR/logstash.yaml
      update_variable "<MOUNT_PATH>" "$MP" $WORKDIR/logstash.yaml
   elif  [ "$namespace" = "$OIGNS" ]
   then
      PVC=${OIM_DOMAIN_NAME}-domain-pv
      MP=`kubectl describe domains $OIG_DOMAIN_NAME -n $OIGNS | grep "Mount Path" | sed 's/Mount Path: //'`
      update_variable "<DOMAIN_NAME>" $OIG_DOMAIN_NAME $WORKDIR/logstash.yaml
      update_variable "<MOUNT_PATH>" "$MP" $WORKDIR/logstash.yaml
   elif  [ "$namespace" = "$OIRINS" ]
   then
      update_variable "<OIRI_DING_SHARE>" $OIRI_DING_SHARE $WORKDIR/logstash.yaml
      update_variable "<PVSERVER>" $PVSERVER $WORKDIR/logstash.yaml
   elif  [ "$namespace" = "$OUDNS" ]
   then
      update_variable "<OUD_POD_PREFIX>" $OUD_POD_PREFIX $WORKDIR/logstash.yaml
   fi

   update_variable "<NAMESPACE>" $namespace $WORKDIR/logstash.yaml
   update_variable "<ELK_VER>" $ELK_VER $WORKDIR/logstash.yaml
 
   kubectl create -f $WORKDIR/logstash.yaml > $LOGDIR/logstash.log 2>&1
   print_status $? $LOGDIR/logstash.log

   ET=`date +%s`
   print_time STEP "Update logstash host" $ST $ET >> $LOGDIR/timings.log
}

# Deploy Elastic Search Operator
#
install_elk_operator()
{

   ST=`date +%s`
   print_msg "Deploy Elastic Search Operator"

   printf "\n\t\t\tAdd Helm Repository - "
   helm repo add elastic https://helm.elastic.co > $LOGDIR/operator.log 2>&1
   print_status $? $LOGDIR/operator.log

   printf "\t\t\tUpdate Helm Repository - "
   helm repo update >> $LOGDIR/operator.log 2>&1
   print_status $? $LOGDIR/operator.log

   printf "\t\t\tInstall Operator - "

   helm install elastic-operator elastic/eck-operator -n $ELKNS --create-namespace >> $LOGDIR/operator.log 2>&1
   print_status $? $LOGDIR/operator.log
  
   check_running $ELKNS elastic-operator

   ET=`date +%s`
   print_time STEP "Deploy Elastic Search Operator" $ST $ET >> $LOGDIR/timings.log
}

# Deploy Elastic Search and Kibana
#
deploy_elk()
{

   ST=`date +%s`
   print_msg "Create Elastic Search Cluster "

   cp $TEMPLATE_DIR/elk_cluster.yaml $WORKDIR 
   filename=$WORKDIR/elk_cluster.yaml

   update_variable "<ELKNS>" $ELKNS $filename
   update_variable "<ELK_VER>" $ELK_VER $filename
   update_variable "<ELK_STORAGE>" $ELK_STORAGE $filename

   kubectl create -f $filename > $LOGDIR/elk.log 2>&1
   print_status $? $LOGDIR/elk.log

   ET=`date +%s`
   print_time STEP "Create Elastic Search cluster" $ST $ET >> $LOGDIR/timings.log
}

deploy_kibana()
{

   ST=`date +%s`
   print_msg "Create Kibana"

   cp $TEMPLATE_DIR/kibana.yaml $WORKDIR 
   filename=$WORKDIR/kibana.yaml

   update_variable "<ELKNS>" $ELKNS $filename
   update_variable "<ELK_VER>" $ELK_VER $filename

   kubectl create -f $filename > $LOGDIR/kibana.log 2>&1
   print_status $? $LOGDIR/kibana.log

   ET=`date +%s`
   print_time STEP "Create Kibana" $ST $ET >> $LOGDIR/timings.log
}

create_elk_nodeport()
{

   ST=`date +%s`
   print_msg "Create Node Port Services"

   printf "\n\t\t\tKibana NodePort Service - "
   cp $TEMPLATE_DIR/kibana_nodeport.yaml $WORKDIR 
   filename=$WORKDIR/kibana_nodeport.yaml

   update_variable "<ELKNS>" $ELKNS $filename
   update_variable "<ELK_KIBANA_K8>" $ELK_KIBANA_K8 $filename

   kubectl create -f $filename > $LOGDIR/kibana_nodeport.log 2>&1
   print_status $? $LOGDIR/kibana_nodeport.log

   printf "\t\t\tELK NodePort Service - "
   cp $TEMPLATE_DIR/elk_nodeport.yaml $WORKDIR 
   filename=$WORKDIR/elk_nodeport.yaml

   update_variable "<ELKNS>" $ELKNS $filename
   update_variable "<ELK_K8>" $ELK_K8 $filename

   kubectl create -f $filename > $LOGDIR/elk_nodeport.log 2>&1
   print_status $? $LOGDIR/elk_nodeport.log

   ET=`date +%s`
   print_time STEP "Create NodePort Services" $ST $ET >> $LOGDIR/timings.log
}

update_elk_password()
{

   ST=`date +%s`
   print_msg "Obtain Elastic Search Password"

   ELK_PWD=`kubectl get secret elasticsearch-es-elastic-user -n $ELKNS -o go-template='{{.data.elastic | base64decode}}'`
   replace_password ELK_PWD $ELK_PWD $PWDFILE
   if [ "$ELK_PWD" = "" ]
   then
      echo "Failed to execute:kubectl get secret elasticsearch-es-elastic-user -n $ELKNS -o go-template='{{.data.elastic | base64decode}}'" > $LOGDIR/elk_pwd.log
      echo "Failed - See logfile $LOGDIR/elk_pwd.log"
      exit 1 
   else
      echo "Success"
   fi


   ET=`date +%s`
   print_time STEP "Obtain ELK Password" $ST $ET >> $LOGDIR/timings.log
}

get_elk_cert()
{

   ST=`date +%s`
   print_msg "Obtain Elastic Search Certificate"

   kubectl cp $ELKNS/elasticsearch-es-default-0:/usr/share/elasticsearch/config/http-certs/..data/ca.crt $WORKDIR/ca.crt >  $LOGDIR/elk_cert.log
   print_status $? $LOGDIR/elk_cert.log

   ET=`date +%s`

   print_time STEP "Obtain ELK certificate" $ST $ET >> $LOGDIR/timings.log
}

create_elk_role()
{

   print_msg "Creating Elastic Search Role"
   ST=`date +%s`

   ROLE_NAME=logstash_writer

   ADMINURL=https://$K8_WORKER_HOST1:$ELK_K8

   REST_API="'$ADMINURL/_security/role/$ROLE_NAME'"

   USER=`encode_pwd elastic:${ELK_PWD}`

   PUT_CURL_COMMAND="curl --location -k --request  PUT "
   CONTENT_TYPE="-H 'Content-Type: application/json' -H 'Authorization: Basic $USER'"
   PAYLOAD="-d '{\"cluster\": [\"manage_index_templates\", \"monitor\", \"manage_ilm\"],\"indices\": [ {\"names\": [ \"logs*\" ],"
   PAYLOAD=$PAYLOAD"\"privileges\": [\"write\",\"create\",\"create_index\",\"manage\",\"manage_ilm\"] } "
   PAYLOAD=$PAYLOAD" ] }'"

   echo "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" > $LOGDIR/elk_role.log 2>&1
   eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/elk_role.log 2>&1
   grep -q "\"created\":true"  $LOGDIR/elk_role.log
   print_status $? $LOGDIR/elk_role.log 2>&1

   ET=`date +%s`
   print_time STEP "Create Elastic Search Role" $ST $ET >> $LOGDIR/timings.log
}

create_elk_user()
{

   print_msg "Creating Elastic Search User"
   ST=`date +%s`


   ADMINURL=https://$K8_WORKER_HOST1:$ELK_K8

   REST_API="'$ADMINURL/_security/user/$ELK_USER'"

   USER=`encode_pwd elastic:${ELK_PWD}`

   PUT_CURL_COMMAND="curl --location -k --request  PUT "
   CONTENT_TYPE="-H 'Content-Type: application/json' -H 'Authorization: Basic $USER'"
   PAYLOAD="-d '{\"password\": \"$ELK_USER_PWD\", \"roles\" : [ \"logstash_writer\"],\"full_name\" : \"Internal Logstash User\""
   PAYLOAD=$PAYLOAD"  }'"

   echo "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" > $LOGDIR/elk_user.log 2>&1
   eval "$PUT_CURL_COMMAND $REST_API $CONTENT_TYPE $PAYLOAD" >> $LOGDIR/elk_user.log 2>&1
   grep -q "\"created\":true"  $LOGDIR/elk_user.log
   print_status $? $LOGDIR/elk_user.log 2>&1

   ET=`date +%s`
   print_time STEP "Create Elastic Search User" $ST $ET >> $LOGDIR/timings.log
}

check_ingress()
{
   NAMESPACE=$1
   INGRESS_NAME=$2

   print_msg "Checking Ingress $INGRESS_NAME exists in $NAMESPACE"
   ST=`date +%s`

   kubectl get ingress -n $NAMESPACE > $LOGDIR/ingress_${INGRESS_NAME}.log 2>&1

   grep -q "No resources found" $LOGDIR/ingress_${INGRESS_NAME}.log

   if [ $? = 0 ]
   then
       echo "Failed - See logfile $LOGDIR/ingress_${INGRESS_NAME}.log"
       exit 1
   else
       echo "Success"
   fi

}
