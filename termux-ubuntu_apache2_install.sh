#!/bin/sh

# Termux-Ubuntu Apache2 & php set
# made by jassmusic @20.07.07
# auto editing /etc/apache2/ports.conf
# auto editing /etc/apache2/apache2.conf

#### set apache2 port what you want
APACHE_PORT="8000"

# install package
apt install -y apache2 php libapache2-mod-php

# change port
sed -i "s/Listen 80/Listen ${APACHE_PORT}/" /etc/apache2/ports.conf

# add ServerName
sed -i '/#ServerRoot "\/etc\/apache2"/i \
ServerName localhost' /etc/apache2/apache2.conf

# make symbolic link
ln -s /var/www/html /home/html

echo ""
echo " Finish! -- run 'service apache2 start'"
echo "         -- address 'http://your-address:${APACHE_PORT}'"
echo "         -- based folder '/home/html'"
echo ""
