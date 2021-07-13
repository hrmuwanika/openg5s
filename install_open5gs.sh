#!/bin/bash

################################################################################
# I recommend that the use of Ubuntu 18.04 LTS or higher
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

#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service sshd restart

#====================================================
# Install Open5GS
#====================================================
sudo apt install -y software-properties-common git
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt install -y open5gs

#=========================================
# Install Open5GS Web user interface which supports the user subscription management
#=========================================
sudo apt-get -y install curl
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y nodejs
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -

# 
# vim /etc/open5gs/mme.yaml 
# vim /etc/open5gs/sgwu.yaml 

# By default the AMF binds to a loopback IP, which is fine if everything is running on the same box, but becomes an issue for real gNodeBs or 
# if we’re running UERANSIM on a different machine. Change the ngap addr to bind the AMF to the machine’s IP
vim /etc/open5gs/amf.yaml
# vim /etc/open5gs/upf.yaml

sudo systemctl restart open5gs-amfd
sudo systemctl restart open5gs-upfd

#=======================================
# Verify
#=======================================
sudo systemctl status open5gs-mmed
sudo systemctl status open5gs-sgwcd
sudo systemctl status open5gs-smfd
sudo systemctl status open5gs-amfd
sudo systemctl status open5gs-sgwud
sudo systemctl status open5gs-upfd
sudo systemctl status open5gs-hssd
sudo systemctl status open5gs-pcrfd
sudo systemctl status open5gs-nrfd
sudo systemctl status open5gs-ausfd
sudo systemctl status open5gs-udmd
sudo systemctl status open5gs-pcfd
sudo systemctl status open5gs-nssfd
sudo systemctl status open5gs-bsfd
sudo systemctl status open5gs-udrd
sudo systemctl status open5gs-webui

echo "\n========================================================================="
echo "Done! The Open5GS server is up and running."
echo "Connect to http://localhost:3000 and login with admin account."
echo "Username : admin"
echo "Password : 1423"
echo "Happy 5G testing!!!!!!!!"
