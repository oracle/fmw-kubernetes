#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
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

SCRIPTDIR=/docker/scripts
RSPFILE=$SCRIPTDIR/responsefile/idm.rsp
SSH="ssh -q"

# Create local Directories
#
create_local_workdir()
{
    ST=`date +%s`
    if ! [ -d $WORKDIR ]
    then
        echo "Creating Working Directory :$WORKDIR"
        mkdir -p $WORKDIR
    else
        echo "Using Working Directory : $WORKDIR"
    fi
    ET=`date +%s`
}

create_logdir()
{
    ST=`date +%s`
    if ! [ -d $LOGDIR ]
    then
        echo "Creating Log Directory :$LOGDIR"
        mkdir -p $LOGDIR
    else
        echo "Using Log Directory : $LOGDIR"
    fi
    ET=`date +%s`
    print_time STEP "Create Work Directory" $ST $ET >> $LOGDIR/timings.log
}

#
check_oper_exists()
{
   echo -n "Check Operator has been installed - "
   kubectl get namespaces | grep -q $OPERNS 
   if [ $? = 0 ]
   then
       echo "Success"
   else
       echo "Fail Install Operator before continuing."
       exit 1
   fi
}

# Helm Functions
#
upgrade_operator()
{
    nslist=$1
    ST=`date +%s`
    
    echo "Adding Namespaces:$nslist to Operator"
    cd $WORKDIR/weblogic-kubernetes-operator
    helm upgrade --reuse-values --namespace $OPERNS --set "domainNamespaces={$nslist}" --wait weblogic-kubernetes-operator kubernetes/charts/weblogic-operator > $LOGDIR/upgrade_operator.log 2>&1
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
    kubectl get nodes | grep -v Disabled | sed '/NAME/d' | awk '{ print $1 }'
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
    kubectl get crd | grep -q domains.weblogic.oracle
    if [ $? = 0 ]
    then
          kubectl delete crd domains.weblogic.oracle
    fi
}

# Create Namespace if it does not already exist
#
create_namespace()
{
   NS=$1
   ST=`date +%s`
   echo -n "Creating Namespace: $NS - "
   kubectl get namespace $NS >/dev/null 2> /dev/null
   if [ "$?" = "0" ]
   then
      echo "Already Exists"
   else
       kubectl create namespace $NS > $LOGDIR/create_ns.log 2>&1
       echo "Success"
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
   kubectl create serviceaccount -n $nsp $actname
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
   if ! [ "$?" = "0" ]
   then
      echo "Failed to copy $filename."
      exit 1
   fi
}

# Determine the status of a Persistent Volume
#
function check_pv_ok()
{
    DOMAIN_NAME=$1
    status=$(kubectl get pv | grep $DOMAIN_NAME-domain-pv | awk '{ print $5}' )
    if [ "$status" = "Bound" ]
    then
        return 0
    else
        return 1
    fi
}

# Determine the status of a Persistent Volume Claim
#
function check_pvc_ok()
{
    domain_name=$1
    namespace=$2
    status=$(kubectl get pvc -n $namespace | grep $domain_name-domain-pvc | awk '{ print $2}' )
    if [ "$status" = "Bound" ]
    then
        return 0
    else
        return 1
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
   echo -n "Creating a Kubernetes Domain Secret - "
   cd $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-weblogic-domain-credentials 
   ./create-weblogic-credentials.sh -u $wlsuser -p $wlspwd -n $namespace -d $domain_name -s $domain_name-credentials > $LOGDIR/domain_secret.log  2>&1

   if [ "$?" = "0" ]
   then
        echo "Success"
   else
        echo "Fail"
        exit 1
   fi
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
   echo -n "Creating a Kubernetes RCU Secret - "
   cd $WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-rcu-credentials
   ./create-rcu-credentials.sh -u $rcuprefix -p $rcupwd -a sys -q $syspwd -d $domain_name -n $namespace -s $domain_name-rcu-credentials> $LOGDIR/rcu_secret.log  2>&1

   if [ "$?" = "0" ]
   then
        echo "Success"
   else
        echo "Fail"
        exit 1
   fi
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
   echo -n "Creating Work directory inside container - "
   kubectl exec -n $namespace -ti $domain_name-adminserver -- mkdir -p $K8_WORKDIR
   if [ "$?" = "0" ]
   then 
      echo "Success"
   else
      echo "Fail"
      exit 1
   fi
   echo -n "Creating Keystores directory inside container - "
   kubectl exec -n $namespace -ti $domain_name-adminserver -- mkdir -p $PV_MOUNT/keystores
   if [ "$?" = "0" ]
   then 
      echo "Success"
   else
      echo "Fail"
      exit 1
   fi
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
   if ! [ "$?" = "0" ]
   then 
      echo "Failed to execute command: kubectl exec -n $namespace -ti $domain_name-adminserver -- $command"
      exit 1
   fi
}

# Execute a command inside the Kubernetes container
#
run_wlst_command()
{
   namespace=$1
   domain_name=$2
   command=$3
  
   kubectl exec -n $namespace -ti $domain_name-adminserver -- /u01/oracle/oracle_common/common/bin/wlst.sh $command
   if ! [ "$?" = "0" ]
   then 
      echo "Failed to Execute wlst command: $command"
      exit 1
   fi
}

# Download Samples to Directory
#
download_samples()
{
    workdir=$1
    ST=`date +%s`
    cd $workdir
    echo "Downloading Oracle Identity Management Samples"
    git clone https://github.com/oracle/fmw-kubernetes.git
    ET=`date +%s`

    print_time STEP "Download IDM Samples" $ST $ET >> $LOGDIR/timings.log
}

# Download WebLogic Kubernetes Operator to Directory
#
download_operator_samples()
{
    workdir=$1
    ST=`date +%s`
    cd $workdir
    echo "Downloading Oracle WebLogic Kubernetes Operator Config"
    git clone https://github.com/oracle/weblogic-kubernetes-operator.git --branch release/$OPER_VER
    ET=`date +%s`

    print_time STEP "Download Operator Samples" $ST $ET >> $LOGDIR/timings.log
}

# Create helper pod
#
create_helper_pod ()
{
   NS=$1
   IMAGE=$2

   ST=`date +%s`
   echo -n "Creating Helper Pod - "
   kubectl get pod -n $NS helper > /dev/null 2> /dev/null
   if [ "$?" = "0" ]
   then
       echo "Already Exists"
   else
       kubectl run helper  --image oracle/$IMAGE:12.2.1.4.0 -n $NS -- sleep infinity > $LOGDIR/helper.log 2>&1
       if [ "$?" = "0" ]
       then
           echo "Success"
           sleep 20
       else
           echo "Fail"
           exit 1
       fi
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
   echo -n "Updating Server Start Count to $noReplicas -"
   if [ "$install_type" = "oam" ]
   then
      filename=$WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-access-domain/domain-home-on-pv/output/weblogic-domains/$OAM_DOMAIN_NAME
      sed -i "s/replicas:.*/replicas: $noReplicas/" $filename/domain.yaml
      echo "Success"
      echo "Starting $noReplicas WebLogic Managed Servers"
      kubectl apply -f $filename/domain.yaml
      echo "Saving a Copy of Domain files to : $WORKDIR/TO_KEEP/$OAM_DOMAIN_NAME"
      mkdir -p $WORKDIR/TO_KEEP/$OAM_DOMAIN_NAME
      cp $filename/* $WORKDIR/TO_KEEP/$OAM_DOMAIN_NAME
      cp $WORKDIR/OAM/create-domain-inputs.yaml $WORKDIR/TO_KEEP/$OAM_DOMAIN_NAME
   else
      filename=$WORKDIR/weblogic-kubernetes-operator/kubernetes/samples/scripts/create-oim-domain/domain-home-on-pv/output/weblogic-domains/$OIG_DOMAIN_NAME
      sed -i "s/replicas:.*/replicas: $noReplicas/" $filename/domain.yaml
      sed -i "s/replicas:.*/replicas: $noReplicas/" $filename/domain_oim_soa.yaml
      echo "Success"
      echo "Starting $noReplicas WebLogic Servers"
      kubectl apply -f $filename/domain_oim_soa.yaml
      echo "Saving a Copy of Domain files to : $WORKDIR/TO_KEEP/$OIG_DOMAIN_NAME"
      mkdir -p $WORKDIR/TO_KEEP/$OIG_DOMAIN_NAME
      cp $filename/* $WORKDIR/TO_KEEP/$OIG_DOMAIN_NAME
      cp $WORKDIR/OIG/create-domain-inputs.yaml $WORKDIR/TO_KEEP/$OIG_DOMAIN_NAME
   fi

   ET=`date +%s`
   print_time STEP "Update Server Count" $ST $ET >> $LOGDIR/timings.log
}

# Docker Functions
#

function check_docker_image {
    IMAGE=$1
    KNODES=`get_k8nodes`
    RETCODE=0
    echo "Checking Docker Image $IMAGE exists on each Kubernetes node"
    for node in $KNODES
    do
         echo -n "... Checking docker image $IMAGE on $node :"
         if [ "$IMAGE" = "oud" ]
         then
              if [[ $($SSH $node "docker images | grep -v "oudsm" | grep $IMAGE | tr -s ' ' | cut -d ' ' -f 3") = "" ]]
              then
                  echo " Missing."
                  RETCODE=1
              else
                  echo "exists"
              fi
         elif [[ $($SSH $node "docker images | grep -E \"^$IMAGE( |$)\" | tr -s ' ' | cut -d ' ' -f 3") = "" ]]
         then
             echo " Missing."
             RETCODE=1
         else
             echo "exists"
         fi
    done
    return $RETCODE
}

function remove_docker_image {
    IMAGE=$1
    KNODES=`get_k8nodes`
    for node in $KNODES
    do
         image_id=`$SSH $node "docker images" | grep oracle/$IMAGE | awk '{print $3}' | head -1`
         if [ "$IMAGE" = "oud" ]
         then
              image_id=`$SSH $node "docker images" | grep -v oudsm | grep oracle/$IMAGE | awk '{print $3}' | head -1`
              if [ "$image_id" = "" ]
              then
                  echo "... Docker Image $IMAGE not present on node $node."
              else
                  echo  "... Removing docker image $IMAGE on $node :"
                  $SSH $node "docker image rm -f $image_id"
              fi
         elif [ "$image_id" = "" ]
         then
             echo "... Docker Image $IMAGE not present on node $node."
             RETCODE=1
         else
             image_id=`$SSH $node "docker images" | grep $IMAGE | awk '{print $3}' | head -1`
             echo II:$image_id
             echo  "... Removing docker image $IMAGE on $node :"
             $SSH $node "docker image rm -f $image_id"
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
    for node in $KNODES
    do
         echo -n "Checking $IMAGE:$LABEL on $node :"
         if [ "$IMAGE" = "oud" ]
         then
              if [[ $($SSH $node "docker images | grep -v "oudsm" | grep $IMAGE | grep $LABEL | tr -s ' ' | cut -d ' ' -f 3") = "" ]]
              then
                  echo " . Loading"
                  $SSH $node "docker load < $IMAGE_FILE"
                  $SSH $node "docker tag oracle/$IMAGE:$LABEL oracle/$IMAGE:$VER"
              else
                  echo "exists"
              fi
         elif [[ $($SSH $node "docker images | grep $IMAGE | grep $LABEL | tr -s ' ' | cut -d ' ' -f 3") = "" ]]
         then
             echo " . Loading"
             $SSH $node "docker load < $IMAGE_FILE"
             if ! [[ "$IMAGE" = oiri* ]]
             then
                 $SSH $node "docker tag oracle/$IMAGE:$LABEL oracle/$IMAGE:$VER"
             fi
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
      echo -n "Creating $SCHEMA_TYPE Schemas - "

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
      if [ $? = 0 ]
      then
           echo "Success"
      else
           echo "Fail"
           exit 1
      fi

      if [ "$SCHEMA_TYPE" = "OIG" ]
      then
         echo -n "Patching OIM Schema - " 
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
    
    echo -e "\t Starting - $SERVER_NAME \c"
    sleep 120
    X=0
    while [ "$X" = "0" ]
    do

        POD=`kubectl --namespace $NAMESPACE get pod -o wide | grep $SERVER_NAME `
        if [ "$POD" = "" ]
        then
             kubectl --namespace $NAMESPACE get pod -o wide | grep infra-domain-job | grep Error > /dev/null
             if [ $? = 0 ]
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
        elif [ "$PODSTATUS" = "ErrImagePull" ]
        then
              echo "Pod $SERVER_NAME has failed to Obtain the image - Check Docker Image is present on $NODE."
              X=2
        elif [ "$PODSTATUS" = "CrashLoopBackOff" ]
        then
              echo "Pod $SERVER_NAME has failed to Start - Check Docker Image is present on $NODE."
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
    
    echo -e "\t Stopping $SERVER_NAME \c"

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
  echo "Starting Domain $DOMAIN_NAME "
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

  echo "Stopping Domain $DOMAIN_NAME "
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

# Obtain an SSL certificate from a load balancer
#
get_lbr_certificate()
{
     LBRHOST=$1
     LBRPORT=$2
    
     echo -n "Obtaining Load Balancer Certificate $LBRHOST:$LBRPORT - "
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

     print_time STEP "Obtaining Load Balancer Certificate $LBRHOST:$LBRPORT" $ST $ET >> $LOGDIR/timings.log
}

# Determine where a script stop to enable continuation
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

    echo -n "Checking Loadbalancer $1 port $2 - "

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
