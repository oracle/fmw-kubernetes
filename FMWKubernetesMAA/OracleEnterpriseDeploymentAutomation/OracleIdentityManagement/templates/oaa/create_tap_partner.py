# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example WLST script to Register OAA as a TAP Partner of OAM
#
connect('<OAM_WEBLOGIC_USER>','<OAM_WEBLOGIC_PWD>','t3://<OAM_DOMAIN_NAME>-adminserver.<OAMNS>.svc.cluster.local:<OAM_ADMIN_PORT>')
registerThirdPartyTAPPartner(partnerName = "OAM-OAA-TAP", keystoreLocation= "/u01/oracle/user_projects/workdir/OAMOAAKeyStore.jks", password="<OAA_KEYSTORE_PWD>", tapTokenVersion="v2.0", tapScheme="TAPScheme", tapRedirectUrl="<OAM_LOGIN_LBR_PROTOCOL>://<OAM_LOGIN_LBR_HOST>:<OAM_LOGIN_LBR_PORT>/oam/pages/login.jsp")
exit()


