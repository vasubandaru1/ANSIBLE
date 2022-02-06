#!/bin/bash

count=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" | jq ".Reservations[].Instances[].PrivateIpAddress" | grep -v null | wc -l)

 if [ $count -eq 0 ]; then
   aws ec2 run-instances --image-id ami-0d997c5f64a74852c --instance-type t3.micro --security-group-ids sg-0a57500c7aa97fd16  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$1}]" | jq
   else
     echo "Instance already exists"

fi
IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$1" | jq ".Reservations[].Instances[].PrivateIpAddress" | grep -v null | wc -l)
sed -e "s/DNSname/$1.roboshop.internal/" -e "s/Ipaddress/$(IP)/" record.jsm >/tmp/record.jsm
aws route53 change-resource-record-sets --hosted-zone-id HOSTED-ZONE-ID --change-batch file:///tmp/record.jsm | jq