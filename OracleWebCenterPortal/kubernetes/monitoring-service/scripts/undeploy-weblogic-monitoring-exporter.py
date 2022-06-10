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
    argsList = ' -domainName <domainUID> -adminServerName <adminServerName> -adminURL <adminURL> -username <username> -password <password>'
    argsList=argsList + ' -wcpClusterName <wcpClusterName>' + ' -wlsMonitoringExporterTowcpCluster <wlsMonitoringExporterTowcpCluster>'
    argsList=argsList + ' -wcpPortletClusterName <wcpPortletClusterName>' + ' -wlsMonitoringExporterTowcpPortletCluster <wlsMonitoringExporterTowcpPortletCluster>'
    print sys.argv[0] + argsList
    sys.exit(0)

if len(sys.argv) < 1:
    usage()

# domainName will be passed by command line parameter -domainName.
domainName = "wcp-domain"

# adminServerName will be passed by command line parameter  -adminServerName
adminServerName = "AdminServer"

# adminURL will be passed by command line parameter  -adminURL
adminURL = "wcp-domain-adminserver:7001"

# wcpClusterName will be passed by command line parameter -wcpClusterName
wcpClusterName = "wcp-cluster"

# wlsMonitoringExporterTowcpCluster will be passed by command line parameter -wlsMonitoringExporterTowcpCluster
wlsMonitoringExporterTowcpCluster = "false"
# wcpPortletClusterName will be passed by command line parameter -wcpPortletClusterName
wcpPortletClusterName = "wcportlet-cluster"

# wlsMonitoringExporterTowcpPortletCluster will be passed by command line parameter -wlsMonitoringExporterTowcpPortletCluster
wlsMonitoringExporterTowcpPortletCluster = "false"

# username will be passed by command line parameter  -username
username = "weblogic"

# password will be passed by command line parameter -password
password = "Welcome1"


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
   elif sys.argv[i] == '-wcpClusterName':
       wcpClusterName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wlsMonitoringExporterTowcpCluster':
       wlsMonitoringExporterTowcpCluster = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wcpPortletClusterName':
       wcpPortletClusterName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wlsMonitoringExporterTowcpPortletCluster':
       wlsMonitoringExporterTowcpPortletCluster = sys.argv[i+1]
       i += 2

   else:
       print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
       usage()
       sys.exit(1)

# Undeploy
connect(username, password, 't3://' + adminURL)
unDeploy('wls-exporter-adminserver',adminServerName)
if 'true' == wlsMonitoringExporterTowcpCluster:
   unDeploy('wls-exporter-wcp',wcpClusterName)

if 'true' == wlsMonitoringExporterTowcpPortletCluster:
   unDeploy('wls-exporter-wcpPortlet',wcpPortletClusterName)

disconnect()
exit() 

