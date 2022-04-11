# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class WCContent12214Provisioner:

    MACHINES = {
        'machine1' : {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5658
        }
    }

    MANAGED_SERVERS = []
    ADDL_MANAGED_SERVERS = []
    ADDL_CLUSTER = 'ibr_cluster'
    ADDL_MANAGED_SERVER_BASENAME = 'ibr_server'
    ADDL_MANAGED_SERVER_PORT = 16250
    ADDL_MANAGED_SERVER_SSL_PORT = 16251

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

    UCM_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/wccontent/common/templates/wls/oracle.ucm.cs_template.jar'
        ],
        'serverGroupsToTarget' : [ 'UCM-MGD-SVR' ]
    }

    IBR_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/wccontent/common/templates/wls/oracle.ucm.ibr_template.jar'
        ],
        'serverGroupsToTarget' : [ 'IBR-MGD-SVR' ]
    }
    
    def __init__(self, oracleHome, javaHome, domainParentDir, adminListenPort, adminServerSSLPort, adminName, managedNameBase, managedServerPort, managedServerSSLPort, prodMode, managedCount, clusterName, sslEnabled):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def createWCContentDomain(self, domainName, user, password, db, dbPrefix, dbPassword, adminListenPort, adminServerSSLPort, adminName, managedNameBase, managedServerPort, managedServerSSLPort,  prodMode, managedCount, clusterName, sslEnabled, exposeAdminT3Channel=None, t3ChannelPublicAddress=None, t3ChannelPort=None):

	print '================================================================='
        print '    Oracle WebCenter Content Domain Creation Script    '     
        print '                         12.2.1.4.0                              '
	print '================================================================='

        print 'Creating Base Domain...'
        domainHome = self.createBaseDomain(domainName, user, password, adminListenPort, adminServerSSLPort, adminName, managedNameBase,
                                           managedServerPort, managedServerSSLPort, prodMode, managedCount, clusterName, sslEnabled)

        print 'Extending Domain...'
        self.extendDomain(domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress,
                          t3ChannelPort)
        print 'Domain Creation is done...'


    def createBaseDomain(self, domainName, user, password, adminListenPort, adminServerSSLPort, adminName, managedNameBase, managedServerPort, managedServerSSLPort, prodMode, managedCount, clusterName, sslEnabled):
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
        ms_port    = int(managedServerPort)
        ms_count   = int(managedCount)
        adminSSLport = int(adminServerSSLPort)

        # Create Admin Server
        # =======================
        print 'Creating Admin Server...'
        cd('/Servers/AdminServer')
        #set('ListenAddress', '%s-%s' % (domain_uid, admin_server_name_svc))
        set('ListenPort', admin_port)
        set('Name', adminName)
        cmo.setWeblogicPluginEnabled(true)
        if (sslEnabled == 'true'):
            print('Enabling SSL for Admin server...')
            cd('/Servers/' + adminName)
            create(adminName, 'SSL')
            cd('/Servers/' + adminName + '/SSL/' + adminName)
            set('ListenPort', adminSSLport)
            set('Enabled', 'True')

        # Define the user password for weblogic
        # =====================================
        cd('/Security/' + domainName + '/User/weblogic')
        set('Name', user)
        set('Password', password)

        # Create a cluster
        # ======================
        print 'Creating cluster...' + clusterName
        cd('/')
        cl=create(clusterName, 'Cluster')

        # Create managed servers
        managedSSLPort = int(managedServerSSLPort)
        self.MANAGED_SERVERS = self.createManagedServers(ms_count, managedNameBase, ms_port, clusterName, self.MANAGED_SERVERS, managedSSLPort, sslEnabled)
        print 'Managed servers created...'

	# Creating additional managed servers
        print 'Creating additional cluster... ' + 'ibr_cluster'
        cd('/')
        cl=create('ibr_cluster', 'Cluster')

        # Creating  managed servers for additional cluster
        self.ADDL_MANAGED_SERVERS = self.createManagedServers(ms_count, self.ADDL_MANAGED_SERVER_BASENAME, self.ADDL_MANAGED_SERVER_PORT, self.ADDL_CLUSTER, self.ADDL_MANAGED_SERVERS, self.ADDL_MANAGED_SERVER_SSL_PORT, sslEnabled)
        print 'Created managed Servers for additional cluster..... ' + self.ADDL_CLUSTER

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

    def extendDomain(self, domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress,
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

        print 'Applying UCM templates...'
        for extensionTemplate in self.UCM_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))

        print 'Applying IBR templates...'
        for extensionTemplate in self.IBR_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))

        print 'Extension Templates added...'

        if 'UCM_server1' not in self.MANAGED_SERVERS:
            print 'INFO: deleting UCM_server1'
            cd('/')
            delete('UCM_server1', 'Server')
            print 'WC_Content default managed server deleted...'
        if 'IBR_server1' not in self.MANAGED_SERVERS and 'IBR_server1' not in self.ADDL_MANAGED_SERVERS:
            cd('/')
            delete('IBR_server1', 'Server')
            print 'IBR defult managed server deleted...'

        self.configureJDBCTemplates(db, dbPrefix, dbPassword)

        print 'Targeting Server Groups...'

        serverGroupsToTarget = list(self.JRF_12214_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.UCM_12214_TEMPLATES['serverGroupsToTarget'])
        self.targetUCMServers(serverGroupsToTarget)
        serverGroupsToTarget = list(self.JRF_12214_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.IBR_12214_TEMPLATES['serverGroupsToTarget'])
        self.targetIBRServers(serverGroupsToTarget)

        print 'Targeting Cluster ...'
        
        cd('/')
        print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + clusterName
        cd('/Cluster/' + clusterName)
        set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        
        print "Set WLS clusters as target of defaultCoherenceCluster:" + clusterName
        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', clusterName)

        cd('/')
        print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + self.ADDL_CLUSTER
        cd('/Cluster/' + self.ADDL_CLUSTER)
        set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        
        print "Set WLS clusters as target of defaultCoherenceCluster:" + self.ADDL_CLUSTER
        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', self.ADDL_CLUSTER)

        print 'Preparing to update domain...'
        updateDomain()
        print 'Domain updated successfully'
        closeDomain()
        return


    ###########################################################################
    # Helper Methods                                                          #
    ###########################################################################

    def createManagedServers(self, ms_count, managedNameBase, ms_port, cluster_name, ms_servers, managedServerSSLPort, sslEnabled):
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
            print 'before calling SSL if enabled'
            if (sslEnabled == 'true'):
              print 'Enabling SSL for Managed server...'
              create(name, 'SSL')
              cd('/Servers/' + name+ '/SSL/' + name)
              set('ListenPort', managedServerSSLPort)
              set('Enabled', 'True')
        print ms_servers
        return ms_servers

    def targetUCMServers(self, serverGroupsToTarget):
        for managedName in self.MANAGED_SERVERS:
            if not managedName == 'AdminServer':
                setServerGroups(managedName, serverGroupsToTarget)
                print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + managedName
                cd('/Servers/' + managedName)
                set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def targetIBRServers(self, serverGroupsToTarget):
        for managedName in self.ADDL_MANAGED_SERVERS:
            if not managedName == 'AdminServer':
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
# print str(sys.argv[0]) + " called with the following sys.argv array:"
# for index, arg in enumerate(sys.argv):
#    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) < 19:
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
rcuSchemaPrefix = 'WCCK6'
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
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

provisioner = WCContent12214Provisioner(oracleHome, javaHome, domainParentDir, adminListenPort, adminServerSSLPort, adminName, managedNameBase, managedServerPort, managedServerSSLPort, prodMode, managedCount, clusterName, sslEnabled)
provisioner.createWCContentDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword, adminListenPort, adminServerSSLPort, adminName, managedNameBase, managedServerPort, managedServerSSLPort, prodMode, managedCount, clusterName, sslEnabled, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
