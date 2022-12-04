#!/bin/bash
backend_file="backend.tf"

config_backend() {
  cat << EOF > $backend_file
terraform {
  backend "s3" {
    bucket = "${aws_environment}-devops-tools"
    key    = "terraform/${resource_name}/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "terraform-lock"
  }
}
EOF

}

if ! ls *.tf >/dev/null ; then
  echo "can't find terraform tf file."
  exit 1
fi

# check aws profile
case $AWS_PROFILE in
  rgpk-lab )
    aws_environment="staging" ;;
  prod-example )
    aws_environment="prod" ;;
  * )
    echo "Please configure aws profile to rgpk-lab or prod-example"
    exit 1
esac

resource_name=`pwd | awk -Fdevops_terraform\/ '{ print $2 }'`

if [ -f $backend_file ]; then
  if ! egrep -q "^[[:blank:]]+key[[:blank:]]+=[[:blank:]]+\"terraform/${resource_name}/terraform.tfstate" $backend_file ; then
    echo "can't find key. $backend_file will be updated."
    config_backend && terraform init -force-copy
  fi
  if ! egrep -q "^[[:blank:]]+dynamodb_table[[:blank:]]+=[[:blank:]]+\"terraform-lock" $backend_file ; then
    echo "can't find dynamodb_table. $backend_file will be updated."
    config_backend && terraform init -force-copy
  fi
else
  config_backend
  echo "created $backend_file file."
  terraform init -force-copy
fi
