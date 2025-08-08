# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys

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

try:
   print 'Enabling secure domain in progress ....'
   readDomain(domainHome)
   cd('/SecurityConfiguration/' + domainName)
   create('NO_NAME_0', 'SecureMode')
   cd('SecureMode/NO_NAME_0')
   set('SecureModeEnabled', true)
except:
   dumpStack()
print 'Preparing to update domain...'
cd('/')
updateDomain()
closeDomain()
sys.exit(0)

