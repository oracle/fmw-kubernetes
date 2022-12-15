"""
Copyright (c) 2022, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
"""
from wlsdeploy.logging import platform_logger
from wlsdeploy.util.cla_utils import CommandLineArgUtil
from soasuitedeploy.util.soacla_util import SOACommandLineArgUtil

class SOAContext(object):
    
    _class_name = "SOAContext"

    def __init__(self, program_name, arg_map):

        self._program_name = program_name
        self._logger = platform_logger.PlatformLogger('wlsdeploy.util')

        self._soa_url = None

        self.__copy_from_args(arg_map)

    def __copy_from_args(self, arg_map):

        if SOACommandLineArgUtil.SOAURL_SWITCH in arg_map:
            self._soa_url = arg_map[SOACommandLineArgUtil.SOAURL_SWITCH]

    def get_soa_url(self):
        return self._soa_url