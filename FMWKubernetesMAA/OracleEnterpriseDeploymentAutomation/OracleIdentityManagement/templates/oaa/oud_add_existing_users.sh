#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of Adding Existing Users to the OAA User Group
#

echo "dn:cn=<OAA_USER_GROUP>,<LDAP_GROUP_SEARCHBASE>" > /u01/oracle/config-input/update_group.ldif
echo "changetype: modify" >> /u01/oracle/config-input/update_group.ldif
echo "add: uniqueMember" >> /u01/oracle/config-input/update_group.ldif
/u01/oracle/oud/bin/ldapsearch -h <OUD_POD_PREFIX>-oud-ds-rs-lbr-ldap.<OUDNS>.svc.cluster.local -p 1389 -D <LDAP_ADMIN_USER> -w <LDAP_ADMIN_PWD> -b <LDAP_USER_SEARCHBASE> "cn=*" dn | grep -v <OAA_ADMIN_USER> | grep -v "dn: <LDAP_USER_SEARCHBASE>" | grep cn| awk ' { print "uniqueMember: "$2 } ' >> /u01/oracle/config-input/update_group.ldif
/u01/oracle/oud/bin/ldapmodify -h <OUD_POD_PREFIX>-oud-ds-rs-lbr-ldap.<OUDNS>.svc.cluster.local -p 1389 -D <LDAP_ADMIN_USER> -w <LDAP_ADMIN_PWD> -f /u01/oracle/config-input/update_group.ldif
