#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
#
# Licensed under the Universal Permissive License v 1.0 as shown at 
# https://oss.oracle.com/licenses/upl

curl -L -O https://github.com/oracle/weblogic-monitoring-exporter/releases/download/v1.1.0/wls-exporter.war 

echo "-------------------wls-exporter-ms start-------------------"
tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
mkdir -p $tmp_dir/WEB-INF
echo "created $tmp_dir"

cp config/config_ms.yml $tmp_dir/config.yml
cp config/weblogic.xml $tmp_dir/WEB-INF/weblogic.xml
echo  "Copying completed"

warDir=$PWD
pushd $tmp_dir

cp $warDir/wls-exporter.war $warDir/wls-exporter-ms.war
echo "in temp dir"
zip $warDir/wls-exporter-ms.war WEB-INF/weblogic.xml
zip $warDir/wls-exporter-ms.war config.yml
echo "wls-exporter-ms.war is ready"
echo "-------------------wls-exporter-ms end-------------------"

echo "-------------------wls-exporter-as start-------------------"
cp $warDir/config/config_as.yml $tmp_dir/config.yml
echo  "Copying completed"
cp $warDir/wls-exporter.war $warDir/wls-exporter-as.war
echo "in temp dir"
zip $warDir/wls-exporter-as.war WEB-INF/weblogic.xml
zip $warDir/wls-exporter-as.war config.yml
echo "wls-exporter-as.war is ready"
echo "-------------------wls-exporter-as end-------------------"
echo  "zip completed"
popd
rm -rf $tmp_dir
rm $warDir/wls-exporter.war
