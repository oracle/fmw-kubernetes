#!/usr/bin/python
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of script to update the SOAConfig Mbean
#

import os, sys


connect('<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','t3://<OIG_DOMAIN_NAME>-oim-server1.<OIGNS>.svc.cluster.local:14000')
msBean = ObjectName('oracle.iam:name=SOAConfig,type=XMLConfig.SOAConfig,XMLConfig=Config,Application=oim')
soaconfig = mbs.setAttribute(msBean,Attribute('Soapurl','http://<OIG_DOMAIN_NAME>-cluster-soa-cluster.<OIGNS>.svc.cluster.local:8001'))
print soaconfig
disconnect()
exit()

