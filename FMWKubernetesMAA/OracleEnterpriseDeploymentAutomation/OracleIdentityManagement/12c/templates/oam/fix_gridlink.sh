#!/bin/bash
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of using sed to enable FAN in datasources
#
cd <PV_MOUNT>/domains/<OAM_DOMAIN_NAME>/config
grep -L fan-enabled jdbc/*.xml | xargs sed -i "s/<\/jdbc-data-source>/<jdbc-oracle-params><fan-enabled>true<\/fan-enabled><\/jdbc-oracle-params><\/jdbc-data-source>/g"
grep -L fan-enabled fmwconfig/jps-config.xml | xargs sed -i "s/<\/jdbc-data-source>/<jdbc-oracle-params><fan-enabled>true<\/fan-enabled><\/jdbc-oracle-params><\/jdbc-data-source>/g"
exit
