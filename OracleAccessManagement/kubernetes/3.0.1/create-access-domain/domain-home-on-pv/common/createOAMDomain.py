# Copyright (c) 2020, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class OAM12214Provisioner:

    jrfDone = 0;
    MACHINES = {
        'machine1' : {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5658
        }
    }


    MANAGED_SERVERS = []
    MANAGED_SERVERS_GRP = [ 'OAM-MGD-SVRS' ]
    
    ADDL_MANAGED_SERVERS = []
    ADDL_MANAGED_SERVERS_GRP = [ 'OAM-POLICY-MANAGED-SERVER' ]
    ADDL_CLUSTER = 'policy_cluster'
    ADDL_MANAGED_SERVER_BASENAME = 'oam_policy_mgr'
    ADDL_MANAGED_SERVER_PORT = 15100


    WLS_BASE_TEMPLATE_NAME = 'Basic WebLogic Server Domain'
    OAM_12214_TEMPLATE_NAME = 'Oracle Access Management Suite'

    WLS_12214_TEMPLATES = {
        'baseTemplate' : '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls.jar'
    }

    OAM_EXTENSION_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wc_skin_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wc_composer_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.opss.rest_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsmjksmgmt_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsmagent_template.jar',
            '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls_schema.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.security.sso_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsmpolicyattachment_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.state-management.memory-provider-template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf.ws.core_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.cie.runtime_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.ums.client_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.opss_jrf_metadata_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.adf.template.jar',
            '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls_coherence_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.clickhistory_template.jar',
            '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls_jrf.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_base_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsm.console.core_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.emas_wls_template.jar',
            '@@ORACLE_HOME@@/idm/common/templates/applications/oracle.idm.common_template_12.2.2.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_wls_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_idm_template.jar',
            '@@ORACLE_HOME@@/idm/common/templates/applications/oracle.idm.ids.config.ui_template_12.2.2.jar',
            '@@ORACLE_HOME@@/idm/common/templates/wls/oracle.oam_12.2.2.0.0_template.jar'
        ]
    }
    
    
    def __init__(self, oracleHome, javaHome, domainParentDir, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return



    def createOAMDomain(self, domainName, user, password, db, dbPrefix, dbPassword, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType,
                          exposeAdminT3Channel=None, t3ChannelPublicAddress=None, t3ChannelPort=None):
        domainHome = self.createBaseDomain(domainName, user, password, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType)
        self.extendOamDomain(domainHome, db, dbPrefix, dbPassword, managedNameBase, managedServerPort, managedCount, clusterName, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)


    def createManagedServers(self, ms_count, managedNameBase, ms_port, cluster_name, ms_servers, ms_listenAddress):
        # Create managed servers
        for index in range(0, ms_count):
            cd('/')
            msIndex = index+1
            cd('/')
            name = '%s%s' % (managedNameBase, msIndex)
  	    listenAddress = '%s%s%s' % ('oamk8namespace',ms_listenAddress,msIndex)
            create(name, 'Server')
            cd('/Servers/%s/' % name )
            print('managed server name is %s' % name);
            set('ListenPort', ms_port)
            set('ListenAddress',listenAddress)
	    set('Name', name)	
            set('NumOfRetriesBeforeMSIMode', 0)
            set('RetryIntervalBeforeMSIMode', 1)
            set('Cluster', cluster_name)
            cmo.setWeblogicPluginEnabled(true)
            ms_servers.append(name)
        print ms_servers
        return ms_servers

    def createBaseDomain(self, domainName, user, password, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType):
        baseTemplate = self.replaceTokens(self.WLS_12214_TEMPLATES['baseTemplate'])

        readTemplate(baseTemplate)
        
        setOption('DomainName', domainName)
        setOption('JavaHome', self.javaHome)
        setOption('AppDir', self.domainParentDir + '/applications')

        if (prodMode == 'true'):
            setOption('ServerStartMode', 'prod')
        else:
            setOption('ServerStartMode', 'dev')
        set('Name', domainName)

        admin_port = int(adminListenPort)

        # Create Admin Server
        # =======================
        print 'Creating Admin Server...'
        cd('/Servers/AdminServer')
        set('ListenPort', admin_port)
        set('Name', adminName)
        cmo.setWeblogicPluginEnabled(true)

        # Define the user password for weblogic
        # =====================================
        cd('/Security/' + domainName + '/User/weblogic')
        set('Name', user)
        set('Password', password)

        # Create a cluster
        # ======================
        print 'Creating oam servers cluster...'
        cd('/')
        cl=create(clusterName, 'Cluster')
        
        # Creating additional managed servers cluster
        print 'Creating policy managers cluster... ' + self.ADDL_CLUSTER
        cd('/')
        cl=create(self.ADDL_CLUSTER, 'Cluster')

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

        setOption('OverwriteDomain', 'true')
        domainHome = self.domainParentDir + '/' + domainName
        print 'Will create Base domain at ' + domainHome

        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'Base domain created at ' + domainHome
        return domainHome


    def readAndApplyExtensionTemplates(self, domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort):
        print 'Extending domain at ' + domainHome
        print 'Database  ' + db
        readDomain(domainHome)
        setOption('AppDir', self.domainParentDir + '/applications')

        print 'ExposeAdminT3Channel %s with %s:%s ' % (exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
        if 'true' == exposeAdminT3Channel:
            self.enable_admin_channel(t3ChannelPublicAddress, t3ChannelPort)

        self.applyExtensionTemplates()
        print 'Extension Templates added'
        return
        
    def applyExtensionTemplates(self):
        print 'Apply Extension templates'
        for extensionTemplate in self.OAM_EXTENSION_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))
        return
        
    def configureJDBCTemplates(self,db,dbPrefix,dbPassword):
        print 'Configuring the Service Table DataSource...'
        fmwDb = 'jdbc:oracle:thin:@' + db
        print 'fmwDatabase  ' + fmwDb
        cd('/JDBCSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource')
        cd('JDBCDriverParams/NO_NAME_0')
        set('DriverName', 'oracle.jdbc.OracleDriver')
        set('URL', fmwDb)
        set('PasswordEncrypted', dbPassword)

        stbUser = dbPrefix + '_STB'
        cd('Properties/NO_NAME_0/Property/user')
        set('Value', stbUser)

        print 'Getting Database Defaults...'
        getDatabaseDefaults()
        return

    def targetManagedServers(self):
        print 'Targeting Managed Server Groups...'
        cd('/')
        for managedName in self.MANAGED_SERVERS:
            setServerGroups(managedName, self.MANAGED_SERVERS_GRP)
            cd('/Servers/' + managedName)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return
    
    def targetAddlManagedServers(self):
        print 'Targeting Additional Managed Server Groups...'
        cd('/')
        for managedName in self.ADDL_MANAGED_SERVERS:
            setServerGroups(managedName, self.ADDL_MANAGED_SERVERS_GRP)
            cd('/Servers/' + managedName)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return
        
    def targetCluster(self, clusterName):
        print 'Targeting Cluster ...'
        cd('/')
        print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + clusterName
        cd('/Cluster/' + clusterName)
        set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def extendOamDomain(self, domainHome, db, dbPrefix, dbPassword, managedNameBase, managedServerPort, managedCount, clusterName, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort):
        self.readAndApplyExtensionTemplates(domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
        print 'Extension Templates added'

        print 'Deleting oam_server1'
        cd('/')
        delete('oam_server1', 'Server')
        print 'The default oam_server1 coming from the oam extension template deleted'
        print 'Deleting oam_policy_mgr1'
        cd('/')
        delete('oam_policy_mgr1', 'Server')
        print 'The default oam_server1 coming from the oam extension template deleted'

        print 'Configuring JDBC Templates ...'
        self.configureJDBCTemplates(db,dbPrefix,dbPassword)

        print 'Configuring Managed Servers ...'
        ms_port    = int(managedServerPort)
        ms_count   = int(managedCount)
        # Creating oam servers
        oam_listenAddress='-oam-server' 
        self.MANAGED_SERVERS = self.createManagedServers(ms_count, managedNameBase, ms_port, clusterName, self.MANAGED_SERVERS, oam_listenAddress)
        # Creating policy managers
	policy_listenAddress='-oam-policy-mgr'
        self.ADDL_MANAGED_SERVERS = self.createManagedServers(ms_count, self.ADDL_MANAGED_SERVER_BASENAME, self.ADDL_MANAGED_SERVER_PORT, self.ADDL_CLUSTER, self.ADDL_MANAGED_SERVERS, policy_listenAddress)

        print 'Targeting Server Groups...'
        cd('/')
        self.targetManagedServers()
        self.targetAddlManagedServers()
        self.targetCluster(clusterName);
        self.targetCluster(self.ADDL_CLUSTER);
        cd('/')


        print 'Preparing to update domain...'
        updateDomain()
        print 'Domain updated successfully'
        closeDomain()
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
          '-managedServerCount <managedCount> -clusterName <clusterName>' \
          '-domainType <oam>' \
          '-exposeAdminT3Channel <quoted true or false> -t3ChannelPublicAddress <address of the cluster> ' \
          '-t3ChannelPort <t3 channel port> '
    sys.exit(0)

# Uncomment for Debug only
#print str(sys.argv[0]) + " called with the following sys.argv array:"
#for index, arg in enumerate(sys.argv):
#    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) < 17:
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
rcuSchemaPrefix = 'OAM1'
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
    elif sys.argv[i] == '-adminName':
        adminName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-managedNameBase':
        managedNameBase = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-managedServerPort':
        managedServerPort = sys.argv[i + 1]
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
    elif sys.argv[i] == '-domainType':
        domainType = sys.argv[i + 1]
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
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

provisioner = OAM12214Provisioner(oracleHome, javaHome, domainParentDir, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName)
provisioner.createOAMDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword, adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort)
