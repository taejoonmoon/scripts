#!/bin/bash
# check mfa status
# https://docs.aws.amazon.com/cli/latest/reference/iam/list-mfa-devices.html
iam_users=`aws iam list-users | jq -r '.Users | .[].UserName' | grep -v terraform`

for iam_user in $iam_users
do
    #if aws iam list-mfa-devices --user-name $iam_user| grep -i SerialNumber; then 
    if mfa_device=`aws iam list-mfa-devices --user-name $iam_user| grep -i SerialNumber`; then 
        echo "$iam_user: MFA device $mfa_device"
    else
        echo "$iam_user: mfa X"
    fi
done
