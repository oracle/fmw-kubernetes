"""
Copyright (c) 2022, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
"""
import exceptions
import os
import sys

from oracle.weblogic.deploy.deploy import DeployException

from wlsdeploy.exception import exception_helper
from wlsdeploy.exception.expection_types import ExceptionType
from wlsdeploy.tool.util import wlst_helper
from wlsdeploy.tool.util.wlst_helper import WlstHelper
from wlsdeploy.logging.platform_logger import PlatformLogger

wlst_functions = None

class FmwWlstHelper(WlstHelper):

    __class_name = 'FmwWlstHelper'
    __logger = PlatformLogger('wlsdeploy.wlst')


    def __init__(self, exception_type):

        self._extype = exception_type
        WlstHelper.__init__(self, exception_type);

    def domainInit(self):

        WlstHelper.domain_runtime(self)

    def _loadWlstFunc(self, funcName):
        fn = None
        
        if wlst_functions is not None and funcName in wlst_functions:
            fn = wlst_functions[funcName]

        if fn is None:
            raise exception_helper.create_exception(self._extype, 'WLSDPLY-00087', funcName)
        return fn

    def findService(self, service, mbean):

        _method_name = 'findService'
        try:
            result = self._loadWlstFunc('findService')(service, mbean)
        except self._loadWlstFunc('WLSTException'), e:
            self.__logger.throwing(class_name=self.__class_name, method_name=_method_name, error=pwe)
            raise pwe
        self.__logger.exiting(class_name=self.__class_name, method_name=_method_name, result=result)
        return result

    def deployComposite(self, url, location, overwrite, **kwargs ):

        _method_name = 'deployComposite'
        try:
            result = self._loadWlstFunc('sca_deployComposite')(url, location, overwrite, **kwargs)
        except self._loadWlstFunc('WLSTException'), e:
            self.__logger.throwing(class_name=self.__class_name, method_name=_method_name, error=pwe)
            raise pwe
        self.__logger.exiting(class_name=self.__class_name, method_name=_method_name, result=result)
        return result        


