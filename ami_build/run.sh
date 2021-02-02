# export AWS_PROFILE=example
packer validate -syntax-only aws-ami-baking.json
#packer build -var-file=var-files/variables_${OS}.json -var-file=var-files/variables_${AWS_PROFILE}.json aws-ami-baking.json
packer build  -var-file=variables_ubuntu.json aws-ami-baking.json

ami_id="ami-0b1e492719fab1019"
account="802433541830"
aws ec2 reset-image-attribute --image-id $ami_id --attribute launchPermission
aws ec2 modify-image-attribute --image-id $ami_id --launch-permission "{\"Add\":[{\"UserId\":\"$account\"}]}"

