# Copyright (c) 2020, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

connect('@USERNAME@', '@PASSWORD@', 't3://@DOMAIN_UID@-adminserver:7001')
domainRuntime()
setMultiDataCentreClusterName(clusterName='@CLUSTER_ID@')
exit()
