#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of Adding Existing Users to the OAA User Group
#

/u01/oracle/oud/bin/ldapsearch -h "<LDAP_HOST>" -p "<LDAP_PORT>" -D "<LDAP_ADMIN_USER>" -w "<LDAP_ADMIN_PWD>" -b "cn=<OAA_USER_GROUP>,<LDAP_GROUP_SEARCHBASE>" "cn=*" 
