# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example WLST script to Load the OAA Plugin into OAM
#
connect('<OAM_WEBLOGIC_USER>','<OAM_WEBLOGIC_PWD>','t3://<OAM_DOMAIN_NAME>-adminserver.<OAMNS>.svc.cluster.local:<OAM_ADMIN_PORT>')
oamCustomPluginInstallation(pluginName="OAAAuthnPlugin",sourcePath="/u01/oracle/user_projects/workdir")
exit()


