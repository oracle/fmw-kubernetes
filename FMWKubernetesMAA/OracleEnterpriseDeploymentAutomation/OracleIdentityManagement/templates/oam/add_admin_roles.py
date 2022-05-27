# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of using WLST to add LDAP groups to the WebLogic Administration Role
#
connect('<OAM_WEBLOGIC_USER>','<OAM_WEBLOGIC_PWD>','t3://<OAM_DOMAIN_NAME>-adminserver.<OAMNS>.svc.cluster.local:30012')
cd('/SecurityConfiguration/<OAM_DOMAIN_NAME>/Realms/myrealm/RoleMappers/XACMLRoleMapper')
cmo.setRoleExpression('', 'Admin', 'Grp(<LDAP_OAMADMIN_GRP>)|Grp(<LDAP_WLSADMIN_GRP>)|Grp(Administrators)')
exit()

EOF

