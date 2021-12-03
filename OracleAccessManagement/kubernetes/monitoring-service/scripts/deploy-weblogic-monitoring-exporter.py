# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
import sys
#======================================================= 
# Function for fresh plain deployment
#======================================================= 
def newDeploy(appName,target):
    try:
      print 'Deploying .........'
      deploy(appName,'/u01/oracle/wls-exporter-deploy/'+appName+'.war', target, upload="true",remote="true")
      startApplication(appName)
    except Exception, ex:
      print ex.toString()

#======================================================== 
# Main program here...
# Target you can change as per your need
#========================================================  

def usage():
    argsList = ' -domainName <domainUID> -adminServerName <adminServerName> -adminURL <adminURL> -username <username> -password <password>'
    argsList=argsList + ' -oamClusterName <oamClusterName>' + ' -wlsMonitoringExporterTooamCluster <wlsMonitoringExporterTooamCluster>'
    argsList=argsList + ' -policyClusterName <policyClusterName>' + ' -wlsMonitoringExporterTopolicyCluster <wlsMonitoringExporterTopolicyCluster>'
    print sys.argv[0] + argsList
    sys.exit(0)

if len(sys.argv) < 1:
    usage()

# domainName will be passed by command line parameter -domainName.
domainName = "accessdomain"

# adminServerName will be passed by command line parameter  -adminServerName
adminServerName = "AdminServer"

# adminURL will be passed by command line parameter  -adminURL
adminURL = "accessdomain-adminserver:7001"

# oamClusterName will be passed by command line parameter -oamClusterName
oamClusterName = "oam_cluster"

# wlsMonitoringExporterTooamCluster will be passed by command line parameter -wlsMonitoringExporterTooamCluster
wlsMonitoringExporterTooamCluster = "true"


# policyClusterName will be passed by command line parameter -policyClusterName
policyClusterName = "policy_cluster"

# wlsMonitoringExporterTopolicyCluster will be passed by command line parameter -wlsMonitoringExporterTopolicyCluster
wlsMonitoringExporterTopolicyCluster = "true"

# username will be passed by command line parameter  -username
username = "weblogic"

# password will be passed by command line parameter -password
password = "welcome1"

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
   elif sys.argv[i] == '-oamClusterName':
       oamClusterName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wlsMonitoringExporterTooamCluster':
       wlsMonitoringExporterTooamCluster = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-policyClusterName':
       policyClusterName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wlsMonitoringExporterTopolicyCluster':
       wlsMonitoringExporterTopolicyCluster = sys.argv[i+1]
       i += 2
   else:
       print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
       usage()
       sys.exit(1)

# Deployment
connect(username, password, 't3://' + adminURL)
cd('AppDeployments')
newDeploy('wls-exporter-adminserver',adminServerName)
if 'true' == wlsMonitoringExporterTooamCluster:
  newDeploy('wls-exporter-oam',oamClusterName)

if 'true' == wlsMonitoringExporterTopolicyCluster:
  newDeploy('wls-exporter-policy',policyClusterName)

disconnect()
exit()
 
