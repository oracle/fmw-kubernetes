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
. $RSPFILE
export SAMPLES_DIR=`echo $SAMPLES_REP | awk -F  "/" '{print $NF}' | sed 's/.git//'`

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

    ST=`date +%s`
    print_msg "Creating Container Registry Secret in namespace $namespace"
    
    kubectl create secret -n $namespace docker-registry regcred --docker-server=$registry --docker-username=$username --docker-password=$pass > $LOGDIR/create_reg_secret.log 2>&1
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
    cd $WORKDIR/samples
    helm install weblogic-kubernetes-operator charts/weblogic-operator --namespace $OPERNS --set image=$OPER_IMAGE:$OPER_VER --set serviceAccount=$OPER_ACT \
            --set "enableClusterRoleBinding=true" \
            --set "javaLoggingLevel=FINE" \
            --set "domainNamespaceSelectionStrategy=LabelSelector" \
            --set "domainNamespaceLabelSelector=weblogic-operator\=enabled" \
            --wait > $LOGDIR/install_oper.log 2>&1
    print_status $? $LOGDIR/install_oper.log
    ET=`date +%s`
    print_time STEP "Install Operator" $ST $ET >> $LOGDIR/timings.log

}
upgrade_operator()
{
    nslist=$1
    ST=`date +%s`
    
    print_msg  "Adding Namespaces:$nslist to Operator"
    cd $WORKDIR/weblogic-kubernetes-operator
    helm upgrade --reuse-values --namespace $OPERNS --set "domainNamespaces={$nslist}" --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator > $LOGDIR/upgrade_operator.log 2>&1
    print_status $? $LOGDIR/upgrade_operator.log
    ET=`date +%s`
    print_time STEP "Add Namespaces:$nslist to Operator" $ST $ET >> $LOGDIR/timings.log
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

   PORTS=`kubectl get service -n $NS | grep NodePort | grep $SVC | awk '{ print $5 }'`

   PORT1=(`echo $PORTS | cut -f1 -d, | sed 's/\/TCP//;s/:/ /'`)
   PORT2=(`echo $PORTS | cut -f2 -d, | sed 's/\/TCP//;s/:/ /'`)

   echo $PORTS | grep -q ,

   if [ $? = 1 ]
   then 
        echo  ${PORT1[1]}
   else
       if [ ${PORT1[0]} = 80 ]
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
      grep AlreadyExists -q $LOGDIR/create_svc.log
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
   kubectl exec -n $namespace -ti $domain_name-adminserver -- /u01/oracle/oracle_common/common/bin/wlst.sh $command 2> /dev/null
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

     #echo $val | sed 's/\//\\\//g'
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
     NEWVAL=$(echo $VAL | sed 's/\//\\\//g')
     sed -i "s/$VAR/$NEWVAL/g" $FILE
     if [ "$?" = "1" ]
     then 
        echo "Error Modifying File: $FILE"
     fi
}

#Get the path and name of a docker image file
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

      printf "#!/bin/bash\n" > $WORKDIR/create_schema.sh
      printf "/u01/oracle/oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE " >> $WORKDIR/create_schema.sh
      printf " -connectString $DB_HOST:$DB_PORT/$DB_SERVICE " >> $WORKDIR/create_schema.sh
      printf " -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true -selectDependentsForComponents true " >> $WORKDIR/create_schema.sh
      printf " -schemaPrefix $RCU_PREFIX" >> $WORKDIR/create_schema.sh
 
      if [ "$SCHEMA_TYPE" = "OIG" ]
      then
           printf "$OIG_SCHEMAS" >> $WORKDIR/create_schema.sh
      elif [ "$SCHEMA_TYPE" = "OAM" ]
      then
           printf "$OAM_SCHEMAS" >> $WORKDIR/create_schema.sh
      else
           printf "\nInvalid Schema Type: $SCHEMA_TYPE \n"
           exit 1
      fi

      printf " -f < /tmp/pwd.txt \n" >> $WORKDIR/create_schema.sh
      printf " exit \n" >> $WORKDIR/create_schema.sh

      kubectl cp /tmp/pwd.txt  $NAMESPACE/helper:/tmp
      kubectl cp $WORKDIR/create_schema.sh  $NAMESPACE/helper:/tmp
      kubectl exec -n $NAMESPACE -ti helper -- /bin/bash < /tmp/create_schema.sh > $LOGDIR/create_schemas.log 2>&1
      print_status $? $LOGDIR/create_schemas.log
      if [ "$SCHEMA_TYPE" = "OIG" ]
      then
         printf "\t\t\tPatching OIM Schema - " 
         printf "/u01/oracle/oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin/ant " >> $WORKDIR/patch_schema.sh
         printf " -f /u01/oracle/idm/server/setup/deploy-files/automation.xml " >> $WORKDIR/patch_schema.sh
         printf " run-patched-sql-files " >> $WORKDIR/patch_schema.sh
         printf " -logger org.apache.tools.ant.NoBannerLogger " >> $WORKDIR/patch_schema.sh
         printf " -logfile /tmp/patch_oim_wls.log " >> $WORKDIR/patch_schema.sh
         printf " -DoperationsDB.host=$DB_HOST" >> $WORKDIR/patch_schema.sh
         printf " -DoperationsDB.port=$DB_PORT " >> $WORKDIR/patch_schema.sh
         printf " -DoperationsDB.serviceName=$DB_SERVICE " >> $WORKDIR/patch_schema.sh
         printf " -DoperationsDB.user=${RCU_PREFIX}_OIM " >> $WORKDIR/patch_schema.sh
         printf " -DOIM.DBPassword=$RCUPWD " >> $WORKDIR/patch_schema.sh
         printf " -Dojdbc=/u01/oracle/oracle_common/modules/oracle.jdbc/ojdbc8.jar \n" >> $WORKDIR/patch_schema.sh
         printf "exit \n" >> $WORKDIR/patch_schema.sh


         kubectl cp $WORKDIR/patch_schema.sh  $NAMESPACE/helper:/tmp
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
    
    printf "\t\t\tChecking $SERVER_NAME "
    if [ "$SERVER_NAME" = "adminserver" ]
    then
        sleep 120
    else 
        sleep 10
    fi
    X=0
    while [ "$X" = "0" ]
    do

        POD=`kubectl --namespace $NAMESPACE get pod -o wide | grep $SERVER_NAME `
        if [ "$POD" = "" ]
        then
             JOB_STATUS=`kubectl --namespace $NAMESPACE get pod -o wide | grep infra-domain-job | awk '{ print $3 }'`
             if [ "$JOB_STATUS" = "Error" ]
             then
                  echo "Domain Creation has an Error"
             else
                  echo "Server Does not exist"
             fi
             exit 1
        fi
        PODSTATUS=`echo $POD | awk '{ print $3 }'`
        RUNNING=`echo $POD | awk '{ print $2 }'`
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
        if [ "$RUNNING" = "1/1" ] 
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
           sleep 60
        else
             echo "Stopped"
           X=1
        fi
    done
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

     scp $LOCAL_WORKDIR/OHS/$OHS_HOST1/* $OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/moduleconf/ > $LOGDIR/copy_ohs.log 2>&1
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

         scp $LOCAL_WORKDIR/OHS/$OHS_HOST2/* $OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/moduleconf/ >> $LOGDIR/copy_ohs.log 2>&1
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

