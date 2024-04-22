# Copyright (c) 2020, 2024, Oracle  and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import os
import sys
import com.oracle.cie.domain.script.jython.WLSTException as WLSTException


class OIMProvisioner:
    MACHINES = {
        'machine1': {
            'NMType': 'SSL',
            'ListenAddress': 'localhost',
            'ListenPort': 5658
        }
    }

    OIM_MANAGED_SERVERS = ['oim_server1']
    SOA_MANAGED_SERVERS = ['soa_server1']

    SOA_CLUSTERS = {
        'soa_cluster': {}
    }

    OIM_CLUSTERS = {
        'oim_cluster': {}
    }

    SERVERS = {
        'AdminServer': {
            'ListenAddress': '',
            'ListenPort': 7001,
            'Machine': 'machine1'
        }

    }

    SOA_SERVERS = {
        'soa_server1': {
            'ListenAddress': '',
            'ListenPort': 8001,
            'Machine': 'machine1',
            'Cluster': 'soa_cluster'
        }
    }

    OIM_SERVERS = {
        'oim_server1': {
            'ListenAddress': '',
            'ListenPort': 14001,
            'Machine': 'machine1',
            'Cluster': 'oim_cluster'
        }
    }

    JRF_12214_TEMPLATES = {
        'baseTemplate': '@@ORACLE_HOME@@/wlserver/common/templates/wls/wls.jar',
        'extensionTemplates': [
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.jrf.ws.async_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.wsmpm_template.jar',
            '@@ORACLE_HOME@@/oracle_common/common/templates/wls/oracle.ums_template.jar',
            '@@ORACLE_HOME@@/em/common/templates/wls/oracle.em_wls_template.jar'
        ],
        'serverGroupsToTarget': ['JRF-MAN-SVR', 'WSMPM-MAN-SVR']
    }

    SOA_12214_TEMPLATES = {
        'extensionTemplates': [
            '@@ORACLE_HOME@@/soa/common/templates/wls/oracle.soa_template.jar'
        ],
        'serverGroupsToTarget': ['SOA-MGD-SVRS']
    }

    OIM_TEMPLATES = {
        'serverGroupsToTarget': ['OIM-MGD-SVRS']
    }

    def __init__(self, oracleHome, javaHome, domainParentDir, adminListenPort, adminName, managedNameBase,
                 managedServerPort, prodMode, managedCount, clusterName):
        self.oracleHome = self.validateDirectory(oracleHome)
        self.javaHome = self.validateDirectory(javaHome)
        self.domainParentDir = self.validateDirectory(domainParentDir, create=True)
        return

    def createOimDomain(self, domainName, user, password, db, dbPrefix, dbPassword, adminListenPort, adminName,
                        managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType,
                        frontEndHost, frontEndHttpPort, dstype, exposeAdminT3Channel=None, t3ChannelPublicAddress=None,
                        t3ChannelPort=None):

        domainHome = self.createBaseDomain(domainName, user, password, adminListenPort, adminName, managedNameBase,
                                           managedServerPort, prodMode, managedCount, clusterName, domainType)

        self.extendOimDomain(domainHome, db, dbPrefix, dbPassword, user, password, adminListenPort, adminName,
                             managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType,
                             frontEndHost, frontEndHttpPort, dstype, exposeAdminT3Channel, t3ChannelPublicAddress,
                             t3ChannelPort)

    def createBaseDomain(self, domainName, user, password, adminListenPort, adminName, managedNameBase,
                         managedServerPort, prodMode, managedCount, clusterName, domainType):
        selectTemplate('Basic WebLogic Server Domain')
        loadTemplates()
        showTemplates()
        setOption('DomainName', domainName)
        setOption('JavaHome', self.javaHome)
        setOption('AppDir', self.domainParentDir + '/applications')

        if (prodMode == 'true'):
            setOption('ServerStartMode', 'prod')
        else:
            setOption('ServerStartMode', 'dev')

        set('Name', domainName)

        admin_port = int(adminListenPort)
        ms_port = int(managedServerPort)
        ms_count = int(managedCount)

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
        print 'Writing base domain...'
        writeDomain(domainHome)
        closeTemplate()
        print 'Base domain created at ' + domainHome
        return domainHome

    def extendOimDomain(self, domainHome, db, dbPrefix, dbPassword, user, password, adminListenPort, adminName,
                        managedNameBase, managedServerPort, prodMode, managedCount, clusterName, domainType,
                        frontEndHost, frontEndHttpPort, dstype, exposeAdminT3Channel, t3ChannelPublicAddress, t3ChannelPort,
                        ):
        print 'Extending domain at ' + domainHome
        fmwDb = 'jdbc:oracle:thin:@' + db
        readDomain(domainHome)
        selectTemplate('Oracle Identity Manager')
        loadTemplates()
        showTemplates()
        setOption('AppDir', self.domainParentDir + '/applications')
        if 'true' == exposeAdminT3Channel:
            self.enable_admin_channel(t3ChannelPublicAddress, t3ChannelPort)

        admin_port = int(adminListenPort)
        ms_port = int(managedServerPort)
        ms_count = int(managedCount)
        ms_t3_port = 14002
        oim_listenAddress = '-oim-server'

        #enable DB Persistence for JMS Stores and JTA TLog
        if isJMSStorePersistenceConfigurable() and not isJMSStoreDBPersistenceSet():
            print("Enabling DB Persistence for JMS Stores")
            enableJMSStoreDBPersistence(True)
        if isJTATLogPersistenceConfigurable() and not isJTATLogDBPersistenceSet():
            print("Enabling DB Persistence for JTA TLog")
            enableJTATLogDBPersistence(True)

        # Create a OIM cluster
        # ======================
        print 'Creating cluster...'
        cd('/')
        cl = create(clusterName, 'Cluster')

        # Creating a SOA Cluster : Name is hard Coded as there is no way to input multiple clusters name
        soa_cluster_name = 'soa_cluster'
        cd('/')
        create(soa_cluster_name, 'Cluster')

        # Creating OIM Managed Servers

        cd('/Servers/oim_server1')
        create('T3Channel', 'NetworkAccessPoint')
        cd('/Servers/oim_server1/NetworkAccessPoint/T3Channel')
        set('ListenPort', int(ms_t3_port))
        set('PublicPort', int(ms_t3_port))
        cmo.setHttpEnabledForThisProtocol(true)
        cmo.setTunnelingEnabled(true)

        for index in range(1, ms_count):
            cd('/')
            msIndex = index + 1
            cd('/')
            name = '%s%s' % ('oim_server', msIndex)
            listenAddress = '%s%s%s' % ('oimk8namespace', oim_listenAddress, msIndex)
            create(name, 'Server')
            cd('/Servers/%s/' % name)
            print('managed server name is %s' % name);
            set('ListenPort', ms_port)
            set('ListenAddress', listenAddress)
            set('NumOfRetriesBeforeMSIMode', 0)
            set('RetryIntervalBeforeMSIMode', 1)
            set('Cluster', clusterName)
            cmo.setWeblogicPluginEnabled(true)
            create('T3Channel', 'NetworkAccessPoint')
            cd('/Servers/' + name + '/NetworkAccessPoint/T3Channel')
            set('ListenPort', int(ms_t3_port))
            set('PublicPort', int(ms_t3_port))
            cmo.setHttpEnabledForThisProtocol(true)
            cmo.setTunnelingEnabled(true)
            self.OIM_MANAGED_SERVERS.append(name)
        print self.OIM_MANAGED_SERVERS

        # TODO: replace the ms_count with the variable passed from config maps
        soa_ms_count = ms_count
        soa_managedNameBase = 'soa_server'
        soa_listenAddress = '-soa-server'
        soa_ms_port = 8001

        cd('/')
        cd('/Server/soa_server1')
        set('ListenPort', soa_ms_port)
        set('ListenAddress', 'oimk8namespace-soa-server1')
        cmo.setWeblogicPluginEnabled(true)

        cd('/')
        cd('/Server/oim_server1')
        set('ListenPort', ms_port)
        set('ListenAddress', 'oimk8namespace-oim-server1')
        cmo.setWeblogicPluginEnabled(true)

        # Create soa  managed servers
        for index in range(1, soa_ms_count):
            cd('/')
            msIndex = index + 1
            cd('/')
            name = '%s%s' % (soa_managedNameBase, msIndex)
            listenAddress = '%s%s%s' % ('oimk8namespace', soa_listenAddress, msIndex)
            create(name, 'Server')
            cd('/Servers/%s/' % name)
            print('managed server name is %s' % name);
            set('ListenPort', soa_ms_port)
            set('ListenAddress', listenAddress)
            set('NumOfRetriesBeforeMSIMode', 0)
            set('RetryIntervalBeforeMSIMode', 1)
            set('Cluster', soa_cluster_name)
            cmo.setWeblogicPluginEnabled(true)
            self.SOA_MANAGED_SERVERS.append(name)
        print self.SOA_MANAGED_SERVERS

        ## Assigning servers to the clusters

        for managedName in self.SOA_MANAGED_SERVERS:
            assign('Server', managedName, 'Cluster', soa_cluster_name)

        for managedName in self.OIM_MANAGED_SERVERS:
            assign('Server', managedName, 'Cluster', clusterName)

        print('front end host :' + frontEndHost)
        print('front end HTTP Port :' + frontEndHttpPort)
        frontEndURL = "http://" + frontEndHost + ":" + frontEndHttpPort

        print('frontEndURL :' + frontEndURL)

        ## Setting Front End Host Port for SOA
        cd('/')
        setFEHostURL(frontEndURL, "https://nohost:4455", "true")

        cd('/Cluster')
        cd('%s' % soa_cluster_name)

        ## Setting front End Host Port for OIM
        cd('/Cluster')
        cd('%s' % clusterName)

        # Targeting Server Groups
        print('Targeting SOA Server Groups...')
        serverGroupsToTarget = list(self.SOA_12214_TEMPLATES['serverGroupsToTarget'])
        cd('/')
        self.targetSOAServers(serverGroupsToTarget)

        # Targeting Server Groups
        print('Targeting OIM Server Groups...')
        oimServerGroupsToTarget = list(self.OIM_TEMPLATES['serverGroupsToTarget'])
        cd('/')
        self.targetOIMServers(oimServerGroupsToTarget)


        print('Using datasource type: ' + dstype)
        #construct Long URL from short URL for AGL datasource
        if dstype == "agl":
            db_host = db.split(":")[0].strip()
            db_port = db.split(":")[1].split("/")[0].strip()
            db_service = db.split("/")[1].strip()
            db_long_url = "(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=" + db_host + ")(PORT=" + db_port + ")))(CONNECT_DATA=(SERVICE_NAME=" + db_service + ")))"
            print("using long url: " + db_long_url)
            fmwDb_agl = 'jdbc:oracle:thin:@' + db_long_url

        cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OPSS')

        #for AGL datasource configuration
        if dstype == "agl":
            print("creating AGL datasource for opss-data-source")
            cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source')
            create('opss-data-source', 'JDBCOracleParams')
            cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            #configure JDBC Connection pool params
            cd('/JDBCSystemResource/opss-data-source/JdbcResource/opss-data-source/JDBCConnectionPoolParams/NO_NAME_0')
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            #configure Global Transaction Protocol
            cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            #set long url
            cd('/JdbcSystemResource/opss-data-source/JdbcResource/opss-data-source/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_IAU_APPEND')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for opss-audit-DBDS")
            cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS')
            create('opss-audit-DBDS', 'JDBCOracleParams')
            cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JDBCConnectionPoolParams/NO_NAME_0')
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/opss-audit-DBDS/JdbcResource/opss-audit-DBDS/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_IAU_VIEWER')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for opss-audit-viewDS")
            cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS')
            create('opss-audit-viewDS', 'JDBCOracleParams')
            cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JDBCConnectionPoolParams/NO_NAME_0')
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/opss-audit-viewDS/JdbcResource/opss-audit-viewDS/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        # Config WSM
        cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_MDS')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for mds-soa")
            cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa')
            create('mds-soa', 'JDBCOracleParams')
            cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/mds-soa/JdbcResource/mds-soa/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InitialCapacity', 0)
            set('MaxCapacity', 200)
            set('RemoveInfectedConnections', 'false')
            set('SecondsToTrustAnIdlePoolConnection', 10)
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        # Database configuration for SOA
        cd('/JdbcSystemResource/OraSDPMDataSource/JdbcResource/OraSDPMDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_UMS')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for OraSDPMDataSource")
            cd('/JdbcSystemResource/OraSDPMDataSource/JdbcResource/OraSDPMDataSource')
            create('OraSDPMDataSource', 'JDBCOracleParams')
            cd('/JdbcSystemResource/OraSDPMDataSource/JdbcResource/OraSDPMDataSource/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/OraSDPMDataSource/JdbcResource/OraSDPMDataSource/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InitialCapacity', 0)
            set('MaxCapacity', 1200)
            set('SecondsToTrustAnIdlePoolConnection', 0)
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/OraSDPMDataSource/JdbcResource/OraSDPMDataSource/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'TwoPhaseCommit')

            # set long url
            cd('/JdbcSystemResource/OraSDPMDataSource/JdbcResource/OraSDPMDataSource/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/mds-owsm/JdbcResource/mds-owsm/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_MDS')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for mds-owsm")
            cd('/JdbcSystemResource/mds-owsm/JdbcResource/mds-owsm')
            create('mds-owsm', 'JDBCOracleParams')
            cd('/JdbcSystemResource/mds-owsm/JdbcResource/mds-owsm/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/mds-owsm/JdbcResource/mds-owsm/JDBCConnectionPoolParams/NO_NAME_0')
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InitialCapacity', 0)
            set('SecondsToTrustAnIdlePoolConnection', 0)
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/mds-owsm/JdbcResource/mds-owsm/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/mds-owsm/JdbcResource/mds-owsm/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/SOADataSource/JdbcResource/SOADataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_SOAINFRA')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for SOADataSource")
            cd('/JdbcSystemResource/SOADataSource/JdbcResource/SOADataSource')
            create('SOADataSource', 'JDBCOracleParams')
            cd('/JdbcSystemResource/SOADataSource/JdbcResource/SOADataSource/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/SOADataSource/JdbcResource/SOADataSource/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InitialCapacity', 0)
            set('MaxCapacity', 1200)
            set('SecondsToTrustAnIdlePoolConnection', 10)
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')
            set('RemoveInfectedConnections', 'false')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/SOADataSource/JdbcResource/SOADataSource/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'TwoPhaseCommit')

            # set long url
            cd('/JdbcSystemResource/SOADataSource/JdbcResource/SOADataSource/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/SOALocalTxDataSource/JdbcResource/SOALocalTxDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_SOAINFRA')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for SOALocalTxDataSource")
            cd('/JdbcSystemResource/SOALocalTxDataSource/JdbcResource/SOALocalTxDataSource')
            create('SOALocalTxDataSource', 'JDBCOracleParams')
            cd('/JdbcSystemResource/SOALocalTxDataSource/JdbcResource/SOALocalTxDataSource/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/SOALocalTxDataSource/JdbcResource/SOALocalTxDataSource/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InitialCapacity', 0)
            set('MaxCapacity', 1200)
            set('SecondsToTrustAnIdlePoolConnection', 10)
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')
            set('RemoveInfectedConnections', 'false')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/SOALocalTxDataSource/JdbcResource/SOALocalTxDataSource/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/SOALocalTxDataSource/JdbcResource/SOALocalTxDataSource/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/EDNDataSource/JdbcResource/EDNDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_SOAINFRA')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for EDNDataSource")
            cd('/JdbcSystemResource/EDNDataSource/JdbcResource/EDNDataSource')
            create('EDNDataSource', 'JDBCOracleParams')
            cd('/JdbcSystemResource/EDNDataSource/JdbcResource/EDNDataSource/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/EDNDataSource/JdbcResource/EDNDataSource/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InitialCapacity', 0)
            set('MaxCapacity', 80)
            set('SecondsToTrustAnIdlePoolConnection', 10)
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')
            set('RemoveInfectedConnections', 'false')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/EDNDataSource/JdbcResource/EDNDataSource/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'TwoPhaseCommit')

            # set long url
            cd('/JdbcSystemResource/EDNDataSource/JdbcResource/EDNDataSource/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)


        cd('/JdbcSystemResource/EDNLocalTxDataSource/JdbcResource/EDNLocalTxDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_SOAINFRA')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for EDNLocalTxDataSource")
            cd('/JdbcSystemResource/EDNLocalTxDataSource/JdbcResource/EDNLocalTxDataSource')
            create('EDNLocalTxDataSource', 'JDBCOracleParams')
            cd('/JdbcSystemResource/EDNLocalTxDataSource/JdbcResource/EDNLocalTxDataSource/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/EDNLocalTxDataSource/JdbcResource/EDNLocalTxDataSource/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InitialCapacity', 0)
            set('MaxCapacity', 80)
            set('SecondsToTrustAnIdlePoolConnection', 10)
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')
            set('RemoveInfectedConnections', 'false')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/EDNLocalTxDataSource/JdbcResource/EDNLocalTxDataSource/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/EDNLocalTxDataSource/JdbcResource/EDNLocalTxDataSource/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_MDS')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for mds-soa")
            cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa')
            create('mds-soa', 'JDBCOracleParams')
            cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/mds-soa/JdbcResource/mds-soa/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InitialCapacity', 0)
            set('MaxCapacity', 200)
            set('SecondsToTrustAnIdlePoolConnection', 10)
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')
            set('RemoveInfectedConnections', 'false')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/mds-soa/JdbcResource/mds-soa/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_STB')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for LocalSvcTblDataSource")
            cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource')
            create('LocalSvcTblDataSource', 'JDBCOracleParams')
            cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            # configure JDBC Connection pool params
            cd('/JDBCSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InitialCapacity', 0)
            set('MaxCapacity', 800)
            set('SecondsToTrustAnIdlePoolConnection', 0)
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/oimOperationsDB/JdbcResource/oimOperationsDB/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OIM')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for oimOperationsDB")
            cd('/JdbcSystemResource/oimOperationsDB/JdbcResource/oimOperationsDB')
            create('oimOperationsDB', 'JDBCOracleParams')
            cd('/JdbcSystemResource/oimOperationsDB/JdbcResource/oimOperationsDB/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            cd('/JDBCSystemResource/oimOperationsDB/JdbcResource/oimOperationsDB/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InactiveConnectionTimeoutSeconds', 300)
            set('InitialCapacity', 32)
            set('MaxCapacity', 200)
            set('MinCapacity', 128)
            set('SecondsToTrustAnIdlePoolConnection', 30)
            set('StatementCacheSize', 10)
            set('StatementCacheType', 'LRU')
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/oimOperationsDB/JdbcResource/oimOperationsDB/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'TwoPhaseCommit')

            # set long url
            cd('/JdbcSystemResource/oimOperationsDB/JdbcResource/oimOperationsDB/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)


        cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        set('PasswordEncrypted', dbPassword)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OIM')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for soaOIMLookupDB")
            cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB')
            create('soaOIMLookupDB', 'JDBCOracleParams')
            cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            cd('/JDBCSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InactiveConnectionTimeoutSeconds', 300)
            set('InitialCapacity', 20)
            set('MaxCapacity', 80)
            set('MinCapacity', 80)
            set('SecondsToTrustAnIdlePoolConnection', 30)
            set('StatementCacheSize', 10)
            set('StatementCacheType', 'LRU')
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'TwoPhaseCommit')

            # set long url
            cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/mds-oim/JdbcResource/mds-oim/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_MDS')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for mds-oim")
            cd('/JdbcSystemResource/mds-oim/JdbcResource/mds-oim')
            create('mds-oim', 'JDBCOracleParams')
            cd('/JdbcSystemResource/mds-oim/JdbcResource/mds-oim/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            cd('/JDBCSystemResource/mds-oim/JdbcResource/mds-oim/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InactiveConnectionTimeoutSeconds', 300)
            set('InitialCapacity', 15)
            set('MaxCapacity', 60)
            set('MinCapacity', 60)
            set('SecondsToTrustAnIdlePoolConnection', 30)
            set('StatementCacheSize', 10)
            set('StatementCacheType', 'LRU')
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/mds-oim/JdbcResource/mds-oim/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/mds-oim/JdbcResource/mds-oim/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/oimJMSStoreDS/JdbcResource/oimJMSStoreDS/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OIM')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for oimJMSStoreDS")
            cd('/JdbcSystemResource/oimJMSStoreDS/JdbcResource/oimJMSStoreDS')
            create('oimJMSStoreDS', 'JDBCOracleParams')
            cd('/JdbcSystemResource/oimJMSStoreDS/JdbcResource/oimJMSStoreDS/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            cd('/JDBCSystemResource/oimJMSStoreDS/JdbcResource/oimJMSStoreDS/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InactiveConnectionTimeoutSeconds', 300)
            set('InitialCapacity', 15)
            set('MaxCapacity', 60)
            set('MinCapacity', 60)
            set('SecondsToTrustAnIdlePoolConnection', 30)
            set('StatementCacheSize', 10)
            set('StatementCacheType', 'LRU')
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/oimJMSStoreDS/JdbcResource/oimJMSStoreDS/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/oimJMSStoreDS/JdbcResource/oimJMSStoreDS/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/ApplicationDB/JdbcResource/ApplicationDB/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OIM')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for ApplicationDB")
            cd('/JdbcSystemResource/ApplicationDB/JdbcResource/ApplicationDB')
            create('ApplicationDB', 'JDBCOracleParams')
            cd('/JdbcSystemResource/ApplicationDB/JdbcResource/ApplicationDB/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            cd('/JDBCSystemResource/ApplicationDB/JdbcResource/ApplicationDB/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InactiveConnectionTimeoutSeconds', 300)
            set('InitialCapacity', 50)
            set('MaxCapacity', 200)
            set('MinCapacity', 200)
            set('SecondsToTrustAnIdlePoolConnection', 30)
            set('StatementCacheSize', 10)
            set('StatementCacheType', 'LRU')
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')


            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/ApplicationDB/JdbcResource/ApplicationDB/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/ApplicationDB/JdbcResource/ApplicationDB/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.xa.client.OracleXADataSource')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_OIM')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for soaOIMLookupDB")
            cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB')
            create('soaOIMLookupDB', 'JDBCOracleParams')
            cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            cd('/JDBCSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JDBCConnectionPoolParams/NO_NAME_0')
            set('CapacityIncrement', 1)
            set('ConnectionCreationRetryFrequencySeconds', 10)
            set('InactiveConnectionTimeoutSeconds', 300)
            set('InitialCapacity', 20)
            set('MaxCapacity', 80)
            set('MinCapacity', 80)
            set('SecondsToTrustAnIdlePoolConnection', 30)
            set('StatementCacheSize', 10)
            set('StatementCacheType', 'LRU')
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'TwoPhaseCommit')

            # set long url
            cd('/JdbcSystemResource/soaOIMLookupDB/JdbcResource/soaOIMLookupDB/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)

        cd('/JdbcSystemResource/WLSSchemaDataSource/JdbcResource/WLSSchemaDataSource/JdbcDriverParams/NO_NAME')
        cmo.setUrl(fmwDb)
        cmo.setDriverName('oracle.jdbc.OracleDriver')
        set('PasswordEncrypted', dbPassword)
        cd('Properties/NO_NAME/Property/user')
        cmo.setValue(dbPrefix + '_WLS')

        # for agl datasource configuration
        if dstype == "agl":
            print("creating agl datasource for WLSSchemaDataSource")
            cd('/JdbcSystemResource/WLSSchemaDataSource/JdbcResource/WLSSchemaDataSource')
            create('WLSSchemaDataSource', 'JDBCOracleParams')
            cd('/JdbcSystemResource/WLSSchemaDataSource/JdbcResource/WLSSchemaDataSource/JDBCOracleParams/NO_NAME_0')
            set('FanEnabled', 'true')
            set('ActiveGridlink', 'True')

            cd('/JDBCSystemResource/WLSSchemaDataSource/JdbcResource/WLSSchemaDataSource/JDBCConnectionPoolParams/NO_NAME_0')
            set('MaxCapacity', 300)
            set('TestFrequencySeconds', 0)
            set('TestConnectionsOnReserve', 'true')
            set('TestTableName', 'SQL ISVALID')

            # configure Global Transaction Protocol
            cd('/JdbcSystemResource/WLSSchemaDataSource/JdbcResource/WLSSchemaDataSource/JdbcDataSourceParams/NO_NAME')
            set('GlobalTransactionsProtocol', 'None')

            # set long url
            cd('/JdbcSystemResource/WLSSchemaDataSource/JdbcResource/WLSSchemaDataSource/JdbcDriverParams/NO_NAME')
            cmo.setUrl(fmwDb_agl)



        cd('/')
        cd('Credential/TargetStore/oim')
        cd('TargetKey/keystore')
        create('c', 'Credential')
        cd('Credential')
        set('Username', 'keystore')
        set('Password', password)

        cd('/')
        cd('Credential/TargetStore/oim')
        cd('TargetKey/OIMSchemaPassword')
        create('c', 'Credential')
        cd('Credential')
        set('Username', dbPrefix + '_OIM')
        set('Password', dbPassword)

        cd('/')
        cd('Credential/TargetStore/oim')
        cd('TargetKey/sysadmin')
        create('c', 'Credential')
        cd('Credential')
        set('Username', 'xelsysadm')
        set('Password', password)

        cd('/')
        cd('Credential/TargetStore/oim')
        cd('TargetKey/WeblogicAdminKey')
        create('c', 'Credential')
        cd('Credential')
        set('Username', user)
        set('Password', password)

        updateDomain()
        closeDomain()

        exit()

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

    def readAndApplyJRFTemplates(self, domainHome, db, dbPrefix, dbPassword, exposeAdminT3Channel,
                                 t3ChannelPublicAddress, t3ChannelPort):
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

    def targetSOAServers(self, serverGroupsToTarget):
        print 'Targeting Server Groups...'
        cd('/')
        for managedName in self.SOA_MANAGED_SERVERS:
            setServerGroups(managedName, serverGroupsToTarget)
            print "Set CoherenceClusterSystemResource to defaultCoherenceCluster for server:" + managedName
            cd('/Servers/' + managedName)
            set('CoherenceClusterSystemResource', 'defaultCoherenceCluster')
        return

    def targetOIMServers(self, serverGroupsToTarget):
        print 'Targeting Server Groups...'
        cd('/')
        for managedName in self.OIM_MANAGED_SERVERS:
            setServerGroups(managedName, serverGroupsToTarget)
        return


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
          '-domainType <soa|osb|bpm|soaosb>' \
          '-exposeAdminT3Channel <quoted true or false> -t3ChannelPublicAddress <address of the cluster> ' \
          '-t3ChannelPort <t3 channel port> ' \
          '-datasourceType <type of datasource, default generic, Option agl>'
    sys.exit(0)


# Uncomment for Debug only
# print str(sys.argv[0]) + " called with the following sys.argv array:"
# for index, arg in enumerate(sys.argv):
#    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) < 17:
    usage()

# oracleHome will be passed by command line parameter -oh.
oracleHome = None
# javaHome will be passed by command line parameter -jh.
javaHome = None
# domainParentDir will be passed by command line parameter -parent.
domainParentDir = None
# domainUser is hard-coded to weblogic. You can change to other name of your choice. Command line paramter -user.
domainUser = 'weblogic'
# domainPassword will be passed by Command line parameter -password.
domainPassword = None
# rcuDb will be passed by command line parameter -rcuDb.
rcuDb = None
# change rcuSchemaPrefix to your infra schema prefix. Command line parameter -rcuPrefix.
rcuSchemaPrefix = 'SOA1'
# change rcuSchemaPassword to your infra schema password. Command line parameter -rcuSchemaPwd.
rcuSchemaPassword = None
exposeAdminT3Channel = None
t3ChannelPort = None
t3ChannelPublicAddress = None
frontEndHost = None
frontEndHttpPort = None

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
    elif sys.argv[i] == '-frontEndHost':
        frontEndHost = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-frontEndHttpPort':
        frontEndHttpPort = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-datasourceType':
        dstype = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

provisioner = OIMProvisioner(oracleHome, javaHome, domainParentDir, adminListenPort, adminName, managedNameBase,
                             managedServerPort, prodMode, managedCount, clusterName)
provisioner.createOimDomain(domainName, domainUser, domainPassword, rcuDb, rcuSchemaPrefix, rcuSchemaPassword,
                            adminListenPort, adminName, managedNameBase, managedServerPort, prodMode, managedCount,
                            clusterName, domainType, frontEndHost, frontEndHttpPort, dstype, exposeAdminT3Channel,
                            t3ChannelPublicAddress, t3ChannelPort)
