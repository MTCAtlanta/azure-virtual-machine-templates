#!/bin/bash
# wait for Linux Diagnostic Extension to complete
while ( ! grep "Start mdsd" /var/log/azure/Microsoft.OSTCExtensions.LinuxDiagnostic/2.1.5/extension.log); do
    sleep 5
done

# install Apache and PHP
apt-get -y update
apt-get -y install apache2 php5

# write some PHP
cd /var/www/html

https://raw.githubusercontent.com/MTCAtlanta/azure-virtual-machine-templates/master/two-lab-apache-vms/index.php
rm /var/www/html/index.html
# restart Apache
apachectl restart