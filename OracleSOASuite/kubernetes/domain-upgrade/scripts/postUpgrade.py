# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys
import re

def read_password_from_stdin():
    print("Enter schema password:")
    return sys.stdin.readline().strip()

def usage(status=0):
   print sys.argv[0] + '-domainName <domain_name> -domainHomeDir <domain_home>' + \
   '-connectionString <connection_string> -rcuPrefix <rcu_prefix>'
   sys.exit(status)

#############################
# Entry point to the script #
#############################

schemaPassword = read_password_from_stdin()
if not schemaPassword:
    raise ValueError("Schema password is required")
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
   else:
       print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
       usage(1)
       sys.exit(1)

print 'Post upgrade changes in progress ....'
wlsRuntimeUser=rcuPrefix + '_WLS_RUNTIME'
print 'Updating the JDBC data source for schema ' + wlsRuntimeUser
try:
   readDomain(domainHome)
   cd('/JdbcSystemResource/WLSRuntimeSchemaDataSource/JdbcResource/WLSRuntimeSchemaDataSource/JdbcDriverParams/NO_NAME_0')
   dbUrl="jdbc:oracle:thin:@" + connectionString
   cmo.setUrl(dbUrl)
   cmo.setDriverName('oracle.jdbc.OracleDriver')
   set('PasswordEncrypted', schemaPassword)
   cd('Properties/NO_NAME_0/Property/user')
   cmo.setValue(wlsRuntimeUser)
   print 'Updating the JDBC data source for schema ' + wlsRuntimeUser + ' completed'
   print 'Preparing to update domain...'
   cd('/')
   updateDomain()
   closeDomain()
except:
   dumpStack()
   print 'Updating the JDBC data source for schema ' + wlsRuntimeUser + ' failed'
   print 'Review the logs for details'
   sys.exit(1)
sys.exit(0)

