#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example file to compile java program and set the Compliance Flag in the OIG Database
#
export JAVA_HOME=/u01/jdk
export CLASSPATH=/u01/oracle/oracle_common/modules/oracle.jdbc/ojdbc8.jar:/u01/oracle/user_projects/workdir
echo "Compiling Java Code:"

javac /u01/oracle/user_projects/workdir/setCompliance.java -Xlint:deprecation -Xlint:unchecked

echo "Running Code"
java setCompliance <OIG_DB_SCAN>:<OIG_DB_LISTENER>/<OIG_DB_SERVICE> <OIG_RCU_PREFIX>_OIM <OIG_SCHEMA_PWD>
