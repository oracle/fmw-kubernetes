# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a WLST script to set the connection pool parameters on the oamDS Datasource
#
connect('<OAM_WEBLOGIC_USER>','<OAM_WEBLOGIC_PWD>','t3://<OAM_DOMAIN_NAME>-adminserver.<OAMNS>.svc.cluster.local:30012')
edit()
startEdit()
cd('/JDBCSystemResources/oamDS/JDBCResource/oamDS/JDBCConnectionPoolParams/oamDS')
cmo.setInitialCapacity(800)
cmo.setMinCapacity(800)
cmo.setMaxCapacity(800)
save()
activate(block="true")
exit()


