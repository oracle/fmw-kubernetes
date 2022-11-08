#!/usr/bin/python
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of using WLST to delete and Oracle HTTP Server Instance
#
#
 
import os, sys
 
v_mwHome="<MW_HOME>"
v_domainHome="<OHS_DOMAIN>"
v_domainName="ohsDomain"
v_OHSInstanceName="<OHS_NAME>"
 

readDomain(v_domainHome)
cd('/')
 
delete (v_OHSInstanceName,'SystemComponent')
 
updateDomain()
