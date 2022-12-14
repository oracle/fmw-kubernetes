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

from soasuitedeploy.util.fmwwlsthelper import FmwWlstHelper
from wlsdeploy.aliases.model_constants import SOURCE_PATH
from soasuitedeploy.util.soa_constants import OSB_APPLICATIONS

class OSBDeployer(Deployer):

    _class_name = "OSBDeployer"

    _session_mbean = "com.bea.wli.sb.management.configuration.SessionManagementMBean"
    _alsb_config_mbean = "com.bea.wli.sb.management.configuration.ALSBConfigurationMBean"
    _session_service_name = "SessionManagement"
    _passphrase = "osb_configs"


    def __init__(self, model, model_context, aliases, wlst_mode=WlstModes.OFFLINE):

        Deployer.__init__(self, model, model_context, aliases, wlst_mode)
        self.sessionName = None
        self.sessionMBean = None
        self.alsbConfigMBean = None
        self.fmwWlstHelper = FmwWlstHelper(ExceptionType.DEPLOY)

    def __initALSBMBeanSession(self):
      
        self.sessionName = self.__getSessionName()
        self.sessionMBean = self.__createMBeanSession(self.sessionName)
        self.alsbConfigMBean = self.__getALSBConfigMBean(self.sessionName)

    def __uploadOSBApp(self, app):
        _method_name = '__uploadOSBApp' 

        value = self.model._soadeployments[OSB_APPLICATIONS][app][SOURCE_PATH]

        if self.archive_helper.contains_file(value):
            print("Extracting file: " + value)
            extractLocation = self.model_context.get_domain_home()
            if self.model_context.get_domain_home() == None:
                extractLocation = path_utils.fixup_path(tempfile.gettempdir())
            self.archive_helper.extract_file(value, extractLocation)
            fullpath = os.path.join(extractLocation, os.path.basename(value))
            print("Uploading OSB App : " + fullpath)
            thebytes = self.__readAppFile(fullpath)
            self.alsbConfigMBean.uploadJarFile(thebytes)
        else:
            print( value + " not in archive" )
        return 0

    def __readAppFile(self, fileName):
        try:
            file = open(fileName, "rb")
            thebytes = file.read()
            file.close()
            return thebytes
        except FileNotFoundError:
            raise fileName + " not found."

    def __getSessionName(self):
        sessionName = String('OSBDeployer' + Long(System.currentTimeMillis()).toString())
        return sessionName


    def __createMBeanSession(self, sessionName):
        mbean = self.fmwWlstHelper.findService( "SessionManagement", self._session_mbean )
        mbean.createSession(sessionName)
        return mbean

    def __getALSBConfigMBean(self, sessionName):
        mbean = self.fmwWlstHelper.findService( String("ALSBConfiguration.").concat(sessionName), "com.bea.wli.sb.management.configuration.ALSBConfigurationMBean")
        return mbean

    def __discardUploadSession(self):
        if self.sessionMBean:
            self.sessionMBean.discardSession(self.sessionName)

    def __deployApp(self, app):

        self.__uploadOSBApp(app)
        alsbJarInfo = self.alsbConfigMBean.getImportJarInfo()
        alsbImportPlan = alsbJarInfo.getDefaultImportPlan()
        alsbImportPlan.setPassphrase("osb_configs")
        alsbImportPlan.setPreserveExistingEnvValues(True)
        importResult = self.alsbConfigMBean.importUploaded(alsbImportPlan)
        
        
        if importResult.getImported().size() > 0:
            for ref in importResult.getImported():
                print("Imported " + ref.toString())

    def deploy_online(self):
        _method_name = 'deploy_online'
        
        try:
            self.fmwWlstHelper.domainInit()
            for app in self.model._soadeployments[OSB_APPLICATIONS]:
                self.__initALSBMBeanSession()
                self.__deployApp(app)
                self.sessionMBean.activateSession(self.sessionName, "Imported OSB App : %s" % app)
        except DeployException, de:
            self.__discardUploadSession()
            raise de
        exit_code = 0

        return exit_code    
