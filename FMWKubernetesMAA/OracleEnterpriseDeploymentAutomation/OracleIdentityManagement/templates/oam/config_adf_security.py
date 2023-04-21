# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of using WLST to add logout to ADF pages
#
connect('<OAM_WEBLOGIC_USER>','<OAM_WEBLOGIC_PWD>','t3://<OAM_DOMAIN_NAME>-adminserver.<OAMNS>.svc.cluster.local:<OAM_ADMIN_PORT>')
addOAMSSOProvider(loginuri="/${app.context}/adfAuthentication", logouturi="/oam/logout.html")
exit()


