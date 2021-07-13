#!/bin/bash

# Requirements
## VPS with Ubuntu 16.04 or later
## CMake 3.17 or later
## gcc 9.0.0 or later
## g++ 9.0.0 or later


sudo apt update
sudo apt upgrade

#=========================================
# Install UERANSIM dependencies
#=========================================
sudo apt install -y make gcc g++ libsctp-dev lksctp-tools iproute2 
sudo snap install cmake --classic

cd /usr/src
git clone https://github.com/aligungr/UERANSIM
cd UERANSIM
make

# Inside here we’ll need to set the the parameters of our simulated gNodeB, for us this means (unless you’ve changed the PLMN etc) just changing
# the Link IPs that the gNodeB binds to, and the IP of the AMFs 
vim ../config/open5gs-gnb.yaml

# in terminal 1
cd build
./nr-gnb -c ../config/open5gs-gnb.yaml

vim ../config/open5gs-ne.yaml

# in terminal 2
cd build
./nr-ne -c ../config/open5gs-ne.yaml

