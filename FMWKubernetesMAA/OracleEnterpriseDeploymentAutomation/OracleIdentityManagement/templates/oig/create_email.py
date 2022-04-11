# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example WLST script to Create an UMS Email Driver
#
connect('<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','t3://<OIG_DOMAIN_NAME>-adminserver.<OIGNS>.svc.cluster.local:<OIG_ADMIN_PORT>')
driverProperties=EmailDriverProperties()
driverProperties.OutgoingMailServer='<OIG_EMAIL_SERVER>'
driverProperties.OutgoingMailServerPort='<OIG_EMAIL_PORT>'
driverProperties.Capability='SEND'
driverProperties.RetryLimit='3'
driverProperties.IncomingMailServer='None'
driverProperties.IncomingMailIDs = 'none@hostname'
driverProperties.IncomingUserIDs = 'none@hostname'
driverProperties.OutgoingDefaultFromAddr='none@hostname'
driverProperties.OutgoingMailServerSecurity='<OIG_EMAIL_SECURITY>'
driverProperties.DefaultFromAddress='<OIG_EMAIL_ADDRESS>'
driverProperties.OutgoingUsername='<OIG_EMAIL_ADDRESS>'
driverProperties.OutgoingPassword='<OIG_EMAIL_PWD>'
configUserMessagingDriver(baseDriver='email',appName='EmailDriver1',driverProperties=driverProperties,clusterName='soa_cluster')

exit()


