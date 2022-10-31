# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
import sys
class ConfigureWCCADFDomain:  

    def configureMbeanAttribs(self):
        print 'Configuring MBean attributes of '+domainUID+'-wccadf-server1'
        # login to wlst online
        connect(domainUser,domainPassword, 't3://'+domainUID+'-wccadf-server1:'+domainPort+'')

        custom()
        
        # Navigate Mbean hierarchy and set AdfScopeHaSupport to true
        cd ('oracle.adf.share.config')
        cd ('oracle.adf.share.config:ApplicationName=Oracle WebCenter Content - Web UI,name=ADFcConfiguration,type=ADFConfig,Application=Oracle WebCenter Content - Web UI,ADFConfig=ADFConfig')
        set ('AdfScopeHaSupport','true')

        # Navigate Mbean hierarchy and set ClusterCompatible to true
        cd ('..')
        cd ('oracle.adf.share.config:ApplicationName=Oracle WebCenter Content - Web UI,name=WccAdfConfiguration,type=ADFConfig,Application=Oracle WebCenter Content - Web UI,ADFConfig=ADFConfig')
        set ('ClusterCompatible',true)

        # Invoke save operation for both settings done above
        cd ('..')
        cd ('oracle.adf.share.config:ApplicationName=Oracle WebCenter Content - Web UI,name=ADFConfig,type=ADFConfig,Application=Oracle WebCenter Content - Web UI')
        mbs.invoke(ObjectName('oracle.adf.share.config:ApplicationName=Oracle WebCenter Content - Web UI,name=ADFConfig,type=ADFConfig,Application=Oracle WebCenter Content - Web UI'), 'save', None, None)

        # Navigate Mbean hierarchy and set PropConnectionUrl to the current host url with proper intradoc port
        cd('/')
        cd ('oracle.adf.share.connections')
        cd ('oracle.adf.share.connections:type=WccConnection,beantype=Runtime,ADFConnections=ADFConnections,Application=Oracle WebCenter Content - Web UI,name=WccAdfServerConnection,ApplicationName=Oracle WebCenter Content - Web UI')

        set('PropConnectionUrl','idc://'+hostName+':'+intradocPort+'')

        # Invoke save operation for the setting done above
        cd('..')
        cd ('oracle.adf.share.connections:ApplicationName=Oracle WebCenter Content - Web UI,name=ADFConnections,beantype=Runtime,type=ADFConnections,Application=Oracle WebCenter Content - Web UI')
        mbs.invoke(ObjectName('oracle.adf.share.connections:ApplicationName=Oracle WebCenter Content - Web UI,name=ADFConnections,beantype=Runtime,type=ADFConnections,Application=Oracle WebCenter Content - Web UI'), 'save', None, None)

        print 'Configured MBean attributes of '+domainUID+'-wccadf-server1'
        
i = 1
while i < len(sys.argv):
    
    if sys.argv[i] == '-user':
        domainUser = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-password':
        domainPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-domainUID':
        domainUID = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-domainPort':
        domainPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-hostName':
        hostName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-intradocPort':
        intradocPort = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        sys.exit(1)

config = ConfigureWCCADFDomain()
config.configureMbeanAttribs()
