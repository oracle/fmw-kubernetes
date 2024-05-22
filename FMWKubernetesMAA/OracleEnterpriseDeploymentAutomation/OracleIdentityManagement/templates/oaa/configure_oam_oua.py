# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example WLST script to Register OAA as a TAP Partner of OAM
#
connect('<OAM_WEBLOGIC_USER>','<OAM_WEBLOGIC_PWD>','t3://<OAM_DOMAIN_NAME>-adminserver.<OAMNS>.svc.cluster.local:<OAM_ADMIN_PORT>')
editUserIdentityStore(name='OAMIDSTORE',enablePasswordPolicy='true',idStorePwdSchema='Oblix',idStoreGlobalUserId='uid',idStoreChallengeQuestions='mail',idStoreChallengeAnswers='pager',isNative='true')
configurePersistentLogin(enable="true",validityInDays="30", maxAuthnLevel="2", userAttribute="obPSFTID")
exit()
