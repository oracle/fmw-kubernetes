#!/usr/bin/python
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a WLST script to update the OIMSOAIntegration MBean
#

import os, sys

connect('<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','t3://<OIG_DOMAIN_NAME>-oim-server1.<OIGNS>.svc.cluster.local:14000')
custom()
msBean = ObjectName('oracle.iam:name=OIMSOAIntegrationMBean,type=IAMAppRuntimeMBean,Application=oim')
params = ['<OIG_WEBLOGIC_USER>','<OIG_WEBLOGIC_PWD>','http://<OIG_LBR_INT_HOST>:<OIG_LBR_INT_PORT>/','<OIG_LBR_PROTOCOL>://<OIG_LBR_HOST>:<OIG_LBR_PORT>/','http://<OIG_DOMAIN_NAME>-cluster-soa-cluster.<OIGNS>.svc.cluster.local:8001/','t3://<OIG_DOMAIN_NAME>-cluster-soa-cluster.<OIGNS>.svc.cluster.local:8001','http://<OIG_DOMAIN_NAME>-cluster-soa-cluster.<OIGNS>.svc.cluster.local:8001/ucs/messaging/webservice/']
sign = ['java.lang.String', 'java.lang.String','java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String', 'java.lang.String']
intgresult = mbs.invoke(msBean, 'integrateWithSOAServer', params, sign)
print intgresult
disconnect()
exit()

