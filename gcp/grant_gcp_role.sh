#!/bin/bash

REGION="asia-northeast3"
ZONE="$REGION-a"
HOST_PROJECT="sample-gw-shared-vpc"
PROJECT="sample-gw-dev-324106"

roles="roles/compute.networkViewer
roles/compute.viewer
roles/iam.serviceAccountUser
roles/iap.tunnelResourceAccessor
roles/cloudsql.client
roles/redis.viewer
"

add_user_roles() {
    member=$1

    for role in $roles
    do
        #echo $role
        #gcloud projects add-iam-policy-binding sample-gw-dev-324106 --member=user:sample.gcp.lab@gmail.com --role=roles/viewer
        echo "gcloud projects add-iam-policy-binding $PROJECT --member=$member --role=$role"
    done
}

check_user_roles() {
    member=$1

    POLICY_JSON="tmp_policy.json"

    gcloud projects get-iam-policy $PROJECT --format=json > $POLICY_JSON
    
    # https://stackoverflow.com/questions/40027395/passing-bash-variable-to-jq
    user_roles=`cat $POLICY_JSON  | jq '.bindings[]' | jq '. | {members: .members[], role: .role }' | jq -r --arg member "$member" '. | select(.members==$member)' | jq -r  .role`
    for user_role in $user_roles
    do
        echo $user_role
    done
    
    test -f $POLICY_JSON && rm -f $POLICY_JSON
}

delete_user_roles() {
    member=$1

    get_user_roles=`check_user_roles $member`

    for role in $get_user_roles
    do
        #echo $role
        gcloud projects remove-iam-policy-binding $PROJECT --member=$member --role=$role > /dev/null
        #echo "gcloud projects remove-iam-policy-binding $PROJECT --member=$member --role=$role"
    done

}

#member="user:sample.gcp.lab@gmail.com"
#member="serviceAccount:sample-web-general-sa@sample-gw-dev-324106.iam.gserviceaccount.com"
member=$1
action=$2

if [ $# -ne 2 ]; then
    echo "Usage: $0 member {get|add|delete}"
    exit -1
fi

echo "member: $member"

case $action in
  get)
    check_user_roles $member
    ;;

  add)
    add_user_roles $member
    ;;
  delete)
    delete_user_roles $member
    ;;

  *)
    echo "unknown"
    ;;
esac


#if [ $action = "get" ];
#then
#    check_user_roles $member
#fi
#
#if [ $action = "delete" ];
#then
#    delete_user_roles $member
#fi

#add_user_roles $member
#check_user_roles user:sample.gcp.lab@gmail.com
#delete_user_roles $member
