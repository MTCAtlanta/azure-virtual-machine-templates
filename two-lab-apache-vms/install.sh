#!/bin/bash

# install Apache and PHP
apt-get -y update
apt-get -y install apache2 php5

# write some PHP
cd /var/www/html

wget https://raw.githubusercontent.com/MTCAtlanta/azure-virtual-machine-templates/master/two-lab-apache-vms/index.php
rm /var/www/html/index.html
# restart Apache
apachectl restart