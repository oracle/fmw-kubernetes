#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of using oamreg to create a Webgate Agent
#
echo -e "<OUD_OAMADMIN_USER>\n<OUD_USER_PWD>\nn" | /u01/oracle/idm/oam/server/rreg/bin/oamreg.sh inband <PV_MOUNT>/workdir/Webgate_IDM.xml -noprompt
cp -r /u01/oracle/idm/oam/server/rreg/output/Webgate_IDM /u01/oracle/user_projects/domains/<OAM_DOMAIN_NAME>/output
