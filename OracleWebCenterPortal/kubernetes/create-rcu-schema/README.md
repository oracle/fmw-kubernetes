# Managing RCU schema for a OracleWebCenterPortal domain

The sample scripts in this directory demonstrate how to:
* Create an RCU schema in the Oracle DB that will be used by a OracleWebCenterPortal domain.
* Delete the RCU schema in the Oracle DB used by a OracleWebCenterPortal domain.

## Start an Oracle Database service in a Kubernetes cluster

A RCU schema requires an Oracle Database. For a sample with instructions about starting and accessing an Oracle Database, see `${WORKDIR}/create-oracle-db-service/README.md` about using its `start-db-service.sh` script.

## Create the RCU schema in the Oracle Database

The `create-rcu-schema.sh` script generates an RCU schema in an Oracle database by deploying a pod named `rcu` (if one isn't already deployed) and running a script named `createRepository.sh` in the pod.

The `rcu` pod assumes that either the image, `oracle/wcportal:release-version`,
is available in the Docker image repository or an `ImagePullSecret` is created for `container-registry.oracle.com`. To create a secret for accessing `container-registry.oracle.com`, see `create-image-pull-secret.sh`.

The `rcu` pod requires that you create a secret in the same namespace as the `rcu` pod which contains the database's SYSDBA username and password in its `sys_username` and `sys_password` fields, and also contains the password of your choice for RCU schemas in its `password field`. In the local shell:
```shell
$ ${KUBERNETES_CLI:-kubectl} -n default create secret generic oracle-rcu-secret \
  --from-literal='sys_username=sys' \
  --from-literal='sys_password=MY_SYS_PASSWORD' \
  --from-literal='password=MY_RCU_SCHEMA_PASSWORD'
```
- Replace MY_DBA_PASSWORD with the same value that you chose when deploying the database.
- Replace MY_RCU_SCHEMA_PASSWORD with your choice of RCU schema password.
- Oracle passwords can contain upper case, lower case, digits, and special characters.
  Use only `_` and `#` as special characters to eliminate potential parsing errors in Oracle connection strings.

Here is a sample run of the script:
```
$ ./create-rcu-schema.sh -h
usage: ./create-rcu-schema.sh -s <schemaPrefix> [-t <schemaType>] [-d <dburl>] [-n <namespace>] [-c <credentialsSecretName>] [-p <docker-store>] [-i <image>] [-u <imagePullPolicy>] [-o <rcuOutputDir>] [-r <customVariables>] [-l <timeoutLimit>] [-b <databaseType>] [-e <edition>] [-h] 
  -s RCU Schema Prefix (required)
  -t RCU Schema Type (optional)
      (supported values: wcp,wcpp, default: wcp)
  -d RCU Oracle Database URL (optional)
      (default: oracle-db.default.svc.cluster.local:1521/devpdb.k8s)
  -n Namespace for RCU pod (optional)
      (default: default)
  -c Name of credentials secret (optional).
       (default: oracle-rcu-secret)
       Must contain SYSDBA username at key 'sys_username',
       SYSDBA password at key 'sys_password',
       and RCU schema owner password at key 'password'.
  -p OracleWebCenterPortal ImagePullSecret (optional)
      (default: none)
  -i OracleWebCenterPortal Image (optional)
      (default: oracle/wcportal:release-version)
  -u OracleWebCenterPortal ImagePullPolicy (optional)
      (default: IfNotPresent)
  -o Output directory for the generated YAML file. (optional)
      (default: rcuoutput)
  -r Comma-separated custom variables in the format variablename=value. (optional).
      (default: none)
  -l Timeout limit in seconds. (optional).
      (default: 300)
  -b Type of database to which you are connecting (optional). Supported values: ORACLE,EBR
      (default: ORACLE)
  -e The edition name. This parameter is only valid if you specify type of database (-b) as EBR. (optional).
      (default: 'ORA$BASE')
  -h Help

NOTE: The c, p, i, u, and o arguments are ignored if an rcu pod is already running in the namespace.
```
```shell
$ ${KUBERNETES_CLI:-kubectl} -n MYNAMESPACE create secret generic oracle-rcu-secret \
  --from-literal='sys_username=sys'
  --from-literal='sys_password=MY_SYS_PASSWORD'
  --from-literal='password=MY_RCU_SCHEMA_PASSWORD'
```
```shell
$ ./create-rcu-schema.sh -s domain1
ImagePullSecret[none] Image[oracle/wcportal:release-version] dburl[oracle-db.default.svc.cluster.local:1521/devpdb.k8s] rcuType[wcp] customVariables[none]
pod/rcu created
[rcu] already initialized ..
Checking Pod READY column for State [1/1]
Pod [rcu] Status is Ready Iter [1/60]
NAME   READY   STATUS    RESTARTS   AGE
rcu    1/1     Running   0          6s
NAME   READY   STATUS    RESTARTS   AGE
rcu    1/1     Running   0          11s
CLASSPATH=/u01/jdk/lib/tools.jar:/u01/oracle/wlserver/modules/features/wlst.wls.classpath.jar:

PATH=/u01/oracle/wlserver/server/bin:/u01/oracle/wlserver/../oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin:/u01/jdk/jre/bin:/u01/jdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle:/u01/oracle/wlserver/../oracle_common/modules/org.apache.maven_3.2.5/bin

Your environment has been set.
Check if the DB Service is ready to accept request
DB Connection String [oracle-db.default.svc.cluster.local:1521/devpdb.k8s], schemaPrefix [wcp-domain], rcuType [wcp], customVariables[none], databaseType [ORACLE]

**** Success!!! ****

You can connect to the database in your app using:

  java.util.Properties props = new java.util.Properties();
  props.put("user", "sys as sysdba");
  props.put("password", "Oradoc_db1");
  java.sql.Driver d =
    Class.forName("oracle.jdbc.OracleDriver").newInstance();
  java.sql.Connection conn =
    Driver.connect("sys as sysdba", props);
Creating RCU Schema for OracleWebCenterPortal Domain ...
Extra RCU Schema Component Choosen[]

Processing command line ....

Repository Creation Utility - Checking Prerequisites
Checking Component Prerequisites
Repository Creation Utility - Creating Tablespaces
Validating and Creating Tablespaces
Create tablespaces in the repository database
Repository Creation Utility - Create
Repository Create in progress.
Executing pre create operations
        Percent Complete: 20
        Percent Complete: 20
        .....
        Percent Complete: 96
        Percent Complete: 100
        .....
Executing post create operations

Repository Creation Utility: Create - Completion Summary

Database details:
-----------------------------
Host Name                                    : oracle-db.default.svc.cluster.local
Port                                         : 1521
Service Name                                 : DEVPDB.K8S
Connected As                                 : sys
Prefix for (prefixable) Schema Owners        : DOMAIN1
RCU Logfile                                  : /tmp/RCU2020-05-01_14-35_1160633335/logs/rcu.log

Component schemas created:
-----------------------------
Component                                    Status         Logfile

Common Infrastructure Services               Success        /tmp/RCU2020-05-01_14-35_1160633335/logs/stb.log
Oracle Platform Security Services            Success        /tmp/RCU2020-05-01_14-35_1160633335/logs/opss.log
Audit Services                               Success        /tmp/RCU2020-05-01_14-35_1160633335/logs/iau.log
Audit Services Append                        Success        /tmp/RCU2020-05-01_14-35_1160633335/logs/iau_append.log
Audit Services Viewer                        Success        /tmp/RCU2020-05-01_14-35_1160633335/logs/iau_viewer.log
Metadata Services                            Success        /tmp/RCU2020-05-01_14-35_1160633335/logs/mds.log
WebLogic Services                            Success        /tmp/RCU2020-05-01_14-35_1160633335/logs/wls.log

Repository Creation Utility - Create : Operation Completed
[INFO] Modify the domain.input.yaml to use [oracle-db.default.svc.cluster.local:1521/devpdb.k8s] as rcuDatabaseURL and [domain1] as rcuSchemaPrefix
```

## Drop the RCU schema from the Oracle Database

Use the `./drop-rcu-schema.sh` script to drop the RCU schema based `schemaPrefix` and `dburl`. The script works by deploying a pod named `rcu` (if one isn't already deployed) and running a script named `dropRepository.sh` in the pod.

The `rcu` pod assumes that either the image, `oracle/wcportal:release-version`, is available in the Docker image repository or an `ImagePullSecret` is created for `container-registry.oracle.com`. To create a secret for accessing `container-registry.oracle.com`, see `create-image-pull-secret.sh`.

The `rcu` pod requires that you create a secret in the same namespace as the `rcu` pod which contains the database's SYSDBA username and password in its `sys_username` and `sys_password` fields, and also contains the password of your choice for RCU schemas in its `password` field.

In the local shell:

```
$ ./drop-rcu-schema.sh -h
usage: ./drop-rcu-schema.sh -s <schemaPrefix> [-t <schemaType>] [-d <dburl>] [-n <namespace>] [-c <credentialsSecretName>] [-p <docker-store>] [-i <image>] [-u <imagePullPolicy>] [-o <rcuOutputDir>] [-r <customVariables>] [-b <databaseType>] [-e <edition>] [-h]
  -s RCU Schema Prefix (required)
  -t RCU Schema Type (optional)
      (supported values: wcp,wcpp, default: wcp)
  -d RCU Oracle Database URL (optional)
      (default: oracle-db.default.svc.cluster.local:1521/devpdb.k8s)
  -n Namespace for RCU pod (optional)
      (default: default)
  -c Name of credentials secret (optional).
       (default: oracle-rcu-secret)
       Must contain SYSDBA username at key 'sys_username',
       SYSDBA password at key 'sys_password',
       and RCU schema owner password at key 'password'.
  -p OracleWebCenterPortal ImagePullSecret (optional)
      (default: none)
  -i OracleWebCenterPortal Image (optional)
      (default: oracle/wcportal:release-version)
  -u OracleWebCenterPortal ImagePullPolicy (optional)
      (default: IfNotPresent)
  -o Output directory for the generated YAML file. (optional)
      (default: rcuoutput)
  -r Comma-separated custom variables in the format variablename=value. (optional).
      (default: none)
  -b Type of database to which you are connecting (optional). Supported values: ORACLE,EBR
      (default: ORACLE)
  -e The edition name. This parameter is only valid if you specify type of database (-b) as EBR. (optional).
      (default: 'ORA$BASE')	  
  -h Help

NOTE: The c, p, i, u, and o arguments are ignored if an rcu pod is already running in the namespace.
```

```shell
$ ${KUBERNETES_CLI:-kubectl} -n default create secret generic oracle-rcu-secret \
  --from-literal='sys_username=sys' \
  --from-literal='sys_password=MY_SYS_PASSWORD' \
  --from-literal='password=MY_RCU_SCHEMA_PASSWORD'
```
- Replace MY_DBA_PASSWORD with the same value that you chose when deploying the database.
- Replace MY_RCU_SCHEMA_PASSWORD with the same value you chose when creating the schema.

```shell
$ ./drop-rcu-schema.sh -s domain1
CLASSPATH=/u01/jdk/lib/tools.jar:/u01/oracle/wlserver/modules/features/wlst.wls.classpath.jar:

PATH=/u01/oracle/wlserver/server/bin:/u01/oracle/wlserver/../oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin:/u01/jdk/jre/bin:/u01/jdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle:/u01/oracle/wlserver/../oracle_common/modules/org.apache.maven_3.2.5/bin

Your environment has been set.
Check if the DB Service is ready to accept request
DB Connection String [oracle-db.default.svc.cluster.local:1521/devpdb.k8s] schemaPrefix [wcp-domain] rcuType[wcp] customVariables[none] databaseType [ORACLE]
**** Success!!! ****

You can connect to the database in your app using:

  java.util.Properties props = new java.util.Properties();
  props.put("user", "sys as sysdba");
  props.put("password", "Oradoc_db1");
  java.sql.Driver d =
    Class.forName("oracle.jdbc.OracleDriver").newInstance();
  java.sql.Connection conn =
    Driver.connect("sys as sysdba", props);
Dropping RCU Schema for OracleWebCenterPortal Domain ...
Extra RCU Schema Component(s) Choosen[]

Processing command line ....
Repository Creation Utility - Checking Prerequisites
Checking Global Prerequisites
Repository Creation Utility - Checking Prerequisites
Checking Component Prerequisites
Repository Creation Utility - Drop
Repository Drop in progress.
        Percent Complete: 2
        Percent Complete: 14
        .....
        Percent Complete: 99
        Percent Complete: 100
        .....

Repository Creation Utility: Drop - Completion Summary

Database details:
-----------------------------
Host Name                                    : oracle-db.default.svc.cluster.local
Port                                         : 1521
Service Name                                 : DEVPDB.K8S
Connected As                                 : sys
Prefix for (prefixable) Schema Owners        : DOMAIN1
RCU Logfile                                  : /tmp/RCU2020-05-01_14-42_651700358/logs/rcu.log

Component schemas dropped:
-----------------------------
Component                                    Status         Logfile

Common Infrastructure Services               Success        /tmp/RCU2020-05-01_14-42_651700358/logs/stb.log
Oracle Platform Security Services            Success        /tmp/RCU2020-05-01_14-42_651700358/logs/opss.log
Audit Services                               Success        /tmp/RCU2020-05-01_14-42_651700358/logs/iau.log
Audit Services Append                        Success        /tmp/RCU2020-05-01_14-42_651700358/logs/iau_append.log
Audit Services Viewer                        Success        /tmp/RCU2020-05-01_14-42_651700358/logs/iau_viewer.log
Metadata Services                            Success        /tmp/RCU2020-05-01_14-42_651700358/logs/mds.log
WebLogic Services                            Success        /tmp/RCU2020-05-01_14-42_651700358/logs/wls.log

Repository Creation Utility - Drop : Operation Completed
pod "rcu" deleted
Checking Status for Pod [rcu] in namesapce [default]
Error from server (NotFound): pods "rcu" not found
Pod [rcu] removed from nameSpace [default]
```

## Stop an Oracle Database service in a Kubernetes cluster

Use the script ``${WORKDIR}/create-oracle-db-service/stop-db-service.sh``

