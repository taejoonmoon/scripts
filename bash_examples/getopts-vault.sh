#!/bin/bash
# get secret from vault 

usage() {
    echo "$0 -t <vault token> -e (staging|prod) -p <key path> -s (ygy|bdt|devops)"
    echo "option"
    echo " -t: vault token for trusted entities"
    echo " -e: environment"
    echo " -p: vault kv path"
    echo " -s: service"
    echo
    echo "example: $0 -t xxxxx -e staging -p secret/hello -s devops"
}

while getopts "t:e:p:s:h" opt; do
    case $opt in
        t) trusted_entity_token=$OPTARG
            ;;
        e) environment=$OPTARG
            if [ $environment != "staging" ] && [ $environment != "prod" ] ; then
                echo "$environment is not proper value."
                usage
                exit 1
            fi
            ;;
        p) kv_path=$OPTARG
            ;;
        s) service=$OPTARG
            if [ $service != "ygy" ] && [ $service != "bdt" ] && [ $service != "devops" ] ; then
                echo "$service is not proper value."
                usage
                exit 1
            else
                role_name="$service-approle"
            fi
            ;;
        h) usage
            exit
            ;;
        \?) usage
            exit 1
            ;;
    esac
done
shift $(($OPTIND-1))

if [ -z $trusted_entity_token ]; then
    echo "Can't find vault token for trusted entity."
    exit 1
fi

if ! which vault > /dev/null ; then
    echo "Can't find vault. Please install vault. https://www.vaultproject.io/downloads.html"
    exit 1
fi

if ! which jq > /dev/null ; then
    echo "Can't find jq. Please install jq."
    exit 1
fi

if [ $environment = "staging" ]; then
    vault_domain="vault-staging.example.co.kr"
else [ $environment = "prod" ]
    vault_domain="vault.example.co.kr"
fi

vault_port="8200"
vault_url="https://$vault_domain:$vault_port"
using_wrapping_token="yes"
renew_token="yes"

export VAULT_ADDR=$vault_url
 
if ! vault login $trusted_entity_token > /dev/null ; then
    echo "Please check vault token."
    exit 1
fi

if [ $renew_token = "yes" ]; then
    if ! vault token renew > /dev/null ; then
        echo "can't vault token renew."
        exit 1
    fi
fi

if ! role_id=`vault read -field role_id auth/approle/role/$role_name/role-id` ; then
    echo "can't find role_id. Please check $role_name."
    exit 1
fi
if [ $using_wrapping_token = "yes" ]; then
    if ! wrapping_token=`vault write -field wrapping_token -wrap-ttl=60s -f auth/approle/role/$role_name/secret-id` ; then
        echo "can't find wrapping token."
        exit 1
    fi 
    if ! secret_id=`VAULT_TOKEN=$wrapping_token vault unwrap -format=json | jq -r ".data.secret_id"` ; then
        echo "can't find secret_id."
        exit 1
    fi
else
    if ! secret_id=`vault write -format=json -f auth/approle/role/$role_name/secret-id | jq -r ".data.secret_id"` ; then
        echo "can't find secret_id."
        exit 1
    fi
fi
 
if ! MY_VAULT_TOKEN=`vault write -field token auth/approle/login role_id="${role_id}" secret_id="${secret_id}"` ; then
    echo "can't login to vault with role_id and secret_id."
    exit 1
fi
 
if ! vault login $MY_VAULT_TOKEN > /dev/null ; then
    echo "Please check vault token."
    exit 1
fi

vault read -format=json $kv_path | jq -r .data
