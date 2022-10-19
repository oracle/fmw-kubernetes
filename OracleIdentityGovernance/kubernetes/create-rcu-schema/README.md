# Managing RCU schema for a OracleIdentityGovernance domain

The sample scripts in this directory demonstrate how to:
* Create an RCU schema in the Oracle DB that will be used by a OracleIdentityGovernance domain.
* Delete the RCU schema in the Oracle DB used by a OracleIdentityGovernance domain.

## Start an Oracle Database service in a Kubernetes cluster

Use the script ``samples/scripts/create-oracle-db-service/start-db-service.sh``

For creating a OracleIdentityGovernance domain, you can use the Database connection string, `oracle-db.default.svc.cluster.local:1521/devpdb.k8s`, as an `rcuDatabaseURL` parameter in the `domain.input.yaml` file.

You can access the Database through the NodePort outside of the Kubernetes cluster, using the URL  `<hostmachine>:30011/devpdb.k8s`.

**Note**: To create a OracleIdentityGovernance domain image, the domain-in-image model needs a public Database URL as an `rcuDatabaseURL` parameter.


## Create the RCU schema in the Oracle Database

This script generates the RCU schema based `schemaPrefix` and `dburl`.

The script assumes that either the image, `oracle/oig:12.2.1.4.0`, is available in the nodes or an `ImagePullSecret` is created to pull the image. To create a secret, see the script `create-image-pull-secret.sh`.

```
$ ./create-rcu-schema.sh -h
usage: ./create-rcu-schema.sh -s <schemaPrefix> -t <schemaType> -d <dburl> -i <image> -u <imagePullPolicy> -p <docker-store> -n <namespace> -q <sysPassword> -r <schemaPassword>  -o <rcuOutputDir>  -c <customVariables> [-l] <timeoutLimit> [-h]
  -s RCU Schema Prefix (required)
  -t RCU Schema Type (optional)
      (supported values: oim)
  -d RCU Oracle Database URL (optional)
      (default: oracle-db.default.svc.cluster.local:1521/devpdb.k8s)
  -p OracleIdentityGovernance ImagePullSecret (optional)
      (default: none)
  -i OracleIdentityGovernance Image (optional)
      (default: oracle/oig:12.2.1.4.0)
  -u OracleIdentityGovernance ImagePullPolicy (optional)
      (default: IfNotPresent)
  -n Namespace for RCU pod (optional)
      (default: default)
  -q password for database SYSDBA user. (optional)
      (default: Oradoc_db1)
  -r password for all schema owner (regular user). (optional)
      (default: Oradoc_db1)
  -o Output directory for the generated YAML file. (optional)
      (default: rcuoutput)
  -c Comma-separated variables in the format variablename=value. (optional).
      (default: none)
  -l Timeout limit in seconds. (optional).
      (default: 300)
  -h Help

$ ./create-rcu-schema.sh -s domain1
ImagePullSecret[none] Image[oracle/oig:12.2.1.4.0] dburl[oracle-db.default.svc.cluster.local:1521/devpdb.k8s] rcuType[oig] customVariables[none]
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
DB Connection String [oracle-db.default.svc.cluster.local:1521/devpdb.k8s], schemaPrefix [oimcluster] rcuType [oig]

**** Success!!! ****

You can connect to the database in your app using:

  java.util.Properties props = new java.util.Properties();
  props.put("user", "sys as sysdba");
  props.put("password", "Oradoc_db1");
  java.sql.Driver d =
    Class.forName("oracle.jdbc.OracleDriver").newInstance();
  java.sql.Connection conn =
    Driver.connect("sys as sysdba", props);
Creating RCU Schema for OracleIdentityGovernance Domain ...
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

Use this script to drop the RCU schema based `schemaPrefix` and `dburl`.

```
$ ./drop-rcu-schema.sh -h
usage: ./drop-rcu-schema.sh -s <schemaPrefix> -d <dburl> -n <namespace> -q <sysPassword> -r <schemaPassword> [-h]
  -s RCU Schema Prefix (required)
  -t RCU Schema Type (optional)
      (supported values: oim)
  -d Oracle Database URL (optional)
      (default: oracle-db.default.svc.cluster.local:1521/devpdb.k8s)
  -n Namespace where RCU pod is deployed (optional)
      (default: default)
  -q password for database SYSDBA user. (optional)
      (default: Oradoc_db1)
  -r password for all schema owner (regular user). (optional)
      (default: Oradoc_db1)
  -c Comma-separated variables in the format variablename=value. (optional).
      (default: none)      
  -h Help

$ ./drop-rcu-schema.sh -s domain1
CLASSPATH=/u01/jdk/lib/tools.jar:/u01/oracle/wlserver/modules/features/wlst.wls.classpath.jar:

PATH=/u01/oracle/wlserver/server/bin:/u01/oracle/wlserver/../oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin:/u01/jdk/jre/bin:/u01/jdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/u01/jdk/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle:/u01/oracle/wlserver/../oracle_common/modules/org.apache.maven_3.2.5/bin

Your environment has been set.
Check if the DB Service is ready to accept request
DB Connection String [oracle-db.default.svc.cluster.local:1521/devpdb.k8s] schemaPrefix [domain1] rcuType[oig]

**** Success!!! ****

You can connect to the database in your app using:

  java.util.Properties props = new java.util.Properties();
  props.put("user", "sys as sysdba");
  props.put("password", "Oradoc_db1");
  java.sql.Driver d =
    Class.forName("oracle.jdbc.OracleDriver").newInstance();
  java.sql.Connection conn =
    Driver.connect("sys as sysdba", props);
Dropping RCU Schema for OracleIdentityGovernance Domain ...
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

Use the script ``samples/scripts/create-oracle-db-service/stop-db-service.sh``

