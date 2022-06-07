# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl

import xml.dom.minidom
import re
import sys

def getManagedServerCount(domainHome):
# use the parse() function to load and parse an XML file
   doc = xml.dom.minidom.parse(domainHome + "/config/config.xml")
   servers = doc.getElementsByTagName("server")
   print "Total Configured Managed Servers: %d " % (servers.length - 1)
   return servers.length - 1;


# Method to uncomment and comment the required tag and save back
def replaceXml(domainHome, ms_server):
	f = open(domainHome + "/config/fmwconfig/servers/" + ms_server + "/config/ticket-cache.xml","r+w")
	filecontent = f.read()
	#Uncomment the one to be used
	filecontent = re.sub ( r'<!--<cacheManagerPeerProviderFactory','<cacheManagerPeerProviderFactory', filecontent,1)
	filecontent = re.sub ( r'cas_tgt" />-->','cas_tgt" />', filecontent,1)
	#Comment the one not used
	filecontent = re.sub ( r'<cacheManagerPeerProviderFactory','<!--cacheManagerPeerProviderFactory', filecontent,1)
	filecontent = re.sub ( r'propertySeparator="," />','propertySeparator="," -->', filecontent,1)
	f.seek(0)
	f.write(filecontent)
	f.write("\n\n\n")
	f.close()

# Method to replace the properties
def replaceRmiUrlsInCache(domainHome, prefix, n, ms_server, excludedServerNumber, filename, port):
	doc = xml.dom.minidom.parse(domainHome + "/config/fmwconfig/servers/" + ms_server + "/config/" + filename)
	abc = doc.getElementsByTagName("cacheManagerPeerProviderFactory")	
	processString = "peerDiscovery=manual,rmiUrls=//localhost:<port>/notifier"
	
	for element in abc:		
		element.setAttribute("properties", processString)
		
		for x in range (1,n-1):
			processString = processString + "|//localhost:<port>/notifier"
	
	# We should have got the properties attribute now tokenized with localhost and 41001. Exclude 1 add the rest
	for i in range (1,n+1):
		if i <> int(excludedServerNumber):
			processString = re.sub ( r'localhost',prefix + str(i), processString,1)
			processString = re.sub ( r'<port>',str(port), processString,1)	
			
	element.setAttribute("properties", processString)
	print(processString)
	ghi = doc.getElementsByTagName("cacheManagerPeerListenerFactory")
	for element in ghi:		
		processString = element.getAttribute("properties")	
	processString = "hostName="+prefix+ str(excludedServerNumber) +",port=" + str(port) +",remoteObjectPort=" + str(int(port)+1) + ",socketTimeoutMillis=12000"
	element.setAttribute("properties", processString)
	myfile = open(domainHome + "/config/fmwconfig/servers/" + ms_server + "/config/" + filename , "w")
	myfile.write(doc.toxml())
	myfile.close()
	print("Updated " + filename)
	
# Method to replace the properties
def replaceRmiUrls(domainHome, prefix, n, ms_server, excludedServerNumber, port):
	doc = xml.dom.minidom.parse(domainHome + "/config/fmwconfig/servers/" + ms_server + "/config/ticket-cache.xml")
	abc = doc.getElementsByTagName("cacheManagerPeerProviderFactory")	
	processString = ""
	
	for element in abc:		
		processString = element.getAttribute("properties")
		
		for x in range (1,n-1):
			processString = processString + "|//localhost:41001/cas_st|//localhost:41001/cas_tgt"
	
	# We should have got the properties attribute now tokenized with localhost and 41001. Exclude 1 add the rest
	for i in range (1,n+1):
		if i <> int(excludedServerNumber):
			processString = re.sub ( r'localhost',prefix + str(i), processString,1)
			processString = re.sub ( r'41001',str(port), processString,1)	
			processString = re.sub ( r'localhost',prefix + str(i), processString,1)
			processString = re.sub ( r'41001',str(port), processString,1)

	element.setAttribute("properties", processString)
	print(processString)
	ghi = doc.getElementsByTagName("cacheManagerPeerListenerFactory")
	for element in ghi:		
		processString = element.getAttribute("properties")	
	processString = "hostName=" + prefix + str(excludedServerNumber) + ",port=" + str(port) + ",remoteObjectPort=" + str(int(port)+1) + ",socketTimeoutMillis=12000"
	element.setAttribute("properties", processString)
	myfile = open(domainHome + "/config/fmwconfig/servers/" + ms_server + "/config/ticket-cache.xml", "w")
	myfile.write(doc.toxml())
	myfile.close()
	print("Updated " + "ticket-cache.xml")	
	
def main():
	# count the arguments
	arguments = len(sys.argv) - 1
	print ("The script is called with %i arguments" % (arguments))
	domainHome = sys.argv[1]
	serverPrefix = sys.argv[2]
	ms_server = sys.argv[3]
	port = sys.argv[4]
	excludedServerNumber = ms_server[-1]
	print("Host prefix set to " + serverPrefix)
	print("Managed Server set to - " + ms_server)
	print("Excluded Server Number set to - " + excludedServerNumber)
	print("Starting port set to - " + port)
	replaceXml(domainHome, ms_server)
	servercount = getManagedServerCount(domainHome)	
	replaceRmiUrls(domainHome, serverPrefix, servercount, ms_server, excludedServerNumber, port)
	replaceRmiUrlsInCache(domainHome, serverPrefix, servercount, ms_server, excludedServerNumber, "linked-cache.xml", int(port) + 2)
	replaceRmiUrlsInCache(domainHome, serverPrefix, servercount, ms_server, excludedServerNumber, "cs-cache.xml", int(port) + 4)
	replaceRmiUrlsInCache(domainHome, serverPrefix, servercount, ms_server, excludedServerNumber, "cas-cache.xml", int(port) + 6 )
	replaceRmiUrlsInCache(domainHome, serverPrefix, servercount, ms_server, excludedServerNumber, "ss-cache.xml", int(port) + 8 )
	
	
if __name__ == "__main__":
	# calling main function
	main()
	
