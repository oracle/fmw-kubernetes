#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a shell script to create OAA Users
#
/u01/oracle/oud/bin/ldapmodify -h <OUD_POD_PREFIX>-oud-ds-rs-lbr-ldap.<OUDNS>.svc.cluster.local -p 1389 -D <LDAP_ADMIN_USER> -w <LDAP_ADMIN_PWD> -f /u01/oracle/config-input/users.ldif
