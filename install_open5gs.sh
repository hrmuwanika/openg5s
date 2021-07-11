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
