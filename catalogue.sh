#!/bin/bash

source common.sh

COMPONENT_NAME=Catalogue
COMPONENT=catalogue

Nodejs



exit

print "Install Nodejs"
yum install -y gcc-c++ make &>>$LOG
curl -s -L https://rpm.nodesource.com/setup_6.x | sudo -E bash - &>>$LOG
yum install -y nodejs &>>$LOG
stat $?

print "Add roboshop user"
id roboshop &>>$LOG
if [ $? -eq 0 ]; then
  echo user Roboshop already exists &>>$LOG
else
  useradd roboshop &>>$LOG
fi
stat $?

print "Download catalogue"
curl -s -L -o /tmp/catalogue.zip "https://github.com/roboshop-devops-project/catalogue/archive/main.zip" &>>$LOG
stat $?

print "Remove old content"
rm -rf /home/roboshop/catalogue
stat $?

print "Extract catalogue"
unzip -o -d /home/roboshop /tmp/catalogue.zip &>>$LOG
stat $?

print "copy content"
mv /home/roboshop/catalogue-main /home/roboshop/catalogue
stat $?

print "Nodejs dependecies"
npm install --unsafe-perm &>>$LOG
stat $?

print "Fix app permissions"
chown -R roboshop:roboshop /home/roboshop
stat $?

print "update DNS records in systemD config"
sed -i -e "s/MONGO_DNSNAME/mongodb.roboshop.internal/" /home/roboshop/catalogue/systemd.service &>>$LOG
stat$?

print "copy systemd file"
mv /home/roboshop/catalogue/systemd.service /etc/systemd/system/catalogue.service
stat$?

print "start catalogue service"
systemctl daemon-reload &>>$LOG && systemctl restart catalogue &>>$LOG && systemctl enable catalogue &>>$LOG
stat$?

print "checking DB connection from APP"
STAT=$(curl -s localhost:8080/health) | jq.mongo
echo status = $STAT
if [ "$STAT" = "true" ]; then
  stat 0
  else
    stat 1
