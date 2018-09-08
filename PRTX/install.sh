#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE="smrtc.conf"
BINARY_FILE="/usr/local/bin/smartcd"
CROP_REPO="https://github.com/SMRT-Cloud/smrtc.git"
COIN_TGZ='https://github.com/telostia/smartcloud-guides/releases/download/0.001/smrtc-linux.tar.gz'

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $@. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof cropcoind)" ]; then
  echo -e "${GREEN}\c"
  read -e -p "smrtcd is already running. Do you want to add another MN? [Y/N]" NEW_SMRTC
  echo -e "{NC}"
  clear
else
  NEW_SMRTC="new"
fi
}

function prepare_system() {

echo -e "Prepare the system to install SmartCloud master node."
apt-get update >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade >/dev/null 2>&1
apt install -y software-properties-common >/dev/null 2>&1
echo -e "${GREEN}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get update >/dev/null 2>&1
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" make software-properties-common \
build-essential libtool autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git wget pwgen curl libdb4.8-dev bsdmainutils \
libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw pwgen
clear
if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git pwgen curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev ufw"
 exit 1
fi

clear
echo -e "Checking if swap space is needed."
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
SWAP=$(swapon -s)
if [[ "$PHYMEM" -lt "2" && -z "$SWAP" ]];
  then
    echo -e "${GREEN}Server is running with less than 2G of RAM, creating 2G swap file.${NC}"
    dd if=/dev/zero of=/swapfile bs=1024 count=2M
    chmod 600 /swapfile
    mkswap /swapfile
    swapon -a /swapfile
else
  echo -e "${GREEN}The server running with at least 2G of RAM, or SWAP exists.${NC}"
fi
clear
}

function deploy_binaries() {
  cd $TMP
  wget -q $COIN_TGZ >/dev/null 2>&1
  gunzip cropcoind.gz >/dev/null 2>&1
  chmod +x smrtcd >/dev/null 2>&1
  cp smrtcd /usr/local/bin/ >/dev/null 2>&1
}

function ask_permission() {
 echo -e "${RED}I trust NodeCircle and want to use binaries compiled on his server.${NC}."
 echo -e "Please type ${RED}YES${NC} if you want to use precompiled binaries, or type anything else to compile them on your server"
 read -e NodeCircle
}

function compile_smartcloud() {
  echo -e "Clone git repo and compile it. This may take some time. Press a key to continue."
  read -n 1 -s -r -p ""

  git clone $SMRTC_REPO $TMP_FOLDER
  cd $TMP_FOLDER/src
  mkdir obj/support
  mkdir obj/crypto
  make -f makefile.unix
  compile_error smartcloud
  cp -a smrtcd $BINARY_FILE
  clear
}

function enable_firewall() {
  echo -e "Installing and setting up firewall to allow incomning access on port ${GREEN}$CROPCOINPORT${NC}"
  ufw allow $SMARTCLOUDPORT/tcp comment "SmartCloud MN port" >/dev/null
  ufw allow $[SMARTCLOUDPORT+1]/tcp comment "SmartCloud RPC port" >/dev/null
  ufw allow ssh >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}

function systemd_cropcoin() {
  cat << EOF > /etc/systemd/system/$SMARTCLOUDUSER.service
[Unit]
Description=SmartCloud service
After=network.target
[Service]
Type=forking
User=$SMARTCLOUDUSER
Group=$SMARTCLOUDUSER
WorkingDirectory=$SMARTCLOUDHOME
ExecStart=$BINARY_FILE -daemon
ExecStop=$BINARY_FILE stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $SMARTCLOUDUSER.service
  systemctl enable $SMARTCLOUDUSER.service >/dev/null 2>&1

  if [[ -z $(pidof smrtcd) ]]; then
    echo -e "${RED}smrtcd is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo "systemctl start $SMARTCLOUDUSER.service"
    echo "systemctl status $SMARTCLOUDUSER.service"
    echo "less /var/log/syslog"
    exit 1
  fi
}

function ask_port() {
DEFAULTSMARTCLOUDPORT=17720
read -p "SMARTCLOUD Port: " -i $DEFAULTSMARTCLOUDPORT -e SMARTCLOUDPORT
: ${SMARTCLOUDPORT:=$DEFAULTSMARTCLOUDPORT}
}

function ask_user() {
  DEFAULTSMARTCLOUDUSER="smartcloud"
  read -p "Cropcoin user: " -i $DEFAULTSMARTCLOUDUSER -e SMARTCLOUDUSER
  : ${SMARTCLOUDUSER:=$DEFAULTSMARTCLOUDUSER}

  if [ -z "$(getent passwd $SMARTCLOUDUSER)" ]; then
    useradd -m $SMARTCLOUDUSER
    USERPASS=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w12 | head -n1)
    echo "$SMARTCLOUDUSER:$USERPASS" | chpasswd

    SMARTCLOUDHOME=$(sudo -H -u $SMARTCLOUDUSER bash -c 'echo $HOME')
    DEFAULTCROPCOINFOLDER="$SMARTCLOUDHOME/.smrtc"
    read -p "Configuration folder: " -i $DEFAULTSMARTCLOUDFOLDER -e SMARTCLOUDFOLDER
    : ${SMARTCLOUDFOLDER:=$DEFAULTSMARTCLOUDFOLDER}
    mkdir -p $SMARTCLOUDFOLDER
    chown -R $SMARTCLOUDUSER: $SMARTCLOUDFOLDER >/dev/null
  else
    clear
    echo -e "${RED}User exits. Please enter another username: ${NC}"
    ask_user
  fi
}

function check_port() {
  declare -a PORTS
  PORTS=($(netstat -tnlp | awk '/LISTEN/ {print $4}' | awk -F":" '{print $NF}' | sort | uniq | tr '\r\n'  ' '))
  ask_port

  while [[ ${PORTS[@]} =~ $SMARTCLOUDPORT ]] || [[ ${PORTS[@]} =~ $[SMARTCLOUDPORT+1] ]]; do
    clear
    echo -e "${RED}Port in use, please choose another port:${NF}"
    ask_port
  done
}

function create_config() {
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $SMARTCLOUDFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
rpcport=$[SMARTCLOUDPORT+1]
listen=1
server=1
daemon=1
port=$SMARTCLOUDPORT
EOF
}

function create_key() {
  echo -e "Enter your ${RED}Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
  read -e SMARTCLOUDKEY
  if [[ -z "$SMARTCLOUDKEY" ]]; then
  sudo -u $SMARTCLOUDUSER /usr/local/bin/smrtcd -conf=$SMARTCLOUDFOLDER/$CONFIG_FILE -datadir=$SMARTCLOUDFOLDER
  sleep 5
  if [ -z "$(pidof smrtcd)" ]; then
   echo -e "${RED}smrtcd server couldn't start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  SMARTCLOUDKEY=$(sudo -u $SMARTCLOUDUSER $BINARY_FILE -conf=$SMARTCLOUDFOLDER/$CONFIG_FILE -datadir=$SMARTCLOUDFOLDER masternode genkey)
  sudo -u $SMARTCLOUDUSER $BINARY_FILE -conf=$SMARTCLOUDFOLDER/$CONFIG_FILE -datadir=$SMARTCLOUDFOLDER stop
fi
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $SMARTCLOUDFOLDER/$CONFIG_FILE
  NODEIP=$(curl -s4 api.ipify.org)
  cat << EOF >> $SMARTCLOUDFOLDER/$CONFIG_FILE
logtimestamps=1
maxconnections=256
masternode=1
masternodeaddr=$NODEIP:$SMARTCLOUDPORT
masternodeprivkey=$SMARTCLOUDKEY
addnode=139.99.159.113
addnode=139.99.196.73
addnode=139.99.202.60
addnode=139.99.197.112
EOF
  chown -R $SMARTCLOUDUSER: $SMARTCLOUDFOLDER >/dev/null
}

function important_information() {
 echo
 echo -e "================================================================================================================================"
 echo -e "SmartCloud Masternode is up and running as user ${GREEN}$SMARTCLOUDUSER${NC} and it is listening on port ${GREEN}$SMARTCLOUDPORT${NC}."
 echo -e "${GREEN}$SMARTCLOUDUSER${NC} password is ${RED}$USERPASS${NC}"
 echo -e "Configuration file is: ${RED}$SMARTCLOUDFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $SMARTCLOUDUSER.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $SMARTCLOUDUSER.service${NC}"
 echo -e "VPS_IP:PORT ${RED}$NODEIP:$SMARTCLOUDPORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${RED}$SMARTCLOUDKEY${NC}"
 echo -e "================================================================================================================================"
}

function setup_node() {
  ask_user
  check_port
  create_config
  create_key
  update_config
  enable_firewall
  systemd_smartcloud
  important_information
}


##### Main #####
clear

checks
if [[ ("$NEW_SMARTCLOUD" == "y" || "$NEW_SMARTCLOUD" == "Y") ]]; then
  setup_node
  exit 0
elif [[ "$NEW_SMARTCLOUD" == "new" ]]; then
  prepare_system
  ask_permission
  if [[ "$NODECIRCLE" == "YES" ]]; then
    deploy_binaries
  else
    compile_smartcloud
  fi
  setup_node
else
  echo -e "${GREEN}smrtcd already running.${NC}"
  exit 0
fi
