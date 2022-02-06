#!/bin/bash

print() {
  echo -n -e "\e[1m$1\e[0m.."
  echo -e "\n\e[36m..............1$..............\e[0m" >>$LOG
}

stat() {
  if [ $1 -eq 0 ];
  then
    echo -e "\e[1;32mSUCESS\e[0m"
  else
    echo -e "\e[1;33mFAILURE\e[0m"
    echo -e "\e[1;34mscript the failed and check detailed log in $LOG file \e[0m"
 fi
}

LOG=/tmp/roboshop.log
rm -f $LOG

ROBOSHOP_USER() {
  print "Add roboshop user"
  id roboshop &>>$LOG
  if [ $? -eq 0 ]; then
    echo user Roboshop already exists &>>$LOG
  else
    useradd roboshop &>>$LOG
  stat $?
fi

}

SYSTEMD() {
  print "Fix app permissions"
  chown -R roboshop:roboshop /home/roboshop
  stat $?

  print "update DNS records in systemD config"
  sed -i -e "s/MONGO_DNSNAME/mongodb.roboshop.internal/" -e "s/REDIS_ENDPOINT/redis.roboshop.internal/" -e "s/MONGO_ENDPOINT/mongodb.roboshop.internal/"-e "s/CATALOGUE_ENDPOINT/catalogue.roboshop.internal/" -e "s/CARTENDPOINT/cart.roboshop.internal/" -e "s/DBHOST/mysql.roboshop.internal/" -e "s/CARTHOST/cart.roboshop.internal/" -e "s/USERHOST/user.roboshop.internal/" -e "s/AMQHOST/rabbitmq.roboshop.internal/" /home/roboshop/$COMPONENT/systemd.service &>>$LOG
  stat $?

  print "copy systemd file"
  mv /home/roboshop/$COMPONENT/systemd.service /etc/systemd/system/$COMPONENT.service
  stat $?

  print "start $COMPONENT_NAME service"
  systemctl daemon-reload &>>$LOG && systemctl restart $COMPONENT &>>$LOG && systemctl enable $COMPONENT &>>$LOG
  stat $?

}

MAVEN() {
  Print "Install Maven"
  yum install maven -y &>>$LOG
  stat $?

  ROBOSHOP_USER

 DOWNLOAD "/home/roboshop"

 print "Maven package"
 cd /home/roboshop/${COMPONENT}
 mvn clean package &>>$LOG && mv target/shipping-1.0.jar shipping.jar &>>$LOG
 stat $?

 SYSTEMD

  }

DOWNLOAD() {
  print "Download $COMPONENT_NAME"
  curl -s -L -o /tmp/${COMPONENT}.zip "https://github.com/roboshop-devops-project/${COMPONENT}/archive/main.zip" &>>$LOG
  stat $?

print "Extract $COMPONENT_NAME"
unzip -o -d $1 /tmp/${COMPONENT}.zip &>>$LOG
 stat $?

if [ "$1" = "/home/roboshop" ]; then
  print "Remove old content"
  rm -rf /home/roboshop/$COMPONENT
  stat $?

  print "copy content"
 mv /home/roboshop/$COMPONENT-main /home/roboshop/$COMPONENT
 stat $?

 fi

}


Nodejs() {
print "Install Nodejs"
yum install -y gcc-c++ make &>>$LOG
curl -s -L https://rpm.nodesource.com/setup_6.x | sudo -E bash - &>>$LOG
yum install -y nodejs &>>$LOG
stat $?

ROBOSHOP_USER

DOWNLOAD '/home/roboshop'

print "Nodejs dependecies"
npm install --unsafe-perm &>>$LOG
stat $?

SYSTEMD

}
PYTHON() {

print "Install python3"
 yum install python36 gcc python3-devel -y &>>$LOG

ROBOSHOP_USER

DOWNLOAD '/home/roboshop'

print "Install the dependencies"
cd /home/roboshop/${COMPONENT}
 pip3 install -r requirements.txt &>>$LOG
stat $?

print "Update ${COMPONENT_NAME} service"
USER_ID=$(id -u roboshop)
GROUP_ID=$(id -g roboshop)
 sed -i -e "/uid/ c uid = ${USER_ID}" -e "/gid/ c gid = ${GROUP_ID}" /home/roboshop/${COMPONENT}/${COMPONENT}.ini &>>$LOG
stat $?

SYSTEMD

}