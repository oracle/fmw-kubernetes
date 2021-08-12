#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.  
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OUDSM deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oudsm.sh
#
. ../common/functions.sh
. $RSPFILE


helm uninstall -n $OUDNS oudsm 
check_stopped $OUDNS oudsm-1
rm -rf $OUDSM_LOCAL_SHARE/*
