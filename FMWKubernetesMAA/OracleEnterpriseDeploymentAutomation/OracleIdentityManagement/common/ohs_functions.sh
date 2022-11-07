# Copyright (c) 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of procedures used to configure OHS
#
# Usage: Not invoked directly

#
# Copy Binary to OHS Host
#
copy_binary()
{
   HOSTNAME=$1
   print_msg "Copying Installer to $HOSTNAME"

   ST=`date +%s`

   if [ ! -e $TEMPLATE_DIR/installer/$OHS_INSTALLER ]
   then 
       echo "Failed - Installer $OHS_INSTALLER not found in $TEMPLATE_DIR/installer."
       exit 1
   fi
   scp $TEMPLATE_DIR/installer/$OHS_INSTALLER $HOSTNAME:. > $LOGDIR/$HOSTNAME/copy_installer.log 2>&1
 
   print_status $? $LOGDIR/$HOSTNAME/copy_installer.log

   ET=`date +%s`
   print_time STEP "Copy Oracle HTTP Server Installer to $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}


#
# Unzip Binary on OHS Host
#
unzip_binary()
{
   HOSTNAME=$1
   print_msg "Unzipping Installer on $HOSTNAME"

   ST=`date +%s`

   ssh $HOSTNAME "unzip -o $OHS_INSTALLER" > $LOGDIR/$HOSTNAME/unzip_installer.log 2>&1
 
   print_status $? $LOGDIR/$HOSTNAME/unzip_installer.log

   ET=`date +%s`
   print_time STEP "Unzip Installer on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Copy response file to OHS host for silent install
#
copy_rsp()
{
   HOSTNAME=$1
   print_msg "Copy Response File to $HOSTNAME"

   ST=`date +%s`

   cp $TEMPLATE_DIR/install_ohs.rsp $WORKDIR
   update_variable "<OHS_ORACLE_HOME>" $OHS_ORACLE_HOME $WORKDIR/install_ohs.rsp

   scp $WORKDIR/install_ohs.rsp $HOSTNAME:. > $LOGDIR/$HOSTNAME/copy_rsp.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/copy_rsp.log

   ET=`date +%s`
   print_time STEP "Copy Response File to $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Create the Oracle Home Directory 
#
create_home_dir()
{
   HOSTNAME=$1
   print_msg "Create Oracle Home on $HOSTNAME"

   ST=`date +%s`

   printf "\n\t\t\tCreate Directory - "
   ssh $HOSTNAME "sudo mkdir -p $OHS_ORACLE_HOME"  > $LOGDIR/$HOSTNAME/create_oh.log 2>&1 
   print_status $? $LOGDIR/$HOSTNAME/create_oh.log

   printf "\t\t\tChange Ownership - "
   ssh $HOSTNAME "myuid=`id -u` ; mygid=`id -g `; sudo chown -R \$myuid:\$mygid $OHS_BASE"  >> $LOGDIR/$HOSTNAME/create_oh.log 2>&1 
   print_status $? $LOGDIR/$HOSTNAME/create_oh.log
   ET=`date +%s`
   print_time STEP "Create Oracle Home on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Create oraInst.loc file
#
create_orainst()
{
   HOSTNAME=$1
   print_msg "Create Oracle Inventory File on $HOSTNAME"

   ST=`date +%s`

   mygid=`ssh $HOSTNAME "id -gn" `
   echo "inventory_loc=$OHS_BASE/oraInventory" > $WORKDIR/oraInst.loc
   echo "inst_group=$mygid" >> $WORKDIR/oraInst.loc

   scp $WORKDIR/oraInst.loc $HOSTNAME:. > $LOGDIR/$HOSTNAME/create_orainst.log 2>&1
   print_status $? $LOGDIR/$HOSTNAME/create_orainst.log
  
   ssh $HOSTNAME "sudo mv oraInst.loc /etc" >>$LOGDIR/$HOSTNAME/create_orainst.log 2>&1

   ET=`date +%s`
   print_time STEP "Create Oracle Inventory File on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Install the Oracle HTTP Server
#
install_ohs()
{
   HOSTNAME=$1
   print_msg "Installing Oracle HTTP Server on $HOSTNAME"

   ST=`date +%s`

   INSTALLER=`echo "$OHS_INSTALLER" | sed 's/_Disk1_1of1.zip/.bin/'`

   ssh $HOSTNAME "./$INSTALLER -silent -responseFile ~/install_ohs.rsp" > $LOGDIR/$HOSTNAME/install_ohs.log 2>&1
 
   print_status $? $LOGDIR/$HOSTNAME/install_ohs.log

   ET=`date +%s`
   print_time STEP "Install Oracle HTTP Server on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Create a response file to create OHS Instance
#
create_instance_file()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Create Instance Creation File for $HOSTNAME"

   ST=`date +%s`

   cp $TEMPLATE_DIR/create_instance.py $WORKDIR/create_instance_${OHS_NAME}.py

   filename=$WORKDIR/create_instance_${OHS_NAME}.py

   MW_HOME=$(dirname "$OHS_ORACLE_HOME")
   update_variable "<MW_HOME>" $OHS_ORACLE_HOME $filename
   update_variable "<JAVA_HOME>" $OHS_ORACLE_HOME/oracle_common/jdk/jre $filename
   update_variable "<OHS_DOMAIN>" $OHS_DOMAIN $filename
   update_variable "<OHS_NAME>" $OHS_NAME $filename
   update_variable "<OHS_HTTP_PORT>" $OHS_PORT $filename
   update_variable "<OHS_HTTPS_PORT>" $OHS_HTTPS_PORT $filename
   update_variable "<NM_USER>" $NM_ADMIN_USER $filename
   update_variable "<NM_PWD>" $NM_ADMIN_PWD $filename

   NM_HOME=$OHS_DOMAIN/nodemanager
   update_variable "<NM_HOME>" $NM_HOME $filename
   update_variable "<NM_PORT>" $NM_PORT $filename


   scp $filename $HOSTNAME:. > $LOGDIR/$HOSTNAME/copy_instance_file.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/copy_instance_file.log

   ET=`date +%s`
   print_time STEP "Copy Response File to $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Create a response file to create OHS Instance
#
delete_instance()
{
   HOSTNAME=$1
   OHS_NAME=$2

   cp $TEMPLATE_DIR/delete_instance.py $WORKDIR/delete_instance_${OHS_NAME}.py

   filename=$WORKDIR/delete_instance_${OHS_NAME}.py

   MW_HOME=$(dirname "$OHS_ORACLE_HOME")
   update_variable "<MW_HOME>" $OHS_ORACLE_HOME $filename
   update_variable "<OHS_NAME>" $OHS_NAME $filename
   update_variable "<OHS_DOMAIN>" $OHS_DOMAIN $filename

   scp $filename $HOSTNAME:. 
   ssh $HOSTNAME "$OHS_ORACLE_HOME/oracle_common/common/bin/wlst.sh delete_instance_${OHS_NAME}.py" 

}

# 
# Create the Oracle HTTTP Server Instance in Standalone mode.
#
create_instance()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Create Instance $OHS_NAME on $HOSTNAME"

   ST=`date +%s`

   ssh $HOSTNAME "$OHS_ORACLE_HOME/oracle_common/common/bin/wlst.sh create_instance_${OHS_NAME}.py" > $LOGDIR/$HOSTNAME/create_instance.log
   print_status $? $LOGDIR/$HOSTNAME/create_instance.log

   ET=`date +%s`
   print_time STEP "Create Instance $OHS_NAME on  $HOSTNAME" $ST $ET >> $LOGDIR/timings.log

}

#
# Set OHS Tuning parameters
#
tune_instance()
{
   HOSTNAME=$1
   print_msg "Tune Oracle Http Server Instance on $HOSTNAME"
  
   ST=`date +%s`

   scp $TEMPLATE_DIR/ohs.sedfile $HOSTNAME:. > $LOGDIR/$HOSTNAME/tune_instance.log 2>&1
   echo ssh $HOSTNAME "sed -i -f ohs.sedfile $OHS_DOMAIN/config/fmwconfig/components/OHS/ohs?/httpd.conf" > $LOGDIR/$HOSTNAME/tune_instance.log 2>&1
   ssh $HOSTNAME "sed -i -f ohs.sedfile $OHS_DOMAIN/config/fmwconfig/components/OHS/ohs?/httpd.conf" >> $LOGDIR/$HOSTNAME/tune_instance.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/tune_instance.log

   ET=`date +%s`
   print_time STEP "Tune Instance $OHS_NAME on  $HOSTNAME" $ST $ET >> $LOGDIR/timings.log

}  

#
# Start Node Manager
#
start_nm()
{
   HOSTNAME=$1
   print_msg "Start Node Manager on $HOSTNAME"
  
   ST=`date +%s`

   ssh $HOSTNAME "nohup $OHS_DOMAIN/bin/startNodeManager.sh >$OHS_DOMAIN/nodemanager/nohup.out 2>&1 &" >> $LOGDIR/$HOSTNAME/start_nm.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/start_nm.log

   ET=`date +%s`
   print_time STEP "Start Node Manager on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log

}  

#
# Stop Node Manager
#
stop_nm()
{
   HOSTNAME=$1
   print_msg "Stop Node Manager on $HOSTNAME"
  
   ST=`date +%s`

   ssh $HOSTNAME "$OHS_DOMAIN/bin/stopNodeManager.sh " 

}  

#
# Start the Oracle HTTP Server Instance
#
start_ohs()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Start Oracle HTTP Server on $HOSTNAME"
  
   ST=`date +%s`

   echo $NM_ADMIN_PWD >$WORKDIR/nm.pwd
   scp $WORKDIR/nm.pwd $HOSTNAME:.nm.pwd > $LOGDIR/$HOSTNAME/start_ohs.log 2>&1

   ssh $HOSTNAME "$OHS_DOMAIN/bin/startComponent.sh $OHS_NAME storeUserConfig < \$HOME/.nm.pwd" >> $LOGDIR/$HOSTNAME/start_ohs.log 2>&1
   ssh $HOSTNAME "rm \$HOME/.nm.pwd" >> $LOGDIR/$HOSTNAME/start_ohs.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/start_ohs.log

   ET=`date +%s`
   print_time STEP "Start Oracle Http Server on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log

}  

#
# Stop the Oracle HTTP Server Instance
#
stop_ohs()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Stop Oracle HTTP Server on $HOSTNAME"
  
   ssh $HOSTNAME "$OHS_DOMAIN/bin/stopComponent.sh $OHS_NAME " 

}  
#
# Deploy WebGate in OHS Instance
#
deploy_webgate()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Deploy WebGate on $HOSTNAME"

   ST=`date +%s`

   echo ssh $HOSTNAME "$OHS_ORACLE_HOME/webgate/ohs/tools/deployWebGate/deployWebGateInstance.sh -w $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME -oh $OHS_ORACLE_HOME"  > $LOGDIR/$HOSTNAME/deploy_webgate.log 2>&1
   ssh $HOSTNAME "$OHS_ORACLE_HOME/webgate/ohs/tools/deployWebGate/deployWebGateInstance.sh -w $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME -oh $OHS_ORACLE_HOME"  >> $LOGDIR/$HOSTNAME/deploy_webgate.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/deploy_webgate.log

   ET=`date +%s`
   print_time STEP "Deploy WebGate on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Enable WebGate
#
install_webgate()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Install WebGate on $HOSTNAME"

   ST=`date +%s`

   echo ssh $HOSTNAME "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OHS_ORACLE_HOME/lib;$OHS_ORACLE_HOME/webgate/ohs/tools/setup/InstallTools/EditHttpConf -w $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME -oh $OHS_ORACLE_HOME"  > $LOGDIR/$HOSTNAME/install_webgate.log 2>&1
   ssh $HOSTNAME "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OHS_ORACLE_HOME/lib;$OHS_ORACLE_HOME/webgate/ohs/tools/setup/InstallTools/EditHttpConf -w $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME -oh $OHS_ORACLE_HOME"  > $LOGDIR/$HOSTNAME/install_webgate.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/install_webgate.log

   ET=`date +%s`
   print_time STEP "Install WebGate on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Update WebGate to allow OAP Rest calls
#
update_webgate()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Enable OAM Rest OAP Calls on $HOSTNAME"

   ST=`date +%s`

   scp $TEMPLATE_DIR/webgate_rest.conf $HOSTNAME:. > $LOGDIR/$HOSTNAME/update_wg.log 2>&1
   ssh $HOSTNAME "cat \$HOME/webgate_rest.conf >>  $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME/webgate.conf"  > $LOGDIR/$HOSTNAME/enable_rest.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/enable_rest.log

   ET=`date +%s`
   print_time STEP "Enable OAM Rest OAP calls on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Copy the Load Balancer certificate to the WebGate deployement
#
copy_lbr_cert()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Copy $OAM_LOGIN_LBR_HOST Certificate to WebGate on $HOSTNAME"

   ST=`date +%s`

   printf "\n\t\t\tObtain Certificate - "
   get_lbr_certificate $OAM_LOGIN_LBR_HOST $OAM_LOGIN_LBR_PORT >$LOGDIR/$HOSTNAME/copy_cert.log 2>&1
   print_status $? $LOGDIR/$HOSTNAME/copy_cert.log

   printf "\t\t\tCopy Certificate - "
   scp $WORKDIR/${LBRHOST}.pem $HOSTNAME:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME/webgate/config/cacert.pem >>$LOGDIR/$HOSTNAME/copy_cert.log 2>&1
   print_status $? $LOGDIR/$HOSTNAME/copy_cert.log

   ET=`date +%s`
   print_time STEP "Copy $OAM_LOGIN_LBR_HOST Certificate to WebGate on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}
