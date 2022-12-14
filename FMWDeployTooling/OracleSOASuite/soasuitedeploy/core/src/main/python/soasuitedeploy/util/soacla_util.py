"""
Copyright (c) 2022, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
Module that handles SOA command-line argument parsing and common validation.
"""

import os
import java.net.URI as JURI
import java.net.URISyntaxException as JURISyntaxException

from wlsdeploy.exception import exception_helper
from wlsdeploy.exception.exception_helper import create_cla_exception
from wlsdeploy.json.json_translator import JsonToPython
from wlsdeploy.logging.platform_logger import PlatformLogger
from wlsdeploy.util import path_utils
from wlsdeploy.util.cla_utils import CommandLineArgUtil

_logger = PlatformLogger('wlsdeploy.util')


class SOACommandLineArgUtil(object):
    _class_name = 'SOACommandLineArgUtil'

    SOAURL_SWITCH   = '-soa_url'

    def __init__(self, program_name, soa_args):
        self._program_name = program_name
        self._soa_args = list(soa_args)
        self._required_result = {}

    def process_args(self, args):

        method_name = 'process_args'
        
        args_len = len(args)

        if args_len > 2:
            soaurl_key = None
            soaurl_value = None
            idx = 1
            while idx < args_len:
                key = args[idx]
                if key in self._soa_args:
                    value, idx = self._get_arg_value(args, idx)
                    if self.is_soa_url_key(key):
                        self._validate_soa_url_arg(value)
                        self._add_arg(key, value)
                        soaurl_key = key
                        soaurl_value = value
                idx += 1

            if soaurl_key is not None:
                args.remove(soaurl_key)
            if soaurl_value is not None:
                args.remove(soaurl_value)

        combined_arg_map = self._required_result.copy()
        return combined_arg_map

    def is_soa_url_key(self, key):
        return self.SOAURL_SWITCH ==  key           

    def _get_arg_value(self, args, index):

        method_name = '_get_arg_value'
        key = args[index]

        index = index + 1
        if index >= len(args):
            ex = self._get_out_of_args_exception(key)
            _logger.throwing(ex, class_name=self._class_name, method_name=method_name)
            raise ex
        return args[index], index         

    def _validate_soa_url_arg(self, value):
        method_name = '_validate_soa_url_arg'

        if value is None or len(value) == 0:
            ex = exception_helper.create_cla_exception(CommandLineArgUtil.ARG_VALIDATION_ERROR_EXIT_CODE, 'WLSDPLY-01611')
            _logger.throwing(ex, class_name=self._class_name, method_name=method_name)
            raise ex

        url_separator_index = value.find('://')
        if not url_separator_index > 0:
            ex = exception_helper.create_cla_exception(CommandLineArgUtil.ARG_VALIDATION_ERROR_EXIT_CODE, 'WLSDPLY-01612', value)
            _logger.throwing(ex, class_name=self._class_name, method_name=method_name)
            raise ex

        try:
            JURI(value)
        except JURISyntaxException, use:
            ex = exception_helper.create_cla_exception(CommandLineArgUtil.ARG_VALIDATION_ERROR_EXIT_CODE,
                                                       'WLSDPLY-01613', value, use.getLocalizedMessage(), error=use)
            _logger.throwing(ex, class_name=self._class_name, method_name=method_name)
            raise ex                   

    def _add_arg(self, key, value, is_file_path=False):
        method_name = '_add_arg'

        fixed_value = value
        if is_file_path:
            fixed_value = value.replace('\\', '/')

        if key in self._soa_args:
            self._required_result[key] = fixed_value
        else:
            ex = exception_helper.create_cla_exception(CommandLineArgUtil.USAGE_ERROR_EXIT_CODE,
                                                       'WLSDPLY-01632', key, self._program_name)
            _logger.throwing(ex, class_name=self._class_name, method_name=method_name)
            raise ex    

    def _get_out_of_args_exception(self, key):
        ex = exception_helper.create_cla_exception(CommandLineArgUtil.USAGE_ERROR_EXIT_CODE, 'WLSDPLY-01638', key, self._program_name)
        return ex                    