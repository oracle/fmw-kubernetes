# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a WLST script to set the WebLogic Plugin
#
connect('<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','t3://<OIG_DOMAIN_NAME>-adminserver.<OIGNS>.svc.cluster.local:<OIG_ADMIN_PORT>')
edit()
startEdit()
cd('/WebAppContainer/<OIG_DOMAIN_NAME>')
cmo.setWeblogicPluginEnabled(true)
save()
activate(block="true")
exit()


