#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example script to generate OIGOAMIntegration.sh property files
#
sed -i /u01/oracle/idm/server/ssointg/config/configureWLSAuthnProviders.config -f /u01/oracle/user_projects/workdir/oamoig.sedfile
sed -i /u01/oracle/idm/server/ssointg/config/configureWLSAuthnProviders.config -f /u01/oracle/user_projects/workdir/autn.sedfile
sed -i /u01/oracle/idm/server/ssointg/config/configureLDAPConnector.config -f /u01/oracle/user_projects/workdir/oamoig.sedfile
sed -i /u01/oracle/idm/server/ssointg/config/addMissingObjectClasses.config -f /u01/oracle/user_projects/workdir/oamoig.sedfile
sed -i /u01/oracle/idm/server/ssointg/config/configureSSOIntegration.config -f /u01/oracle/user_projects/workdir/oamoig.sedfile
sed -i /u01/oracle/idm/server/ssointg/config/enableOAMSessionDeletion.config -f /u01/oracle/user_projects/workdir/oamoig.sedfile

exit
