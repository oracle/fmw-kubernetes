# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys

import com.oracle.cie.domain.script.jython.WLSTException as WLSTException

class Capture12214Provisioner:

    MANAGED_SERVERS = []

    CLUSTER = 'capture_cluster'
    CAPTURE_SERVER_BASENAME = 'capture_server'
    CAPTURE_SERVER_PORT = 16400
    CAPTURE_SERVER_SSL_PORT = 16401

    JRF_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_template.jar'
        ],
        'serverGroupsToTarget' : [ 'JRF-MAN-SVR' ]
    }

    CAPTURE_12214_TEMPLATES = {
        'extensionTemplates' : [
            '@@ORACLE_HOME@@/wccapture/common/templates/wls/oracle.capture_template.jar'
        ],
        'serverGroupsToTarget' : ['CAPTURE-MGD-SVR']
    }    

    def __init__(self, oracleHome, javaHome, domainParentDir, domainName, prodMode, managedCount, sslEnabled):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def extendCaptureDomain(self, domainParentDir, db, dbPrefix, dbPassword, prodMode, managedCount, sslEnabled):

        print '================================================================='
        print '    WebCenter Capture WebLogic Operator Domain Extension Script  '
        print '                         12.2.1.4.0                              '
        print '================================================================='
        
        print 'Extending Domain with Capture...'
        ms_count = int(managedCount)
        self.extendDomain(domainParentDir, ms_count, db, dbPrefix, dbPassword)
        print 'Domain Extension with Capture is done...'

    def extendDomain(self, domainHome, ms_count, db, dbPrefix, dbPassword):
        print 'Extending domain at ' + domainHome
        print 'Database  ' + db
        readDomain(domainHome)

        # Create Capture cluster
        # ======================
        print 'Creating Capture cluster...' + self.CLUSTER
        cd('/')
        cl=create(self.CLUSTER, 'Cluster')

        # Create Capture Managed servers
        print 'Creating Capture Managed Servers...'

        self.MANAGED_SERVERS = self.createManagedServers(ms_count, self.CAPTURE_SERVER_BASENAME, self.CAPTURE_SERVER_PORT, self.CLUSTER, self.MANAGED_SERVERS, self.CAPTURE_SERVER_SSL_PORT, sslEnabled)
        print 'Capture Managed servers created...'

        print 'Applying Capture domain extension templates...'
        for extensionTemplate in self.CAPTURE_12214_TEMPLATES['extensionTemplates']:
            addTemplate(self.replaceTokens(extensionTemplate))

        print 'Capture Extension Templates added...'

        print 'Configuring JDBCTemplates...'
        self.configureJDBCTemplates(db, dbPrefix, dbPassword)

        print 'Targeting Server Groups...'

        serverGroupsToTarget = list(self.JRF_12214_TEMPLATES['serverGroupsToTarget'])
        serverGroupsToTarget.extend(self.CAPTURE_12214_TEMPLATES['serverGroupsToTarget'])
        self.targetCaptureServers(serverGroupsToTarget)
        

        print 'Targeting Cluster ...'
        clusterName = self.CLUSTER
        
        cd('/')
        print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for cluster:" + clusterName
        cd('/Cluster/' + clusterName)
        set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        
        print "Set WLS clusters as target of defaultCoherenceCluster:" + clusterName
        cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
        set('Target', clusterName)

        # Delete the CAPTURE_server1 (default server)
        if 'CAPTURE_server1' not in self.MANAGED_SERVERS:
            cd('/')
            delete('CAPTURE_server1', 'Server')
            print 'CAPTURE default Managed server deleted...'

        try:
            delete('capture-jms-server', 'JMSServer')
            print 'Capture default JMS server deleted...'
        except:
            print("Default capture-jms-server not found")

        print 'Preparing to update domain...'
        updateDomain()
        print 'Domain updated successfully'
        closeDomain()
        return


    ###########################################################################
    # Helper Methods                                                          #
    ###########################################################################
        
    def createManagedServers(self, ms_count, managedNameBase, ms_port, cluster_name, ms_servers, managedServerSSLPort, sslEnabled):
        # Create Managed servers
        for index in range(0, ms_count):
            print 'Creating Managed servers...'
            cd('/')
            msIndex = index+1
            cd('/')
            name = '%s%s' % (managedNameBase, msIndex)
            create(name, 'Server')
            cd('/Servers/%s/' % name )
            print('Managed server name is %s' % name);
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
              set('ListenPort', managedServerSSLPort)
              set('Enabled', 'True')
        print ms_servers
        return ms_servers

    def targetCaptureServers(self, serverGroupsToTarget):
        for managedName in self.MANAGED_SERVERS:
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

    

#############################
# Entry point to the script #
#############################

def usage():
    print sys.argv[0] + ' -oh <oracle_home> -jh <java_home> -parent <domain_parent_dir> -name <domain-name>' + \
          '-rcuDb <rcu-database> -rcuPrefix <rcu-prefix> -rcuSchemaPwd <rcu-schema-password> ' + \
          '-prodMode <prodMode> -managedServerCount <managedCount> -sslEnabled <sslEnabled> '
    sys.exit(0)

# Uncomment for Debug only
#print str(sys.argv[0]) + " called with the following sys.argv array:"
#for index, arg in enumerate(sys.argv):
#    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) < 10:
    usage()

#oracleHome will be passed by command line parameter -oh.
oracleHome = None
#javaHome will be passed by command line parameter -jh.
javaHome = None
#domainParentDir will be passed by command line parameter -parent.
domainParentDir = None
#rcuDb will be passed by command line parameter -rcuDb.
rcuDb = None
#change rcuSchemaPrefix to your infra schema prefix. Command line parameter -rcuPrefix.
rcuSchemaPrefix = 'WCCK6'
#change rcuSchemaPassword to your infra schema password. Command line parameter -rcuSchemaPwd.
rcuSchemaPassword = None


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
    elif sys.argv[i] == '-rcuDb':
        rcuDb = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuPrefix':
        rcuSchemaPrefix = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-rcuSchemaPwd':
        rcuSchemaPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-prodMode':
        prodMode = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-managedServerCount':
        managedCount = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-sslEnabled':
        sslEnabled = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

provisioner = Capture12214Provisioner(oracleHome, javaHome, domainParentDir, domainName, prodMode, managedCount, sslEnabled)
provisioner.extendCaptureDomain(domainParentDir, rcuDb, rcuSchemaPrefix, rcuSchemaPassword, prodMode, managedCount, sslEnabled)
