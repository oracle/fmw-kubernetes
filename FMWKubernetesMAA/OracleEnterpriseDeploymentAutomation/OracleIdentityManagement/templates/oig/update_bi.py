#!/usr/bin/python
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a WLST script to update BI Integration Parameters
#

import os, sys


connect('<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','t3://<OIG_DOMAIN_NAME>-oim-server1.<OIGNS>.svc.cluster.local:14000')
msBean = ObjectName('oracle.iam:name=Discovery,type=XMLConfig.DiscoveryConfig,XMLConfig=Config,Application=oim')
biconfig = mbs.setAttribute(msBean,Attribute('BIPublisherURL','<OIG_BI_PROTOCOL>://<OIG_BI_HOST>:<OIG_BI_PORT>'))
print biconfig
disconnect()
connect('<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','t3://<OIG_DOMAIN_NAME>-adminserver.<OIGNS>.svc.cluster.local:<OIG_ADMIN_PORT>')
updateCred(map='oim',key='BIPWSKey',user='<OIG_BI_USER>',password='<OIG_BI_USER_PWD>')
exit()

exit
