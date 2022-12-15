"""
Copyright (c) 2022, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
This module serves as a wrapper for the model dictionary.
It has convenience methods for accessing top-level fields in the model.
"""

import os
import pprint

import oracle.weblogic.deploy.util.PyOrderedDict as OrderedDict
from wlsdeploy.aliases.model_constants import KUBERNETES
from wlsdeploy.logging.platform_logger import PlatformLogger
from wlsdeploy.util.weblogic_helper import WebLogicHelper
from wlsdeploy.util.model import Model

from soa_constants import KNOWN_TOPLEVEL_MODEL_SECTIONS

class FMWModel(Model):
	
	_class_name = 'FMWModel'

	def __init__(self, model_dictionary=None, wls_version=None):
		Model.__init__(self, model_dictionary, wls_version)
		self._soadeployments = OrderedDict()

		if model_dictionary is not None:
			if 'soaDeployments' in model_dictionary:
				self._soadeployments = model_dictionary['soaDeployments']

	def get_model_top_level_keys():
		return list(KNOWN_TOPLEVEL_MODEL_SECTIONS)

	def get_model_soadeployments_key():
		return 'soaDeployments'
