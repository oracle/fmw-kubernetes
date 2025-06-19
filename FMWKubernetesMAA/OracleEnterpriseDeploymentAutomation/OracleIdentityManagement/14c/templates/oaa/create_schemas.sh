#!/bin/bash
# Copyright (c) 2025, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of Creating an OAA Schemas
#
export SCRIPT_PATH=/tmp/dbfiles

chmod +x /tmp/dbfiles/*.sh
cd /tmp/dbfiles
/tmp/dbfiles/createOAASchema.sh -f /tmp/dbfiles/installOAA.properties
