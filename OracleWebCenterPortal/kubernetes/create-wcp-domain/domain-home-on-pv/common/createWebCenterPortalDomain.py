# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class WCPortal12214Provisioner:

    MACHINES = {
        'machine1' : {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5658
        }
    }

    MANAGED_SERVERS = []
    ADDL_MANAGED_SERVERS = []
    JRF_12214_TEMPLATES = {
        'baseTemplate' : '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls.jar',
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf.ws.async_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsmpm_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.ums_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_wls_template.jar'
        ],
        'serverGroupsToTarget' : [ 'JRF-MAN-SVR', 'WSMPM-MAN-SVR' ]
    }

    WCPortal_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/wcportal/common/templates/wls/oracle.wc_spaces_template.jar',
            '@@ORACLE_HOME@@/wcportal/common/templates/wls/oracle.analyticscollector_template.jar'
        ],
        'serverGroupsToTarget' : [ 'SPACES-MGD-SVRS', 'AS-MGD-SVRS' ]
    }
    WCPortlet_12214_TEMPLATES = {
                'extensionTemplates' : [
                    '@@ORACLE_HOME@@/wcportal/common/templates/wls/oracle.portlet_producer_apps_template.jar',
           	    '@@ORACLE_HOME@@/wcportal/common/templates/wls/oracle.ootb_producers_template.jar'
                ],
                'serverGroupsToTarget' : [ 'PRODUCER_APPS-MGD-SVRS' ]
    }
    def __init__(self, oracleHome, javaHome, domainParentDir, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def createWCPortalDomain(self, domainName, user, password, db, dbPrefix, dbPassword, adminListenPort, adminName,
                          managedNameBase, managedServerPort, prodMode, managedCount, clusterName, sslEnabled, adminServerSSLPort, managedServerSSLPort, configurePortletServer, portletClusterName, portletServerNameBase,  portletServerPort, portletServerSSLPort,
                          exposeAdminT3Channel=None, t3ChannelPublicAddress=None, t3ChannelPort=None):

	print '================================================================='
        print '    WebCenter Portal Weblogic Operator Domain Creation Script    '
        print '                         12.2.1.4                              '
	print '================================================================='

        print 'Creating Base Domain...'
        domainHome = self.createBaseDomain(domainName, user, password, adminListenPort, adminServerSSLPort, adminName, managedNameBase,
                                           managedServerPort, managedServerSSLPort, configurePortletServer, portletClusterName, portletServerNameBase, portletServerPort, portletServerSSLPort, prodMode, managedCount, clusterName, sslEnabled)

        print 'Extending Domain...'
        self.extendDomain(domainHome, db, dbPrefix, dbPassword, configurePortletServer, exposeAdminT3Channel, t3ChannelPublicAddress,
                          t3ChannelPort)
        print 'Domain Creation is done...'


    def createBaseDomain(self, domainName, user, password, adminListenPort, adminServerSSLPort, adminName,
                            managedNameBase, managedServerPort, managedServerSSLPort, configurePortletServer, portletClusterName, portletServerNameBase, portletServerPort, portletServerSSLPort, prodMode, managedCount, clusterName ,sslEnabled):
        baseTemplate = self.replaceTokens(self.JRF_12214_TEMPLATES['baseTemplate'])

        readTemplate(baseTemplate)
        setOption('DomainName', domainName)
        setOption('JavaHome', self.javaHome)
        if (prodMode == 'true'):
            setOption('ServerStartMode', 'prod')
        else:
            setOption('ServerStartMode', 'dev')
        set('Name', domainName)

        admin_port = int(adminListenPort)
        ms_port = int(managedServerPort)
        ms_count = int(managedCount)
        ms_sslport = int(managedServerSSLPort)
        admin_sslport = int(adminServerSSLPort)
        portlet_port = int(portletServerPort)
        portlet_ssl_port = int(portletServerSSLPort)
        # Create Admin Server
        # =======================
        print 'Creating Admin Server...'
        cd('/Servers/AdminServer')
        #set('ListenAddress', '%s-%s' % (domain_uid, admin_server_name_svc))
        set('ListenPort', admin_port)
        set('Name', adminName)
        cmo.setWeblogicPluginEnabled(true)
        #Enabling SSL For AdminServer
        #=============================
        if (sslEnabled == 'true'):
          print('Enabling SSL for Admin server...')
          cd('/Servers/' + adminName)
          create(adminName, 'SSL')
          cd('/Servers/' + adminName + '/SSL/' + adminName)
          set('ListenPort', admin_sslport)
          set('Enabled', 'True')


        # Define the user password for weblogic
        # =====================================
        cd('/Security/' + domainName + '/User/weblogic')
        set('Name', user)
        set('Password', password)

        # Create a cluster
        # ======================
        print 'Creating cluster...'
        cd('/')
        cl = create(clusterName, 'Cluster')

        # Create managed servers
        self.MANAGED_SERVERS = self.createManagedServers(ms_count, managedNameBase, ms_port, ms_sslport, clusterName, self.MANAGED_SERVERS, sslEnabled)
        print 'Managed servers created...'
        if (configurePortletServer == 'true'):
          print 'Creating Portlet cluster...'
          cd('/')
          cl = create(portletClusterName, 'Cluster')
          # Create portlet managed server
          self.ADDL_MANAGED_SERVERS = self.createManagedServers(ms_count, portletServerNameBase, portlet_port, portlet_ssl_port, portletClusterName, self.ADDL_MANAGED_SERVERS, sslEnabled)
          print 'Managed servers created...'
          # Create Node Manager
        # =======================
        print 'Creating Node Manager...'
        for machine in self.MACHINES:
            cd('/')
            create(machine, 'Machine')
            cd('Machine/' + machine)
            create(machine, 'NodeManager')
            cd('NodeManager/' + machine)
            for param in self.MACHINES[machine]:
                set(param, self.MACHINES[machine][param])

        setOption('OverwriteDomain', 'true')
        domainHome = self.domainParentDir + '/' + domainName
        print 'Will create Base domain at ' + domainHome

        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'Base domain created at ' + domainHome
        return domainHome

    def extendDomain(self, domainHome, db, dbPrefix, dbPassword, configurePortletServer, exposeAdminT3Channel, t3ChannelPublicAddress,
                     t3ChannelPort):
        print 'Extending domain at ' + domainHome
        print 'Database  ' + db
        readDomain(domainHome)
        setOption('AppDir', self.domainParentDir + '/applications')

        print 'ExposeAdminT3Channel %s with %s:%s ' % (exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
        if 'true' == exposeAdminT3Channel:
            self.enable_admin_channel(t3ChannelPublicAddress, t3ChannelPort)

        print 'Applying JRF templates...'
        for extensionTemplate in self.JRF_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))

        print 'Applying WCPortal templates...'
        for extensionTemplate in self.WCPortal_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        cd('/')
        delete('WC_Portal', 'Server')
        print 'WC_Portal Managed server deleted...'

        print 'Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12214_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.WCPortal_12214_TEMPLATES['serverGroupsToTarget'])
        self.targetWCPServers(serverGroupsToTarget)
        print 'Targeting Cluster ...'

        cd('/')
        print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + clusterName
        cd('/Cluster/' + clusterName)
        set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')

        print "Set WLS clusters as target of defaultCoherenceCluster:" + clusterName
        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', clusterName)

        if (configurePortletServer == 'true'):
          print 'Applying WCPortlet templates...'

          for extensionTemplate in self.WCPortlet_12214_TEMPLATES['extensionTemplates']:
              addTemplate(self.replaceTokens(extensionTemplate))
          print 'WCPortlet Templates added...'
          cd('/')
          delete('WC_Portlet', 'Server')
          print 'WC_Portlet Managed server deleted...'
          print 'Targeting Server Groups...'
          serverGroupsToTarget = list(self.JRF_12214_TEMPLATES['serverGroupsToTarget'])
          serverGroupsToTarget.extend(self.WCPortlet_12214_TEMPLATES['serverGroupsToTarget'])
          self.targetWCPortletServers(serverGroupsToTarget)
          print 'Targeting Cluster ...'
          cd('/')
          print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + portletClusterName
          cd('/Cluster/' + portletClusterName)
          set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
          print "Set WLS clusters as target of defaultCoherenceCluster:" + portletClusterName
          cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
          set('Target', portletClusterName)

        print 'Configuring JDBC templates'
        self.configureJDBCTemplates(db, dbPrefix, dbPassword)
        print 'Preparing to update domain...'
        updateDomain()
        print 'Domain updated successfully'
        closeDomain()
        return


    ###########################################################################
    # Helper Methods                                                          #
    ###########################################################################

    def createManagedServers(self, ms_count, managedNameBase, ms_port, ms_sslport, cluster_name, ms_servers, sslEnabled):
        # Create managed servers
        for index in range(0, ms_count):
            cd('/')
            msIndex = index+1
            cd('/')
            name = '%s%s' % (managedNameBase, msIndex)
            create(name, 'Server')
            cd('/Servers/%s/' % name )
            print('managed server name is %s' % name);
            set('ListenPort', ms_port)
            set('NumOfRetriesBeforeMSIMode', 0)
            set('RetryIntervalBeforeMSIMode', 1)
            set('Cluster', cluster_name)
            cmo.setWeblogicPluginEnabled(true)
            ms_servers.append(name)
            if (sslEnabled == 'true'):
              print 'Enabling SSL for Managed server...'
              create(name, 'SSL')
              cd('/Servers/' + name+ '/SSL/' + name)
              set('ListenPort', ms_sslport)
              set('Enabled', 'True')
        print ms_servers
        return ms_servers

    def targetWCPServers(self, serverGroupsToTarget):
        for managedName in self.MANAGED_SERVERS:
            setServerGroups(managedName, serverGroupsToTarget)
            print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + managedName
            cd('/Servers/' + managedName)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def targetWCPortletServers(self, serverGroupsToTarget):
        for managedName in self.ADDL_MANAGED_SERVERS:
            setServerGroups(managedName, serverGroupsToTarget)
            print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + managedName
            cd('/Servers/' + managedName)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def configureJDBCTemplates(self, db, dbPrefix, dbPassword):
        print 'Configuring the Service Table DataSource...'
        fmwDb = 'jdbc:oracle:thin:@' + db
        print 'fmwDatabase  ' + fmwDb
        cd('/JDBCSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource')
        cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.OracleDriver')
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)

        cd('Properties/NO_NAME_0')
        create('oracle.jdbc.fanEnabled', 'Property')
        cd('Property')
        cd('oracle.jdbc.fanEnabled')
        set('Value', 'false')
        cd('../../../..')

        stbUser = dbPrefix + '_STB'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', stbUser)

        print 'Getting Database Defaults...'
        getDatabaseDefaults()
        return

    def validateDirectory(self, dirName, create=False):
        directory = os.path.realpath(dirName)
        if not os.path.exists(directory):
            if create:
                os.makedirs(directory)
            else:
                message = 'Directory ' + directory + ' does not exist'
                raise WLSTException(message)
        elif not os.path.isdir(directory):
            message = 'Directory ' + directory + ' is not a directory'
            raise WLSTException(message)
        return self.fixupPath(directory)


    def fixupPath(self, path):
        result = path
        if path is not None:
            result = path.replace('\\', '/')
        return result


    def replaceTokens(self, path):
        result = path
        if path is not None:
            result = path.replace('@@ORACLE_HOME@@', oracleHome)
        return result

    def enable_admin_channel(self, admin_channel_address, admin_channel_port):
        if admin_channel_address == None or admin_channel_port == 'None':
            return
        cd('/')
        admin_server_name = get('AdminServerName')
        print('setting admin server t3channel for ' + admin_server_name)
        cd('/Servers/' + admin_server_name)
        create('T3Channel', 'NetworkAccessPoint')
        cd('/Servers/' + admin_server_name + '/NetworkAccessPoint/T3Channel')
        set('ListenPort', int(admin_channel_port))
        set('PublicPort', int(admin_channel_port))
        set('PublicAddress', admin_channel_address)

#############################
# Entry point to the script #
#############################

def usage():
    print sys.argv[0] + ' -oh <oracle_home> -jh <java_home> -parent <domain_parent_dir> -name <domain-name> ' + \
          '-user <domain-user> -password <domain-password> ' + \
          '-rcuDb <rcu-database> -rcuPrefix <rcu-prefix> -rcuSchemaPwd <rcu-schema-password> ' \
          '-adminListenPort <adminListenPort> -adminName <adminName> ' \
          '-managedNameBase <managedNameBase> -managedServerPort <managedServerPort> -prodMode <prodMode> ' \
          '-managedServerCount <managedCount> -clusterName <clusterName> ' \
          '-exposeAdminT3Channel <quoted true or false> -t3ChannelPublicAddress <address of the cluster> ' \
          '-t3ChannelPort <t3 channel port> '
    sys.exit(0)

# Uncomment for Debug only
#print str(sys.argv[0]) + " called with the following sys.argv array:"
#for index, arg in enumerate(sys.argv):
#    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) < 16:
    usage()

#oracleHome will be passed by command line parameter -oh.
oracleHome = None
#javaHome will be passed by command line parameter -jh.
javaHome = None
#domainParentDir will be passed by command line parameter -parent.
domainParentDir = None
#domainUser is hard-coded to weblogic. You can change to other name of your choice. Command line paramter -user.
domainUser = 'weblogic'
#domainPassword will be passed by Command line parameter -password.
domainPassword = None
#rcuDb will be passed by command line parameter -rcuDb.
rcuDb = None
#change rcuSchemaPrefix to your infra schema prefix. Command line parameter -rcuPrefix.
rcuSchemaPrefix = 'DEV12'
#change rcuSchemaPassword to your infra schema password. Command line parameter -rcuSchemaPwd.
rcuSchemaPassword = None
exposeAdminT3Channel = None
t3ChannelPort = None
t3ChannelPublicAddress = None
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
    elif sys.argv[i] == '-user':
        domainUser = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-password':
        domainPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuDb':
        rcuDb = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuPrefix':
        rcuSchemaPrefix = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuSchemaPwd':
        rcuSchemaPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminListenPort':
        adminListenPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminServerSSLPort':
        adminServerSSLPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminName':
        adminName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-managedNameBase':
        managedNameBase = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-managedServerPort':
        managedServerPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-managedServerSSLPort':
        managedServerSSLPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-portletServerPort':
        portletServerPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-portletServerSSLPort':
        portletServerSSLPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-prodMode':
        prodMode = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-managedServerCount':
        managedCount = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-clusterName':
        clusterName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-t3ChannelPublicAddress':
        t3ChannelPublicAddress = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-t3ChannelPort':
        t3ChannelPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-exposeAdminT3Channel':
        exposeAdminT3Channel = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-sslEnabled':
        sslEnabled = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-portletServerNameBase':
        portletServerNameBase = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-portletClusterName':
        portletClusterName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-configurePortletServer':
        configurePortletServer = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

provisioner = WCPortal12214Provisioner(oracleHome, javaHome, domainParentDir, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName)
provisioner.createWCPortalDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword,
                              adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount,
                              clusterName, sslEnabled, adminServerSSLPort, managedServerSSLPort, configurePortletServer, portletClusterName, portletServerNameBase ,portletServerPort, portletServerSSLPort, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
