#!/bin/bash
## info
# terraform show 에서 뽑아낸 데이터를 이용하여 특정 aws 리소스정보 찾기.
# terraform state 를 json format 으로 뽑아내서 json 활용
# terraform state show aws_security_group.hgi-seoul-app-sg -> json support x
# 실행하기 전에 AWS key export 해야 api로 sg 정보 가져올 수 있음
#
## to do list
# not support module.
#
## reference
# Passing bash variable to jq
# https://stackoverflow.com/questions/40027395/passing-bash-variable-to-jq


## variable
tf_show_json_file="temp_tf_show.json"
aws_api_sg_json_file="temp_aws_sg.json"
tf_sg_list_file="temp_tf_sglist"


## rm temp file
function clean_temp_file {
    rm -fv $tf_show_json_file $aws_api_sg_json_file $tf_sg_list_file
}

## terraform sg output
function output_sg {
    echo "terraform state list | grep aws_security_group[.] > $tf_sg_list_file"
    terraform state list | grep aws_security_group[.] > $tf_sg_list_file
	for sg in `cat $tf_sg_list_file`
	do
	    #echo $sg
	    echo "output \"sg-$sg\" {
  value = $sg.id
}"
	done
}


## inspect terraform state to json format
function tf_state_json_result {
   if ! test -f $tf_show_json_file ; then 
       echo "terraform show -json | jq . > $tf_show_json_file" 
       terraform show -json | jq . > $tf_show_json_file
   fi
}


## find tf address with type
function find_tf_address {
    #type="aws_instance"
    type=$1

    #find_tf_address=`cat show-json  | jq .values.root_module[]  | jq '.[] | select(.type == "aws_instance")' |  jq -r '.address'`
    #find_tf_address=`cat show-json  | jq .values.root_module[]  | jq '.[] | select(.type == "aws_security_group")' |  jq -r '.address'`

    cat $tf_show_json_file  | jq .values.root_module[]  | jq --arg type "$type" '.[] | select(.type == $type)' |  jq -r '.address'
}

## show terrafrom sg
function show_sg_list {
	sg_list=`find_tf_address aws_security_group`
	for sg in $sg_list
	do
	    sg_id=`cat $tf_show_json_file  | jq .values.root_module[]  | jq --arg sg "$sg" '.[] | select(.address == $sg)' | jq -r '.values.id'`
	    sg_name=`cat $tf_show_json_file  | jq .values.root_module[]  | jq --arg sg "$sg" '.[] | select(.address == $sg)' | jq -r '.values.name'`
	    echo "$sg_id $sg_name" | sort
	done
}


## show terrafrom ec2 with sg
function show_ec2_list {
	ec2_list=`find_tf_address aws_instance`
	
	for ec2 in $ec2_list
	do
	    ec2_id=`cat $tf_show_json_file  | jq .values.root_module[]  | jq --arg ec2 "$ec2" '.[] | select(.address == $ec2)' |  jq -r '.values.id'`
	    ec2_tags_name=`cat $tf_show_json_file  | jq .values.root_module[]  | jq --arg ec2 "$ec2" '.[] | select(.address == $ec2)' |  jq -r '.values.tags.Name'`
	    ec2_sg_list=`cat $tf_show_json_file  | jq .values.root_module[]  | jq --arg ec2 "$ec2" '.[] | select(.address == $ec2)' |  jq -r '.values.vpc_security_group_ids[]'`
	    echo "$ec2_id $ec2_tags_name"
	    for ec2_sg in $ec2_sg_list
	    do
	        #cat show-json  | jq .values.root_module[]  | jq '.[] | select(.type == "aws_security_group")' | jq '. | select(.values.id == "sg-0f3b79dc88776e7c1")'
	        ec2_sg_name=`cat $tf_show_json_file  | jq .values.root_module[]  | jq '.[] | select(.type == "aws_security_group")' | jq --arg ec2_sg "$ec2_sg"  '. | select(.values.id == $ec2_sg)' | jq -r '.values.name'`
	        echo "$ec2_sg $ec2_sg_name"
	    done
	    echo
	
	done

}


## compare sg between terraform and AWS
function compare_sg_tf_and_aws {
    echo "aws ec2 describe-security-groups > $aws_api_sg_json_file"
	aws ec2 describe-security-groups > $aws_api_sg_json_file

	#aws_sg_id=`cat $aws_api_sg_json_file  | jq .SecurityGroups[] | jq -r .GroupId | sort`
	aws_sg_id=`cat $aws_api_sg_json_file  | jq .SecurityGroups[] | jq -r .GroupId`
	for aws_sg in $aws_sg_id
	do
	    aws_sg_groupname=`cat $aws_api_sg_json_file  | jq .SecurityGroups[]  | jq -r --arg aws_sg "$aws_sg" '. | select(.GroupId == $aws_sg) | .GroupName'`
	
	    # check terraform sg with GroupId
	    check_tf_sg=`cat $tf_show_json_file  | jq .values.root_module[]  | jq '.[] | select(.type == "aws_security_group")' | jq --arg aws_sg "$aws_sg" '. | select(.values.id == $aws_sg) | .values.name'`
	    if [ "$check_tf_sg" == "" ]; then
	        exist_tf_sg="none"
	    else
	        exist_tf_sg="ok"
	    fi
	
	    echo "$aws_sg $aws_sg_groupname $exist_tf_sg"
	done
}


## compare AWS ec2 and terraform ec2
function compare_ec2_tf_and_aws {
	aws ec2 describe-instances > instances.json
	aws_ec2_id_list=`cat instances.json  | jq -r '.Reservations[] | .Instances[] | .InstanceId'`
	
	#tf_show_json_file="temp_tf_show.json"
	
	for ec2 in $aws_ec2_id_list
	do
	    #echo $ec2
	    check_tf_ec2=`cat $tf_show_json_file  | jq .values.root_module[]  | jq --arg ec2 "$ec2" '.[] | select(.values.id == $ec2)' |  jq -r '.values.id'`
	    #cat temp_tf_show.json | jq .values.root_module[]  | jq '.[] | select(.values.id == "i-0552276cb0e69bdfd")' | jq -r '.values.id'
	
	    if [ "$check_tf_ec2" == "" ]; then
	        exist_tf_ec2="none"
	    else
	        exist_tf_ec2="terraform"
	    fi
	     echo "$ec2 $exist_tf_ec2"
	done
}



tf_state_json_result

echo "===== AWS SG ====="
compare_sg_tf_and_aws


#echo "===== Terraform SG ====="
#show_sg_list

echo
echo "===== Terraform ec2 with sg ====="
show_ec2_list

#compare_ec2_tf_and_aws

clean_temp_file
