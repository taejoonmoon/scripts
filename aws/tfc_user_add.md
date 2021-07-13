1. 사전조건 : iam user생성을 위해서는 admin 권한이 필요하다. 
AWS SSO의 해당 AWS account -> Command line or programmtic access 에서 credentials를 생성하면 임시 token을 이용하여 AWS에 api로 전급할 수 있다.
https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-configure-envvars.html?icmpid=docs_sso_user_portal
AWS_SESSION_TOKEN : AWS STS 작업에서 직접 검색한 임시 보안 자격 증명을 사용하는 경우 필요한 세션 토큰 값을 지정합니다. 
https://docs.aws.amazon.com/cli/latest/reference/sts/assume-role.html 문서를 보면 AssueRole에 의해 생성된 임시 security credentials의 유효기간은 1시간이다.
By default, the temporary security credentials created by AssumeRole last for one hour. 


아래 스크립트에서는 jq 를 이용하므로 쉘에서 실행하려면 사전에 jq를 설치해야 한다.

1. AWS CLI를 이용한 IAM user 생성
다음 작업을 진행한다. 
user 생성
tag 설정
AdministratorAccess 권한의 user policy 추가
access key 발급
 
tags를 이용하여 누가 만들었는지, 어디에서 쓰는지를 명시하였다.
아래 실행시 deployedby는 IAM user 생성하는 본인을 확인할 수 있도록 해주자. usedby 는 TC에서 쓰는 것을 명시했다.

```
tfc_user="tfc"

# create user
aws iam create-user --user-name $tfc_user
aws iam tag-user --user-name $tfc_user --tags '{"Key": "deployedby", "Value": "bsj-tjmoon"}'
aws iam tag-user --user-name $tfc_user --tags '{"Key": "usedby", "Value": "BSG Terraform Cloud"}'
aws iam list-user-tags --user-name $tfc_user
aws iam attach-user-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --user-name $tfc_user
result=`aws iam create-access-key --user-name $tfc_user`
echo "run this command"
echo "export AWS_ACCESS_KEY_ID=`echo $result  | jq .AccessKey.AccessKeyId`"
echo "export AWS_SECRET_ACCESS_KEY=`echo $result  | jq .AccessKey.SecretAccessKey`"
```

# delete user
```
aws iam delete-access-key --user-name $tfc_user --access-key-id xxxxx
aws iam detach-user-policy --user-name $tfc_user --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam delete-user --user-name $tfc_user
```

AWS_SESSION_TOKEN : AWS STS 작업에서 직접 검색한 임시 보안 자격 증명을 사용하는 경우 필요한 세션 토큰 값을 지정합니다. 
https://docs.aws.amazon.com/cli/latest/reference/sts/assume-role.html 문서를 보면 AssueRole에 의해 생성된 임시 security credentials의 유효기간은 1시간이다.
By default, the temporary security credentials created by AssumeRole last for one hour. 

