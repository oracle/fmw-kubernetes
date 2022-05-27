connect('<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','t3://<OIG_DOMAIN_NAME>-adminserver.<OIGNS>.svc.cluster.local:<OIG_ADMIN_PORT>')
grantAppRole(appStripe="soa-infra",  appRoleName="SOAAdmin",principalClass="weblogic.security.principal.WLSGroupImpl", principalName="<LDAP_WLSADMIN_GRP>")
grantAppRole(appStripe="wsm-pm",  appRoleName="policy.Updater",principalClass="weblogic.security.principal.WLSGroupImpl", principalName="<LDAP_WLSADMIN_GRP>")
exit()
