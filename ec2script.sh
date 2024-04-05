#!/bin/bash
# Script for quick configuration of an EC2 Server

# Installs the necessaries for most PHP Jobs

# Run as Root or suffer the consequences of stuff telling you it can't get a lock and whatnot

cd /etc/yum.repos.d
wget http://rpms.famillecollet.com/enterprise/remi.repo
sed -i.bak -e '1,/remi-test/ s/#baseurl/baseurl/' -e '1,/remi-test/ s/$releasever\/remi/5\/remi/' remi.repo
cd

yum install httpd-devel mod_ssl mysql php* vsftpd mysql-server sqlite gcc make pcre-devel git-all

yum --enablerepo=remi install phpmyadmin

pear install pecl/xdebug
pecl install apc

sed -i.bak 's/shm_size=64/shm_size=64M/' /etc/php.d/apc.ini

cd /etc
sed -i.bak -e 's/;date.timezone =/date.timezone = "America/Denver"' -e 's/;intl.default_locale =/intl.default_locale = en_US' -e 's/;sysvshm.init_mem = 10000/&\
zend_extension="\/usr\/lib64\/php\/modules\/xdebug.so"/' php.ini

cd /etc/httpd/conf.d
sed -i.bak -e '1,/\/Directory/ s/deny from all/allow from all/' phpMyAdmin.conf

if [ -n "$1" ]
then
	useradd "$1"
	passwd	"$1"
	usermod -a -G root "$1"
	usermod -a -G apache "$1"
	usermod -a -G ftp "$1"
fi

chmod -R 0775 /var/www/html
chgrp -R apache /var/www/html
chmod g+s /var/www/html
chown -R apache /var/www/html

VSFTPDFILE=/etc/vsftpd/vsftpd.conf
echo "pasv_enable=YES" 1>>$VSFTPDFILE
echo "pasv_min_port=1024" 1>>$VSFTPDFILE
echo "pasv_max_port=1048" 1>>$VSFTPDFILE
echo -n "Input the Public IP of your EC2 Instance followed by [ENTER]: "
read pubip
echo "pasv_address=$pubip" 1>>$VSFTPDFILE

service httpd start
service vsftpd start
service mysqld start

echo -n "Input the desired mysql password for 'admin' followed by [ENTER]: "
read MYSQLPASS

mysql -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY '$MYSQLPASS'; GRANT ALL PRIVILEGES on *.* to 'admin'@'localhost' WITH GRANT OPTION;"

service mysqld restart