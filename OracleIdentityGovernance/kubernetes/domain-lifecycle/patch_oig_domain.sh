#!/usr/bin/env bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# The script automates OIG domain patching with given image and modifies the DB Schema.
# The script will first bring down the helper pod and create a new helper pod with latest image
# Then it will stop admin, soa and oim servers using serverRestartPolicy as NEVER.
# After all servers are stopped, then it will perform the db schema changes from helper pod.
# the script will rely on job configmap for fetching db credentials. Post DB schema changes, it will
# bring admin, soa and oim servers up using the latest image and serverRestartPolicy set to IF_NEEDED
# The script will exit with zero return code if all servers come up and be in ready state.

# Example usage:
#   patch_oig_domain.sh -n oigns -i 12.2.1.4.0-oct22
#

script="${BASH_SOURCE[0]}"

function fail {
  echo [ERROR] $*
  exit 1
}

function info {
  echo [INFO] $*
}

function check_running()
{
    NAMESPACE=$1
    SERVER_NAME=$2
    TIMEOUT=$3
    IMAGE=$4
    DOMAIN=$5
    DELAY=$6

    printf "Checking $SERVER_NAME "
    if [ "$SERVER_NAME" = "helper" ]
    then
      sleep 60
      PODNAME=$SERVER_NAME
    else
        sleep ${DELAY:=10}
    fi

    (( max = TIMEOUT / 60 ))
    count=0
    X=0

    while [ "$X" = "0" ] && [ $count -lt $max ]
    do
      POD=`kubectl -n $NAMESPACE get pods -o wide | grep $SERVER_NAME | head -1`
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

      running_image_tag=`kubectl get pod ${PODNAME} -n ${NAMESPACE} -o jsonpath="{.spec.containers[0].image}"`
      #check if server is running with correct image, then proceed with checking status and readiness
      if [ "$running_image_tag" = "$IMAGE" ]
      then
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
        if [ "$SERVER_NAME" = *"oim-server"* ]
        then
              kubectl logs -n $NAMESPACE ${PODNAME} | grep -q "BootStrap configuration Failed"
              if [ $? = 0 ]
              then
                 echo "BootStrap configuration Failed - check kubectl logs -n $NAMESPACE ${PODNAME}"
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
             (( count += 1 ))
        fi
      else
        sleep 60
        (( count += 1 ))
      fi
    done

    if [ "$X" = "0" ]
    then
      fail "$SERVER_NAME is still not ready after timeout...check kubectl get pods -n $NAMESPACE for details"
    fi
}

function usage {
  cat << EOF
  Usage:
    $(basename $0) -n namespace -i imagetag [-r registry] [-l logdir] [-t timeout] [-h]
  Description:
    This script performs the patching of OIG Kubernetes cluster
    with new image. It will execute the following steps sequentially:
    - Check if helper pod exists in given namespace. If yes, then it deletes
      the helper pod. It will bring up a new helper pod with new image.
    - Stops Admin, SOA and OIM servers using serverStartPolicy set as
      NEVER in domain definition yaml.
    - Wait for all servers to be stopped (default timeout 2000s)
    - Introspect db properties including credentials from job configmap.
    - Perform DB schema changes from helper pod
    - Starts Admin, SOA and OIM server by setting serverStartPolicy to
      IF_NEEDED and image to new image tag.
    - Waits for all servers to be ready (default timeout 2000s)

    The script exits non zero if a configurable timeout is reached
    before the target pod count is reached, depending upon the domain
    configuration. It also exits non zero if there is any failure while
    patching the DB schema and domain.

  Parameters:
    -n <namespace>  : Mandatory. Kubernetes namespace where OIG domain in running.
                      There should be only one OIG domain running in given
                      namespace. for example, oigns
    -i <imagetag>   : Mandatory. Image tag of the updated image. for example,
                      12.2.1.4.0-8-ol7-210721.0748
    -r registry     : Optional. Container registry to be used for fetching image.
                      Default value will be fetched from running domain
                      definition. for example,
                      container-registry.oracle.com/middleware/oig_cpu
    -l custom_log_dir : Optional. Default will be under script working directory

    -t <timeout>    : Optional. Timeout in seconds. Defaults to 2000s.
    -h              : This help.
EOF
  exit $1
}

unset image_registry
unset imagetag
unset LOG_DIR
unset registry

BASEDIR="$( cd "$( dirname "${script}" )" && pwd )"
#
# Parse the command line options
#
while getopts "hn:i:r:l:t:" opt; do
  case $opt in
    n) namespace="${OPTARG}"
    ;;
    i) imagetag="${OPTARG}"
    ;;
    r) registry="${OPTARG}"
    ;;
    l) log_dir="${OPTARG}"
    ;;
    t) timeout="${OPTARG}"
    ;;
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done

if [ ! -x "$(command -v kubectl)" ]; then
  echo "Can't find kubectl.  Please add it to the path."
  exit 1
fi

if [ ! -x "$(command -v base64)" ]; then
  echo "Can't find base64.  Please add it to the path."
  exit 1
fi

if [ -z ${namespace} ]; then
  echo "${script}: -n must be specified."
  missingRequiredOption="true"
fi

if [ -z ${imagetag} ]; then
  echo "${script}: -i must be specified."
  missingRequiredOption="true"
fi

if [ "${missingRequiredOption}" == "true" ]; then
  usage 1
fi

#log settings
LOG_TIME="`date +%Y-%m-%d_%H-%M-%S`"
if [ -z $log_dir ]; then
  LOG_DIR=$BASEDIR/log/oim_patch_log-$LOG_TIME
else
  LOG_DIR=$log_dir/oim_patch_log-$LOG_TIME
fi
mkdir -p $LOG_DIR

#check if namespace exists
kubectl get ns ${namespace} > $LOG_DIR/check_namespace.log 2>&1

if [ $? != 0 ]
then
  fail "Namespace ${namespace} doesn't exist. Check the namespace and rerun.."
fi

#get domainUID. assuming only one domain in the namespace
domainUID=`kubectl get domains -n ${namespace} -o jsonpath="{.items..metadata.name}"`
info "Found domain name: $domainUID"

#fetch registry name
if [ -z ${registry} ]; then
  registry=`kubectl get domain ${domainUID} -n ${namespace} -o jsonpath="{..image}" | cut -d ":" -f 1`
fi

image_registry=$registry
info "Image Registry: $image_registry"

if [ -z ${timeout} ]
then
  timeout=2000
fi

current_image_tag=`kubectl get domain ${domainUID} -n ${namespace} -o jsonpath="{..image}" | cut -d ":" -f 2`
current_image_reg=`kubectl get domain ${domainUID} -n ${namespace} -o jsonpath="{..image}" | cut -d ":" -f 1`
info "Domain $domainUID is currently running with image: $current_image_reg:$current_image_tag"

#fetch no. of current weblogic pod under given domain
##fetch oim and soa replica count from domain config
NO_OF_PODS_ORIG=0
cluster_name=`kubectl get domains ${domainUID} -n ${namespace} -o jsonpath="{.spec.clusters[0]['clusterName']}"`
if [ $cluster_name == 'soa_cluster' ]; then
  NO_OF_SOA_REPLICAS=`kubectl get domains ${domainUID} -n ${namespace} -o jsonpath="{.spec.clusters[0]['replicas']}"`
  NO_OF_OIM_REPLICAS=`kubectl get domains ${domainUID} -n ${namespace} -o jsonpath="{.spec.clusters[1]['replicas']}"`
else
  NO_OF_OIM_REPLICAS=`kubectl get domains ${domainUID} -n ${namespace} -o jsonpath="{.spec.clusters[0]['replicas']}"`
  NO_OF_SOA_REPLICAS=`kubectl get domains ${domainUID} -n ${namespace} -o jsonpath="{.spec.clusters[1]['replicas']}"`
fi

(( NO_OF_PODS_ORIG = NO_OF_PODS_ORIG + NO_OF_SOA_REPLICAS + NO_OF_OIM_REPLICAS + 1  ))
echo "current no of pods under $domainUID are $NO_OF_PODS_ORIG"

#make sure if any old helper pod is running or not, if yes then delete it
helper_pod_name="helper"
result=`kubectl get pods ${helper_pod_name} -n ${namespace} --ignore-not-found=true | grep ${helper_pod_name} | wc | awk ' { print $1; }'`
if [ "${result:=Error}" != "0" ]; then
  info "The pod ${helper_pod_name} already exists in namespace ${namespace}."
  info "Deleting pod ${helper_pod_name}"
  kubectl delete pod ${helper_pod_name} -n ${namespace}
  sleep 30
fi

#fetch imagepullsecrets dynamically from domain. if no imagepullsecret, then exit. No option of passing.
image_pull_secrets=`kubectl get domain ${domainUID} -n ${namespace} -o jsonpath="{.spec.imagePullSecrets[*]['name']}"`
info "Fetched Image Pull Secret: $image_pull_secrets"
if [ ! -z $image_pull_secrets ]
then
  is_image_pull_secret=`kubectl get secrets -n ${namespace} | grep -i $image_pull_secrets | head -1`
  if [ "$is_image_pull_secret" = "" ]
  then
    fail "ImagePullSecrets $image_pull_secrets doesn't exist in namespace $namespace. Create it first and rerun this script."
  else
    info "Creating new helper pod with image: $image_registry:$imagetag"
    kubectl run --image=${image_registry}:${imagetag} --image-pull-policy="IfNotPresent" --overrides='{"apiVersion": "v1","spec":{"imagePullSecrets": [{"name": '\"${image_pull_secrets}\"'}]}}' ${helper_pod_name} -n ${namespace} -- sleep infinity
  fi
else
  echo "[WARNING] Could not fetch any imagePullSecrets from $domainUID definition. Proceeding with helper pod creation without imagePullSecrets."
  kubectl run helper --image ${image_registry}:${imagetag} -n ${namespace} -- sleep infinity
fi

#create a new helper pod and wait for it to run.
check_running $namespace $helper_pod_name $timeout $image_registry:$imagetag $domainUID 30

#Stopping Admin, SOA and OIM servers
info "Stopping Admin, SOA and OIM servers in domain $domainUID. This may take some time, monitor log $LOG_DIR/stop_servers.log for details"
kubectl patch domain ${domainUID} -n ${namespace} --type merge -p '{"spec":{"serverStartPolicy":"NEVER"}}' > $LOG_DIR/stop_servers.log 2>&1

#wait for all pods to be down
sh wl-pod-wait.sh -d ${domainUID} -n ${namespace} -t $timeout -p 0 >> $LOG_DIR/stop_servers.log 2>&1

if [ $? != 0 ]
then
  fail "All servers under domain ${domainUID} could not be stopped. Check kubectl get pods -n ${namespace} for details"
fi

NO_OF_PODS=$(kubectl get pods -n ${namespace} -l weblogic.serverName,weblogic.domainUID=${domainUID} -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | wc -l)

if [ $NO_OF_PODS == 0 ]
then
  info "All servers are now stopped successfully. Proceeding with DB Schema changes"
else
  fail "All servers under domain ${domainUID} could not be stopped. Check kubectl get pods -n ${namespace} for details"
fi

#fetch details from job configmap for db schema changes
JOB_CM=`kubectl get cm -n ${namespace} | grep -i fmw-infra-sample-domain-job | awk '{print $1}' | tr -d " "`
rcuSchemaPrefix=`kubectl get cm ${JOB_CM} -n ${namespace} -o template --template {{.data}} | grep "rcuSchemaPrefix:" | cut -d ":" -f 2 | tr -d " "`
rcuCredentialsSecret=`kubectl get cm ${JOB_CM} -n ${namespace} -o template --template {{.data}} | grep "rcuCredentialsSecret:" | cut -d ":" -f 2 | tr -d " "`
rcuDatabaseURL=`kubectl get cm ${JOB_CM} -n ${namespace} -o template --template {{.data}} | grep "rcuDatabaseURL:" | awk -F 'rcuDatabaseURL:' '{print $2}' | tr -d " "`
DB_HOST=`echo $rcuDatabaseURL | cut -d ":" -f 1 | tr -d " "`
DB_PORT=`echo $rcuDatabaseURL | tr ":" "\t" | awk '{print $2}' | tr -d " " | tr "/" "\t" | awk '{print $1}' | tr -d " "`
DB_SERVICE=`echo $rcuDatabaseURL | tr ":" "\t" | awk '{print $2}' | tr -d " " | tr "/" "\t" | awk '{print $2}' | tr -d " "`
RCU_SCHEMA_PWD=`kubectl get secrets ${rcuCredentialsSecret} -n ${namespace} -o yaml | grep "\spassword" | tr -d " " | tr ":" "\t" | awk '{print $2}' | tr -d " " | base64 -d`
SYS_PWD=`kubectl get secrets ${rcuCredentialsSecret} -n ${namespace} -o yaml | grep "\ssys_password" | tr -d " " | tr ":" "\t" | awk '{print $2}' | tr -d " " | base64 -d`

echo "DB_HOST=$DB_HOST
  DB_PORT=$DB_PORT
  DB_SERVICE=$DB_SERVICE
  RCU_SCHEMA_PREFIX=$rcuSchemaPrefix
  RCU_CREDENTIALS_SECRET=$rcuCredentialsSecret
  RCUDATABASEURL=$rcuDatabaseURL
  JOBCM=$JOB_CM" > $LOG_DIR/db.properties

#run db schema patch command
info "Patching OIM schemas..."
kubectl exec -it ${helper_pod_name} -n ${namespace} -- bash -c "echo -e ${SYS_PWD}'\n'${RCU_SCHEMA_PWD} > /tmp/pwd.txt"
kubectl exec -it ${helper_pod_name} -n ${namespace} -- /u01/oracle/oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin/ant \
-f /u01/oracle/idm/server/setup/deploy-files/automation.xml \
run-patched-sql-files invoke-metadata-seeding \
-logger org.apache.tools.ant.NoBannerLogger \
-logfile /u01/oracle/idm/server/bin/patch_oim_wls.log \
-DmdsDB.user=${rcuSchemaPrefix}_MDS \
-DmdsDB.password=$RCU_SCHEMA_PWD \
-DmdsDB.port=$DB_PORT \
-DmdsDB.serviceName=$DB_SERVICE \
-DmdsDB.host=$DB_HOST \
-Dserver.dir=/u01/oracle/idm/server \
-Dmw_home=/u01/oracle \
-Djava_home=/u01/jdk \
-DoperationsDB.host=$DB_HOST \
-DoperationsDB.port=$DB_PORT \
-DoperationsDB.serviceName=$DB_SERVICE \
-DoperationsDB.user=${rcuSchemaPrefix}_OIM \
-DOIM.DBPassword=$RCU_SCHEMA_PWD \
-Dojdbc=/u01/oracle/oracle_common/modules/oracle.jdbc/ojdbc8.jar > $LOG_DIR/patch_schema.log 2>&1

if [ $? -gt 0 ]; then
  kubectl cp  $namespace/$helper_pod_name:/u01/oracle/idm/server/bin/patch_oim_wls.log $LOG_DIR/patch_oim_wls.log > /dev/null
  fail "OIM schema update failed. Check log $LOG_DIR/patch_oim_wls.log for details"
fi

if [ $? -eq 0 ]; then
  kubectl cp  $namespace/$helper_pod_name:/u01/oracle/idm/server/bin/patch_oim_wls.log $LOG_DIR/patch_oim_wls.log > /dev/null
  grep -q "BUILD SUCCESSFUL" $LOG_DIR/patch_oim_wls.log
  if [ $? = 0 ]
  then
    info "OIM schema update successful. Check log $LOG_DIR/patch_oim_wls.log for details"
  else
    fail "OIM schema update failed. Check log $LOG_DIR/patch_oim_wls.log for details"
  fi
fi

#cleanup /tmp/pwd.txt
kubectl exec -it $helper_pod_name -n $namespace -- rm -rf /tmp/pwd.txt

info "Starting Admin, SOA and OIM servers with new image $image_registry:$imagetag"
kubectl patch domain ${domainUID} -n ${namespace} --type merge  -p '{"spec":{"image":'\"${image_registry}':'${imagetag}\"', "serverStartPolicy":"IF_NEEDED"}}' > $LOG_DIR/patch_domain.log 2>&1
if [ $? -eq 1 ]; then
  fail "Domain update failed.."
fi

#wait for pod to be ready with latest image
info "Waiting for $NO_OF_PODS_ORIG weblogic pods to be ready..This may take several minutes, do not close the window. Check log $LOG_DIR/monitor_weblogic_pods.log for progress "
sh wl-pod-wait.sh -d ${domainUID} -n ${namespace} -t $timeout -p $NO_OF_PODS_ORIG > $LOG_DIR/monitor_weblogic_pods.log 2>&1

if [ $? != 0 ]
then
  fail "All pods under $domainUID are not in ready state. Check logs and run kubectl get pods -n $namespace for details"
fi

grep -q "Success!" $LOG_DIR/monitor_weblogic_pods.log

if [ $? != 0 ]
then
  fail "All pods under $domainUID are not in ready state. Check logs and run kubectl get pods -n $namespace for details"
else
  echo "[SUCCESS] All servers under $domainUID are now in ready state with new image: $image_registry:$imagetag"
  exit 0
fi






