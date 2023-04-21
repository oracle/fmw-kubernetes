# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example WLST script to Add LDAP users to the WebLogic Administration Role
#
connect('<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','t3://<OIG_DOMAIN_NAME>-adminserver.<OIGNS>.svc.cluster.local:<OIG_ADMIN_PORT>')
cd('/SecurityConfiguration/governancedomain/Realms/myrealm/RoleMappers/XACMLRoleMapper')
cmo.setRoleExpression('', 'Admin', 'Grp(WLSAdministrators)|Grp(Administrators)')
exit()


