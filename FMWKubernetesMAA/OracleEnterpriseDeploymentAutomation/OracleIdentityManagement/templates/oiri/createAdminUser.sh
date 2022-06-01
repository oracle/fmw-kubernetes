#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example file to compile java program and Run Recon Jobs
#
export JAVA_HOME=/u01/jdk
export CLASSPATH=/u01/oracle/idm/oam/server/rreg/lib/commons-logging.jar:/u01/oracle/oracle_common/modules/oracle.jrf/jrf-api.jar:/u01/oracle/soa/plugins/jdeveloper/bpm/libraries/log4j-1.2.8.jar:/u01/oracle/idm/server/client/oimclient.jar:/u01/oracle/oracle_common/modules/clients/com.oracle.webservices.fmw.client.jar:/u01/oracle/idm/server/idmdf/event-recording-client.jar:/u01/oracle/idm/server/idmdf/idmdf-common.jar:/u01/oracle/idm/designconsole/ext/wlthint3client.jar:/u01/oracle/soa/soa/modules/quartz-all-1.6.5.jar:/u01/oracle/oracle_common/modules/oracle.mds/mdsrt.jar:/u01/oracle/oracle_common/modules/oracle.jdbc/ojdbc8.jar:/u01/oracle/user_projects/workdir
echo "Compiling Java Code:"

javac /u01/oracle/user_projects/workdir/createAdminUser.java -Xlint:deprecation -Xlint:unchecked > createAdminUser_compile.log 2> createAdminUser_compile_err.log

java -Djava.security.policy=/u01/oracle/user_projects/workdir/lib/xl.policy -Djava.security.auth.login.config=/u01/oracle/user_projects/workdir/lib/authwl.conf -DAPPSERVER_TYPE=wls -Dweblogic.Name=oim_server1 createAdminUser t3://<OIG_DOMAIN_NAME>-oim-server1.oigns.svc.cluster.local:14000/ <LDAP_XELSYSADM_USER> <LDAP_USER_PWD> <OIRI_SERVICE_USER> <OIRI_SERVICE_PWD> <OIRI_ENG_USER> <OIRI_ENG_PWD>  <OIRI_ENG_GROUP>


