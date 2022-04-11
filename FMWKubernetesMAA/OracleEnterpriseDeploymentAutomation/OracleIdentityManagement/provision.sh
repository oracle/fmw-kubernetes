#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of an Umbrella script that will perform a full end to end Identity Managment Provisioning
#
# Dependencies: ./prechecks.sh
#               ./responsefile/idm.rsp
#               ./provision_oud.sh
#               ./provision_oudsm.sh
#               ./provision_operator.sh
#               ./provision_oam.sh
#               ./provision_oig.sh
#
# Usage: provision.sh
#

. ./responsefile/idm.rsp
./prereqchecks.sh

if [ "$INSTALL_OUD" = "true" ] || [ "$INSTALL_OUD" = "TRUE" ]
then
     ./provision_oud.sh
fi

if [ "$INSTALL_OUDSM" = "true" ] || [ "$INSTALL_OUDSM" = "TRUE" ]
then
     ./provision_oudsm.sh
fi
if [ "$INSTALL_OAM" = "true" ] || [ "$INSTALL_OAM" = "TRUE" ]  [ "$INSTALL_OIG" = "true" ] || [ "$INSTALL_OIG" = "TRUE" ]
then
     ./provision_operator.sh
fi
if [ "$INSTALL_OAM" = "true" ] || [ "$INSTALL_OAM" = "TRUE" ]  
then
     ./provision_oam.sh
fi
if [ "$INSTALL_OIG" = "true" ] || [ "$INSTALL_OIG" = "TRUE" ]
then
     ./provision_oig.sh
fi
exit
