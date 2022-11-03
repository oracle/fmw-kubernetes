# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
import sys
class ConfigureIPMConnection:  

    def ConfigureIPMDetails(self):
        print 'Configuring FrontendHost, FrontendPort for IPM access and enable HTTP connections to UCM'
        # login to wlst online
        connect(domainUser, domainPassword, 't3://'+adminUrl)

        edit()
        startEdit()
        
        # Navigate Mbean hierarchy and set FrontendHost and FrontendPort
        cd ('Clusters/ipm_cluster')

        set ('FrontendHost',frontendHost)
       
        if (sslEnabled == 'true'):
            set('FrontendHTTPSPort',frontendPort)
        else:
            set('FrontendHTTPPort',frontendPort)

        # Invoke save operation and activate
        save()
        activate() 
        print 'Configured FrontendHost, FrontendPort for IPM access'
        self.enableHTTPConnection()

    def enableHTTPConnection(self):

        print 'Started enabling HTTP connections to UCM'

        cd('/')
        beginRepositorySession()
        createPolicySet('ws-client', 'ws-client', 'Domain("*")')
        attachPolicySetPolicy('oracle/wss10_saml_token_client_policy')
        commitRepositorySession()

        beginRepositorySession()
        createPolicySet('ws-service', 'ws-service', 'Domain("*")')
        attachPolicySetPolicy('oracle/wss_saml_or_username_token_service_policy')
        commitRepositorySession()
        
        grantPermission(codeBaseURL="file:${common.components.home}/modules/oracle.wsm.common_12.1.3/wsm-agent-core.jar", permClass="oracle.wsm.security.WSIdentityPermission", permTarget="resource=imaging", permActions="assert")
        grantPermission(codeBaseURL="file:${common.components.home}/modules/oracle.wsm.common_12.1.3/wsm-agent-core.jar", permClass="oracle.wsm.security.WSIdentityPermission", permTarget="resource=imaging-vc", permActions="assert")

        grantPermission(codeBaseURL="file:${common.components.home}/modules/oracle.wsm.common/wsm-agent-core.jar", permClass="oracle.wsm.security.WSIdentityPermission", permTarget="resource=imaging", permActions="assert")
        grantPermission(codeBaseURL="file:${common.components.home}/modules/oracle.wsm.common/wsm-agent-core.jar", permClass="oracle.wsm.security.WSIdentityPermission", permTarget="resource=imaging-vc", permActions="assert")

        serverConfig()
        cd('SecurityConfiguration/wccinfra/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
        cmo.createUser('IPM_SystemServiceUser','welcome1','')
        cmo.createUser('IPM_AgentServiceUser','welcome1','')
        
        print 'Enabled HTTP connections to UCM'
        
i = 1
while i < len(sys.argv):
    
    if sys.argv[i] == '-user':
        domainUser = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-password':
        domainPassword = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminUrl':
        adminUrl = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-loadbalancerHost':
        frontendHost = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-loadbalancerPort':
        frontendPort = sys.argv[i + 1]
        i += 2  
    elif sys.argv[i] == '-sslEnabled':
        sslEnabled = sys.argv[i + 1]
        i += 2
    else:
        print 'Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i])
        usage()
        sys.exit(1)

config = ConfigureIPMConnection()
config.ConfigureIPMDetails()

