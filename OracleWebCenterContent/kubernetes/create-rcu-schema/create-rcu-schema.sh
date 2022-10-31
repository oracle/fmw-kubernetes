#!/bin/bash
# Copyright (c) 2020, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Configure RCU schema based on schemaPreifix and rcuDatabaseURL

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/../common/utility.sh

function usage {
  echo "usage: ${script} -s <schemaPrefix> -t <schemaType> -d <dburl> -i <image> -u <imagePullPolicy> -p <docker-store> -n <namespace> -q <sysPassword> -r <schemaPassword>  -o <rcuOutputDir> -c <customVariables> [-l] <timeoutLimit>  [-h] "
  echo "  -s RCU Schema Prefix (required)"
  echo "  -t RCU Schema Type (optional)"
  echo "      (supported values: wcc)"
  echo "  -d RCU Oracle Database URL (optional) "
  echo "      (default: oracle-db.default.svc.cluster.local:1521/devpdb.k8s) "
  echo "  -p OracleWebCenterContent ImagePullSecret (optional) "
  echo "      (default: none) "
  echo "  -i OracleWebCenterContent Image (optional) "
  echo "      (default: oracle/wccontent:12.2.1.4) "
  echo "  -u OracleWebCenterContent ImagePullPolicy (optional) "
  echo "      (default: IfNotPresent) "
  echo "  -n Namespace for RCU pod (optional)"
  echo "      (default: default)"
  echo "  -q password for database SYSDBA user. (optional)"
  echo "      (default: Oradoc_db1)"
  echo "  -r password for all schema owner (regular user). (optional)"
  echo "      (default: Oradoc_db1)"
  echo "  -o Output directory for the generated YAML file. (optional)"
  echo "      (default: rcuoutput)"
  echo "  -c Comma-separated custom variables in the format variablename=value. (optional)."
  echo "      (default: none)"
  echo "  -l Timeout limit in seconds. (optional)."
  echo "      (default: 300)"
  echo "  -h Help"
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
 pname=`kubectl get po -n ${ns} | grep -w ${pod} | awk '{print $1}'`
 if [ -z ${pname} ]; then 
  echo "No such pod [$pod] exists in NameSpace [$ns] "
  exit -1
 fi 

 rcode=`kubectl get po ${pname} -n ${ns} | grep -w ${pod} | awk '{print $2}'`
 [[ ${rcode} -eq "${state}"  ]] && status="Ready"

 while [ ${status} != "Ready" -a $count -le $max ] ; do
  sleep 5 
  rcode=`kubectl get po/$pod -n ${ns} | grep -v NAME | awk '{print $2}'`
  [[ ${rcode} -eq "1/1"  ]] && status="Ready"
  echo "Pod [$1] Status is ${status} Iter [$count/$max]"
  count=`expr $count + 1`
 done
 if [ $count -gt $max ] ; then
   echo "[ERROR] Unable to start the Pod [$pod] after ${timeout}s "; 
   exit 1
 fi 

 pname=`kubectl get po -n ${ns} | grep -w ${pod} | awk '{print $1}'`
 kubectl -n ${ns} get po ${pname}
}

timeout=300

while getopts ":h:s:d:p:i:t:n:q:r:o:u:c:l:" opt; do
  case $opt in
    s) schemaPrefix="${OPTARG}"
    ;;
    t) rcuType="${OPTARG}"
    ;;
    d) dburl="${OPTARG}"
    ;;
    p) pullsecret="${OPTARG}"
    ;;
    i) fmwimage="${OPTARG}"
    ;;
    n) namespace="${OPTARG}"
    ;;
    q) sysPassword="${OPTARG}"
    ;;
    r) schemaPassword="${OPTARG}"
    ;;
    o) rcuOutputDir="${OPTARG}"
    ;;
    u) imagePullPolicy="${OPTARG}"
    ;;
    c) customVariables="${OPTARG}"
    ;;
    l) timeout="${OPTARG}"
    ;;
    h) usage 0
    ;;
    *) usage 1
    ;;
  esac
done

if [ -z ${schemaPrefix} ]; then
  echo "${script}: -s <schemaPrefix> must be specified."
  usage 1
fi

if [ -z ${dburl} ]; then
  dburl="oracle-db.default.svc.cluster.local:1521/devpdb.k8s"
fi

if [ -z ${rcuType} ]; then
  rcuType="wcc"
fi

if [ -z ${pullsecret} ]; then
  pullsecret="none"
  pullsecretPrefix="#"
fi

if [ -z ${fmwimage} ]; then
 fmwimage="oracle/wccontent:12.2.1.4"
fi

if [ -z ${imagePullPolicy} ]; then
 imagePullPolicy="IfNotPresent"
fi

if [ -z ${namespace} ]; then
 namespace="default"
fi

if [ -z ${sysPassword} ]; then
 sysPassword="Oradoc_db1"
fi

if [ -z ${schemaPassword} ]; then
 schemaPassword="Oradoc_db1"
fi

if [ -z ${rcuOutputDir} ]; then
 rcuOutputDir="rcuoutput"
fi

if [ -z ${customVariables} ]; then
 customVariables="none"
fi

if [ -z ${timeout} ]; then
 timeout=300
fi

echo "ImagePullSecret[$pullsecret] Image[${fmwimage}] dburl[${dburl}] rcuType[${rcuType}] customVariables[${customVariables}]"

mkdir -p ${rcuOutputDir}
rcuYaml=${rcuOutputDir}/rcu.yaml
rm -f ${rcuYaml}
rcuYamlTemp=${scriptDir}/common/template/rcu.yaml.template
cp $rcuYamlTemp $rcuYaml

# Modify the ImagePullSecret based on input
sed -i -e "s:%NAMESPACE%:${namespace}:g" $rcuYaml
sed -i -e "s:%WEBLOGIC_IMAGE_PULL_POLICY%:${imagePullPolicy}:g" $rcuYaml
sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_NAME%:${pullsecret}:g" $rcuYaml
sed -i -e "s:%WEBLOGIC_IMAGE_PULL_SECRET_PREFIX%:${pullsecretPrefix}:g" $rcuYaml
sed -i -e "s?image:.*?image: ${fmwimage}?g" $rcuYaml
kubectl apply -f $rcuYaml

# Make sure the rcu deployment Pod is RUNNING
checkPod rcu $namespace
checkPodStateUsingCustomTimeout rcu $namespace "1/1" ${timeout}
sleep 5
kubectl get po/rcu -n $namespace 

# Generate the default password files for rcu command
echo "$sysPassword" > pwd.txt
echo "$schemaPassword" >> pwd.txt

kubectl exec -n $namespace -i rcu -- bash -c 'cat > /u01/oracle/createRepository.sh' < ${scriptDir}/common/createRepository.sh 
kubectl exec -n $namespace -i rcu -- bash -c 'cat > /u01/oracle/pwd.txt' < pwd.txt 
rm -rf createRepository.sh pwd.txt

kubectl exec -n $namespace -i rcu /bin/bash /u01/oracle/createRepository.sh ${dburl} ${schemaPrefix} ${rcuType} ${sysPassword} ${customVariables}
if [ $? != 0  ]; then
 echo "######################";
 echo "[ERROR] Could not create the RCU Repository";
 echo "######################";
 exit -3;
fi

echo "[INFO] Modify the domain.input.yaml to use [$dburl] as rcuDatabaseURL and [${schemaPrefix}] as rcuSchemaPrefix "

