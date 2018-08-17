# Printex MultiMasternode install Script
Shell script to install a Printex Masternode on a Linux server running Ubuntu 16.04. Up to 5 recomended for a vps. 
***

Create VPS for 5 USD/Month at https://www.vultr.com/?ref=7459078 (UBUNTU 16.04, x64, 1CPU, 1024MB) 

This script will let you choose as many masternodes you want and will set them up on one vps running UBUNTU 16.04
(5 is the max I recmond on one vps for now)

Save each PRIVATEKEY for Later use

## Installation
```
  wget https://raw.githubusercontent.com/rarealton/masternode-scripts/master/PRTX/install.sh
  bash install.sh
```
***

## Desktop wallet setup  

After the MN is up and running, you need to configure the desktop wallet accordingly. Here are the steps:  
1. Open the Printex Desktop Wallet.  
2. Go to FILE then Reciveing address and create a New Address: **MN_NAME**  
3. Send **10000** PRTX to **MN_NAME**. You need to send all 10000 coins in one single transaction.
4. Wait for 15 confirmations.  
5. Go to **Help -> "Debug Window - Console"**  
6. Type the following command: **masternode outputs**  
7. Go to **TOOLS** at the top  
8. Click **Open Masternode Configuration File** and fill the details:  
* Alias: **MN1**  
* Address: **VPS_IP:PORT**  
* Privkey: **Masternode Private Key**  
* TxHID: **First value from Step 6**  
* Output index:  **Second value from Step 6**  
* Put that all on one line like so: 
```
alias IP:port masternodeprivkey collateral_output_txid collateral_output_index
```

NOTE!!! For each additional MN on this vps in the masternode.conf file put the port as 9797 even though on the vps it will not be the same. You must do this for it to work. The Privkey must match though!!

9. Save the file to add the masternode  
11. Close and open the wallet again.
12. Go to **Masternodes** -> **My Master Nodes** tab
13. If you don't see your masternode, click **Update**
14. Unlock your wallet if it is encrypted
15. Then start your masternode. If you get an error saying invalid ip, open tools / debug console and type 
```
startmasternode alias 0 MN1
```
16. Login to your VPS and check your masternode status by running the following command. If you get **Status 4**, it means your masternode is active.
```
printex-cli masternode status
```
 For the extra nodes you will have to go into the Printex folder directly and run the following file. 
```
./prtxmn_status
```

***

## Usage:
```
printex-cli masternode status  
printex-cli getinfo
```
Extra nodes inside their folders run
```
./prtxmn_status
./prtxmn_getinfo
```
Also, if you want to check/start/stop **Printex**, run one of the following commands as **root**:

```
systemctl status Printex #To check if Printex service is running (add a number to the end like Printex2 to check second node)
systemctl start Printex #To start Printex service  
systemctl stop Printex #To stop Printex service  
systemctl is-enabled Printex #To check if Printex service is enabled on boot  
```  
***

### ** IF YOU ARE USING UBUNTU DESKTOP, THERE IS AN EXTRA STEP TO BE DONE FOR THE CLI TO WORK **
cp /root/.printex/printex.conf /home/your_username/.printex/printex.conf

## Donations

Any donation is highly appreciated

**PRTX**: pQm8iRi7PADKHPCiBH2D6zUdnigkXdtPv6  

