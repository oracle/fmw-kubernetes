# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# This script removes the b2bui targets

import os
import sys
import re

#############################
# Entry point to the script #
#############################

def usage(status=0):
   print sys.argv[0] + '-domainName <domain_name> -domainHomeDir <domain_home>'
   sys.exit(status)

i=1
while i < len(sys.argv):
   if sys.argv[i] == '-domainName':
       domainName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-domainHomeDir':
       domainHome = sys.argv[i+1]
       i += 2
   else:
       print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
       usage(1)
       sys.exit(1)

try:
   readDomain(domainHome)
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
