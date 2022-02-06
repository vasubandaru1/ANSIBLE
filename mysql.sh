#!/bin/bash

source common.sh

COMPONENT_NAME=Mysql
COMPONENT=mysql

print "Download Mysql repos"
curl -s -L -o /etc/yum.repos.d/mysql.repo https://raw.githubusercontent.com/roboshop-devops-project/mysql/main/mysql.repo &>>$LOG
stat $?

print "Install Mariadb service"
 yum remove mariadb-libs -y &>>$LOG && yum install mysql-community-server -y &>>$LOG
 stat $?

print "Start mysql sevice"
systemctl enable mysqld &>>$LOG && systemctl start mysqld &>>$LOG
stat $?

DEFAULT_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
NEW_PASSWORD='Roboshop@1'

echo 'show databases;' | mysql -u root -p'${NEW_PASSWORD}' &>>$LOG
if [ $? -ne 0 ]; then
print "changing the DEFAULT_PASSWORD"
echo -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_PASSWORD}';\nuninstall plugin validate_password;" >/tmp/pass.sql mysql --connect-expired-password -u root -p"${DEFAULT_PASSWORD}" </tmp/pass.sql &>>$LOG
stat $?
fi

DOWNLOAD '/tmp'


print "load schema"
cd /tmp/mysql-main
 mysql -u root -pRoboshop@1 <shipping.sql &>>$LOG
stat $?