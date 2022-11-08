#!/bin/bash
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of an Umbrella script that will perform a full end to end Identity Managment Provisioning
#
# Dependencies: ./prechecks.sh
#               ./responsefile/idm.rsp
#               ./provision_ingress.sh
#               ./provision_elk.sh
#               ./provision_prom.sh
#               ./provision_oud.sh
#               ./provision_oudsm.sh
#               ./provision_operator.sh
#               ./provision_oam.sh
#               ./provision_oig.sh
#               ./provision_oaa.sh
#               ./provision_oiri.sh
#
# Usage: provision.sh
#

. ./responsefile/idm.rsp

if [ ! "$1" = "-ignorePrereqs" ]
then
   ./prereqchecks.sh
fi


if [ $? -gt 0 ]
then
    echo "Pre-req checks Failed - Resolve issues before continuing or restart with -ignorePrereqs"
    exit 1
fi

echo ""
if [ "$INSTALL_ELK" = "true" ] 
then
     if [  -f $LOCAL_WORKDIR/elk_installed ]
     then
        echo "Elastic Search Already Installed."
     else 
        ./provision_elk.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/elk_installed ]
        then 
          echo "Provisioning Elastic Search Failed"
          exit 1
        fi
     fi
fi

echo ""
if [ "$INSTALL_PROM" = "true" ] 
then
     if [  -f $LOCAL_WORKDIR/prom_installed ]
     then
        echo "Prometheus Already Installed."
     else 
        ./provision_prom.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/prom_installed ]
        then 
          echo "Provisioning Prometheus"
          exit 1
        fi
     fi
fi

echo ""
if [ "$INSTALL_INGRESS" = "true" ] 
then
     if [  -f $LOCAL_WORKDIR/ingress_installed ]
     then
        echo "Ingress Already Installed."
     else 
        ./provision_ingress.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/ingress_installed ]
        then 
          echo "Provisioning ingress Failed"
          exit 1
        fi
     fi
fi

if [ "$INSTALL_OUD" = "true" ] 
then
     if [  -f $LOCAL_WORKDIR/oud_installed ]
     then
        echo "OUD Already Installed"
     else
        ./provision_oud.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/oud_installed ]
        then 
           echo "Provisioning OUD Failed"
           exit 1
        fi
     fi
fi

if [ "$INSTALL_OUDSM" = "true" ] 
then
     if [  -f $LOCAL_WORKDIR/oudsm_installed ]
     then
        echo "OUDSM Already Installed."
     else
        ./provision_oudsm.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/oudsm_installed ]
        then 
           echo "Provisioning OUDSM Failed"
           exit 1
        fi
     fi
fi

if [ "$INSTALL_OHS" = "true" ] 
then
     if [  -f $LOCAL_WORKDIR/ohs_installed ]
     then
        echo "OHS Already Installed."
     else
        ./provision_ohs.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/ohs_installed ]
        then 
           echo "Provisioning OHS Failed"
           exit 1
        fi
     fi
fi

if [ "$INSTALL_WLSOPER" = "true" ] 
then
     if [ -f $LOCAL_WORKDIR/operator_installed ]
     then 
         echo "WebLogic Operator Already Installed."
     else
        ./provision_operator.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/operator_installed ]
        then 
           echo "Provisioning WebLogic Operator Failed"
           exit 1
        fi
     fi
fi

if [ "$INSTALL_OAM" = "true" ] 
then
     if [ -f $LOCAL_WORKDIR/oam_installed ]
     then 
         echo "OAM Already Installed."
     else
        ./provision_oam.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/oam_installed ]
        then 
           echo "Provisioning OAM Failed"
           exit 1
        fi
     fi
fi
if [ "$INSTALL_OIG" = "true" ] 
then
     if [ -f $LOCAL_WORKDIR/oig_installed ]
     then
         echo "OIG Already Installed."
     else
        ./provision_oig.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/oig_installed ]
        then 
           echo "Provisioning OIG Failed"
           exit 1
        fi
     fi
fi

if [ "$INSTALL_OAA" = "true" ] 
then
     if [  -f $LOCAL_WORKDIR/oaa_installed ]
     then
        echo "OAA Already Installed."
     else
        ./provision_oaa.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/oaa_installed ]
        then 
           echo "Provisioning OAA Failed"
           exit 1
        fi
     fi
fi

if [ "$INSTALL_OIRI" = "true" ] 
then
     if [ -f $LOCAL_WORKDIR/oiri_installed ]
     then
        echo "OIRI Already Installed."
     else
        ./provision_oiri.sh
        if [ $? -gt 0 ] || [ ! -f $LOCAL_WORKDIR/oiri_installed ]
        then 
           echo "Provisioning OIRI Failed"
           exit 1
        fi
     fi
fi
exit
