# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which can be used to create local backups and transfer and restore them to a DR system.
# 
#
# Usage: oaa_dr.sh
#

COPIES=3
EXCLUDE_LIST="--exclude=\".snapshot\" --exclude=\"backups\" --exclude=\"dr_scripts\" --exclude=\"backup_running\" --exclude=\"k8sconfig\" --exclude=\"ca.crt\""


create_oci_snapshot()
{
    PRIMARY_BASE=$1
    BACKUP_DIR=$2
    echo -n "Creating Snapshot : $BACKUP_DIR - "
    mkdir $PRIMARY_BASE/.snapshot/$BACKUP_DIR
    if [ $? -gt 0 ]
    then
       echo Failed.
       exit 1
    else
       echo "Success"
    fi
    copy_to_remote  $PRIMARY_BASE/.snapshot/$BACKUP_DIR $BACKUP_DIR 
}

create_backup()
{
    PRIMARY_BASE=$1
    BACKUP_DIR=$2
    echo "Creating Backup of $PRIMARY_BASE into $PRIMARY_BASE/backups/$BACKUP_DIR - "
    mkdir -p $PRIMARY_BASE/backups/$BACKUP_DIR
    CMD="rsync -avz $EXCLUDE_LIST $PRIMARY_BASE/ $PRIMARY_BASE/backups/$BACKUP_DIR"
    eval $CMD
    if [ $? -gt 0 ]
    then
       echo Failed.
       exit 1
    else
       echo "Success"
    fi
}


restore_backup()
{
    PRIMARY_BASE=$1
    BACKUP_DIR=$2
    echo "Restoring Backup :$PRIMARY_BASE/backups/$BACKUP_DIR to $PRIMARY_BASE - "
    CMD="rsync -avz $EXCLUDE_LIST $PRIMARY_BASE/backups/$BACKUP_DIR/ $PRIMARY_BASE"
    eval $CMD
    if [ $? -gt 0 ]
    then
       echo Failed.
       exit 1
    else
       echo "Success"
    fi
}

update_db_connection()
{
    PRIMARY_BASE=$1
    echo "Updating Database Connections"
    cd $PRIMARY_BASE
    db_files=$(grep -rl "$OAA_REMOTE_SCAN" . | grep -v backup)
    if [ "$db_files" = "" ]
    then
       echo "No database connections found to change.  Check the LOCAL and REMOTE SCAN addresses are set correctly in the config map dr-cm in the DR namespace."
    fi

    for file in $db_files
    do 
       echo "Changing scan address from $OAA_REMOTE_SCAN to $OAA_LOCAL_SCAN in file $file"
       sed -i "s/$OAA_REMOTE_SCAN/$OAA_LOCAL_SCAN/g" $file
       if [ ! "$OAA_REMOTE_SERVICE" = "$OAA_LOCAL_SERVICE" ]
       then
           echo "Changing service from $OAA_REMOTE_SERVICE to $OAA_LOCAL_SERVICE in file $file"
           sed -i "s/$OAA_REMOTE_SERVICE/$OAA_LOCAL_SERVICE/g" $file
       fi
    done

    if [ $? -gt 0 ]
    then
       echo Failed.
       exit 1
    else
       echo "Success"
    fi
}

update_property_file()
{
    PRIMARY_BASE=$1
    file=$PRIMARY_BASE/installOAA.properties
    echo "Updating OAA Property File"
    cd $PRIMARY_BASE
    echo "Unset Create DB Schemas in file $file"
    sed -i "s/database.createschema=true/database.createschema=false/g" $file

    if [ $? -gt 0 ]
    then
       echo Failed.
       exit 1
    else
       echo "Success"
    fi
}

update_k8_connection()
{
    echo "Updating Kubernetes Connections"
    cd $PRIMARY_BASE
    k8_files="$PRIMARY_BASE/data/conf/data-ingestion-config.yaml $VAULT_PRIMARY_BASE/data/conf/env.properties "
    if [ "$k8_files" = "" ]
    then
       echo "No Kubernetes connections found to change.  Check the LOCAL and REMOTE K8 addresses are set correctly in the config map dr-cm in the DR namespace."
    fi

    for file in $k8_files
    do 
       echo "Changing Kubernetes Cluster address from $OAA_REMOTE_K8 to $OAA_LOCAL_K8 in file $file"
       sed -i "s/$OAA_REMOTE_K8/$OAA_LOCAL_K8/g" $file
    done

    if [ $? -gt 0 ]
    then
       echo Failed.
       exit 1
    else
       echo "Success"
    fi
}
check_backup_running()
{
    PRIMARY_BASE=$1
    DR_BASE=$2
    if [ -e $PRIMARY_BASE/backup_running ]
    then
      echo "Previous Backup Still running, exiting."
      exit 1
    else
      if [ "$DR_TYPE" = "PRIMARY" ]
      then
         touch $PRIMARY_BASE/backup_running
         touch $DR_BASE/backup_running
      fi
    fi
}

copy_to_remote()
{
   PRIMARY_BASE=$1
   DR_BASE=$2
   BACKUP_DIR=$3

    echo "Remote Copy of  Backup :$PRIMARY_BASE/backups/$BACKUP_DIR"
    
    mkdir -p $DR_BASE/backups/$BACKUP_DIR
    CMD="rsync -avz $EXCLUDE_LIST $PRIMARY_BASE/backups/$BACKUP_DIR/ $DR_BASE/backups/$BACKUP_DIR"
    echo CMD:$CMD
    eval $CMD
    if [ $? -gt 0 ]
    then
       echo Failed.
       exit 1
    else
       echo "Success"
    fi

}
check_restore_running()
{
    PRIMARY_BASE=$1
    if [ -e $PRIMARY_BASE/restore_running ]
    then
      echo "Previous restore Still running, exiting."
      exit 1
    else
      touch $PRIMARY_BASE/restore_running
    fi
}

remove_old_backups()
{
    BACKUP_DIR=$1
    NO_BACKUPS=$(ls -lstd $BACKUP_DIR/20* | wc -l )
    TO_MANY=$((NO_BACKUPS-COPIES))
    if [ $TO_MANY -gt 0 ] 
    then
      BACKUPS_TO_DELETE=$( ls -lstd $BACKUP_DIR/20* | awk '{print $10}' | head -$TO_MANY)
      for file in $BACKUPS_TO_DELETE
      do
         echo "Deleting Backup : $file"
         rm -rf $file
      done
    fi
}


ST=$(date +%s)

CONFIG_PRIMARY_BASE=/u01/primary_oaaconfigpv
CONFIG_DR_BASE=/u01/dr_oaaconfigpv
VAULT_PRIMARY_BASE=/u01/primary_oaavaultpv
VAULT_DR_BASE=/u01/dr_oaavaultpv
CRED_PRIMARY_BASE=/u01/primary_oaacredpv
CRED_DR_BASE=/u01/dr_oaacredpv
LOG_PRIMARY_BASE=/u01/primary_oaalogpv
LOG_DR_BASE=/u01/dr_oaalogpv

check_backup_running $CONFIG_PRIMARY_BASE $CONFIG_DR_BASE

if [ "$DR_TYPE" = "PRIMARY" ] 
then
    BACKUP=$(date +%F_%H-%M-%S)

    if [ "$ENV_TYPE" = "OCI" ]
    then
       create_oci_snapshot $CONFIG_PRIMARY_BASE $BACKUP
       remove_old_backups $CONFIG_PRIMARY_BASE/.snapshot
       create_oci_snapshot $VAULT_PRIMARY_BASE $BACKUP
       remove_old_backups $VAULT_PRIMARY_BASE/.snapshot
       create_oci_snapshot $CRED_PRIMARY_BASE $BACKUP
       remove_old_backups $CRED_PRIMARY_BASE/.snapshot
       create_oci_snapshot $LOG_PRIMARY_BASE $BACKUP
       remove_old_backups $LOG_PRIMARY_BASE/.snapshot
    else
       create_backup $CONFIG_PRIMARY_BASE $BACKUP
       copy_to_remote  $CONFIG_PRIMARY_BASE $CONFIG_DR_BASE $BACKUP
       remove_old_backups $CONFIG_PRIMARY_BASE/backups
       create_backup $VAULT_PRIMARY_BASE $BACKUP
       copy_to_remote  $VAULT_PRIMARY_BASE $VAULT_DR_BASE $BACKUP
       remove_old_backups $VAULT_PRIMARY_BASE/backups
       create_backup $CRED_PRIMARY_BASE $BACKUP
       copy_to_remote  $CRED_PRIMARY_BASE $CRED_DR_BASE $BACKUP
       remove_old_backups $CRED_PRIMARY_BASE/backups
       create_backup $LOG_PRIMARY_BASE $BACKUP
       copy_to_remote  $LOG_PRIMARY_BASE $LOG_DR_BASE $BACKUP
       remove_old_backups $LOG_PRIMARY_BASE/backups
    fi

    echo "Backup Complete"
    rm $CONFIG_PRIMARY_BASE/backup_running
    rm $CONFIG_DR_BASE/backup_running

elif [ "$DR_TYPE" = "STANDBY" ] 
then
    BACKUP=$(ls -lstr $CONFIG_PRIMARY_BASE/backups | tail -1 | awk '{ print $10 }')

    check_restore_running  $CONFIG_PRIMARY_BASE
    check_backup_running  $CONFIG_PRIMARY_BASE
    restore_backup $CONFIG_PRIMARY_BASE $BACKUP
    update_db_connection $CONFIG_PRIMARY_BASE
    update_property_file $CONFIG_PRIMARY_BASE
    remove_old_backups $CONFIG_PRIMARY_BASE/backups

    restore_backup $VAULT_PRIMARY_BASE $BACKUP
    remove_old_backups $VAULT_PRIMARY_BASE/backups
    echo "Restore Complete"

    restore_backup $CRED_PRIMARY_BASE $BACKUP
    remove_old_backups $CRED_PRIMARY_BASE/backups
    echo "Restore Complete"

    restore_backup $LOG_PRIMARY_BASE $BACKUP
    remove_old_backups $LOG_PRIMARY_BASE/backups
    echo "Restore Complete"

    rm $CONFIG_PRIMARY_BASE/restore_running
fi


ET=$(date +%s)
time_taken=$((ET-ST))

if [ "$DR_TYPE" = "PRIMARY" ]
then
    eval "echo  Total Time taken to create Backup: $(date -ud "@$time_taken" +' %H hours %M minutes %S seconds')"
else
    eval "echo  Total Time taken to Restore Backup: $(date -ud "@$time_taken" +' %H hours %M minutes %S seconds')"
fi

exit
