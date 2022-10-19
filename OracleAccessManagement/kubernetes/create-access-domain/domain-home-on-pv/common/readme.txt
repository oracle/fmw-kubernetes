This is a README file describing the usage of the script oamconfig_modify.sh.
Make sure the script oamconfig_modify.sh has executable permission.
Take a look at the oamconfig.properties file before executing the script.
Modify the oamconfig.properties as per your setup.
Sample oamconfig.properties 
########################################################
#Below are only the sample values, please modify them as per your setup

# The name space where OAM servers are created
OAM_NAMESPACE=accessns

# Define the INGRESS CONTROLLER used. typical value is nginx
INGRESS=nginx

# Define the INGRESS CONTROLLER name used during installation. 
INGRESS_NAME=nginx-ingress

# FQDN of the LBR Host i.e the host from where you access oam console
LBR_HOST=XXX.xxx.example.com
########################################################

Usage:
<Absolute path of oamconfig_modify.sh>/oamconfig_modify.sh <OAM_ADMIN_USER>:<OAM_ADMIN_PASSWORD>
