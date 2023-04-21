# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a WLST script to remove OAM from the default Coherence Cluster
#
connect('<OAM_WEBLOGIC_USER>','<OAM_WEBLOGIC_PWD>','t3://<OAM_DOMAIN_NAME>-adminserver.<OAMNS>.svc.cluster.local:30012')
edit()
startEdit()



cd('/Clusters/oam_cluster')
cmo.setCoherenceClusterSystemResource(None)

cd('/CoherenceClusterSystemResources/defaultCoherenceCluster')
cmo.removeTarget(getMBean('/Clusters/oam_cluster'))

cd('/Clusters/policy_cluster')
cmo.setCoherenceClusterSystemResource(None)

cd('/CoherenceClusterSystemResources/defaultCoherenceCluster')
cmo.removeTarget(getMBean('/Clusters/policy_cluster'))
save()
activate(block="true")
exit()

