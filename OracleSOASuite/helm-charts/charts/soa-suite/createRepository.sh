#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
. /u01/oracle/wlserver/server/bin/setWLSEnv.sh

echo "Check if the DB Service is ready to accept request "
connectString=${1:-oracle-db.default.svc.cluster.local:1521/devpdb.k8s}
schemaPrefix=${2:-soainfra}
rcuType=${3:-soa}
sysUsername="$(cat /rcu-secret/username)"
sysPassword="$(cat /rcu-secret/password)"
customVariables=${4:-none}
databaseType=${5:-ORACLE}
dbTypeValue="-databaseType ${databaseType}"
if [ "${databaseType}" == "EBR" ]; then
   edition=${6:-'ORA$BASE'}
   dbTypeValue="${dbTypeValue} -edition ${edition}"
fi

echo "DB Connection String [$connectString], schemaPrefix [${schemaPrefix}] rcuType [${rcuType}] customVariables [${customVariables}], databaseType [${databaseType}]"

max=1500
counter=0
while [ $counter -le ${max} ]
do
 java utils.dbping ORACLE_THIN "${sysUsername} as sysdba" "${sysPassword}" ${connectString} > dbping.err 2>&1
 [[ $? == 0 ]] && break;
 ((counter++))
 echo "[$counter/${max}] Retrying the DB Connection ..."
 sleep 10
done

if [ $counter -gt ${max} ]; then
 echo "Error output from 'java utils.dbping ORACLE_THIN \"${sysUsername} as sysdba\" SYSPASSWORD ${connectString}' from '$(pwd)/dbping.err':"
 cat dbping.err
 echo "[ERROR] Oracle DB Service is not ready after [${max}] iterations ..."
 exit -1
else
 java utils.dbping ORACLE_THIN "${sysUsername} as sysdba" "${sysPassword}" ${connectString}
fi

if [ $customVariables != "none" ]; then
  extVariables="-variables $customVariables"
  echo $extVariables
else
  extVariables=""  
fi
case $rcuType in

osb)
   extComponents="-component SOAINFRA"
   echo "Creating RCU Schema for OracleSOASuite Domain ..."
   ;;
soa|soaosb)
   extComponents="-component SOAINFRA -component ESS"
   echo "Creating RCU Schema for OracleSOASuite Domain ..."
   ;;
     * )
    echo "[ERROR] Unknown RCU Schema Type [$rcuType]"
    echo "Supported values: osb,soa,soaosb"
    exit -1
  ;;
esac

echo "Extra RCU Schema Component Choosen[${extComponents}]" 
echo "Extra RCU Schema Variable Choosen[${extVariables}]" 
echo "DatabaseType value Choosen [${dbTypeValue}]"

#Debug 
#export DISPLAY=0.0
#/u01/oracle/oracle_common/bin/rcu -listComponents

/u01/oracle/oracle_common/bin/rcu -silent -createrepository \
 ${dbTypeValue} -connectString ${connectString} \
 -dbUser "$(cat /rcu-secret/username)" -dbRole sysdba -useSamePasswordForAllSchemaUsers true \
 -selectDependentsForComponents true \
 -schemaPrefix ${schemaPrefix} ${extComponents} ${extVariables} \
 -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER \
 -component OPSS -component WLS -component STB  \
 <<< "$(cat /rcu-secret/password  ; echo ; echo $schemaPassword)"
status1=$?
echo "Status is $status1"
cat /tmp/RCU*/logs/rcu.log| grep "The specified prefix already exists" > /dev/null
status2=$?
if [ $status2 -eq 0 ]; then
   echo "The specified prefix ${schemaPrefix} already exists"
   exit $status2
else
   exit $status1
fi
