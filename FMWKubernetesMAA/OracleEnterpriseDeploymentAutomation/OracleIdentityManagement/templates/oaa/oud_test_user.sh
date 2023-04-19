#!/bin/bash
# Copyright (c) 2022, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a shell script to create a test user
#
/u01/oracle/oud/bin/ldapmodify -h <LDAP_HOST> -p <LDAP_PORT> -D <LDAP_ADMIN_USER> -w <LDAP_ADMIN_PWD> -f /u01/oracle/config-input/test_user.ldif
