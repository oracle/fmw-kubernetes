#!/bin/bash
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# Initialize
script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"
source ${scriptDir}/utils.sh
warDir=$scriptDir/../bin
mkdir -p $warDir
curl -L -o $warDir/wls-exporter.war https://github.com/oracle/weblogic-monitoring-exporter/releases/download/v2.0.0/wls-exporter.war 
mkdir -p $scriptDir/wls-exporter-deploy 
echo "created $scriptDir/wls-exporter-deploy dir"

function update_wls_exporter_war {
  servername=$1
  port=$2
  tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
  echo "created $tmp_dir"
  mkdir -p $tmp_dir/WEB-INF
  cp $scriptDir/../config/config.yml.template $tmp_dir/config.yml
  cp $scriptDir/../config/weblogic.xml $tmp_dir/WEB-INF/weblogic.xml
  cp $warDir/wls-exporter.war  $tmp_dir/wls-exporter.war

  sed -i -e "s:%PORT%:${port}:g" $tmp_dir/config.yml
  pushd $tmp_dir
  echo "in temp dir"
  zip wls-exporter.war WEB-INF/weblogic.xml
  zip wls-exporter.war config.yml

  cp wls-exporter.war ${scriptDir}/wls-exporter-deploy/wls-exporter-${servername}.war
  popd
} 

initialize

update_wls_exporter_war adminserver ${adminServerPort}
if [[ ${wlsMonitoringExporterTosoaCluster}  == "true" ]];
then
  update_wls_exporter_war soa ${soaManagedServerPort}
fi
if [[ ${wlsMonitoringExporterTooimCluster}  == "true" ]];
then
  update_wls_exporter_war oim ${oimManagedServerPort}
fi

