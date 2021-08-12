#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.  
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete an OUD deployment
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_oud.sh
#
. ../common/functions.sh
. $RSPFILE


helm uninstall -n $OUDNS edg 
check_stopped $OUDNS $OUD_POD_PREFIX-oud-ds-rs-0
check_stopped $OUDNS $OUD_POD_PREFIX-oud-ds-rs-1
rm -rf $LOCAL_WORKDIR/OUD
rm -rf $OUD_LOCAL_PVSHARE/*
