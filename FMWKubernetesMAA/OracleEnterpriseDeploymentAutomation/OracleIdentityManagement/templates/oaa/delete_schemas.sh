#!/bin/bash
# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of Deleting OAA Schemas
#
sqlplus sys/<OAA_DB_SYS_PWD>@<OAA_DB_SCAN>:<OAA_DB_LISTENER>/<OAA_DB_SERVICE> as sysdba << EOF
alter session set "_oracle_script"=TRUE;
drop user <OAA_RCU_PREFIX>_oaa cascade;
delete from SCHEMA_VERSION_REGISTRY where comp_name='Oracle Advanced Authentication' and OWNER=UPPER('<OAA_RCU_PREFIX>_OAA');
commit;
set pages 0
set feedback off
spool /tmp/drop_directories.sql
select 'drop directory '||directory_name||';' from all_directories
where directory_name like 'EXPORT%'
/
spool off
@/tmp/drop_directories
exit

EOF
