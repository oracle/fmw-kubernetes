# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of an setUserOverrides.sh file for OAM
#
JAVA_OPTIONS="${JAVA_OPTIONS} -Djava.net.preferIPv4Stack=true"
MEM_ARGS="-Xms2048m -Xmx8192m"
#MEM_ARGS="-Xms3096m -Xmx8192m"
DERBY_FLAG=false
