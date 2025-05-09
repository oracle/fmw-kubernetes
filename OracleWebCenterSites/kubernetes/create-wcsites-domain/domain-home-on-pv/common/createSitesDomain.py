# Copyright (c) 2021, 2024, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class WCSITES12214Provisioner:

    secureDomain = 'false';
    MACHINES = {
        'wcsites_machine' : {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5658
        }
    }

    MANAGED_SERVERS = []
    
    JRF_12214_TEMPLATES = {
        'baseTemplate' : '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls.jar',
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_wls_template.jar'
        ],
        'serverGroupsToTarget' : [ 'JRF-MAN-SVR' ]
    }

    WCSITES_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/wcsites/common/templates/wls/oracle.wcsites.examples.template.jar'
        ],
        'serverGroupsToTarget' : [ 'WCSITES-MGD-SVR' ]
    }

    def __init__(self, oracleHome, javaHome, domainParentDir, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def createWCSitesDomain(self, domainName, user, password, db, dbPrefix, dbPassword, adminListenPort, adminServerSSLPort, adminName, managedNameBase, managedServerPort, managedServerSSLPort, prodMode, secureMode, managedCount, clusterName, sslEnabled, domainType, adminAdministrationPort, managedServerAdministrationPort, exposeAdminT3Channel=None, t3ChannelPublicAddress=None, t3ChannelPort=None):
        domainHome = self.createBaseDomain(domainName, user, password, adminListenPort, adminServerSSLPort, adminName, managedNameBase, managedServerPort, managedServerSSLPort, prodMode, secureMode, managedCount, sslEnabled, clusterName, domainType, adminAdministrationPort, managedServerAdministrationPort)
        
        if domainType == "wcsites":
                self.extendWcsitesDomain(domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
        
    def createManagedServers(self, ms_count, managedNameBase, ms_port, cluster_name, ms_servers, managedServerSSLPort, sslEnabled, ms_admin_port):
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
            if (self.secureDomain == 'true'):
              set('administrationPort', ms_admin_port)
            set('NumOfRetriesBeforeMSIMode', 0)
            set('RetryIntervalBeforeMSIMode', 1)
            set('Cluster', cluster_name)
            cmo.setWeblogicPluginEnabled(true)
            ms_servers.append(name)
            if (sslEnabled == 'true'):
              print 'Enabling SSL for Managed server...'
              create(name, 'SSL')
              cd('/Servers/' + name+ '/SSL/' + name)
              set('Enabled', 'True')
              set('ListenPort', managedServerSSLPort)
        print ms_servers
        return ms_servers

    def createBaseDomain(self, domainName, user, password, adminListenPort, adminServerSSLPort, adminName, managedNameBase, managedServerPort, managedServerSSLPort, prodMode, secureMode, managedCount, sslEnabled, clusterName, domainType, adminAdministrationPort, managedServerAdministrationPort):
        baseTemplate = self.replaceTokens(self.JRF_12214_TEMPLATES['baseTemplate'])
        
        readTemplate(baseTemplate)
        setOption('DomainName', domainName)
        setOption('JavaHome', self.javaHome)
        domainVersion = cmo.getDomainVersion()
        if prodMode == 'true':
            if (domainVersion == "14.1.2.0.0" and secureMode == 'true'):
               setOption('ServerStartMode', 'secure')
               self.secureDomain = 'true'
            else:
               setOption('ServerStartMode', 'prod')
        else:
            setOption('ServerStartMode', 'dev')
        set('Name', domainName)
        
        admin_port = int(adminListenPort)
        ms_port    = int(managedServerPort)
        ms_count   = int(managedCount)
        adminSSLport = int(adminServerSSLPort)
        managedSSLPort = int(managedServerSSLPort)
        
        # Create Admin Server
        # =======================
        print 'Creating Admin Server...'
        cd('/Servers/AdminServer')
        #set('ListenAddress', '%s-%s' % (domain_uid, admin_server_name_svc))
        set('ListenPort', admin_port)
        if ( self.secureDomain == 'true'):
            set('administrationPort', int(adminAdministrationPort))
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
        print 'Creating cluster...'
        cd('/')
        cl=create(clusterName, 'Cluster')

        # Create Node Manager
        # =======================
        print 'Creating Node Managers...'
        for machine in self.MACHINES:
            cd('/')
            create(machine, 'Machine')
            cd('Machine/' + machine)
            create(machine, 'NodeManager')
            cd('NodeManager/' + machine)
            for param in self.MACHINES[machine]:
                set(param, self.MACHINES[machine][param])

        # Create managed servers
        self.MANAGED_SERVERS = self.createManagedServers(ms_count, managedNameBase, ms_port, clusterName, self.MANAGED_SERVERS, managedSSLPort, sslEnabled, int(managedServerAdministrationPort))
        
        setOption('OverwriteDomain', 'true')
        domainHome = self.domainParentDir + '/' + domainName
        print 'Will create Base domain at ' + domainHome
        
        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'Base domain created at ' + domainHome
        return domainHome

    def readAndApplyJRFTemplates(self, domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort):
        print 'Extending domain at ' + domainHome
        print 'Database  ' + db
        readDomain(domainHome)
        setOption('AppDir', self.domainParentDir + '/applications')
        
        print 'ExposeAdminT3Channel %s with %s:%s ' % (exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
        if 'true' == exposeAdminT3Channel:
            self.enable_admin_channel(t3ChannelPublicAddress, t3ChannelPort)
        
        self.applyJRFTemplates()
        print 'Extension Templates added'
        return

    def applyJRFTemplates(self):
        print 'Applying JRF templates...'
        for extensionTemplate in self.JRF_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return

    def applyWCSITESTemplates(self):
        print 'Applying WCSITES templates...'
        for extensionTemplate in self.WCSITES_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return

    def targetWCSITESServers(self,serverGroupsToTarget):
        print 'Targeting Server Groups...'
        cd('/')
        for managedName in self.MANAGED_SERVERS:
            setServerGroups(managedName, serverGroupsToTarget)
            print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + managedName
            cd('/Servers/' + managedName)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def targetWCSITESCluster(self):
        print 'Targeting Cluster ...'
        cd('/')
        print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + clusterName
        cd('/Cluster/' + clusterName)
        set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def extendWcsitesDomain(self, domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort):
        self.readAndApplyJRFTemplates(domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
        self.applyWCSITESTemplates()
        
        print 'Extension Templates added'
        
        if 'wcsites_server1' not in self.MANAGED_SERVERS:
            print 'INFO: deleting wcsites_server1'
            cd('/')
            delete('wcsites_server1','Server')
            print 'INFO: deleted wcsites_server1'
        
        self.configureJDBCTemplates(db,dbPrefix,dbPassword)
        
        print 'Targeting Server Groups...'
        serverGroupsToTarget = list(self.JRF_12214_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.WCSITES_12214_TEMPLATES['serverGroupsToTarget'])
        
        cd('/')
        self.targetWCSITESServers(serverGroupsToTarget)
        
        cd('/')
        self.targetWCSITESCluster()
        
        print "Set WLS clusters as target of defaultCoherenceCluster:[" + clusterName + "]"
        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', clusterName)
        
        print 'Preparing to update domain...'
        updateDomain()
        print 'Domain updated successfully'
        closeDomain()
        return
		
    def configureJDBCTemplates(self,db,dbPrefix,dbPassword):
        print 'Configuring the Service Table DataSource...'
        #fmwDb = db
        fmwDb = 'jdbc:oracle:thin:@' + db
        driverName = 'oracle.jdbc.OracleDriver'
        print "fmwDb..." + fmwDb
        
        cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_OPSS'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "Set user..." + user
        
        cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_IAU_APPEND'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "Set user..." + user
        
        cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_IAU_VIEWER'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "Set user..." + user
        
        cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_STB'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "Set user..." + user
        
        cd('/JdbcSystemResource/wcsitesDS/JdbcResource/wcsitesDS/JdbcDriverParams/NO_NAME_0')
        set('DriverName', driverName)
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)
        
        user = dbPrefix + '_WCSITES'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', user)
        
        print "Set user..." + user

        print 'Getting Database Defaults...'
        getDatabaseDefaults()
        return
    ###########################################################################
    # Helper Methods                                                          #
    ###########################################################################

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
          '-adminServerSSLPort <adminServerSSLPort> -managedServerSSLPort <managedServerSSLPort> ' \
          '-managedServerCount <managedCount> -clusterName <clusterName>' \
          '-domainType <soa|osb|bpm|soaosb> -secureMode <secureMode> ' \
          '-adminAdministrationPort <adminAdministrationPort> -managedServerAdministrationPort <managedServerAdministrationPort> ' \
          '-exposeAdminT3Channel <quoted true or false> -t3ChannelPublicAddress <address of the cluster> ' \
          '-t3ChannelPort <t3 channel port> -machineName <machineName>' 
    sys.exit(0)

# Uncomment for Debug only
#print str(sys.argv[0]) + " called with the following sys.argv array:"
#for index, arg in enumerate(sys.argv):
#    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) < 18:
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
rcuSchemaPrefix = 'WCS1'
#change rcuSchemaPassword to your infra schema password. Command line parameter -rcuSchemaPwd.
rcuSchemaPassword = None
exposeAdminT3Channel = None
t3ChannelPort = None
t3ChannelPublicAddress = None
machineName = None	
adminAdministrationPort = '9002'
managedServerAdministrationPort = '9111'
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
    elif sys.argv[i] == '-secureMode':
        secureMode = sys.argv[i + 1]
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
    elif sys.argv[i] == '-domainType':
        domainType = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-machineName':
        machineName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminAdministrationPort':
        adminAdministrationPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-managedServerAdministrationPort':
        managedServerAdministrationPort = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)


provisioner = WCSITES12214Provisioner(oracleHome, javaHome, domainParentDir, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName)
provisioner.createWCSitesDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword, adminListenPort, adminServerSSLPort, adminName, managedNameBase, managedServerPort, managedServerSSLPort, prodMode, secureMode, managedCount, clusterName, sslEnabled, domainType, adminAdministrationPort, managedServerAdministrationPort, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
