#!/bin/bash
#
# Post installation script for Ubuntu Server 20.04 LTS
# Written by Wayne Doust 18 May 2021 Version 0.1
#

SCTL="/etc/sysctl.conf"
STAMP=`date +%Y%m%d`
SWPP=20
HOST=`hostname -s`
FQDN=`hostname -d`
MAILFWD=121.200.0.25
EMAILINST=email@$FQDN
EMAILADMIN=admin@$FQDN
SNMPRO=public
SNMPRW=private
SNMPSRV=127.0.0.1
ADDOM=ADdomainname
ADFQDN=ADFQDN
ADUSER=Administrator

timedatectl set-timezone Australia/Sydney
#hostnamectl set-hostname $HOST
#cat $HOST.$FQDN > /etc/hostname

### Apply updates and install cockpit & pcp
## Note: Whilst you can install both, pick either Cockpit or webmin
##
echo
echo Apply updates 
echo
sleep 3
apt -y update && apt -y upgrade
echo
echo Installing cockpit 
echo
sleep 3
apt -y install cockpit cockpit-pcp
apt -y install net-tools
systemctl enable cockpit
systemctl start cockpit

### (Optional) Add server to Actice Directory Domain
#echo "deb http://au.archive.ubuntu.com/ubuntu/ bionic universe" >> /etc/apt/sources.list 
#echo "deb http://au.archive.ubuntu.com/ubuntu/ bionic-updates universe" >> /etc/apt/sources.list 
#hostnamectl set-hostname $HOST.$ADFQDN
#hostnamectl
#echo Check Name servers are correct
#cat /etc/resolv.conf | grep nameserver
#echo
#sleep 10
#systemctl disable systemd-resolved
#systemctl stop systemd-resolved
#apt -y update
#apt -y install realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit
#echo 
#echo Discover AD Domain
#echo 
#realm discover $ADDOM
#realm join -U $ADUSER $ADDOM
#realm list $ADDOM
#pam-auth-update --enable mkhomedir
## Do the following if the previous line doesn't work
##cp /usr/share/pam-configs/mkhomedir /usr/share/pam-configs/mkhomedir.org
##echo "Name: activate mkhomedir" > /usr/share/pam-configs/mkhomedir
##echo "Default: yes" >> /usr/share/pam-configs/mkhomedir
##echo "Priority: 900" >> /usr/share/pam-configs/mkhomedir
##echo "Session-Type: Additional" >> /usr/share/pam-configs/mkhomedir
##echo "Session:" >> /usr/share/pam-configs/mkhomedir
##echo "        required                        pam_mkhomedir.so" >> /usr/share/pam-configs/mkhomedir
##echo "umask=0022 skel=/etc/skel" >> /usr/share/pam-configs/mkhomedir
#pam-auth-update
#systemctl restart sssd
#realm permit $ADUSER@$ADFQDN 
#realm permit 'Domain Admins' 'sysadmins'
#echo "$ADUSER@$ADFQDN	ALL=(ALL)	ALL" 		 > /etc/sudoers.d/domain_admins
#echo "%Domain\ Admins@ADFQDN	ALL=(ALL)	ALL" 	>> /etc/sudoers.d/domain_admins
#echo "%sysadmins@ADFQDN	ALL=(ALL)	ALL" 		>> /etc/sudoers.d/domain_admins

### Optional logging tools based around pcp
## Don't install these unless you know what you're doing
# apt -y install pcp 
# systemctl enable pmcd
# systemctl start pmcd
# systemctl enable pmlogger
# systemctl start pmlogger 
# systemctl enable pmie
# systemctl start pmie 
## use 'pcp atop' 'pmstat' 'pmiostat' etc
## Following is for web API for Grafana
# systemctl enable pmproxy
# systemctl start pmproxy
# wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
# add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
# apt update
# apt -y install grafana
# systemctl enable grafana-server
# systemctl start grafana-server
# ufw allow 3000/tcp
## Securing Grafana using NGINX Reverse Proxy (more here)
## See https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-grafana-on-ubuntu-20-04

### Setup ufw
echo
echo Setting up UFW 
echo
sleep 3
ufw default deny incoming
ufw allow ssh
ufw limit ssh
ufw allow 9090/tcp
echo y | ufw enable
ufw status

### Install fail2ban
echo
echo Installing fail2ban 
echo
sleep 3
apt -y install fail2ban
#configure fail2ban

### Change Swappiness from 60 to 20
## Need to add check for current value in config file
printf "\nCurrent swappiness="
cat /proc/sys/vm/swappiness
cat $SCTL | grep swappiness | sed -e 's/[^0-9]//g'
echo Current setting=$CSWP 
echo Swap Details
swapon --show
echo
echo Set swappiness to 20
echo
sleep 3
printf "\n"
if [ -e $SCTL.org ];
then
	cp -p $SCTL $SCTL.$STAMP;
else
	cp -p $SCTL $SCTL.org;
fi
echo "" >> $SCTL
echo "#Set swappiness to $SWPP" >> $SCTL`
echo "vm.swappiness = $SWPP" >> $SCTL`


### Install useful tools
## wget       - get files via http
## telnet     - telnet client
## bind9utils - utlities for querying dns (such as dig)
## nmap       - network analysis tool
## mlocate    - Faster and more efficient file locator
## mc         - Midnight Commander (XTree like file system interface)
## elinks     - Text based broswer (has dependencies)
## systat     - Statistical tools such as iostat
echo
echo Installing tools 
echo
sleep 3
apt -y install wget telnet bind9-utils nmap mlocate mc systat
#apt -y install elinks

### Install VMware vm-tools
apt -y install vm-tools
vmware-toolbox-cmd -v

## ALT: Install Hyper-V LIS
#echo -e "hv_vmbus" >> /etc/initramfs-tools/modules
#echo -e "hv_storvsc" >> /etc/initramfs-tools/modules
#echo -e "hv_blkvsc" >> /etc/initramfs-tools/modules
#echo -e "hv_netvsc" >> /etc/initramfs-tools/modules
#apt -y install linux-virtual linux-cloud-tools-virtual linux-tools-virtual
#update-initramfs -u
## ALT: Install Hyper-V Enhanced Session Mode (xRDP)
## See https://www.kali.org/docs/virtualization/install-hyper-v-guest-enhanced-session-mode/
#apt -y install git
#git clone https://github.com/Microsoft/linux-vm-tools.git ~/linux-vm-tools
#cd ~/linux-vm-tools/ubuntu/
#chmod +x install.sh
#./install.sh
##edit /etc/xrdp/xrdp.ini Change port=vsock://-1:3389 to use_vsock=false
#systemctl enable xrdp.service
#systemctl start xrdp.service
## On host in Admin PS: Set-VM -VMName <vmname> -EnhancedSessionTransportType HvSocket

### Setup email relay
echo
echo Setup email relay 
echo
sleep 3
apt -y install s-nail
ln -s /usr/bin/s-nail /bin/email
echo -e "set mta=smtp://$MAILFWD " >> /etc/mail.rc
echo -e "set mailx-extra-rc=/etc/mail.rc" >> /etc/s-nail.rc
echo 'Testing Email relay' | s-nail --subject='Email test 1'  -r "$HOST<$HOST@$FQDN>" $EMAILINST

### Setup SNMP (Not finished)
echo
echo Setup SNMP 
echo
sleep 3
apt -y install snmpd snmp
ufw allow snmp
ufw status
#add lines for editing /etc/snmp/snmpd.conf
#change rocommunity public ro6community public etc
#SNMPDOPTS='-LS 0-4 d -Lf /dev/null -p /var/run/snmpd.pid'
cp /etc/snmp/snmpd.conf /etc/snmpd.conf.org
systemctl enable snmpd
systemctl restart snmpd
systemctl status snmpd
snmpwalk -v 2c -c $SNMPRO localhost

### Setup Unattended Updates (Not finished)
echo
echo Setup unattended updates 
echo
sleep 3
apt -y install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades ### Requires intervention
apt-config dump APT::Periodic::Unattended-Upgrade
cat /etc/apt/apt.conf.d/50unattended-upgrades | grep -v '//' | grep '[A-Aa-z]'
apt -y install apt-listchanges 
sed -i "/\b\(Unattended-Upgrade\:\:Mail\)\b/d" /etc/apt/apt.conf.d/50unattended-upgrades
echo -e "Unattended-Upgrade::Mail \"$EMAILADMIN\";" >> /etc/apt/apt.conf.d/50unattended-upgrades

### Install Webmin
echo
echo Installing Webmin 
echo
sleep 3
apt -y install wget apt-transport-https software-properties-common
wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
add-apt-repository "deb [arch=amd64] http://download.webmin.com/download/repository sarge contrib"
apt -y install webmin
ufw allow webmin
ufw limit webmin

###
### Application Section
###

### Install and start VSFTPD
#echo
#echo Installing VSFTPD 
#echo
#sleep 3
#apt -y install vsftpd ftp
#systemctl enable vsftpd.service
#systemctl start vsftpd.service
#ufw allow ftp
#ufw limit ftp
#ufw status

### Install, secure and run MySQL
##
#echo
#echo Installing MariaDB (MySQL) 
#echo
#sleep 3
#apt -y install mariadb-server mariadb-client
# alternate install in case the above doesn't work
#apt -y install mariadb-client-10.3
#apt -y install mariadb-server-10.3
# Secure MySQL
#systemctl start mariadb
#mysql_secure_installation
#systemctl enable mariadb.service

### Install CPAN Minus and update PERL modules (some will fail on dependencies)
#echo
#echo Installing CPAN and PERL modules (This will take a while and requires interaction) 
#echo
#sleep 5
#apt -y install make
#apt -y install libnet-ssleay-perl perl-IO-Zlib 
#cpan App::cpanminus
#cpanm Net::FTPSSL
#cpanm App::cpanoutdated
#cpan-outdated -p | cpanm

### Install Apache web server (needs work)
#echo
#echo Installing Apache web server 
#echo
#sleep 3
#apt -y install apache2 
#apachectl -v
#<change httpd.conf listen to 0.0.0.0:80>
#be sure to set FQDN
#ufw allow http
#ufw allow https
#ufw status
#apachectl graceful
#apachectl configtest

### Install PHP for Apache, MySQL and PEAR
#echo
#echo Installing PHP
#echo
#sleep 3
#apt -y install php php-pear php-mysql 
## Enable the following as required: Postgres, ODBC (MS SQL), LDAP, SOAP 
#apt -y install php-pgsql php-odbc php-ldap php-soap
## Enable the following to install all PHP related development tools (this is a huge list > 60 packages)
## Only install this on test/dev servers. Don't install on stage, canary or prod servers.
#apt -y install pkg-php-tools
## 
#echo -e "<?php phpinfo(); ?>" > /var/www/html/info.php
# Test with http://server/info.php
#systemctl restart httpd.service
## Setup dedicated Apache2 user


### Install NGINX instead of Apache (Needs lots more work)
#echo
#echo Installing NGINX 
#echo
#sleep 3
#apt -y install nginx php php-common php-fpm
## Install as required
#apt -y install php-cli php-json php-pdo php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath
#ufw allow 'nginx http'
#ufw allow 'nginx https'
#ufw reload
#systemctl stop httpd 
#systemctl stop apache2
#systemctl disable --now httpd
#systemctl disable --now apache2
#systemctl enable nginx 
#systemctl start nginx  
#nginx -v 
#nginx -t
#mkdir -p /var/www/<website>/public_html 
#mkdir /var/www/<website>/logs 
#chown -R nginx:nginx /var/www/<website> 
## edit /etc/nginx/sites-available/default

### Install Wordpress (assumes Apache)
#echo
#echo Installing WordPress 
#echo
#sleep 3
#apt -y install php-gd 
#systemctl restart httpd.service
#wget http://wordpress.org/latest.tar.gz
#tar xzvf latest.tar.gz
#rsync -avP ~/wordpress/ /var/www/html/
#mkdir /var/www/html/wp-content/uploads
#chown -R apache:apache /var/www/html/*
## Setup WordPress Database
#mysql -u root -p <password>
#CREATE DATABASE wordpress;
#CREATE USER wordpressuser@localhost IDENTIFIED BY 'password'
#GRANT ALL PRIVILEGES ON wordpress.* TO wordpressuser@localhost IDENTIFIED BY 'password';
#FLUSH PRIVILEGES;
#exit
## Configure WordPress
#cd /var/www/html
#cat wp-config-sample.php | sed 's/database_name_here/wordpress/g' | sed 's/username_here/wordpressuser/g' | sed 's/password_here/password/g' > wp-config.php

### Installs phpMyAdmin
#echo
#echo Installing phpMyAdmin 
#echo
#sleep 3
#apt -y install php-mbstring php-zip php-gd php-json php-myadmin
#cp /etc/phpMyAdmin/config.inc.php /etc/phpMyAdmin/config.inc.php.orig
## Harden PHPMyAdmin
#cat /etc/phpMyAdmin/config.inc.php.orig | sed -e 's/AllowRoot\'\]\ \=\ TRUE/AllowRoot\'\]\ \=\ FALSE/g' > /etc/phpMyAdmin/config.inc.php  
## Test with http://server/phpMyAdmin


### Finish installation
echo
echo Cleanup & Reboot 
echo
sleep 3
apt -y update && apt -y upgrade
apt -y autoremove --purge
echo
echo Rebooting in 60 seconds 
echo
sleep 3
shutdown -r +1 Server Rebooting in 1 minute
echo
echo
sleep 60
