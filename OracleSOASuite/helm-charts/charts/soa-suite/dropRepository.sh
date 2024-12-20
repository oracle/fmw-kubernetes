#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
. /u01/oracle/wlserver/server/bin/setWLSEnv.sh

echo "Check if the DB Service is ready to accept request "
connectString=${1:-oracle-db.default.svc.cluster.local:1521/devpdb.k8s}
schemaPrefix=${2:-soainfra}
rcuType=${3:-soa}
sysPassword="$(cat /rcu-secret/password)"
customVariables=${4:-none}
databaseType=${5:-ORACLE}
dbTypeValue="-databaseType ${databaseType}"
if [ "${databaseType}" == "EBR" ]; then
   edition=${6:-'ORA$BASE'}
   dbTypeValue="${dbTypeValue} -edition ${edition}"
fi

echo "DB Connection String [$connectString], schemaPrefix [${schemaPrefix}] rcuType [${rcuType}] customVariables [${customVariables}], databaseType [${databaseType}]"

max=20
counter=0
while [ $counter -le ${max} ]
do
 java utils.dbping ORACLE_THIN "$(cat /rcu-secret/username) as sysdba" ${sysPassword} ${connectString} > dbping.err 2>&1
 [[ $? == 0 ]] && break;
 ((counter++))
 echo "[$counter/${max}] Retrying the DB Connection ..."
 sleep 10
done

if [ $counter -gt ${max} ]; then 
 echo "[ERROR] Oracle DB Service is not ready after [${max}] iterations ..."
 echo "Dropping RCU Schema ${schemaPrefix} has failed. Please drop RCU Schema manually. Skipping for now...."
 exit
else 
 java utils.dbping ORACLE_THIN "$(cat /rcu-secret/username) as sysdba" ${sysPassword} ${connectString}
fi 

if [ $customVariables != "none" ]; then
  extVariables="-variables $customVariables"
else
  extVariables=""  
fi

case $rcuType in
osb)
   extComponents="-component SOAINFRA"
   echo "Dropping RCU Schema for OracleSOASuite Domain ..."
   ;;
soa|soaosb)
   extComponents="-component SOAINFRA -component ESS"
   echo "Dropping RCU Schema for OracleSOASuite Domain ..."
   ;;
 * )
    echo "[ERROR] Unknown RCU Schema Type [$rcuType]"
    echo "Supported values: osb,soa,soaosb"
    echo "Dropping RCU Schema ${schemaPrefix} has failed. Please drop RCU Schema manually. Skipping for now...."
    exit
  ;;
esac

echo "Extra RCU Schema Component(s) Choosen[${extComponents}]" 
echo "Extra RCU Schema Variable(s)  Choosen[${extVariables}]" 
echo "DatabaseType value Choosen [${dbTypeValue}]"

echo "Waiting for 10 seconds to avoid any connections before dropping RCU Schema...."
sleep 10
/u01/oracle/oracle_common/bin/rcu -silent -dropRepository \
 ${dbTypeValue} -connectString ${connectString} \
 -dbUser "$(cat /rcu-secret/username)" -dbRole sysdba \
 -selectDependentsForComponents true \
 -schemaPrefix ${schemaPrefix} ${extComponents} ${extVariables}  \
 -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER \
 -component OPSS  -component WLS -component STB \
 <<< "$(cat /rcu-secret/password ; echo ; echo $schemaPassword)"
status1=$?
echo "Dropping RCU Schema done with status: $status1"
if [ $status1 -ne 0 ]; then
   echo "Dropping RCU Schema ${schemaPrefix} has failed. Please drop RCU Schema manually. Skipping for now...."
   exit 
else
   exit $status1
fi



