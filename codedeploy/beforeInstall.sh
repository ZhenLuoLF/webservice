#!/bin/bash
cd /var/www/
sudo rm -rf website
mkdir website
sudo chown -R apache.apache website
cd /home/ec2-user
