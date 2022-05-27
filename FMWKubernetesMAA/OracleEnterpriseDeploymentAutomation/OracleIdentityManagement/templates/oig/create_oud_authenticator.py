# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example WLST script to create the OUD Authenticator
#
connect('<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','t3://<OIG_DOMAIN_NAME>-adminserver.<OIGNS>.svc.cluster.local:<OIG_ADMIN_PORT>')
edit()
startEdit()
cd('/SecurityConfiguration/governancedomain/Realms/myrealm')
cmo.destroyAuthenticationProvider(getMBean('/SecurityConfiguration/governancedomain/Realms/myrealm/AuthenticationProviders/OUDAuthenticator'))
cmo.destroyAuthenticationProvider(getMBean('/SecurityConfiguration/governancedomain/Realms/myrealm/AuthenticationProviders/OIMSignatureAuthenticator'))
cmo.createAuthenticationProvider('OUDAuthenticator', 'weblogic.security.providers.authentication.OracleUnifiedDirectoryAuthenticator')

cd('/SecurityConfiguration/governancedomain/Realms/myrealm/AuthenticationProviders/OUDAuthenticator')
cmo.setControlFlag('OPTIONAL')
cmo.setControlFlag('SUFFICIENT')
cmo.setGroupBaseDN('<LDAP_GROUP_SEARCHBASE>')
cmo.setPort(1389)
cmo.setUseRetrievedUserNameAsPrincipal(true)
cmo.setUserBaseDN('<LDAP_USER_SEARCHBASE>')
cmo.setPrincipal('cn=<LDAP_OIGLDAP_USER>,cn=<LDAP_SYSTEMIDS>,<LDAP_SEARCHBASE>')
set("Credential",'<LDAP_USER_PWD>')
cmo.setHost('<OUD_POD_PREFIX>-oud-ds-rs-lbr-ldap.<OUDNS>.svc.cluster.local')
cmo.setAllGroupsFilter('(&(cn=*)(objectclass=groupOfUniqueNames))')
cmo.setGroupFromNameFilter('(&(cn=%g)(objectclass=groupOfUniqueNames))')
cmo.setUserNameAttribute('uid')

cd('/SecurityConfiguration/governancedomain/Realms/myrealm')
set('AuthenticationProviders',jarray.array([ObjectName('Security:Name=myrealmOAMIDAsserter'), ObjectName('Security:Name=myrealmOIMAuthenticationProvider'), ObjectName('Security:Name=myrealmOUDAuthenticator'), ObjectName('Security:Name=myrealmTrust Service Identity Asserter'), ObjectName('Security:Name=myrealmDefaultAuthenticator'), ObjectName('Security:Name=myrealmDefaultIdentityAsserter')], ObjectName))
save()
activate(block="true")
exit()
