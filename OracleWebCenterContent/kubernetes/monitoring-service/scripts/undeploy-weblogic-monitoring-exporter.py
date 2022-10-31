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
    argsList=argsList + ' -ibrClusterName <ibrClusterName>' + ' -wlsMonitoringExporterToibrCluster <wlsMonitoringExporterToibrCluster>'
    argsList=argsList + ' -ucmClusterName <ucmClusterName>' + ' -wlsMonitoringExporterToucmCluster <wlsMonitoringExporterToucmCluster>'
    argsList=argsList + ' -ipmClusterName <ipmClusterName>' + ' -wlsMonitoringExporterToipmCluster <wlsMonitoringExporterToipmCluster>'
    argsList=argsList + ' -captureClusterName <captureClusterName>' + ' -wlsMonitoringExporterTocaptureCluster <wlsMonitoringExporterTocaptureCluster>'
    argsList=argsList + ' -wccadfClusterName <wccadfClusterName>' + ' -wlsMonitoringExporterTowccadfCluster <wlsMonitoringExporterTowccadfCluster>'
    print sys.argv[0] + argsList
    sys.exit(0)

if len(sys.argv) < 1:
    usage()

# domainName will be passed by command line parameter -domainName.
domainName = "wccinfra"

# adminServerName will be passed by command line parameter  -adminServerName
adminServerName = "adminserver"

# adminURL will be passed by command line parameter  -adminURL
adminURL = "wccinfra-adminserver:7001"

# ibrClusterName will be passed by command line parameter -ibrClusterName
ibrClusterName = "ibr_cluster"

# wlsMonitoringExporterToibrCluster will be passed by command line parameter -wlsMonitoringExporterToibrCluster
wlsMonitoringExporterToibrCluster = "false"
# ucmClusterName will be passed by command line parameter -ucmClusterName
ucmClusterName = "ucm_cluster"

# wlsMonitoringExporterToucmCluster will be passed by command line parameter -wlsMonitoringExporterToucmCluster
wlsMonitoringExporterToucmCluster = "false"
# ipmClusterName will be passed by command line parameter -ipmClusterName
ipmClusterName = "ipm_cluster"

# wlsMonitoringExporterToipmCluster will be passed by command line parameter -wlsMonitoringExporterToipmCluster
wlsMonitoringExporterToipmCluster = "false"
# captureClusterName will be passed by command line parameter -captureClusterName
captureClusterName = "capture_cluster"

# wlsMonitoringExporterTocaptureCluster will be passed by command line parameter -wlsMonitoringExporterTocaptureCluster
wlsMonitoringExporterTocaptureCluster = "false"
# wccadfClusterName will be passed by command line parameter -wccadfClusterName
wccadfClusterName = "wccadf_cluster"

# wlsMonitoringExporterTowccadfCluster will be passed by command line parameter -wlsMonitoringExporterTowccadfCluster
wlsMonitoringExporterTowccadfCluster = "false"

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
   elif sys.argv[i] == '-ibrClusterName':
       ibrClusterName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wlsMonitoringExporterToibrCluster':
       wlsMonitoringExporterToibrCluster = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-ucmClusterName':
       ucmClusterName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wlsMonitoringExporterToucmCluster':
       wlsMonitoringExporterToucmCluster = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-ipmClusterName':
       ipmClusterName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wlsMonitoringExporterToipmCluster':
       wlsMonitoringExporterToipmCluster = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-captureClusterName':
       captureClusterName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wlsMonitoringExporterTocaptureCluster':
       wlsMonitoringExporterTocaptureCluster = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wccadfClusterName':
       wccadfClusterName = sys.argv[i+1]
       i += 2
   elif sys.argv[i] == '-wlsMonitoringExporterTowccadfCluster':
       wlsMonitoringExporterTowccadfCluster = sys.argv[i+1]
       i += 2

   else:
       print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
       usage()
       sys.exit(1)

# Undeploy
connect(username, password, 't3://' + adminURL)
unDeploy('wls-exporter-adminserver',adminServerName)
if 'true' == wlsMonitoringExporterToibrCluster:
   unDeploy('wls-exporter-ibr',ibrClusterName)

if 'true' == wlsMonitoringExporterToucmCluster:
   unDeploy('wls-exporter-ucm',ucmClusterName)

if 'true' == wlsMonitoringExporterToipmCluster:
   unDeploy('wls-exporter-ipm',ipmClusterName)

if 'true' == wlsMonitoringExporterTocaptureCluster:
   unDeploy('wls-exporter-capture',captureClusterName)

if 'true' == wlsMonitoringExporterTowccadfCluster:
   unDeploy('wls-exporter-wccadf',wccadfClusterName)

disconnect()
exit() 

