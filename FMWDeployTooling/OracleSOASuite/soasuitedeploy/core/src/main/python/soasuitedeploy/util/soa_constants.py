"""
Copyright (c) 2022, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
"""

from wlsdeploy.aliases.model_constants import KNOWN_TOPLEVEL_MODEL_SECTIONS
from wlsdeploy.aliases.model_constants import DOMAIN_INFO
from wlsdeploy.aliases.model_constants import TOPOLOGY
from wlsdeploy.aliases.model_constants import RESOURCES
from wlsdeploy.aliases.model_constants import APP_DEPLOYMENTS
from wlsdeploy.aliases.model_constants import KUBERNETES

SOA_DEPLOYMENTS = 'soaDeployments'
SOA_COMPOSITES = 'SOAComposites'
OSB_APPLICATIONS = 'OSBApplications'

PARTITION = 'partition'
FORCEDEFAULT = 'forceDefault'
MODE = 'mode'

KNOWN_TOPLEVEL_MODEL_SECTIONS = [
    DOMAIN_INFO,
    TOPOLOGY,
    RESOURCES,
    APP_DEPLOYMENTS,
    KUBERNETES,
	SOA_DEPLOYMENTS
]
