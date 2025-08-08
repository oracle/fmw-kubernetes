# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys

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
       usage()
       sys.exit(1)

print 'Domain upgrade in progress ....'
try:
  readDomainForUpgrade(domainHome)
  print 'Preparing to update domain '+ domainName
  updateDomain()
  print 'Domain upgrade completed ....'
  closeDomain()
except Exception, e:
  if 'The domain is already at the current version' in str(e):
     print "Domain " + domainName + " already upgraded to current version."
     print "Review and perform domain updates manually, if anything missed."
     sys.exit(0)
  else:
     dumpStack()
     sys.exit(1)
sys.exit(0)

