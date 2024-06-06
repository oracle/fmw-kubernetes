#!/bin/bash
# Copyright (c) 2020, 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Drop the RCU schema based on schemaPreifix and Database URL

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/../common/utility.sh

usage() {
  echo "usage: ${script} -s <schemaPrefix> [-t <schemaType>] [-d <dburl>] [-n <namespace>] [-c <credentialsSecretName>] [-p <docker-store>] [-i <image>] [-u <imagePullPolicy>] [-o <rcuOutputDir>] [-r <customVariables>] [-b <databaseType>] [-e <edition>] [-h]"
  echo "  -s RCU Schema Prefix (required)"
  echo "  -t RCU Schema Type (optional)"
  echo "      (supported values: osb,soa,soaosb, default: soa) "
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
  echo "      (default: soasuite:release-version) "
  echo "  -u OracleSOASuite ImagePullPolicy (optional) "
  echo "      (default: IfNotPresent) "
  echo "  -o Output directory for the generated YAML file. (optional)"
  echo "      (default: rcuoutput)"
  echo "  -r Comma-separated custom variables in the format variablename=value. (optional)."
  echo "      (default: none)"
  echo "  -b Type of database to which you are connecting (optional). Supported values: ORACLE,EBR"
  echo "      (default: ORACLE)"
  echo "  -e The edition name. This parameter is only valid if you specify type of database (-b) as EBR. (optional)."
  echo "      (default: 'ORA\$BASE')"
  echo "  -h Help"
  echo ""
  echo "NOTE: The c, p, i, u, and o arguments are ignored if an rcu pod is already running in the namespace."
  echo ""
  exit $1
}

edition='ORA$BASE'
dburl="oracle-db.default.svc.cluster.local:1521/devpdb.k8s"
namespace="default"
createPodArgs=""
databaseType="ORACLE"

if [ -z ${rcuType} ]; then
 rcuType="soa"
fi

if [ -z ${customVariables} ]; then
 customVariables="none"
fi

while getopts ":s:t:d:n:c:p:i:u:o:r:b:e:h:" opt; do
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
    b) databaseType="${OPTARG}"
    ;;
    e) edition="${OPTARG}"
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

if [ "${databaseType}" == "ORACLE" ]; then
   edition=''
fi

# this creates the rcu pod if it doesn't already exist
echo "[INFO] Calling '${scriptDir}/common/create-rcu-pod.sh -n $namespace $createPodArgs'"
${scriptDir}/common/create-rcu-pod.sh -n $namespace $createPodArgs || exit -4

#fmwimage=`${KUBERNETES_CLI:-kubectl} get pod/rcu  -o jsonpath="{..image}"`
echo "DB Connection String [$dbUrl], schemaPrefix [${schemaPrefix}] rcuType [${rcuType}] schemaProfileType [${customVariables}] databaseType [${databaseType}] edition [${edition}]"

${KUBERNETES_CLI:-kubectl} exec -n $namespace -i rcu -- /bin/bash /u01/oracle/dropRepository.sh ${dburl} ${schemaPrefix} ${rcuType} ${customVariables} ${databaseType} ${edition}
if [ $? != 0  ]; then
 echo "######################";
 echo "[ERROR] Could not drop the RCU Repository based on dburl[${dburl}] schemaPrefix[${schemaPrefix}]  ";
 echo "######################";
 exit -3;
fi

