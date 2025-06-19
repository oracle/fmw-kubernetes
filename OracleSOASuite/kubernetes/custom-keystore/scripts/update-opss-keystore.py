# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys

def importKeystoreCertificateToOPSS(keyStoreFilePath, identityPassword, identityType, domainca):
        svc = getOpssService(name='KeyStoreService')
        svc.importKeyStore(appStripe='system', name='castore', password=identityPassword, aliases=domainca,keypasswords=identityPassword, type=identityType, permission=true, filepath=keyStoreFilePath)
        svc.listKeyStoreAliases(appStripe='system', name='castore', password='', type='Certificate')
        svc.exportKeyStoreCertificate(appStripe='system', name='castore', password=identityPassword, alias=domainca, type='Certificate', filepath='/tmp/cert.txt')
        svc.importKeyStoreCertificate(appStripe='system', name='trust', password=identityPassword, alias=domainca, keypassword=identityPassword, type='TrustedCertificate', filepath='/tmp/cert.txt')
        svc.listKeyStoreAliases(appStripe='system', name='trust', password=identityPassword, type='TrustedCertificate')

def updateServiceInstanceProperty(si, key, val):
        on = ObjectName("com.oracle.jps:type=JpsConfig")
        sign = ["java.lang.String", "java.lang.String","java.lang.String"]
        params = [si,key,val]
        mbs.invoke(on,"updateServiceInstanceProperty", params, sign)
        mbs.invoke(on, "persist", None, None)

#========================================================
# Main program here...
# Target you can change as per your need
#========================================================

def usage():
    argsList = ' -domainName <domainUID> -adminURL <adminURL> -username <username> -password <password> -keyStoreFilePath <keyStoreFilePath> -identityPassword <identityPassword> -identityType <identityType> -si <si> -key <key> -value <val>'
    print sys.argv[0] + argsList
    sys.exit(0)

if len(sys.argv) < 1:
    usage()

# domainName will be passed by command line parameter -domainName.
domainName = "soainfra"

# keyStoreFilePath will be passed by command line parameter  -keyStoreFilePath
keyStoreFilePath = "/tmp/file.p12"

# adminURL will be passed by command line parameter  -adminURL
adminURL = "t3s://soainfra-adminserver:9002"

# username will be passed by command line parameter  -username
username = "weblogic"

# password will be passed by command line parameter -password
password = "Welcome1"

# identityPassword will be passed by command line parameter -identityPassword
identityPassword = "identityStorePassword" 

# identityType will be passed by command line parameter -identityType
identityType = "PKCS12"

# val will be passed by command line parameter -value
val = None

# key will be passed by command line parameter -key
key = None

# si will be passed by command line parameter -si
si  = None

i=1
while i < len(sys.argv):
   if sys.argv[i] == '-domainName':
       domainName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-adminServerName':
       adminServerName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-adminURL':
       adminURL = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-username':
       username = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-password':
       password = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-keyStoreFilePath':
       keyStoreFilePath = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-identityPassword':
       identityPassword = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-identityType':
       identityType = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-si':
       si = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-key':
       key = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-value':
       val = sys.argv[i+1]
       i += 2
   else:
       print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
       usage()
       sys.exit(1)


connect(username, password, adminURL)
importKeystoreCertificateToOPSS(keyStoreFilePath,identityPassword,identityType,val)
domainRuntime()
updateServiceInstanceProperty(si,key,val)

