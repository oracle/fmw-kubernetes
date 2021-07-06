# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
import sys
#======================================================= 
# Function for undeployment
#======================================================= 
def unDeploy(appName,target):
   print 'Undeploying .........'
   try:
     stopApplication(appName)
     undeploy(appName, target)
   except Exception, ex:
     print ex.toString()
    
#======================================================== 
# Main program here...
# Target you can change as per your need
#========================================================  
def usage():
    print sys.arg[0] + '-domainName <domainUID> -domainType <domaintype> -adminServerName <adminServerName> -adminURL <adminURL> -username <username> -password <password>'
    sys.exit(0)

if len(sys.argv) < 1:
    usage()

#domainName will be passed by command line parameter -domainName.
domainName = "soainfra"

#domaintype will be passed by command line parameter -domaintype
domaintype = "soa"

# adminServerName will be passed by command line parameter  -adminServerName
adminServerName = "AdminServer"

# adminURL will be passed by command line parameter  -adminURL
adminURL = "soainfra-adminserver:7001"

#username will be passed by command line parameter  -username
username = "weblogic"

#password will be passed by command line parameter -password
password = "Welcome1"


i=1
while i < len(sys.argv):
   if sys.argv[i] == '-domainName':
       domainName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-domainType':
       domaintype = sys.argv[i+1]
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
   else:
       print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
       usage()
       sys.exit(1)

#Undeploy
connect(username, password, 't3://' + adminURL)
unDeploy('wls-exporter-adminserver',adminServerName)
if 'soa' in domaintype:
   unDeploy('wls-exporter-soa','soa_cluster')

if 'osb' in domaintype:
   unDeploy('wls-exporter-osb','osb_cluster')

disconnect()
exit() 

