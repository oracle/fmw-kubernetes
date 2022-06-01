# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#
# This is an example of a script to update the Match Attr
#
MA=`curl -i -s -u $LDAP_OAMADMIN_USER:$LDAP_USER_PWD  http://$K8_WORKER_HOST1:$OAM_ADMIN_K8/iam/admin/config/api/v1/config?path=/DeployedComponent/Server/NGAMServer/Profile/AuthenticationModules/DAPModules | awk '/Name=\"DAPModules/{p=2} p > 0 { print $0; p--}' | tail -1 | cut -f2 -d\"`

echo "<Configuration>" > /tmp/MatchLDAPAttribute_input.xml
echo "  <Setting Name=\"MatchLDAPAttribute\" Type=\"xsd:string\" Path=\"/DeployedComponent/Server/NGAMServer/Profile/AuthenticationModules/DAPModules/${MA}/MatchLDAPAttribute\">uid</Setting>" >> /tmp/MatchLDAPAttribute_input.xml
echo "</Configuration>" >> /tmp/MatchLDAPAttribute_input.xml

curl -s -u $LDAP_OAMADMIN_USER:$LDAP_USER_PWD -H 'Content-Type: text/xml' -X PUT http://$K8_WORKER_HOST1:$OAM_ADMIN_K8/iam/admin/config/api/v1/config -d @/tmp/MatchLDAPAttribute_input.xml
