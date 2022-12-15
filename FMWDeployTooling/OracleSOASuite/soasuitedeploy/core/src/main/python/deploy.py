"""
Copyright (c) 2022, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

The entry point for the deployer tool.
"""
import os
import sys

wls_python_path = os.environ.get('WLSDEPLOY_HOME') + os.sep + 'lib' + os.sep + 'python'
sys.path.insert(0, (os.path.realpath(os.environ.get('WLSDEPLOY_HOME') + os.sep + 'lib' + os.sep + 'python')))

from oracle.weblogic.deploy.deploy import DeployException
from oracle.weblogic.deploy.exception import BundleAwareException
from oracle.weblogic.deploy.util import CLAException
from oracle.weblogic.deploy.util import WebLogicDeployToolingVersion

sys.path.insert(0, os.path.dirname(os.path.realpath(sys.argv[0])))

# imports from local packages start here
from wlsdeploy.aliases.aliases import Aliases
from wlsdeploy.aliases.wlst_modes import WlstModes
from wlsdeploy.exception.expection_types import ExceptionType
from wlsdeploy.logging.platform_logger import PlatformLogger
from wlsdeploy.tool.deploy import deployer_utils
from wlsdeploy.tool.deploy import model_deployer
from wlsdeploy.tool.util import model_context_helper
from wlsdeploy.tool.util import wlst_helper
from wlsdeploy.tool.util.wlst_helper import WlstHelper
from wlsdeploy.util import cla_helper
from wlsdeploy.util import tool_exit
from wlsdeploy.util.cla_utils import CommandLineArgUtil
from wlsdeploy.util.model import Model
from wlsdeploy.util.weblogic_helper import WebLogicHelper
from wlsdeploy.util.exit_code import ExitCode

from wlsdeploy.util.model_context import ModelContext
from wlsdeploy.util.model_config import ModelConfiguration

from soasuitedeploy.util import fmwwlsthelper
from soasuitedeploy.util import fmw_helper
from soasuitedeploy.util.fmwmodel import FMWModel
from soasuitedeploy.util.soacla_util import SOACommandLineArgUtil
from soasuitedeploy.util.soacontext import SOAContext
from soasuitedeploy.deploy.osbdeployer import OSBDeployer
from soasuitedeploy.deploy.soadeployer import SOADeployer
from soasuitedeploy.util.soa_constants import OSB_APPLICATIONS
from soasuitedeploy.util.soa_constants import SOA_COMPOSITES

wlst_helper.wlst_functions = globals()
fmwwlsthelper.wlst_functions = globals()


_program_name = 'soasuitedeploy'
_class_name = 'deploy'
__logger = PlatformLogger('wlsdeploy.deploy')
__wls_helper = WebLogicHelper(__logger)
__wlst_helper = WlstHelper(ExceptionType.DEPLOY)
__wlst_mode = WlstModes.OFFLINE

__required_arguments = [
    CommandLineArgUtil.ORACLE_HOME_SWITCH,
    CommandLineArgUtil.ARCHIVE_FILE_SWITCH,
    CommandLineArgUtil.MODEL_FILE_SWITCH,
    CommandLineArgUtil.ADMIN_URL_SWITCH
]

__optional_arguments = [
    # Used by shell script to locate WLST
    CommandLineArgUtil.DOMAIN_HOME_SWITCH,
    CommandLineArgUtil.DOMAIN_TYPE_SWITCH,
    CommandLineArgUtil.PREVIOUS_MODEL_FILE_SWITCH,
    CommandLineArgUtil.VARIABLE_FILE_SWITCH,
    CommandLineArgUtil.ADMIN_USER_SWITCH,
    CommandLineArgUtil.ADMIN_PASS_SWITCH,
    CommandLineArgUtil.ADMIN_PASS_FILE_SWITCH,
    CommandLineArgUtil.ADMIN_PASS_ENV_SWITCH,
    CommandLineArgUtil.USE_ENCRYPTION_SWITCH,
    CommandLineArgUtil.PASSPHRASE_SWITCH,
    CommandLineArgUtil.PASSPHRASE_FILE_SWITCH,
    CommandLineArgUtil.PASSPHRASE_ENV_SWITCH,
    CommandLineArgUtil.OUTPUT_DIR_SWITCH,
    CommandLineArgUtil.DISCARD_CURRENT_EDIT_SWITCH,
    CommandLineArgUtil.CANCEL_CHANGES_IF_RESTART_REQ_SWITCH
]

__soa_arguments = [
    SOACommandLineArgUtil.SOAURL_SWITCH
]


def __process_args(args):
    """
    Process the command-line arguments and prompt the user for any missing information
    :param args: the command-line arguments list
    :raises CLAException: if an error occurs while validating and processing the command-line arguments
    """
    global __wlst_mode

    soacla_util = SOACommandLineArgUtil(_program_name, __soa_arguments)
    soa_args = soacla_util.process_args(args)
    soa_context = SOAContext(_program_name, soa_args)

    cla_util = CommandLineArgUtil(_program_name, __required_arguments, __optional_arguments)
    cla_util.set_allow_multiple_models(True)
    argument_map = cla_util.process_args(args)

    cla_helper.validate_optional_archive(_program_name, argument_map)
    cla_helper.validate_variable_file_exists(_program_name, argument_map)

    __wlst_mode = cla_helper.process_online_args(argument_map)
    cla_helper.process_encryption_args(argument_map)

    return model_context_helper.create_context(_program_name, argument_map), soa_context

def __deploy(model, model_context, aliases, soa_context):
    """
    The method that does the heavy lifting for deploy.
    :param model: the model
    :param model_context: the model context
    :param aliases: the aliases
    :raises DeployException: if an error occurs
    """
    
    _method_name = '__deploy'

    if __wlst_mode == WlstModes.ONLINE:
        ret_code = __deploy_online(model, model_context, aliases, soa_context)
    else:
        raise Exception('Offline mode not supported.')
    return ret_code


def __deploy_online(model, model_context, aliases, soa_context):
    """
    Online deployment orchestration
    :param model: the model
    :param model_context: the model context
    :param aliases: the aliases object
    :raises: DeployException: if an error occurs
    """
    
    _method_name = '__deploy_online'

    admin_url = model_context.get_admin_url()
    admin_user = model_context.get_admin_user()
    admin_pwd = model_context.get_admin_password()
    timeout = model_context.get_model_config().get_connect_timeout()
    skip_edit_session_check = model_context.is_discard_current_edit() or model_context.is_wait_for_edit_lock()
    __logger.info("WLSDPLY-09005", admin_url, timeout, method_name=_method_name, class_name=_class_name)

    __wlst_helper.connect(admin_user, admin_pwd, admin_url, timeout)

    __logger.info("WLSDPLY-09007", admin_url, method_name=_method_name, class_name=_class_name)

    try:
        if model._soadeployments[SOA_COMPOSITES] is not None:
            soaDeployer = SOADeployer(model, model_context, aliases, soa_context, __wlst_mode)
            exit_code = soaDeployer.deploy_online()
        if model._soadeployments[OSB_APPLICATIONS] is not None:
            osbDeployer = OSBDeployer(model, model_context, aliases, __wlst_mode)
            exit_code = osbDeployer.deploy_online()
    except DeployException, de:
        raise de

    try:
        __wlst_helper.disconnect()
    except BundleAwareException, ex:
        # All the changes are made and active so don't raise an error that causes the program
        # to indicate a failure...just log the error since the process is going to exit anyway.
        __logger.warning('WLSDPLY-09009', _program_name, ex.getLocalizedMessage(), error=ex,
                         class_name=_class_name, method_name=_method_name)
    return exit_code


def __close_domain_on_error():
    """
    An offline error recovery method.
    """
    _method_name = '__close_domain_on_error'
    try:
        __wlst_helper.close_domain()
    except BundleAwareException, ex:
        # This method is only used for cleanup after an error so don't mask
        # the original problem by throwing yet another exception...
        __logger.warning('WLSDPLY-09013', ex.getLocalizedMessage(), error=ex,
                         class_name=_class_name, method_name=_method_name)


def main(args):
    """
    The python entry point for deployer.

    :param args:
    :return:
    """
    _method_name = 'main'

    __logger.entering(args[0], class_name=_class_name, method_name=_method_name)
    for index, arg in enumerate(args):
        __logger.finer('sys.argv[{0}] = {1}', str(index), str(arg), class_name=_class_name, method_name=_method_name)

    __wlst_helper.silence()

    exit_code = ExitCode.OK

    try:
        model_context, soa_context = __process_args(args)
    except CLAException, ex:
        exit_code = ex.getExitCode()
        if exit_code != ExitCode.HELP:
            __logger.severe('WLSDPLY-20008', _program_name, ex.getLocalizedMessage(), error=ex,
                            class_name=_class_name, method_name=_method_name)
        cla_helper.clean_up_temp_files()

        # create a minimal model for summary logging
        model_context = model_context_helper.create_exit_context(_program_name)
        tool_exit.end(model_context, exit_code)

    aliases = Aliases(model_context, wlst_mode=__wlst_mode, exception_type=ExceptionType.DEPLOY)

    model_dictionary = fmw_helper.load_model(_program_name, model_context, aliases, "deploy", __wlst_mode)

    try:
        model = FMWModel(model_dictionary)
        exit_code = __deploy(model, model_context, aliases, soa_context)
    except DeployException, ex:
        __logger.severe('WLSDPLY-09015', _program_name, ex.getLocalizedMessage(), error=ex,
                        class_name=_class_name, method_name=_method_name)
        cla_helper.clean_up_temp_files()
        tool_exit.end(model_context, ExitCode.ERROR)

    cla_helper.clean_up_temp_files()

    tool_exit.end(model_context, exit_code)


if __name__ == '__main__' or __name__ == 'main':
    WebLogicDeployToolingVersion.logVersionInfo(_program_name)
    main(sys.argv)
