#!/bin/bash
sudo su
yum update -y
yum install httpd -y
cd /var/www/html
echo " Hello Sai Reddy . This is Server EC-1 " > index.html
service httpd start
