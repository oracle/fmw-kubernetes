# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys
import re

i=1
while i < len(sys.argv):
   if sys.argv[i] == '-domainName':
       domainName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-domainHomeDir':
       domainHome = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-connectionString':
       connectionString = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-rcuPrefix':
       rcuPrefix = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-schemaPassword':
       schemaPassword = sys.argv[i+1]
       i += 2
   else:
       print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
       usage()
       sys.exit(1)

print 'Domain upgrade in progress ....'
try:
  readDomainForUpgrade(domainHome)
  print 'Preparing to update domain...'
  updateDomain()
  print 'Domain upgrade completed ....'
except Exception, e:
  if 'The domain is already at the current version' in str(e):
     print "Domain already upgraded to current version."
     print "Exiting from domain upgrade progress. Review and perform the updates manually."
     sys.exit(0)
  else:
     dumpStack()
     sys.exit(1)
print 'Post upgrade changes in progess ....'
wlsRuntimeUser=rcuPrefix + '_WLS_RUNTIME'
print 'Updating the JDBC data source for schema ' + wlsRuntimeUser
try:
   cd('/JdbcSystemResource/WLSRuntimeSchemaDataSource/JdbcResource/WLSRuntimeSchemaDataSource/JdbcDriverParams/NO_NAME_0')
   dbUrl="jdbc:oracle:thin:@" + connectionString
   cmo.setUrl(dbUrl)
   cmo.setDriverName('oracle.jdbc.OracleDriver')
   set('PasswordEncrypted', schemaPassword)
   cd('Properties/NO_NAME_0/Property/user')
   cmo.setValue(wlsRuntimeUser)
   print 'Updating the JDBC data source for schema ' + wlsRuntimeUser + ' completed'
except:
   dumpStack()
   print 'Updating the JDBC data source for schema ' + wlsRuntimeUser + ' failed'
   print 'Ignoring and continuing with the other upgrades. Review and update manually if required'

print 'Removing the b2bui targets if exists.'
try:
   appList = re.findall('b2bui', ls('/AppDeployment'))
   if len(appList) >=1:
      cd ('/AppDeployment/b2bui')
      unassign("AppDeployment", "b2bui", "Target", "soa_cluster")
except:
   dumpStack()
   print 'Ignoring and continuing. Review and update manually if required'
print 'Preparing to update domain...'
cd('/')
updateDomain()
sys.exit(0)
