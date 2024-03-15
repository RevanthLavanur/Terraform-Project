#!/bin/bash
sudo su
yum update -y
yum install httpd -y
cd /var/www/html
echo " Hello Revanth Reddy . This is Server EC-2 " > index.html
service httpd start
