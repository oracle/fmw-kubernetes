#!/bin/bash
# Copyright (c) 2022, 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which will delete all IDM Componenets
#
# Dependencies: ../common/functions.sh
#               ../responsefile/idm.rsp
#
# Usage: delete_all.sh [-r responsefile -p passwordfile]
#
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while getopts 'r:p:' OPTION
do
  case "$OPTION" in
    r)
      RSPFILE=$SCRIPTDIR/../responsefile/$OPTARG
     ;;
    p)
      PWDFILE=$SCRIPTDIR/../responsefile/$OPTARG
     ;;
    ?)
     echo "script usage: $(basename $0) [-r responsefile -p passwordfile] " >&2
     exit 1
     ;;
   esac
done


RSPFILE=${RSPFILE=$SCRIPTDIR/../responsefile/idm.rsp}
PWDFILE=${PWDFILE=$SCRIPTDIR/../responsefile/.idmpwds}

if [ ! -e $RSPFILE ]
then
   echo "Responsefile: $RSPFILE does not exist."
   exit 1
fi

if [ ! -e $PWDFILE ]
then
   echo "Password File: $PWDFILE does not exist."
   exit 1
fi

. $RSPFILE
. $PWDFILE

if [ "$INSTALL_OAA" = "true" ] || [ "$INSTALL_OAA" = "TRUE" ]
then
     $SCRIPTDIR/delete_oaa.sh -r $(basename $RSPFILE) -p $(basename $PWDFILE)
     echo 
fi

if [ "$INSTALL_OIRI" = "true" ] || [ "$INSTALL_OIRI" = "TRUE" ]
then
     $SCRIPTDIR/delete_oiri.sh -r $(basename $RSPFILE) -p $(basename $PWDFILE)
     echo 
fi

if [ "$INSTALL_OIG" = "true" ] || [ "$INSTALL_OIG" = "TRUE" ]
then
     $SCRIPTDIR/delete_oig.sh -r $(basename $RSPFILE) -p $(basename $PWDFILE)
     echo 
fi


if [ "$INSTALL_OAM" = "true" ] || [ "$INSTALL_OAM" = "TRUE" ]  
then
     $SCRIPTDIR/delete_oam.sh -r $(basename $RSPFILE) -p $(basename $PWDFILE)
     echo 
fi

if [ "$INSTALL_OUDSM" = "true" ] || [ "$INSTALL_OUDSM" = "TRUE" ]
then
     $SCRIPTDIR/delete_oudsm.sh -r $(basename $RSPFILE) -p $(basename $PWDFILE)
     echo 
fi

if [ "$INSTALL_OUD" = "true" ] || [ "$INSTALL_OUD" = "TRUE" ]
then
     $SCRIPTDIR/delete_oud.sh -r $(basename $RSPFILE) -p $(basename $PWDFILE)
     echo 
fi

if [ "$INSTALL_OAM" = "true" ] || [ "$INSTALL_OAM" = "TRUE" ] || [ "$INSTALL_OIG" = "true" ] || [ "$INSTALL_OIG" = "TRUE" ]
then
     $SCRIPTDIR/delete_operator.sh -r $(basename $RSPFILE) 
     echo 
fi


if [ "$INSTALL_OHS" = "true" ] 
then
     $SCRIPTDIR/delete_ohs.sh -r $(basename $RSPFILE) 
     echo 
fi

if [ "$INSTALL_INGRESS" = "true" ] || [ "$INSTALL_INGRESS" = "TRUE" ]
then
     $SCRIPTDIR/delete_ingress.sh -r $(basename $RSPFILE) 
     echo 
fi

if [ "$INSTALL_ELK" = "true" ] || [ "$INSTALL_ELK" = "TRUE" ]
then
     $SCRIPTDIR/delete_elk.sh -r $(basename $RSPFILE) 
     echo 
fi

if [ "$INSTALL_PROM" = "true" ] || [ "$INSTALL_PROM" = "TRUE" ]
then
     $SCRIPTDIR/delete_prom.sh -r $(basename $RSPFILE) 
     echo 
fi
