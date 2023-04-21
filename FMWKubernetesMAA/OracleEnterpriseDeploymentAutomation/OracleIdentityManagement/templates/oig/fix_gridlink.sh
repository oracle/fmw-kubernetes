#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example script to enable FAN in datasources
#
cd <PV_MOUNT>/domains/<OIG_DOMAIN_NAME>/config
grep -L fan-enabled jdbc/*.xml | xargs sed -i "s/<\/jdbc-data-source>/<jdbc-oracle-params><fan-enabled>true<\/fan-enabled><\/jdbc-oracle-params><\/jdbc-data-source>/g"
grep -L fan-enabled fmwconfig/jps-config.xml | xargs sed -i "s/<\/jdbc-data-source>/<jdbc-oracle-params><fan-enabled>true<\/fan-enabled><\/jdbc-oracle-params><\/jdbc-data-source>/g"
exit
