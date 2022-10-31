#!/bin/bash
# Copyright (c) 2020, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
. /u01/oracle/wlserver/server/bin/setWLSEnv.sh

echo "Check if the DB Service is ready to accept request "
connectString=${1:-oracle-db.default.svc.cluster.local:1521/devpdb.k8s}
schemaPrefix=${2:-wccinfra}
rcuType=${3:-wcc}
sysPassword=${4:-Oradoc_db1}
customVariables=${5:-none}

echo "DB Connection String [$connectString] schemaPrefix [${schemaPrefix}] rcuType[${rcuType}] customVariables[${customVariables}]"

max=20
counter=0
while [ $counter -le ${max} ]
do
 java utils.dbping ORACLE_THIN "sys as sysdba" ${sysPassword} ${connectString} > dbping.err 2>&1 
 [[ $? == 0 ]] && break;
 ((counter++))
 echo "[$counter/${max}] Retrying the DB Connection ..."
 sleep 10
done

if [ $counter -gt ${max} ]; then 
 echo "[ERROR] Oracle DB Service is not ready after [${max}] iterations ..."
 exit -1
else 
 java utils.dbping ORACLE_THIN "sys as sysdba" ${sysPassword} ${connectString}
fi 

if [ $customVariables != "none" ]; then
  extVariables="-variables $customVariables"
else
  extVariables=""  
fi

case $rcuType in
wcc)
   extComponents="-component CONTENT"
   echo "Dropping RCU Schema for OracleWebCenterContent Domain ..."
   ;;
 * )
    echo "[ERROR] Unknown RCU Schema Type [$rcuType]"
    echo "Supported values: wcc"
    exit -1
  ;;
esac

echo "Extra RCU Schema Component(s) Choosen[${extComponents}]" 
echo "Extra RCU Schema Variable(s)  Choosen[${extVariables}]" 

/u01/oracle/oracle_common/bin/rcu -silent -dropRepository \
 -databaseType ORACLE -connectString ${connectString} \
 -dbUser sys  -dbRole sysdba \
 -selectDependentsForComponents true \
 -schemaPrefix ${schemaPrefix} ${extComponents} ${extVariables}  \
 -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER \
 -component OPSS  -component WLS -component STB < /u01/oracle/pwd.txt

