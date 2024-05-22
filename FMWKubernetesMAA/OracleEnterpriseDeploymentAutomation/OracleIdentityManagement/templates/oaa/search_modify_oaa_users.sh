#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of Adding Existing Users to the OAA User Group
#

/u01/oracle/oud/bin/ldapsearch -h "<LDAP_HOST>" -p "<LDAP_PORT>" -D "<LDAP_ADMIN_USER>" -w "<LDAP_ADMIN_PWD>" -b "cn=<OAA_USER_GROUP>,<LDAP_GROUP_SEARCHBASE>" "cn=*" > /tmp/output.txt
for unique_member in `grep "uniqueMember:" /tmp/output.txt | awk '{print $2}' |  cut -f1 -d ","`
do 
/u01/oracle/oud/bin/ldapsearch -h "<LDAP_HOST>" -p "<LDAP_PORT>" -D "<LDAP_ADMIN_USER>" -w "<LDAP_ADMIN_PWD>" -b "$unique_member,<LDAP_USER_SEARCHBASE>" "(obpsftid=true)" cn > /tmp/output1.txt
if [ "$?" = "0" ]
then
  grep "$unique_member" /tmp/output1.txt
  if [ "$?" = "0" ]
  then
    echo "$unique_member already modified"
  else  
    /u01/oracle/oud/bin/ldapmodify -h"<LDAP_HOST>" -p "<LDAP_PORT>" -D "<LDAP_ADMIN_USER>" -w "<LDAP_ADMIN_PWD>" <<EOF
dn: $unique_member,<LDAP_USER_SEARCHBASE>
changetype: modify
replace: obpsftid
obpsftid: true
EOF
  fi  
else
  echo "$unique_member Not Found"
fi
done