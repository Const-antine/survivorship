#!/bin/bash
yum -y update
yum -y install httpd

myip=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
myamid=`curl http://169.254.169.254/latest/meta-data/ami-id`
myinstid=`curl http://169.254.169.254/latest/meta-data/instance-id`


echo "<h2>WebServer with IP: $myip, AMI ID: $yamid , INSTANCE_ID: $myinstid" > /var/www/html/index.html


sudo service httpd start
sudo service httpd enable
