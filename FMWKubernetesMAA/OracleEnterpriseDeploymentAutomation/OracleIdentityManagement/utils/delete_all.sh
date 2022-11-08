#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete all IDM Componenets
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_all.sh
#
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $MYDIR/../common/functions.sh


if [ "$INSTALL_OAA" = "true" ] || [ "$INSTALL_OAA" = "TRUE" ]
then
     $MYDIR/delete_oaa.sh
     echo 
fi

if [ "$INSTALL_OIRI" = "true" ] || [ "$INSTALL_OIRI" = "TRUE" ]
then
     $MYDIR/delete_oiri.sh
     echo 
fi

if [ "$INSTALL_OIG" = "true" ] || [ "$INSTALL_OIG" = "TRUE" ]
then
     $MYDIR/delete_oig.sh
     echo 
fi


if [ "$INSTALL_OAM" = "true" ] || [ "$INSTALL_OAM" = "TRUE" ]  
then
     $MYDIR/delete_oam.sh
     echo 
fi

if [ "$INSTALL_OUDSM" = "true" ] || [ "$INSTALL_OUDSM" = "TRUE" ]
then
     $MYDIR/delete_oudsm.sh
     echo 
fi

if [ "$INSTALL_OUD" = "true" ] || [ "$INSTALL_OUD" = "TRUE" ]
then
     $MYDIR/delete_oud.sh
     echo 
fi

if [ "$INSTALL_OAM" = "true" ] || [ "$INSTALL_OAM" = "TRUE" ] || [ "$INSTALL_OIG" = "true" ] || [ "$INSTALL_OIG" = "TRUE" ]
then
     $MYDIR/delete_operator.sh
     echo 
fi


if [ "$INSTALL_OHS" = "true" ] 
then
     $MYDIR/delete_ohs.sh
     echo 
fi

if [ "$INSTALL_INGRESS" = "true" ] || [ "$INSTALL_INGRESS" = "TRUE" ]
then
     $MYDIR/delete_ingress.sh
     echo 
fi

if [ "$INSTALL_ELK" = "true" ] || [ "$INSTALL_ELK" = "TRUE" ]
then
     $MYDIR/delete_elk.sh
     echo 
fi

if [ "$INSTALL_PROM" = "true" ] || [ "$INSTALL_PROM" = "TRUE" ]
then
     $MYDIR/delete_prom.sh
     echo 
fi
