# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys


def setCustomKeystore(domainHome,identityFile,identityType,identityPassword,trustFile,trustType,trustPassword,identityAlias):
     servers = cmo.getServers()
     for s in servers:
        serverName = s.getName()        
        cd('/Server/' + serverName)
        set('DefaultInternalServletsDisabled','true')
        cmo.setKeyStores('CustomIdentityAndCustomTrust')
        cmo.setCustomIdentityKeyStoreFileName(identityFile)
        cmo.setCustomIdentityKeyStoreType(identityType)
        set('CustomIdentityKeyStorePassPhraseEncrypted',identityPassword)
        cmo.setCustomTrustKeyStoreFileName(trustFile)
        cmo.setCustomTrustKeyStoreType(trustType)
        set('CustomTrustKeyStorePassPhraseEncrypted', trustPassword)
        ls()
        cd('SSL/' + serverName)
        cmo.setServerPrivateKeyAlias(identityAlias)
        set('ServerPrivateKeyPassPhraseEncrypted',identityPassword)
        cmo.setHostnameVerificationIgnored(false)
        cmo.setHostnameVerifier(None)
        cmo.setTwoWaySSLEnabled(false)
        cmo.setClientCertificateEnforced(false)
        cmo.setJSSEEnabled(true)
        ls()

def configureCustomKeystores(domainName, identityFile, identityType, identityPassword, trustFile, trustType, trustPassword, identityAlias):
     domainHome = domainParentDir + '/' + domainName
     readDomain(domainHome)
     setCustomKeystore(domainHome,identityFile,identityType,identityPassword,trustFile,trustType,trustPassword,identityAlias)
     updateDomain()
     closeDomain()

#############################
# Entry point to the script #
#############################

def usage():
    print sys.argv[0] + ' -oh <oracle_home> -jh <java_home> -parent <domain_parent_dir> -name <domain-name> -identityFile <identityFile> -identityType <identity_keystore_type> -identityPassword <identity_keystore_password> -trustFile <trust_keystore_file> -trustType <trust_keystore_type> -trustPassword <trust_keystore_password> -identityAlias <identityAlias> '
    sys.exit(0)


if len(sys.argv) < 11:
    usage()

#oracleHome will be passed by command line parameter -oh.
oracleHome = None
#javaHome will be passed by command line parameter -jh.
javaHome = None
#domainParentDir will be passed by command line parameter -parent.
domainParentDir = None
#identityFile will be passed by command line parameter -identityFile.
identityFile = None
#identityType will be passed by command line parameter -identityType.
identityType = None
#identityPassword will be passed by command line parameter -identityPassword.
identityPassword = None
#trustFile will be passed by command line parameter -trustFile.
trustFile = None
#trustType will be passed by command line parameter -trustType.
trustType = None
#trustPassword will be passed by command line parameter -trustPassword.
trustPassword = None
#identityAlias will be passed by command line parameter -identityAlias.
identityAlias = None

i = 1
while i < len(sys.argv):
    if sys.argv[i] == '-oh':
        oracleHome = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-jh':
        javaHome = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-parent':
        domainParentDir = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-name':
        domainName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-identityFile':
        identityFile = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-identityType':
        identityType = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-identityPassword':
        identityPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-trustFile':
        trustFile = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-trustType':
        trustType = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-trustPassword':
        trustPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-identityAlias':
        identityAlias = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

configureCustomKeystores(domainName, identityFile, identityType, identityPassword, trustFile, trustType, trustPassword, identityAlias)

