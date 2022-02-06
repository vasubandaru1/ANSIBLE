#!/bin/bash

source  common.sh

print "Downloading repo"
curl -s -o /etc/yum.repos.d/mongodb.repo https://raw.githubusercontent.com/roboshop-devops-project/mongodb/main/mongo.repo &>>$LOG
stat $?

print "Install mongodb"
yum install -y mongodb-org &>>$LOG
stat $?

print "update mongodb config"
sed -i -e 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOG
stat $?

print "start mongodb"
systemctl restart mongod &>>$LOG
stat $?

print "Enable mongodb service"
systemctl enable mongod &>>$LOG
stat $?

print "download schema"
curl -s -L -o /tmp/mongodb.zip  "https://github.com/roboshop-devops-project/mongodb/archive/main.zip" &>>$LOG
stat $?

print "Extract schema"
unzip -o -d /tmp /tmp/mongodb.zip &>>$LOG
stat $?

print "Load schema"
cd /tmp/mongodb-main
mongo < catalogue.js &>>$LOG
mongo < users.js &>>$LOG
stat $?

