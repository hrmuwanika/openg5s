#!/bin/bash

################################################################################
# Script for installing Open5G on Ubuntu Focal (20.04)
# Authors: Henry Robert Muwanika
#
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano install_open5gs.sh
# Place this content in it and then make the file executable:
# sudo chmod +x install_open5gs.sh
# Execute the script to install Open5Gs:
# ./install_open5gs.sh
################################################################################
##

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============= Update Server ================"
sudo apt update && sudo apt -y upgrade 
sudo apt autoremove -y

#--------------------------------------------------
# Set up the timezones
#--------------------------------------------------
# set the correct timezone on ubuntu
timedatectl set-timezone Africa/Kigali
timedatectl

#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service sshd restart

#--------------------------------------------------
# Install dependencies
#--------------------------------------------------
sudo apt install -y git gcc g++ flex bison libmariadb-dev libmariadb-dev-compat make autoconf libssl-dev libcurl4-openssl-dev tcpdump \
libncurses5-dev libxml2-dev libpcre3-dev unixodbc-dev vim libsctp-dev libunistring-dev htop dkms libradcli-dev libmnl-dev lsb-release \
screen ntp ntpdate libmariadbclient-dev libcurl3-gnutls libc6 libcurl4 ca-certificates dbus

echo "set mouse-=a" >> ~/.vimrc

echo -e "\n============= Install dependencies ================"
sudo apt install -y software-properties-common dirmngr
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.liquidtelecom.com/repo/10.5/debian buster main'
sudo apt update
sudo apt install -y mariadb-server mariadb-client

sudo systemctl enable mariadb
sudo systemctl start mariadb

mysql_secure_installation

#-----------------------------------------------
# Download Kamailio from source
#-----------------------------------------------
cd /usr/local/src/
sudo mkdir –p kamailio-5.5
cd kamailio-5.5
sudo git clone --depth 1 --no-single-branch https://github.com/kamailio/kamailio kamailio
cd kamailio
git checkout -b 5.5 origin/5.5

make include_modules="cdp cdp_avp db_mysql dialplan ims_auth ims_charging ims_dialog ims_diameter_server ims_icscf ims_ipsec_pcscf \
ims_isc ims_ocs ims_qos ims_registrar_pcscf ims_registrar_scscf ims_usrloc_pcscf ims_usrloc_scscf outbound presence presence_conference \
presence_dialoginfo presence_mwi presence_profile presence_reginfo presence_xml pua pua_bla pua_dialoginfo pua_reginfo pua_rpc pua_usrloc \
pua_xmpp sctp tls utils xcap_client xcap_server xmlops xmlrpc" cfg

make all
make install
ldconfig

sed -i 's/# SIP_DOMAIN=kamailio.org/SIP_DOMAIN=$WEBSITE_NAME/g' /usr/local/etc/kamailio/kamctlrc
sed -i 's/# DBENGINE=MYSQL/DBENGINE=MYSQL/g' /usr/local/etc/kamailio/kamctlrc
sed -i 's/# DBHOST=localhost/DBHOST=localhost/g' /usr/local/etc/kamailio/kamctlrc
sed -i 's/# DBNAME=kamailio/DBNAME=kamailio/g' /usr/local/etc/kamailio/kamctlrc
sed -i 's/# DBRWUSER="kamailio"/DBRWUSER="kamailio"/g' /usr/local/etc/kamailio/kamctlrc
sed -i 's/# DBRWPW="kamailiorw"/DBRWPW="kamailiorw"/g' /usr/local/etc/kamailio/kamctlrc
sed -i 's/# CHARSET="latin1"/CHARSET="latin1"/g' /usr/local/etc/kamailio/kamctlrc

sudo /usr/local/sbin/kamdbctl create

sed -i -e '2i#!define WITH_MYSQL\' /usr/local/etc/kamailio/kamailio.cfg
sed -i -e '3i#!define WITH_AUTH\' /usr/local/etc/kamailio/kamailio.cfg
sed -i -e '4i#!define WITH_USRLOCDB\' /usr/local/etc/kamailio/kamailio.cfg
sed -i -e '5i#!define WITH_NAT\' /usr/local/etc/kamailio/kamailio.cfg

make install-systemd-debian
systemctl daemon-reload
systemctl enable kamailio
systemctl start kamailio

cd /usr/local/src/kamailio/utils/kamctl/mysql
mysql -u root -p
CREATE DATABASE  `pcscf`;
CREATE DATABASE  `scscf`;
CREATE DATABASE  `icscf`;
exit

mysql -u root -p pcscf < standard-create.sql
mysql -u root -p pcscf < presence-create.sql
mysql -u root -p pcscf < ims_usrloc_pcscf-create.sql
mysql -u root -p pcscf < ims_dialog-create.sql

mysql -u root -p scscf < standard-create.sql
mysql -u root -p scscf < presence-create.sql
mysql -u root -p scscf < ims_usrloc_scscf-create.sql
mysql -u root -p scscf < ims_dialog-create.sql
mysql -u root -p scscf < ims_charging-create.sql

cd /usr/local/src/kamailio/misc/examples/ims/icscf
mysql -u root -p icscf < icscf.sql

mysql -u root -p
grant delete,insert,select,update on pcscf.* to pcscf@localhost identified by 'heslo';
grant delete,insert,select,update on scscf.* to scscf@localhost identified by 'heslo';
grant delete,insert,select,update on icscf.* to icscf@localhost identified by 'heslo';
grant delete,insert,select,update on icscf.* to provisioning@localhost identified by 'provi';

GRANT ALL PRIVILEGES ON pcscf.* TO 'pcscf'@'%' identified by 'heslo';
GRANT ALL PRIVILEGES ON scscf.* TO 'scscf'@'%' identified by 'heslo';
GRANT ALL PRIVILEGES ON icscf.* TO 'icscf'@'%' identified by 'heslo';
GRANT ALL PRIVILEGES ON icscf.* TO 'provisioning'@'%' identified by 'provi';

use icscf;
INSERT INTO `nds_trusted_domains` VALUES (1,'ims.mnc001.mcc001.3gppnetwork.org');
INSERT INTO `s_cscf` VALUES (1,'First and only S-CSCF','sip:scscf.ims.mnc001.mcc001.3gppnetwork.org:6060');
INSERT INTO `s_cscf_capabilities` VALUES (1,1,0),(2,1,1);
FLUSH PRIVILEGES;
exit

#----------------------------------------------------
# Open5Gs installation
#----------------------------------------------------
sudo apt install -y software-properties-common curl git
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt install -y open5gs

#=========================================
# Install the WebUI of Open5GS 
#=========================================
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y nodejs

#=========================================
# You can now install WebUI of Open5GS
#=========================================
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -

vim /etc/open5gs/mme.yaml 
vim /etc/open5gs/sgwu.yaml 

vim /etc/open5gs/amf.yaml
vim /etc/open5gs/upf.yaml

sudo systemctl restart open5gs-mmed
sudo systemctl restart open5gs-sgwcd
sudo systemctl restart open5gs-smfd
sudo systemctl restart open5gs-amfd
sudo systemctl restart open5gs-sgwud
sudo systemctl restart open5gs-upfd
sudo systemctl restart open5gs-hssd
sudo systemctl restart open5gs-pcrfd
sudo systemctl restart open5gs-nrfd
sudo systemctl restart open5gs-ausfd
sudo systemctl restart open5gs-udmd
sudo systemctl restart open5gs-pcfd
sudo systemctl restart open5gs-nssfd
sudo systemctl restart open5gs-bsfd
sudo systemctl restart open5gs-udrd
sudo systemctl restart open5gs-webui

#=========================================
# Install Ueransim dependencies
#=========================================
sudo apt install -y make gcc g++ libsctp-dev lksctp-tools iproute2 
sudo snap install cmake --classic

cd /usr/src
git clone https://github.com/aligungr/UERANSIM
cd UERANSIM
make

cd build
./nr-gnb -c ../config/open5gs-gnb.yaml
./nr-ue -c ../config/open5gs-ne.yaml
