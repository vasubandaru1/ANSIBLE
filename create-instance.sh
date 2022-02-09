#!/bin/bash

UPDATE_DNS_RECORDS() {
   IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" | jq ".Reservations[].Instances[].PrivateIpAddress" | grep -v null | wc -l)
  sed -e "s/DNSname/$1-dev.roboshop.internal/" -e "s/Ipaddress/$(IP)/" record.jsm >/tmp/record.jsm
  aws route53 change-resource-record-sets --hosted-zone-id Z10262683C43F5P8H0WOJ
   --change-batch file:///tmp/record.jsm | jq
}
CREATE() {
count=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" | jq ".Reservations[].Instances[].PrivateIpAddress" | grep -v null | wc -l)

 if [ $count -eq 0 ]; then
   aws ec2 run-instances --launch-template launchtemplateid=lt-089978c89270e0069,version=1  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1}]" | jq
   else
     echo -e "\e[1;33m$1 Instance already exists\e[0m"
     return

 fi

 sleep 5

UPDATE_DNS_RECORDS $1

 }

 if [ '$1' == 'all' ]; then
   ALL=(frontend mongodb catalogue redis user cart mysql shipping rabbitmq payment)
   for component in ${ALL[*]}; do
     echo "Creating Instance - $component"
     CREATE $component
     done
  else
    create $1
 fi