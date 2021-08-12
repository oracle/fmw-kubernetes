# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example WLST script to set the WebLogic Plugin
#
connect('<OAM_WEBLOGIC_USER>','<OAM_WEBLOGIC_PWD>','t3://<OAM_DOMAIN_NAME>-adminserver.<OAMNS>.svc.cluster.local:<OAM_ADMIN_PORT>')
edit()
startEdit()
cd('/WebAppContainer/<OAM_DOMAIN_NAME>')
cmo.setWeblogicPluginEnabled(true)
save()
activate(block="true")
exit()


