#!/bin/bash
#action=$1

regions="ap-northeast-2 eu-west-2 ca-central-1 ap-southeast-1 ap-south-1"
#regions="ap-south-1"

action="start-instances"
#action="stop-instances"

for region in $regions
do
    echo $region
    #ec2_id=$(aws ec2 describe-instances --region ap-northeast-2 --query 'Reservations[*].Instances[*].[InstanceId,to_string(Tags[?Key==`Name`].Value)]' --output text \
    ec2_id=$(aws ec2 describe-instances --region $region --query 'Reservations[*].Instances[*].[InstanceId]' --output text \
| tr -d "[" | tr -d "]" | tr -d "\"" )
    for ec2 in $ec2_id
    do
        #aws ec2 start-instances --region $region --instance-ids $ec2 --output text
        aws ec2 $action --region $region --instance-ids $ec2 --output text
        echo
    done
done

