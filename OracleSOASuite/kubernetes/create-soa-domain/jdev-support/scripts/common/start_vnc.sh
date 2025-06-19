#!/bin/bash
# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# Script to start the vnc server

script="${BASH_SOURCE[0]}"
scriptDir="$( cd "$( dirname "${script}" )" && pwd )"

VNC_PW=${1:-vncpassword}
DISPLAY=:1
STARTUPDIR="$HOME/.vnc"
mkdir -p $STARTUPDIR
cat <<EOF > $HOME/.vnc/xstartup
#!/bin/sh
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
xfdesktop & xfce4-panel &
xfsettingsd &
xfwm4 &
xfce4-terminal -e 'bash -c "cd /u01/oracle/jdeveloper/jdev/bin; pwd; bash"' -T "JDeveloper Session" &
EOF
chmod +x $HOME/.vnc/xstartup
PASSWD_PATH="$STARTUPDIR/passwd"
VNC_COL_DEPTH=24
VNC_RESOLUTION=1280x1024

if [[ -f $PASSWD_PATH ]]; then
    echo -e "\n---------  purging existing VNC password settings  ---------"
    rm -f $PASSWD_PATH
fi

echo "$VNC_PW" | vncpasswd -f >> $PASSWD_PATH
chmod 600 $PASSWD_PATH

PasswordFile=$HOME/.vnc/passwd
vnc_cmd="vncserver $DISPLAY -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION"
$vnc_cmd &> $STARTUPDIR/start_vnc_$DISPLAY.log
