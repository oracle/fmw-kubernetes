"""
Copyright (c) 2022, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
Utility CLS methods shared by multiple tools.
"""
import os

from java.io import File
from java.io import IOException
from java.lang import IllegalArgumentException
from java.lang import String
from oracle.weblogic.deploy.util import FileUtils
from oracle.weblogic.deploy.util import TranslateException
from oracle.weblogic.deploy.util import VariableException
from oracle.weblogic.deploy.validate import ValidateException

import oracle.weblogic.deploy.util.PyOrderedDict as OrderedDict
from wlsdeploy.aliases.wlst_modes import WlstModes
from wlsdeploy.exception import exception_helper
from wlsdeploy.logging.platform_logger import PlatformLogger
from wlsdeploy.tool.util import filter_helper
from wlsdeploy.tool.util.archive_helper import ArchiveHelper
from wlsdeploy.tool.validate.validator import Validator
from wlsdeploy.util import cla_utils
from wlsdeploy.util import getcreds
from wlsdeploy.util import model_helper
from wlsdeploy.util import model_translator
from wlsdeploy.util import path_utils

from wlsdeploy.util import tool_exit
from wlsdeploy.util import variables
from wlsdeploy.util.cla_utils import CommandLineArgUtil
from wlsdeploy.util.model_translator import FileToPython


__logger = PlatformLogger('wlsdeploy.util')
_class_name = 'fmw_helper'

_store_environment_variable = '__WLSDEPLOY_STORE_MODEL__'

__tmp_model_dir = None



def load_model(program_name, model_context, aliases, filter_type, wlst_mode):
    """
    Load the model based on the arguments in the model context.
    Apply the variable substitution, if specified, and validate the model.
    Apply any model filters of the specified type that are configured, and re-validate if necessary
    The tool will exit if exceptions are encountered.
    :param program_name: the program name, for logging
    :param model_context: the model context
    :param aliases: the alias configuration
    :param filter_type: the type of any filters to be applied
    :param wlst_mode: offline or online
    :return: the resulting model dictionary
    """
    _method_name = 'load_model'

    variable_map = {}
    try:
        if model_context.get_variable_file():
            # callers of this method allow multiple variable files
            variable_map = variables.load_variables(model_context.get_variable_file(), allow_multiple_files=True)
    except VariableException, ex:
        __logger.severe('WLSDPLY-20004', program_name, ex.getLocalizedMessage(), error=ex,
                        class_name=_class_name, method_name=_method_name)
        clean_up_temp_files()
        tool_exit.end(model_context, CommandLineArgUtil.PROG_ERROR_EXIT_CODE)

    model_file_value = model_context.get_model_file()
    try:
        model_dictionary = merge_model_files(model_file_value, variable_map)
    except TranslateException, te:
        __logger.severe('WLSDPLY-09014', program_name, model_file_value, te.getLocalizedMessage(), error=te,
                        class_name=_class_name, method_name=_method_name)
        clean_up_temp_files()
        tool_exit.end(model_context, CommandLineArgUtil.PROG_ERROR_EXIT_CODE)

    try:
        variables.substitute(model_dictionary, variable_map, model_context)
    except VariableException, ex:
        __logger.severe('WLSDPLY-20004', program_name, ex.getLocalizedMessage(), error=ex,
                        class_name=_class_name, method_name=_method_name)
        clean_up_temp_files()
        tool_exit.end(model_context, CommandLineArgUtil.PROG_ERROR_EXIT_CODE)

    filter_helper.apply_filters(model_dictionary, filter_type, model_context)

    persist_model(model_context, model_dictionary)

    return model_dictionary

def clean_up_temp_files():
    """
    If a temporary directory was created to extract the model from the archive, delete the directory and its contents.
    """
    global __tmp_model_dir

    if __tmp_model_dir is not None:
        FileUtils.deleteDirectory(__tmp_model_dir)
        __tmp_model_dir = None


def merge_model_files(model_file_value, variable_map=None):
    """
    Merge the model files specified by the model file value.
    It may be a single file, or a comma-separated list of files.
    :param variable_map: variables to be used for name resolution, or None
    :param model_file_value: the value specified as a command argument
    :return: the merge model dictionary
    """
    merged_model = OrderedDict()
    model_files = cla_utils.get_model_files(model_file_value)

    for model_file in model_files:
        model = FileToPython(model_file, True).parse()
        merge_model_dictionaries(merged_model, model, variable_map)

    return merged_model


def merge_model_dictionaries(dictionary, new_dictionary, variable_map):
    """
    Merge the values from the new dictionary to the existing one.
    Use variables to resolve keys.
    :param dictionary: the existing dictionary
    :param new_dictionary: the new dictionary to be merged
    :param variable_map: variables to be used for name resolution, or None
    """
    for new_key in new_dictionary:
        new_value = new_dictionary[new_key]
        dictionary_key, replace_key = _find_dictionary_merge_key(dictionary, new_key, variable_map)

        # the key is not in the original dictionary, just add it
        if dictionary_key is None:
            dictionary[new_key] = new_value

        # the new key should replace the existing one - delete the existing key and add the new one
        elif replace_key:
            del dictionary[dictionary_key]
            if not model_helper.is_delete_name(new_key):
                dictionary[new_key] = new_value

        # the key is in both dictionaries - merge if the values are dictionaries, otherwise replace the value
        else:
            value = dictionary[dictionary_key]
            if isinstance(value, dict) and isinstance(new_value, dict):
                merge_model_dictionaries(value, new_value, variable_map)
            else:
                dictionary[new_key] = new_value


def _find_dictionary_merge_key(dictionary, new_key, variable_map):
    """
    Find the key corresponding to new_key in the specified dictionary.
    Determine if the new_key should completely replace the value in the dictionary.
    If no direct match is found, and a variable map is specified, perform check with variable substitution.
    If keys have the same name, but one has delete notation (!server), that is a match, and replace is true.
    :param dictionary: the dictionary to be searched
    :param new_key: the key being checked
    :param variable_map: variables to be used for name resolution, or None
    :return: tuple - the corresponding key from the dictionary, True if dictionary key should be replaced
    """
    if new_key in dictionary:
        return new_key, False

    new_is_delete = model_helper.is_delete_name(new_key)
    match_new_key = _get_merge_match_key(new_key, variable_map)

    for dictionary_key in dictionary.keys():
        dictionary_is_delete = model_helper.is_delete_name(dictionary_key)
        match_dictionary_key = _get_merge_match_key(dictionary_key, variable_map)
        if match_dictionary_key == match_new_key:
            replace_key = new_is_delete != dictionary_is_delete
            return dictionary_key, replace_key

    return None, False


def _get_merge_match_key(key, variable_map):
    """
    Get the key name to use for matching in model merge.
    This includes resolving any variables, and removing delete notation if present.
    :param key: the key to be examined
    :param variable_map: variable map to use for substitutions
    :return: the key to use for matching
    """

    match_key = variables.substitute_key(key, variable_map)

    if model_helper.is_delete_name(match_key):
        match_key = model_helper.get_delete_item_name(match_key)
    return match_key


def persist_model(model_context, model_dictionary):
    """
    If environment variable __WLSDEPLOY_STORE_MODEL__ is set, save the specified model.
    If the variable's value starts with a slash, save to that file, otherwise use a default location.
    :param model_context: the model context
    :param model_dictionary: the model to be saved
    """
    _method_name = 'persist_model'

    if check_persist_model():
        store_value = os.environ.get(_store_environment_variable)

        if os.path.isabs(store_value):
            file_path = store_value
        elif model_context.get_domain_home() is not None:
            file_path = model_context.get_domain_home() + os.sep + 'wlsdeploy' + os.sep + 'domain_model.json'
        else:
            file_dir = FileUtils.createTempDirectory('wlsdeploy')
            file_path = File(file_dir, 'domain_model.json').getAbsolutePath()

        __logger.info('WLSDPLY-01650', file_path, class_name=_class_name, method_name=_method_name)

        persist_dir = path_utils.get_parent_directory(file_path)
        if not os.path.exists(persist_dir):
            os.makedirs(persist_dir)

        model_file = FileUtils.getCanonicalFile(File(file_path))
        model_translator.PythonToFile(model_dictionary).write_to_file(model_file.getAbsolutePath())


def check_persist_model():
    """
    Determine if the model should be persisted, based on the environment variable __WLSDEPLOY_STORE_MODEL__
    :return: True if the model should be persisted
    """
    return os.environ.has_key(_store_environment_variable)
