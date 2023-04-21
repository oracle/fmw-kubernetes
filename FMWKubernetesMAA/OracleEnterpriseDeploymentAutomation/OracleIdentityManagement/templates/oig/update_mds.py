# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a WLST script to update the mds-oim Data source
#
connect('<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','t3://<OIG_DOMAIN_NAME>-adminserver.<OIGNS>.svc.cluster.local:<OIG_ADMIN_PORT>')
edit()
startEdit()
cd('/JDBCSystemResources/mds-oim/JDBCResource/mds-oim/JDBCConnectionPoolParams/mds-oim')
cmo.setInitialCapacity(50)
cmo.setMinCapacity(50)
cmo.setMaxCapacity(150)
cd('/JDBCSystemResources/mds-oim/JDBCResource/mds-oim/JDBCConnectionPoolParams/mds-oim')
cmo.setInactiveConnectionTimeoutSeconds(30)


save()
activate(block="true")
exit()


