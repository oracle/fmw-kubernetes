"""
Copyright (c) 2022, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
"""
import os
import copy
import sys
import tempfile

from array import array
from java.lang import Class
from java.lang import System
from java.lang import String
from java.lang import Long
from oracle.weblogic.deploy.util import PyWLSTException
import oracle.weblogic.deploy.deploy.DeployException as DeployException
from wlsdeploy.aliases.model_constants import ABSOLUTE_PLAN_PATH
from wlsdeploy.aliases.model_constants import ABSOLUTE_SOURCE_PATH
from wlsdeploy.aliases.model_constants import APP_DEPLOYMENTS
from wlsdeploy.aliases.model_constants import APPLICATION
from wlsdeploy.aliases.model_constants import PLAN_PATH
from wlsdeploy.aliases.model_constants import SOURCE_PATH
from wlsdeploy.aliases.model_constants import TARGET
from wlsdeploy.aliases.wlst_modes import WlstModes
from wlsdeploy.aliases.location_context import LocationContext
from wlsdeploy.exception import exception_helper
from wlsdeploy.exception.expection_types import ExceptionType
from wlsdeploy.logging.platform_logger import PlatformLogger
from wlsdeploy.tool.deploy import deployer_utils
from wlsdeploy.util import path_utils
from wlsdeploy.util import model_helper
from wlsdeploy.tool.deploy import log_helper
from wlsdeploy.tool.util.archive_helper import ArchiveHelper
from wlsdeploy.tool.util.attribute_setter import AttributeSetter
from wlsdeploy.tool.util.topology_helper import TopologyHelper
from wlsdeploy.tool.util.wlst_helper import WlstHelper
import wlsdeploy.util.dictionary_utils as dictionary_utils
from wlsdeploy.util.weblogic_helper import WebLogicHelper
from wlsdeploy.tool.deploy.deployer import Deployer
from wlsdeploy.util.cla_utils import CommandLineArgUtil
from wlsdeploy.util.exit_code import ExitCode

from soasuitedeploy.util.fmwwlsthelper import FmwWlstHelper
from soasuitedeploy.util.soacla_util import SOACommandLineArgUtil
from wlsdeploy.aliases.model_constants import SOURCE_PATH
from soasuitedeploy.util.soa_constants import SOA_COMPOSITES
from soasuitedeploy.util.soa_constants import PARTITION
from soasuitedeploy.util.soa_constants import FORCEDEFAULT
from soasuitedeploy.util.soa_constants import MODE

_logger = PlatformLogger('soasuitedeploy.util')
__program_name = 'deployComps'

class SOADeployer(Deployer):

    _class_name = "SOADeployer"


    def __init__(self, model, model_context, aliases, soa_context, wlst_mode=WlstModes.OFFLINE):

        Deployer.__init__(self, model, model_context, aliases, wlst_mode)
        self.sessionName = None
        self.sessionMBean = None
        self.alsbConfigMBean = None
        self.soa_context = soa_context
        self.fmwWlstHelper = FmwWlstHelper(ExceptionType.DEPLOY)

    def __deployApp(self, app):
        _method_name = '__deployApp' 

        partition = 'default'
        forceDefault = False
        mode = ''
        value = self.model._soadeployments[SOA_COMPOSITES][app][SOURCE_PATH]

        if self.model._soadeployments[SOA_COMPOSITES][app][PARTITION] is not None:
            partition = self.model._soadeployments[SOA_COMPOSITES][app][PARTITION]

        if self.model._soadeployments[SOA_COMPOSITES][app][FORCEDEFAULT] is not None:
            forceDefault = self.model._soadeployments[SOA_COMPOSITES][app][FORCEDEFAULT]

        if self.model._soadeployments[SOA_COMPOSITES][app][MODE] is not None:
            mode = self.model._soadeployments[SOA_COMPOSITES][app][MODE]     

        admin_user = self.model_context.get_admin_user()
        admin_pwd = self.model_context.get_admin_password()

        soa_url = self.soa_context.get_soa_url()
        if soa_url is None:
            ex = exception_helper.create_cla_exception(ExitCode.HELP,
                                                           'WLSDPLY-20005', __program_name, SOACommandLineArgUtil.SOAURL_SWITCH)
            _logger.throwing(ex, class_name=self._class_name, method_name=_method_name)
            raise ex

        if self.archive_helper.contains_file(value):
            print("Extracting file: " + value)
            extractLocation = self.model_context.get_domain_home()
            if self.model_context.get_domain_home() == None:
                extractLocation = path_utils.fixup_path(tempfile.gettempdir())
            self.archive_helper.extract_file(value, extractLocation)
            fullpath = os.path.join(extractLocation, os.path.basename(value))
            print("Importing SOA Composite : " + fullpath)
            self.fmwWlstHelper.deployComposite(soa_url, fullpath, True, user=admin_user, password=admin_pwd, partition=partition, forceDefault=forceDefault )
        else:
            print( value + " not in archive" )
        return 0        

    def deploy_online(self):
        _method_name = 'deploy_online'
        
        try:
            for app in self.model._soadeployments[SOA_COMPOSITES]:
                self.__deployApp(app)
        except DeployException, de:
            raise de
        exit_code = ExitCode.OK

        return exit_code    
