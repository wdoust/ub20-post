#!/bin/bash
#
# PowerDNS Recursor installation script for Ubuntu Server 20.04 LTS
# Written by Wayne Doust 28 May 2021 Version 0.1
#
STAMP=`date +%Y%m%d`
PRCONF="/etc/powerdns/recursor.conf"
ALLOWFRM="127.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 169.254.0.0/16, 192.168.0.0/16, 172.16.0.0/12, ::1/128, fc00::/7, fe80::/10"
LOCIP="`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`"
LOCIP6="`ifconfig | sed -En 's/::1//;s/.*inet6 (addr:)?(([[:xdigit:]]*::){,4}[[:xdigit:]]*::{,4}[[:xdigit:]]*::{,4}[[:xdigit:]]*::{,4}[[:xdigit:]]*).*/\2/p'`"

## PowerDNS Recursor
##
echo
echo Installing PowerDNS Recursor with configuration as follows:
echo "          Local Address:  $LOCIP, $LOCIP6"
echo "          Allow From:     $ALLOWFRM"
echo "          Config file:    $PRCONF "
echo
sleep 5
apt -y install pdns-recursor
## Make a backup copy of the config file
##
if [ -e $PRCONF.org ];
then
	cp -p $PRCONF $PRCONF.$STAMP;
else
	cp -p $PRCONF $PRCONF.org;
fi
## Modify config file contents
##
sed  -i "/# allow-from=.*/aallow-from=$ALLOWFRM/" "$PRCONF"
sed  -i "s/^local-address=.*/local-address=$LOCIP, 127.0.0.1, ::/g" "$PRCONF"
## Using following line for IPv6 support (not working)
#sed  -i "s/^local-address=.*/local-address=$LOCIP, $LOCIP6/g" "$PRCONF"
echo 
ufw allow dns
ufw limit dns
systemctl enable  pdns-recursor
systemctl restart pdns-recursor
systemctl status  pdns-recursor
echo
echo Check pdns recursor service is operational (above)
echo About to test PDNS server
echo
sleep 10
netstat -tap | grep pdns
dig @$LOCIP
dig @$LOCIP6
echo
echo Installation complete!
echo
exit 0
