# Masternode-Installscript for Printex MN


Crypto Masternode Install- and Update Script for Printex

Create VPS for 5 USD/Month at https://www.vultr.com/?ref=7459078 (UBUNTU 16.04, x64, 1CPU, 1024MB) 

Install type:

    wget https://raw.githubusercontent.com/rarealton/masternode-scripts/master/PRTX/install.sh
    bash install.sh

This script will let you choose up to 5 masternodes to set up on one vps running UBUNTU 16.04

Save each PRIVATEKEY for Later use

On you Wallet side you have to send 10000 PRTX in one transaction to a dedicated Adress and wait for 15 Confirmations.

in the console on the desktop wallet type:

    masternode outputs

Returns are TXID and OUTPUTID

in the masternode.conf file add a line with the following format:
    
    Alias IP:PORT PRIVATKEY TXID OUTPUTID

    Example: MN1 127.0.0.2:9797 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0

NOTE!!! For each additional MN on this vps in the masternode.conf file put the port as 9797 even though on the vps it will not be the same. You must do this for it to work. 

Restart Wallet

Start Masternode in Masternode Tab.

If you get an error saying invalid ip, open tools / debug console and type startmasternode alias 0 MN1

### ** IF YOU ARE USING UBUNTU DESKTOP, THERE IS AN EXTRA STEP TO BE DONE FOR THE CLI TO WORK **
cp /root/.printex/printex.conf /home/your_username/.printex/printex.conf
