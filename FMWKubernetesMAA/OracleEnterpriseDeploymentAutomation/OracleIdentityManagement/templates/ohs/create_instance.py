#!/usr/bin/python
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of using WLST to create and Oracle HTTP Server Instance
#
#
 
import os, sys
 
v_mwHome="<MW_HOME>"
v_jdkHome="<JAVA_HOME>"
v_domainHome="<OHS_DOMAIN>"
v_domainName="ohsDomain"
v_NMUsername="<NM_USER>"
v_NMPassword="<NM_PWD>"
v_NMHome="<NM_HOME>"
v_NMHost="localhost"
v_NMPort="<NM_PORT>"
v_NMType="SSL"
v_OHSInstanceName="<OHS_NAME>"
v_OHSAdminPort="9999"
v_OHSHTTPPort="<OHS_HTTP_PORT>"
v_OHSHTTPSPort="<OHS_HTTPS_PORT>"
 
selectTemplate('Oracle HTTP Server (Standalone)')
loadTemplates()
 
cd('/')
create(v_domainName, 'SecurityConfiguration') 
cd('SecurityConfiguration/' + v_domainName)
set('NodeManagerUsername',v_NMUsername)
set('NodeManagerPasswordEncrypted',v_NMPassword)
setOption('NodeManagerType', 'CustomLocationNodeManager');
setOption('NodeManagerHome', v_NMHome);
setOption('JavaHome', v_jdkHome )
 
cd('/Machines/localmachine/NodeManager/localmachine')
cmo.setListenAddress(v_NMHost);
cmo.setListenPort(int(v_NMPort));
cmo.setNMType(v_NMType);
 
try:
    delete (v_OHSInstanceName,'SystemComponent')
except Exception:
    pass

create (v_OHSInstanceName,'SystemComponent')
cd('/OHS/'+v_OHSInstanceName)
cmo.setAdminPort(v_OHSAdminPort)
cmo.setListenPort(v_OHSHTTPPort)
cmo.setSSLListenPort(v_OHSHTTPSPort)
 
writeDomain(v_domainHome) 
