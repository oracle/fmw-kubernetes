# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script which can be used to create local backups and transfer and restore them to a DR system.
# 
#
# Usage: oud_dr.sh
#

COPIES=3
EXCLUDE_LIST="--exclude=\".snapshot\" --exclude=\"backups\" --exclude=\"backup_running\" --exclude=\"dr_scripts\" "


create_oci_snapshot()
{
    BACKUP_DIR=$1
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
    BACKUP_DIR=$1
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
    copy_to_remote  $PRIMARY_BASE/backups/$BACKUP_DIR $BACKUP_DIR 
}


restore_backup()
{
    BACKUP_DIR=$1
    echo "Restoring Backup : $PRIMARY_BASE/backups/$BACKUP_DIR - "
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

check_backup_running()
{
    if [ -e $PRIMARY_BASE/backup_running ]
    then
      echo "Previous Backup Still running, exiting."
      exit
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
   source=$1
   remote=$2

    echo "Remote Copy of  Backup :$BACKUP_DIR"
    
    mkdir -p $DR_BASE/backups/$remote
    CMD="rsync -avz $EXCLUDE_LIST $source/ $DR_BASE/backups/$remote"
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
    if [ -e $PRIMARY_BASE/restore_running ]
    then
      echo "Previous restore Still running, exiting."
      exit
    else
      touch $PRIMARY_BASE/restore_running
    fi
}

remove_old_backups()
{
    BACKUP_DIR=$1
    echo NO_BACKUPS=`ls -lstd $BACKUP_DIR/20* | wc -l `
    NO_BACKUPS=`ls -lstrd $BACKUP_DIR/20* | wc -l `
    TO_MANY=$((NO_BACKUPS-COPIES))
    if [ $TO_MANY -gt 0 ] 
    then
      BACKUPS_TO_DELETE=` ls -lstd $BACKUP_DIR/20* | awk '{print $10}' | head -$TO_MANY`
      for file in $BACKUPS_TO_DELETE
      do
         echo "Deleting Backup : $file"
         rm -rf $file
      done
    fi
}

ST=$(date +%s)

PRIMARY_BASE=/u01/primary_oudpv
DR_BASE=/u01/dr_oudpv
check_backup_running

if [ "$DR_TYPE" = "PRIMARY" ] 
then
    BACKUP=$(date +%F_%H-%M-%S)

    if [ "$ENV_TYPE" = "OCI" ]
    then
       create_oci_snapshot $BACKUP
       remove_old_backups $PRIMARY_BASE/.snapshot
    else
       create_backup $BACKUP
       remove_old_backups $PRIMARY_BASE/backups
    fi

    echo "Backup Complete"
    rm $PRIMARY_BASE/backup_running
    rm $DR_BASE/backup_running

elif [ "$DR_TYPE" = "STANDBY" ] 
then
    BACKUP=`ls -lstr $PRIMARY_BASE/backups | tail -1 | awk '{ print $10 }'`

    check_restore_running
    restore_backup $BACKUP
    remove_old_backups $PRIMARY_BASE/backups

    echo "Restore Complete"
    rm $PRIMARY_BASE/restore_running

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
