# Copyright (c) 2022, 2024, Oracle and/or its affiliates.
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

   ST=$(date +%s)

   if [ ! -e $TEMPLATE_DIR/installer/$OHS_INSTALLER ]
   then 
       echo "Failed - Installer $OHS_INSTALLER not found in $TEMPLATE_DIR/installer."
       exit 1
   fi
   $SCP $TEMPLATE_DIR/installer/$OHS_INSTALLER ${OHS_USER}@$HOSTNAME:. > $LOGDIR/$HOSTNAME/copy_installer.log 2>&1
 
   print_status $? $LOGDIR/$HOSTNAME/copy_installer.log

   ET=$(date +%s)
   print_time STEP "Copy Oracle HTTP Server Installer to $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}


#
# Unzip Binary on OHS Host
#
unzip_binary()
{
   HOSTNAME=$1
   print_msg "Unzipping Installer on $HOSTNAME"

   ST=$(date +%s)

   $SSH ${OHS_USER}@$HOSTNAME "unzip -o $OHS_INSTALLER" > $LOGDIR/$HOSTNAME/unzip_installer.log 2>&1
 
   print_status $? $LOGDIR/$HOSTNAME/unzip_installer.log

   ET=$(date +%s)
   print_time STEP "Unzip Installer on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Copy response file to OHS host for silent install
#
copy_rsp()
{
   HOSTNAME=$1
   print_msg "Copy Response File to $HOSTNAME"

   ST=$(date +%s)

   cp $TEMPLATE_DIR/install_ohs.rsp $WORKDIR
   update_variable "<OHS_ORACLE_HOME>" $OHS_ORACLE_HOME $WORKDIR/install_ohs.rsp

   $SCP $WORKDIR/install_ohs.rsp ${OHS_USER}@$HOSTNAME:. > $LOGDIR/$HOSTNAME/copy_rsp.log 2>&1
   print_status $? $LOGDIR/$HOSTNAME/copy_rsp.log

   ET=$(date +%s)
   print_time STEP "Copy Response File to $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Create the Oracle Home Directory 
#
create_home_dir()
{
   HOSTNAME=$1
   print_msg "Create Oracle Home on $HOSTNAME"

   ST=$(date +%s)

   printf "\n\t\t\tCreate Directory - "
   echo $SSH ${OHS_USER}@$HOSTNAME "sudo mkdir -p $OHS_ORACLE_HOME $OHS_BASE $OHS_DOMAIN"  > $LOGDIR/$HOSTNAME/create_oh.log 2>&1 
   $SSH ${OHS_USER}@$HOSTNAME "sudo mkdir -p $OHS_ORACLE_HOME $OHS_BASE $OHS_DOMAIN"  >> $LOGDIR/$HOSTNAME/create_oh.log 2>&1 
   print_status $? $LOGDIR/$HOSTNAME/create_oh.log

   printf "\t\t\tChange Ownership of $OHS_BASE - "
   echo $SSH ${OHS_USER}@$HOSTNAME "sudo sudo find $OHS_BASE ! -name .snapshot -exec chown $OHS_USER:$OHS_GRP {} \;"  >> $LOGDIR/$HOSTNAME/create_oh.log 2>&1 
   $SSH ${OHS_USER}@$HOSTNAME "sudo sudo find $OHS_BASE ! -name .snapshot -exec chown $OHS_USER:$OHS_GRP {} \;"  >> $LOGDIR/$HOSTNAME/create_oh.log 2>&1 
   print_status $? $LOGDIR/$HOSTNAME/create_oh.log

   ET=$(date +%s)
   print_time STEP "Create Oracle Home on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Create oraInst.loc file
#
create_orainst()
{
   HOSTNAME=$1
   print_msg "Create Oracle Inventory File on $HOSTNAME"

   ST=$(date +%s)

   mygid=`ssh $HOSTNAME "id -gn" `
   echo "inventory_loc=$OHS_BASE/oraInventory" > $WORKDIR/oraInst.loc
   echo "inst_group=$mygid" >> $WORKDIR/oraInst.loc

   $SCP $WORKDIR/oraInst.loc ${OHS_USER}@$HOSTNAME:. > $LOGDIR/$HOSTNAME/create_orainst.log 2>&1
   print_status $? $LOGDIR/$HOSTNAME/create_orainst.log

   echo $SSH ${OHS_USER}@$HOSTNAME "sudo mv oraInst.loc /etc" >>$LOGDIR/$HOSTNAME/create_orainst.log 2>&1
   $SSH ${OHS_USER}@$HOSTNAME "sudo mv oraInst.loc /etc" >>$LOGDIR/$HOSTNAME/create_orainst.log 2>&1
   if [ $? -gt 0 ]
   then
     echo "Failed to Move oraInst.loc see logfile $LOGDIR/$HOSTNAME/copy_rsp.log"
     exit 1
   fi
   ET=$(date +%s)
   print_time STEP "Create Oracle Inventory File on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

#
# Install the Oracle HTTP Server
#
install_ohs()
{
   HOSTNAME=$1
   print_msg "Installing Oracle HTTP Server on $HOSTNAME"

   ST=$(date +%s)

   INSTALLER=`echo "$OHS_INSTALLER" | sed 's/_Disk1_1of1.zip/.bin/'`

   $SSH ${OHS_USER}@$HOSTNAME "./$INSTALLER -silent -responseFile ~/install_ohs.rsp" > $LOGDIR/$HOSTNAME/install_ohs.log 2>&1
 
   if [ $? -gt 0 ]
   then
      ERR=`grep Failed $LOGDIR/$HOSTNAME/install_ohs.log | grep -v compat-libcap | grep -v compat-libstdc | grep -v overall | wc -l`
      if [ $ERR = 0 ]
      then
        ssh $HOSTNAME "./$INSTALLER -silent -ignoreSysPreReqs -responseFile ~/install_ohs.rsp" > $LOGDIR/$HOSTNAME/install_ohs.log 2>&1
        print_status $? $LOGDIR/$HOSTNAME/install_ohs.log
      else
        echo "Failed - See logfile $LOGDIR/$HOSTNAME/install_ohs.log"
        exit 1
      fi
   else
      echo "Success"
   fi

   ET=$(date +%s)
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

   ST=$(date +%s)

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


   $SCP $filename ${OHS_USER}@$HOSTNAME:. > $LOGDIR/$HOSTNAME/copy_instance_file.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/copy_instance_file.log

   ET=$(date +%s)
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
   if [ $? -gt 0 ]
   then
     echo "Failed to copy template file $TEMPLATE_DIR/delete_instance.py to $WORKDIR/delete_instance_${OHS_NAME}.py"
     exit 1
   fi

   filename=$WORKDIR/delete_instance_${OHS_NAME}.py

   MW_HOME=$(dirname "$OHS_ORACLE_HOME")
   update_variable "<MW_HOME>" $OHS_ORACLE_HOME $filename
   update_variable "<OHS_NAME>" $OHS_NAME $filename
   update_variable "<OHS_DOMAIN>" $OHS_DOMAIN $filename

   $SCP $filename ${OHS_USER}@$HOSTNAME:. 
   $SSH ${OHS_USER}@$HOSTNAME "$OHS_ORACLE_HOME/oracle_common/common/bin/wlst.sh delete_instance_${OHS_NAME}.py" 

}

# 
# Create the Oracle HTTTP Server Instance in Standalone mode.
#
create_instance()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Create Instance $OHS_NAME on $HOSTNAME"

   ST=$(date +%s)

   $SSH ${OHS_USER}@$HOSTNAME "$OHS_ORACLE_HOME/oracle_common/common/bin/wlst.sh create_instance_${OHS_NAME}.py" > $LOGDIR/$HOSTNAME/create_instance.log 2>&1
   print_status $? $LOGDIR/$HOSTNAME/create_instance.log

   ET=$(date +%s)
   print_time STEP "Create Instance $OHS_NAME on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log

}

#
# Set OHS Tuning parameters
#
tune_instance()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Tune Oracle Http Server Instance on $HOSTNAME"
  
   ST=$(date +%s)

   $SCP $TEMPLATE_DIR/ohs.sedfile ${OHS_USER}@$HOSTNAME:. > $LOGDIR/$HOSTNAME/tune_instance.log 2>&1
   echo $SCP ${OHS_USER}@$HOSTNAME "sed -i -f ohs.sedfile $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME/httpd.conf" > $LOGDIR/$HOSTNAME/tune_instance.log 2>&1
   $SSH ${OHS_USER}@$HOSTNAME "sed -i -f ohs.sedfile $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME/httpd.conf" >> $LOGDIR/$HOSTNAME/tune_instance.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/tune_instance.log

   ET=$(date +%s)
   print_time STEP "Tune Instance $OHS_NAME on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log

}  

#
# Create OHS Health-check
#
create_hc()
{
   HOSTNAME=$1
   OHS_NAME=$2

   print_msg "Create Health Check on $HOSTNAME"
  
   ST=$(date +%s)

   echo $SCP $TEMPLATE_DIR/health-check.html ${OHS_USER}@$HOSTNAME:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME/htdocs > $LOGDIR/$HOSTNAME/create_hc.log 2>&1
   $SCP $TEMPLATE_DIR/health-check.html ${OHS_USER}@$HOSTNAME:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME/htdocs >> $LOGDIR/$HOSTNAME/create_hc.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/create_hc.log

   ET=$(date +%s)
   print_time STEP "Create Health check on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log

}  
#
# Start Node Manager
#
start_nm()
{
   HOSTNAME=$1
   print_msg "Start Node Manager on $HOSTNAME"
  
   ST=$(date +%s)

   $SSH ${OHS_USER}@$HOSTNAME "nohup $OHS_DOMAIN/bin/startNodeManager.sh >$OHS_DOMAIN/nodemanager/nohup.out 2>&1 &" >> $LOGDIR/$HOSTNAME/start_nm.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/start_nm.log

   ET=$(date +%s)
   print_time STEP "Start Node Manager on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log

}  

#
# Stop Node Manager
#
stop_nm()
{
   HOSTNAME=$1
   print_msg "Stop Node Manager on $HOSTNAME"
  
   ST=$(date +%s)

   $SSH ${OHS_USER}@$HOSTNAME "$OHS_DOMAIN/bin/stopNodeManager.sh " 

}  

#
# Start the Oracle HTTP Server Instance
#
start_ohs()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Start Oracle HTTP Server on $HOSTNAME"
  
   ST=$(date +%s)

   echo $NM_ADMIN_PWD >$WORKDIR/nm.pwd
   $SCP $WORKDIR/nm.pwd ${OHS_USER}@$HOSTNAME:.nm.pwd > $LOGDIR/$HOSTNAME/start_ohs.log 2>&1

   $SSH ${OHS_USER}@$HOSTNAME "$OHS_DOMAIN/bin/startComponent.sh $OHS_NAME storeUserConfig < \$HOME/.nm.pwd" >> $LOGDIR/$HOSTNAME/start_ohs.log 2>&1
   $SSH ${OHS_USER}@$HOSTNAME "rm \$HOME/.nm.pwd" >> $LOGDIR/$HOSTNAME/start_ohs.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/start_ohs.log

   ET=$(date +%s)
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
  
   $SSH ${OHS_USER}@$HOSTNAME "$OHS_DOMAIN/bin/stopComponent.sh $OHS_NAME " 

}  
#
# Deploy WebGate in OHS Instance
#
deploy_webgate()
{
   HOSTNAME=$1
   OHS_NAME=$2
   print_msg "Deploy WebGate on $HOSTNAME"

   ST=$(date +%s)

   echo $SSH ${OHS_USER}@$HOSTNAME "$OHS_ORACLE_HOME/webgate/ohs/tools/deployWebGate/deployWebGateInstance.sh -w $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME -oh $OHS_ORACLE_HOME"  > $LOGDIR/$HOSTNAME/deploy_webgate.log 2>&1
   $SSH ${OHS_USER}@$HOSTNAME "$OHS_ORACLE_HOME/webgate/ohs/tools/deployWebGate/deployWebGateInstance.sh -w $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME -oh $OHS_ORACLE_HOME"  >> $LOGDIR/$HOSTNAME/deploy_webgate.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/deploy_webgate.log

   ET=$(date +%s)
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

   ST=$(date +%s)

   echo $SSH ${OHS_USER}@$HOSTNAME "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OHS_ORACLE_HOME/lib;$OHS_ORACLE_HOME/webgate/ohs/tools/setup/InstallTools/EditHttpConf -w $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME -oh $OHS_ORACLE_HOME"  > $LOGDIR/$HOSTNAME/install_webgate.log 2>&1
   $SSH ${OHS_USER}@$HOSTNAME "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OHS_ORACLE_HOME/lib;$OHS_ORACLE_HOME/webgate/ohs/tools/setup/InstallTools/EditHttpConf -w $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME -oh $OHS_ORACLE_HOME"  > $LOGDIR/$HOSTNAME/install_webgate.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/install_webgate.log

   ET=$(date +%s)
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

   ST=$(date +%s)


   cp $TEMPLATE_DIR/webgate_rest.conf $WORKDIR/webgate_rest.conf> $LOGDIR/$HOSTNAME/update_wg.log 2>&1
   if [ ! "$OHS_LBR_NETWORK" = "" ]
   then
      echo "" >> $WORKDIR/webgate_rest.conf
      echo "<LocationMatch \"/health-check.html\">" >> $WORKDIR/webgate_rest.conf
      echo "    require host $OHS_LBR_NETWORK" >> $WORKDIR/webgate_rest.conf
      echo  "</LocationMatch>"  >> $WORKDIR/webgate_rest.conf
   fi

   $SCP $WORKDIR/webgate_rest.conf ${OHS_USER}@$HOSTNAME:. > $LOGDIR/$HOSTNAME/update_wg.log 2>&1
   $SSH ${OHS_USER}@$HOSTNAME "cat \$HOME/webgate_rest.conf >>  $OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME/webgate.conf"  > $LOGDIR/$HOSTNAME/enable_rest.log 2>&1

   print_status $? $LOGDIR/$HOSTNAME/enable_rest.log

   ET=$(date +%s)
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

   ST=$(date +%s)

   printf "\n\t\t\tObtain Certificate - "
   get_lbr_certificate $OAM_LOGIN_LBR_HOST $OAM_LOGIN_LBR_PORT >$LOGDIR/$HOSTNAME/copy_cert.log 2>&1
   print_status $? $LOGDIR/$HOSTNAME/copy_cert.log

   printf "\t\t\tCopy Certificate - "
   $SCP $WORKDIR/${LBRHOST}.pem ${OHS_USER}@$HOSTNAME:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS_NAME/webgate/config/cacert.pem >>$LOGDIR/$HOSTNAME/copy_cert.log 2>&1
   print_status $? $LOGDIR/$HOSTNAME/copy_cert.log

   ET=$(date +%s)
   print_time STEP "Copy $OAM_LOGIN_LBR_HOST Certificate to WebGate on $HOSTNAME" $ST $ET >> $LOGDIR/timings.log
}

update_ohs_route()
{
   print_msg "Change OHS Routing"
   echo

   ST=$(date +%s)

   FILES=$(ls -1 $WORKDIR/*vh.conf)
   K8NODES=$(get_k8nodes)


   for file in $FILES
   do
    printf "\t\t\tProcessing File:$file - "
    PORTS=$(grep WebLogicCluster $file | sed "s/WebLogicCluster//" | awk 'BEGIN { RS = "," } { print $0 }' | cut -f2 -d: | sort | uniq)
    for PORT in $PORTS
    do
      ROUTE="WebLogicCluster "
      for NODE in $K8NODES
      do
        ROUTE="$ROUTE,$NODE:$PORT"
      done
      DIRECTIVE=$(echo $ROUTE | sed 's/,//')
      sed -i "/:$PORT/c\        $DIRECTIVE" $file >> $LOGDIR/update_ohs_route.log 2>&1
    done
    print_status $? $LOGDIR/update_ohs_route.log
   done

   ET=$(date +%s)
   print_time STEP "Change OHS Routing" $ST $ET >> $LOGDIR/timings.log
}


update_ohs_hostname()
{
   print_msg "Change OHS Virtual Host Name "
   ST=$(date +%s)
   OLD_HOSTNAME=$( grep "<VirtualHost" $WORKDIR/*.conf | cut -f2 -d: | awk '{ print $2 }' | head -1 )
   mkdir $WORKDIR/$OHS_HOST1  2>/dev/null
   cp $WORKDIR/*.conf $WORKDIR/$OHS_HOST1
   if [ ! "$OLD_HOSTNAME" = "$OHS_HOST1" ]
   then
      printf "\n\t\t\tChanging $OLD_HOSTNAME to $OHS_HOST1 - "
      sed -i "s/$OLD_HOSTNAME/$OHS_HOST1/" $WORKDIR/$OHS_HOST1/*.conf > $LOGDIR/update_vh.log 2>&1
      print_status $? $LOGDIR/update_vh.log
   fi

   if [ ! "$OHS_HOST2" = "" ]
   then
      mkdir $WORKDIR/$OHS_HOST2  2>/dev/null
      cp $WORKDIR/*.conf $WORKDIR/$OHS_HOST2
      printf "\n\t\t\tChanging $OLD_HOSTNAME to $OHS_HOST2 - "
      sed -i "s/$OLD_HOSTNAME/$OHS_HOST2/" $WORKDIR/$OHS_HOST2/*.conf >> $LOGDIR/update_vh.log 2>&1
      print_status $? $LOGDIR/update_vh.log
   fi
   ET=$(date +%s)
   print_time STEP "Change OHS Virtual HostName" $ST $ET >> $LOGDIR/timings.log
}

  
copy_ohs_dr_config()
{
   print_msg "Copy OHS Config"
   ST=$(date +%s)
   
   printf "\n\t\t\tCopy OHS Config to $OHS_HOST1 - "
   $SCP $WORKDIR/$OHS_HOST1/*vh.conf $OHS_HOST1:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS1_NAME/moduleconf/ > $LOGDIR/copy_ohs_config.log 2>&1
   print_status $? $LOGDIR/copy_ohs_config.log

   if [ ! "$OHS_HOST2" = "" ]
   then
      printf "\t\t\tCopy OHS Config to $OHS_HOST2 - "
      $SCP $WORKDIR/$OHS_HOST2/*vh.conf $OHS_HOST2:$OHS_DOMAIN/config/fmwconfig/components/OHS/$OHS2_NAME/moduleconf/ > $LOGDIR/copy_ohs_config.log 2>&1
      print_status $? $LOGDIR/copy_ohs_config.log
   fi
   ET=$(date +%s)
   print_time STEP "Change OHS Routing" $ST $ET >> $LOGDIR/timings.log
}

# Add location directives to OHS Config Files
#
create_location()
{
  locfile=$1
  nodes=$2
  ohs_path=$3

  printf "\t\t\tAdding location Directives to OHS conf file  - "
  while IFS= read -r LOCATIONS
  do
     file=$(echo $LOCATIONS | cut -f1 -d:)
     location=$(echo $LOCATIONS | cut -f2 -d:)
     port=$(echo $LOCATIONS | cut -f3 -d:)
     ssl=$(echo $LOCATIONS | cut -f4 -d:)

     conf_file=${file}_vh.conf

     case $file in
       iadadmin)
        protocol=$OAM_ADMIN_LBR_PROTOCOL
        ;;
       login)
        protocol=$OAM_LOGIN_LBR_PROTOCOL
        ;;
       prov)
        protocol=$OIG_LBR_PROTOCOL
        ;;
       igdinternal)
        protocol=$OIG_LBR_INT_PROTOCOL
        ;;
       igdadmin)
        protocol=$OIG_ADMIN_LBR_PROTOCOL
        ;;
       *)
         echo "FILE:$file"
        ;;
     esac

     sed -i "/<\/VirtualHost>/d" $ohs_path/$conf_file

     printf "Adding Location $location to $ohs_path/$conf_file - " >> $LOGDIR/$file.log
     grep -q "$location>" $ohs_path/$conf_file
     if [ $? -eq 1 ]
     then
       printf "\n    <Location $location>" >> $ohs_path/$conf_file
       printf "\n        WLSRequest ON" >> $ohs_path/$conf_file
       printf "\n        DynamicServerList OFF" >> $ohs_path/$conf_file

       if [ "$ssl" = "Y" ] && [ "$USE_INGRESS"  = "false" ]
       then
           printf "\n        SecureProxy ON" >> $ohs_path/$conf_file
           printf "\n        WLSSLWallet   \"${ORACLE_INSTANCE}/ohswallet\"" >> $ohs_path/$conf_file
       fi

       if [ "$file" = "login" ]
       then
          printf "\n        WLCookieName OAMJSESSIONID" >> $ohs_path/$conf_file
          echo $location | grep -q well-known
           if [ $? -eq 0 ]
          then
              printf "\n        PathTrim /.well-known" >> $ohs_path/$conf_file
              printf "\n        PathPrepend /oauth2/rest" >> $ohs_path/$conf_file
          fi

       elif [ "$file" = "prov" ]
       then
          printf "\n        WLCookieName oimjsessionid" >> $ohs_path/$conf_file
       elif [ "$file" = "igdinternal" ]
       then
          if [ "$location" = "/spmlws" ] 
          then
              printf "\n        PathTrim /weblogic" >> $ohs_path/$conf_file
          fi
       fi

       if [ "$protocol" = "https" ]
       then
          printf "\n        WLProxySSL ON" >> $ohs_path/$conf_file
          printf "\n        WLProxySSLPassThrough ON" >> $ohs_path/$conf_file
       fi

       cluster_cmd="        WebLogicCluster " >> $ohs_path/$conf_file
       node_count=0
       for node in $nodes
       do
          if [ $node_count -eq 0 ]
          then
             cluster_cmd=$cluster_cmd"$node:$(($port))"
          else
             cluster_cmd=$cluster_cmd",$node:$(($port))"
          fi
          ((node_count++))
       done
       printf "\n$cluster_cmd" >> $ohs_path/$conf_file

       printf "\n    </Location>\n" >> $ohs_path/$conf_file
       echo "Success" >>$LOGDIR/$file.log
    else
       echo "Already Exists" >>$LOGDIR/$file.log
    fi

    printf "\n</VirtualHost>\n" >> $ohs_path/$conf_file
  done < $locfile

}
