#!/bin/bash
# Copyright (c) 2020, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Configure RCU schema based on schemaPreifix and rcuDatabaseURL

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/../common/utility.sh

usage() {
  echo "usage: ${script} -s <schemaPrefix> [-t <schemaType>] [-d <dburl>] [-n <namespace>] [-c <credentialsSecretName>] [-p <docker-store>] [-i <image>] [-u <imagePullPolicy>] [-o <rcuOutputDir>] [-r <customVariables>] [-l <timeoutLimit>] [-h]"
  echo "  -s RCU Schema Prefix (required)"
  echo "  -t RCU Schema Type (optional)"
  echo "      (supported values: osb,soa,soaosb) "
  echo "  -d RCU Oracle Database URL (optional) "
  echo "      (default: oracle-db.default.svc.cluster.local:1521/devpdb.k8s) "
  echo "  -n Namespace for RCU pod (optional)"
  echo "      (default: default)"
  echo "  -c Name of credentials secret (optional)."
  echo "       (default: oracle-rcu-secret)"
  echo "       Must contain SYSDBA username at key 'sys_username',"
  echo "       SYSDBA password at key 'sys_password',"
  echo "       and RCU schema owner password at key 'password'."
  echo "  -p OracleSOASuite ImagePullSecret (optional) "
  echo "      (default: none) "
  echo "  -i OracleSOASuite Image (optional) "
  echo "      (default: soasuite:12.2.1.4) "
  echo "  -u OracleSOASuite ImagePullPolicy (optional) "
  echo "      (default: IfNotPresent) "
  echo "  -o Output directory for the generated YAML file. (optional)"
  echo "      (default: rcuoutput)"
  echo "  -r Comma-separated custom variables in the format variablename=value. (optional)."
  echo "      (default: none)"
  echo "  -l Timeout limit in seconds. (optional)."
  echo "      (default: 300)"
  echo "  -h Help"
  echo ""
  echo "NOTE: The c, p, i, u, and o arguments are ignored if an rcu pod is already running in the namespace."
  echo ""
  exit $1
}

# Checks if all container(s) in a pod are running state based on READY column using given timeout limit
# NAME                READY     STATUS    RESTARTS   AGE
# domain1-adminserver 1/1       Running   0          4m
function checkPodStateUsingCustomTimeout(){

 status="NotReady"
 count=1

 pod=$1
 ns=$2
 state=${3:-1/1}
 timeoutLimit=${4:-300}
 max=`expr ${timeoutLimit} / 5`

 echo "Checking Pod READY column for State [$state]"
 pname=`${KUBERNETES_CLI:-kubectl} get po -n ${ns} | grep -w ${pod} | awk '{print $1}'`
 if [ -z ${pname} ]; then 
  echo "No such pod [$pod] exists in NameSpace [$ns] "
  exit -1
 fi 

 rcode=`${KUBERNETES_CLI:-kubectl} get po ${pname} -n ${ns} | grep -w ${pod} | awk '{print $2}'`
 [[ ${rcode} -eq "${state}"  ]] && status="Ready"

 while [ ${status} != "Ready" -a $count -le $max ] ; do
  sleep 5 
  rcode=`${KUBERNETES_CLI:-kubectl} get po/$pod -n ${ns} | grep -v NAME | awk '{print $2}'`
  [[ ${rcode} -eq "1/1"  ]] && status="Ready"
  echo "Pod [$1] Status is ${status} Iter [$count/$max]"
  count=`expr $count + 1`
 done
 if [ $count -gt $max ] ; then
   echo "[ERROR] Unable to start the Pod [$pod] after ${timeout}s "; 
   exit 1
 fi 

 pname=`${KUBERNETES_CLI:-kubectl} get po -n ${ns} | grep -w ${pod} | awk '{print $1}'`
 ${KUBERNETES_CLI:-kubectl} -n ${ns} get po ${pname}
}

timeout=300

rcuType="${rcuType}"
dburl="oracle-db.default.svc.cluster.local:1521/devpdb.k8s"
namespace="default"
createPodArgs=""

while getopts ":s:t:d:n:c:p:i:u:o:r:l:h:" opt; do
  case $opt in
    s) schemaPrefix="${OPTARG}"
    ;;
    t) rcuType="${OPTARG}"
    ;;
    d) dburl="${OPTARG}"
    ;;
    n) namespace="${OPTARG}"
    ;;
    c|p|i|u|o) createPodArgs+=" -${opt} ${OPTARG}"
    ;;
    r) customVariables="${OPTARG}"
    ;;
    l) timeout="${OPTARG}"
    ;;
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done

if [ -z "${schemaPrefix}" ]; then
  echo "${script}: -s <schemaPrefix> must be specified."
  usage 1
fi

# this creates the rcu pod if it doesn't already exist
echo "[INFO] Calling '${scriptDir}/common/create-rcu-pod.sh -n $namespace $createPodArgs'"
${scriptDir}/common/create-rcu-pod.sh -n $namespace $createPodArgs || exit -4

${KUBERNETES_CLI:-kubectl} exec -n $namespace -i rcu -- /bin/bash /u01/oracle/createRepository.sh ${dburl} ${schemaPrefix} ${rcuType} ${customVariables}
if [ $? != 0 ]; then
 echo "######################";
 echo "[ERROR] Could not create the RCU Repository";
 echo "######################";
 exit -3;
fi

echo "[INFO] RCU Schema created. For samples that use a 'domain.input.yaml' file, modify the file to use '$dburl' for its 'rcuDatabaseURL' and '${schemaPrefix}' for its 'rcuSchemaPrefix'."

